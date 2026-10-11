import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/user_preferences.dart';
import '../service/user_preferences_service.dart';
import 'auth_provider.dart';

final userPreferencesRepositoryProvider = Provider<UserPreferencesRepository>(
  (ref) => SupabaseUserPreferencesRepository(ref.watch(supabaseClientProvider)),
);

final preferencesUserIdProvider = Provider<String?>((ref) {
  final auth = ref.watch(authStateProvider);
  // Restore the session immediately while the auth stream emits its initial value.
  return auth.isLoading
      ? ref.read(supabaseClientProvider).auth.currentUser?.id
      : auth.value?.id;
});

final userPreferencesProvider =
    StateNotifierProvider<UserPreferencesController, UserPreferencesState>((
      ref,
    ) {
      final controller = UserPreferencesController(
        ref.watch(userPreferencesRepositoryProvider),
        ref.watch(preferencesUserIdProvider),
      );
      unawaited(controller.initialize());
      return controller;
    });

final showAnimatedLyricsProvider = Provider<bool>(
  (ref) => ref.watch(
    userPreferencesProvider.select(
      (state) => state.preferences.showAnimatedLyrics,
    ),
  ),
);

class UserPreferencesController extends StateNotifier<UserPreferencesState> {
  UserPreferencesController(this._repository, this.userId)
    : super(const UserPreferencesState());

  final UserPreferencesRepository _repository;
  final String? userId;
  final Map<PreferenceKey, Object> _pending = {};
  final Map<PreferenceKey, int> _versions = {};
  int _revision = 0;
  Future<void>? _initialization;
  Future<void>? _saveFuture;
  Future<void>? _refreshFuture;
  Future<bool>? _cacheFuture;

  Future<void> initialize() => _initialization ??= _loadInitial();

  Future<void> _loadInitial() async {
    try {
      final cached = await _repository.readLocal(userId);
      if (!mounted) return;
      if (cached != null) {
        _pending.addAll(cached.pending);
        state = state.copyWith(
          preferences: cached.preferences.withPending(_pending),
          statuses: {
            for (final key in PreferenceKey.values)
              key: PreferenceSaveStatus.localOnly,
          },
        );
      }
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        localStorageError: 'Device settings could not be loaded.',
      );
    }
    if (!mounted) return;
    if (userId != null) await _refreshRemote();
    if (!mounted) return;
    state = state.copyWith(isReady: true);
    if (_pending.isNotEmpty && state.errorMessage == null) {
      await _flushPending();
    }
  }

  Future<void> setPreference(PreferenceKey key, Object value) async {
    if (!mounted || !state.isReady) return;
    final preferences = state.preferences.withValue(key, value);
    _pending[key] = value;
    _versions[key] = (_versions[key] ?? 0) + 1;
    _revision++;
    state = state.copyWith(
      preferences: preferences,
      statuses: {...state.statuses, key: PreferenceSaveStatus.saving},
      clearError: true,
    );
    // Persist every edit promptly, including edits made during an earlier cloud save.
    await _persistCache();
    if (mounted) await _flushPending();
  }

  Future<void> refresh() async {
    await initialize();
    if (!mounted) return;
    await _flushPending();
    if (!mounted || _pending.isNotEmpty || userId == null) return;
    if (_refreshFuture != null) return _refreshFuture!;
    final future = _refreshRemote();
    _refreshFuture = future;
    try {
      await future;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<void> _refreshRemote() async {
    if (!mounted) return;
    final revision = _revision;
    state = state.copyWith(isRefreshing: true);
    try {
      var remote = await _repository.loadRemote(userId!);
      if (!mounted) return;
      remote ??= await _repository.saveRemote(userId!, const {});
      if (!mounted) return;
      // A refresh started before a new edit must not restore stale data.
      if (revision != _revision) return;
      state = state.copyWith(
        preferences: remote.withPending(_pending),
        statuses: {
          for (final key in PreferenceKey.values)
            key: _pending.containsKey(key)
                ? PreferenceSaveStatus.localOnly
                : PreferenceSaveStatus.saved,
        },
        clearError: true,
      );
      await _persistCache();
    } catch (error) {
      if (mounted && revision == _revision) {
        state = state.copyWith(errorMessage: _cloudError(error));
      }
    } finally {
      if (mounted) state = state.copyWith(isRefreshing: false);
    }
  }

  Future<void> _flushPending() async {
    if (!mounted || _pending.isEmpty) return;
    if (_saveFuture != null) return _saveFuture!;
    final future = _savePending();
    _saveFuture = future;
    try {
      await future;
    } finally {
      _saveFuture = null;
    }
  }

  Future<void> _savePending() async {
    while (mounted && _pending.isNotEmpty) {
      final patch = Map<PreferenceKey, Object>.of(_pending);
      final versions = Map<PreferenceKey, int>.of(_versions);
      state = state.copyWith(
        statuses: {
          ...state.statuses,
          for (final key in _pending.keys) key: PreferenceSaveStatus.saving,
        },
      );
      final savedLocally = await _persistCache();
      if (!mounted) return;
      if (userId == null) {
        state = state.copyWith(
          statuses: {
            ...state.statuses,
            for (final key in _pending.keys)
              key: savedLocally
                  ? PreferenceSaveStatus.localOnly
                  : PreferenceSaveStatus.error,
          },
        );
        return;
      }
      try {
        final remote = await _repository.saveRemote(userId!, {
          for (final entry in patch.entries) entry.key.column: entry.value,
        });
        if (!mounted) return;
        for (final key in patch.keys) {
          if (_versions[key] == versions[key]) _pending.remove(key);
        }
        _revision++;
        state = state.copyWith(
          preferences: remote.withPending(_pending),
          statuses: {
            for (final key in PreferenceKey.values)
              key: _pending.containsKey(key)
                  ? PreferenceSaveStatus.saving
                  : PreferenceSaveStatus.saved,
          },
          clearError: true,
        );
        await _persistCache();
      } catch (error) {
        if (!mounted) return;
        final persisted = await _persistCache();
        if (!mounted) return;
        state = state.copyWith(
          statuses: {
            ...state.statuses,
            for (final key in _pending.keys)
              key: persisted
                  ? PreferenceSaveStatus.localOnly
                  : PreferenceSaveStatus.error,
          },
          errorMessage: _cloudError(error),
        );
        return;
      }
    }
  }

  Future<bool> _persistCache() async {
    if (_cacheFuture != null) return _cacheFuture!;
    final future = _writeCache();
    _cacheFuture = future;
    try {
      return await future;
    } finally {
      _cacheFuture = null;
    }
  }

  Future<bool> _writeCache() async {
    while (mounted) {
      final revision = _revision;
      final cached = CachedUserPreferences(
        preferences: state.preferences,
        pending: _pending,
      );
      try {
        await _repository.writeLocal(userId, cached);
        if (!mounted) return false;
        state = state.copyWith(clearLocalError: true);
        if (_revision == revision) return true;
      } catch (_) {
        if (mounted) {
          state = state.copyWith(
            localStorageError: 'Settings could not be saved on this device.',
          );
        }
        return false;
      }
    }
    return false;
  }

  String _cloudError(Object error) {
    if (error is PostgrestException &&
        const ['42P01', 'PGRST205'].contains(error.code)) {
      return 'Account settings are not set up yet. Your changes will sync after setup.';
    }
    return 'Could not sync settings to your account. Try again when connected.';
  }
}
