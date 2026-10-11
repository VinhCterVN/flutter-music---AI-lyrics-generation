import 'package:flutter_ai_music/data/models/user_preferences.dart';
import 'package:flutter_ai_music/service/user_preferences_service.dart';

class FakePreferencesRepository implements UserPreferencesRepository {
  final local = <String?, CachedUserPreferences>{};
  final remote = <String, UserPreferences>{};
  final writes = <Map<String, Object>>[];
  bool offline = false;
  bool localWriteFails = false;
  Future<void> Function()? beforeRemoteWrite;
  Future<UserPreferences?> Function(String userId)? remoteLoader;

  @override
  Future<CachedUserPreferences?> readLocal(String? userId) async =>
      local[userId];

  @override
  Future<void> writeLocal(String? userId, CachedUserPreferences data) async {
    if (localWriteFails) throw StateError('Device storage unavailable');
    local[userId] = data;
  }

  @override
  Future<UserPreferences?> loadRemote(String userId) async {
    if (offline) throw StateError('Offline');
    if (remoteLoader != null) return remoteLoader!(userId);
    return remote[userId];
  }

  @override
  Future<UserPreferences> saveRemote(
    String userId,
    Map<String, Object> patch,
  ) async {
    writes.add(Map.of(patch));
    await beforeRemoteWrite?.call();
    if (offline) throw StateError('Offline');
    final next = UserPreferences.fromJson({
      ...?remote[userId]?.toJson(),
      ...patch,
    });
    remote[userId] = next;
    return next;
  }
}
