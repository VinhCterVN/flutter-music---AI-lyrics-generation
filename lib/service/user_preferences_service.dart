import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/user_preferences.dart';

abstract class UserPreferencesRepository {
  Future<CachedUserPreferences?> readLocal(String? userId);
  Future<void> writeLocal(String? userId, CachedUserPreferences data);
  Future<UserPreferences?> loadRemote(String userId);
  Future<UserPreferences> saveRemote(String userId, Map<String, Object> patch);
}

class SupabaseUserPreferencesRepository implements UserPreferencesRepository {
  SupabaseUserPreferencesRepository(this._client);

  final SupabaseClient _client;
  static const _requestTimeout = Duration(seconds: 10);
  String _cacheKey(String? userId) =>
      'user_preferences.v1.${userId ?? 'guest'}';

  @override
  Future<CachedUserPreferences?> readLocal(String? userId) async {
    final local = await SharedPreferences.getInstance();
    final json = local.getString(_cacheKey(userId));
    if (json == null) return null;
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map<String, dynamic>) return null;
      return CachedUserPreferences.fromJson(decoded);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> writeLocal(String? userId, CachedUserPreferences data) async {
    final local = await SharedPreferences.getInstance();
    final saved = await local.setString(
      _cacheKey(userId),
      jsonEncode(data.toJson()),
    );
    if (!saved) throw StateError('Device preferences could not be saved');
  }

  void _checkUser(String userId) {
    if (_client.auth.currentUser?.id != userId) {
      throw StateError('The signed-in account has changed');
    }
  }

  @override
  Future<UserPreferences?> loadRemote(String userId) async {
    _checkUser(userId);
    final row = await _client
        .from('user_preferences')
        .select()
        .eq('user_id', userId)
        .maybeSingle()
        .timeout(_requestTimeout);
    _checkUser(userId);
    return row == null ? null : UserPreferences.fromJson(row);
  }

  @override
  Future<UserPreferences> saveRemote(
    String userId,
    Map<String, Object> patch,
  ) async {
    _checkUser(userId);
    // Only supplied columns are updated on conflict; untouched settings are preserved.
    final row = await _client
        .from('user_preferences')
        .upsert({'user_id': userId, ...patch}, onConflict: 'user_id')
        .select()
        .single()
        .timeout(_requestTimeout);
    _checkUser(userId);
    return UserPreferences.fromJson(row);
  }
}
