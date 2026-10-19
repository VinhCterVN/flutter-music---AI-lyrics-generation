import 'package:flutter_ai_music/data/models/user_preferences.dart';
import 'package:flutter_ai_music/service/user_preferences_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'actual device cache preserves pending changes and separates users',
    () async {
      SharedPreferences.setMockInitialValues({});
      final client = SupabaseClient('https://example.com', 'test-key');
      addTearDown(client.dispose);
      final repository = SupabaseUserPreferencesRepository(client);
      await repository.writeLocal(
        'alice',
        CachedUserPreferences(
          preferences: const UserPreferences(showAnimatedLyrics: false),
          pending: {PreferenceKey.showAnimatedLyrics: false},
        ),
      );
      await repository.writeLocal(
        'bob',
        CachedUserPreferences(
          preferences: const UserPreferences(audioQuality: 'Standard'),
        ),
      );
      final recreated = SupabaseUserPreferencesRepository(client);
      final alice = (await recreated.readLocal('alice'))!;
      expect(alice.preferences.showAnimatedLyrics, isFalse);
      expect(alice.pending, {PreferenceKey.showAnimatedLyrics: false});
      expect(
        (await recreated.readLocal('bob'))!.preferences.audioQuality,
        'Standard',
      );
      expect(await recreated.readLocal(null), isNull);
    },
  );

  test('corrupt device cache falls back instead of blocking startup', () async {
    SharedPreferences.setMockInitialValues({
      'user_preferences.v1.alice': '{invalid',
    });
    final client = SupabaseClient('https://example.com', 'test-key');
    addTearDown(client.dispose);
    expect(
      await SupabaseUserPreferencesRepository(client).readLocal('alice'),
      isNull,
    );
  });

  test(
    'invalid cached fields do not become invalid dropdown or pending values',
    () {
      final cached = CachedUserPreferences.fromJson({
        'preferences': {
          'audio_quality': 'Unknown',
          'show_animated_lyrics': 'false',
        },
        'pending': {'audio_quality': 'Unknown', 'show_animated_lyrics': null},
      });
      expect(cached.preferences.audioQuality, 'High');
      expect(cached.preferences.showAnimatedLyrics, isTrue);
      expect(cached.pending, isEmpty);
    },
  );
}
