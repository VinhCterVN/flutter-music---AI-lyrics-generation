import 'dart:async';

import 'package:flutter_ai_music/data/models/user_preferences.dart';
import 'package:flutter_ai_music/provider/user_preferences_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/fake_preferences_repository.dart';

void main() {
  test('loads account preferences before becoming ready', () async {
    final repository = FakePreferencesRepository();
    repository.remote['alice'] = const UserPreferences(
      showAnimatedLyrics: false,
      audioQuality: 'Extreme',
    );
    final controller = UserPreferencesController(repository, 'alice');
    addTearDown(controller.dispose);
    expect(controller.state.isReady, isFalse);
    await controller.initialize();
    expect(controller.state.preferences.showAnimatedLyrics, isFalse);
    expect(controller.state.preferences.audioQuality, 'Extreme');
    expect(controller.state.isReady, isTrue);
    expect(
      controller.state.statusFor(PreferenceKey.showAnimatedLyrics),
      PreferenceSaveStatus.saved,
    );
  });

  test(
    'offline change survives relaunch and retries only dirty fields',
    () async {
      final repository = FakePreferencesRepository()..offline = true;
      var controller = UserPreferencesController(repository, 'alice');
      await controller.initialize();
      await controller.setPreference(PreferenceKey.showAnimatedLyrics, false);
      expect(
        controller.state.statusFor(PreferenceKey.showAnimatedLyrics),
        PreferenceSaveStatus.localOnly,
      );
      expect(controller.state.errorMessage, isNotNull);
      controller.dispose();
      controller = UserPreferencesController(repository, 'alice');
      addTearDown(controller.dispose);
      await controller.initialize();
      expect(controller.state.preferences.showAnimatedLyrics, isFalse);
      repository.offline = false;
      repository.remote['alice'] = const UserPreferences(
        audioQuality: 'Extreme',
      );
      await controller.refresh();
      expect(repository.remote['alice']!.showAnimatedLyrics, isFalse);
      expect(repository.remote['alice']!.audioQuality, 'Extreme');
      expect(controller.state.preferences.audioQuality, 'Extreme');
      expect(repository.writes.last, {'show_animated_lyrics': false});
      expect(repository.local['alice']!.pending, isEmpty);
      expect(
        controller.state.statusFor(PreferenceKey.showAnimatedLyrics),
        PreferenceSaveStatus.saved,
      );
    },
  );

  test(
    'late save cannot replace rapid edits or mark them saved early',
    () async {
      final repository = FakePreferencesRepository();
      repository.remote['alice'] = const UserPreferences();
      final controller = UserPreferencesController(repository, 'alice');
      addTearDown(controller.dispose);
      await controller.initialize();
      final started = Completer<void>();
      final release = Completer<void>();
      var calls = 0;
      repository.beforeRemoteWrite = () async {
        if (calls++ == 0) {
          started.complete();
          await release.future;
        }
      };
      final first = controller.setPreference(
        PreferenceKey.showAnimatedLyrics,
        false,
      );
      await started.future;
      final second = controller.setPreference(
        PreferenceKey.showAnimatedLyrics,
        true,
      );
      final third = controller.setPreference(
        PreferenceKey.audioQuality,
        'Standard',
      );
      await Future<void>.delayed(Duration.zero);
      expect(repository.local['alice']!.preferences.showAnimatedLyrics, isTrue);
      expect(repository.local['alice']!.preferences.audioQuality, 'Standard');
      expect(repository.local['alice']!.pending, {
        PreferenceKey.showAnimatedLyrics: true,
        PreferenceKey.audioQuality: 'Standard',
      });
      expect(controller.state.preferences.showAnimatedLyrics, isTrue);
      expect(
        controller.state.statusFor(PreferenceKey.showAnimatedLyrics),
        PreferenceSaveStatus.saving,
      );
      release.complete();
      await Future.wait([first, second, third]);
      expect(repository.remote['alice']!.showAnimatedLyrics, isTrue);
      expect(repository.remote['alice']!.audioQuality, 'Standard');
      expect(controller.state.preferences.showAnimatedLyrics, isTrue);
      expect(
        controller.state.statusFor(PreferenceKey.showAnimatedLyrics),
        PreferenceSaveStatus.saved,
      );
    },
  );

  test(
    'late refresh cannot overwrite an edit saved while it was loading',
    () async {
      final repository = FakePreferencesRepository();
      repository.remote['alice'] = const UserPreferences();
      final controller = UserPreferencesController(repository, 'alice');
      addTearDown(controller.dispose);
      await controller.initialize();
      final response = Completer<UserPreferences?>();
      final started = Completer<void>();
      repository.remoteLoader = (_) {
        started.complete();
        return response.future;
      };
      final refresh = controller.refresh();
      await started.future;
      await controller.setPreference(PreferenceKey.showAnimatedLyrics, false);
      response.complete(const UserPreferences());
      await refresh;
      expect(controller.state.preferences.showAnimatedLyrics, isFalse);
      expect(
        repository.local['alice']!.preferences.showAnimatedLyrics,
        isFalse,
      );
    },
  );

  test(
    'guest preferences persist without a cloud claim or account leakage',
    () async {
      final repository = FakePreferencesRepository();
      var guest = UserPreferencesController(repository, null);
      await guest.initialize();
      await guest.setPreference(PreferenceKey.showAnimatedLyrics, false);
      expect(
        guest.state.statusFor(PreferenceKey.showAnimatedLyrics),
        PreferenceSaveStatus.localOnly,
      );
      expect(repository.writes, isEmpty);
      guest.dispose();
      guest = UserPreferencesController(repository, null);
      addTearDown(guest.dispose);
      await guest.initialize();
      expect(guest.state.preferences.showAnimatedLyrics, isFalse);
      final alice = UserPreferencesController(repository, 'alice');
      addTearDown(alice.dispose);
      await alice.initialize();
      expect(alice.state.preferences.showAnimatedLyrics, isTrue);
    },
  );

  test('disposal during loading ignores late responses', () async {
    final repository = FakePreferencesRepository();
    final response = Completer<UserPreferences?>();
    repository.remoteLoader = (_) => response.future;
    final controller = UserPreferencesController(repository, 'alice');
    final initialization = controller.initialize();
    await Future<void>.delayed(Duration.zero);
    controller.dispose();
    response.complete(const UserPreferences(showAnimatedLyrics: false));
    await initialization;
    expect(repository.local['alice'], isNull);
  });

  test(
    'relaunch retains the latest edit before a previous cloud save finishes',
    () async {
      final repository = FakePreferencesRepository();
      repository.remote['alice'] = const UserPreferences();
      final controller = UserPreferencesController(repository, 'alice');
      await controller.initialize();
      final started = Completer<void>();
      final release = Completer<void>();
      repository.beforeRemoteWrite = () async {
        started.complete();
        await release.future;
      };
      final first = controller.setPreference(
        PreferenceKey.showAnimatedLyrics,
        false,
      );
      await started.future;
      final latest = controller.setPreference(
        PreferenceKey.showAnimatedLyrics,
        true,
      );
      await Future<void>.delayed(Duration.zero);
      controller.dispose();
      repository.offline = true;
      final relaunched = UserPreferencesController(repository, 'alice');
      addTearDown(relaunched.dispose);
      await relaunched.initialize();
      expect(relaunched.state.preferences.showAnimatedLyrics, isTrue);
      expect(
        repository.local['alice']!.pending[PreferenceKey.showAnimatedLyrics],
        isTrue,
      );
      release.complete();
      await Future.wait([first, latest]);
    },
  );

  test(
    'account change replaces global preferences without leaking the old cache',
    () async {
      final repository = FakePreferencesRepository();
      repository.remote['alice'] = const UserPreferences(
        showAnimatedLyrics: false,
      );
      repository.remote['bob'] = const UserPreferences(audioQuality: 'Extreme');
      final identity = StateProvider<String?>((ref) => 'alice');
      final container = ProviderContainer(
        overrides: [
          preferencesUserIdProvider.overrideWith((ref) => ref.watch(identity)),
          userPreferencesRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
      addTearDown(container.dispose);
      container.listen(userPreferencesProvider, (_, next) {});
      final alice = container.read(userPreferencesProvider.notifier);
      await alice.initialize();
      expect(container.read(showAnimatedLyricsProvider), isFalse);
      container.read(identity.notifier).state = 'bob';
      final bob = container.read(userPreferencesProvider.notifier);
      expect(identical(alice, bob), isFalse);
      await bob.initialize();
      expect(container.read(showAnimatedLyricsProvider), isTrue);
      expect(
        container.read(userPreferencesProvider).preferences.audioQuality,
        'Extreme',
      );
      await bob.setPreference(PreferenceKey.audioQuality, 'Standard');
      expect(repository.remote['alice']!.audioQuality, 'High');
      expect(
        repository.local['alice']!.preferences.showAnimatedLyrics,
        isFalse,
      );
    },
  );

  test(
    'uncreated Supabase table uses defaults and exposes setup retry',
    () async {
      final repository = FakePreferencesRepository();
      repository.remoteLoader = (_) async => throw const PostgrestException(
        message: 'Missing table',
        code: 'PGRST205',
      );
      final controller = UserPreferencesController(repository, 'alice');
      addTearDown(controller.dispose);
      await controller.initialize();
      expect(controller.state.isReady, isTrue);
      expect(controller.state.preferences.showAnimatedLyrics, isTrue);
      expect(controller.state.errorMessage, contains('not set up yet'));
      expect(
        controller.state.statusFor(PreferenceKey.showAnimatedLyrics),
        isNot(PreferenceSaveStatus.saved),
      );
    },
  );

  test(
    'reports failure when neither local storage nor cloud can save',
    () async {
      final repository = FakePreferencesRepository()
        ..offline = true
        ..localWriteFails = true;
      final controller = UserPreferencesController(repository, 'alice');
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.setPreference(PreferenceKey.showAnimatedLyrics, false);
      expect(
        controller.state.statusFor(PreferenceKey.showAnimatedLyrics),
        PreferenceSaveStatus.error,
      );
      expect(controller.state.localStorageError, isNotNull);
    },
  );
}
