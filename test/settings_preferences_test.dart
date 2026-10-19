import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/user_preferences.dart';
import 'package:flutter_ai_music/provider/user_preferences_provider.dart';
import 'package:flutter_ai_music/ui/layout/preferences_startup_gate.dart';
import 'package:flutter_ai_music/ui/pages/setting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_preferences_repository.dart';

void main() {
  testWidgets('startup displays the player while cloud settings load', (
    tester,
  ) async {
    final repository = FakePreferencesRepository();
    final loaded = Completer<UserPreferences?>();
    repository.remoteLoader = (_) => loaded.future;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesUserIdProvider.overrideWith((ref) => 'alice'),
          userPreferencesRepositoryProvider.overrideWith((ref) => repository),
        ],
        child: const MaterialApp(
          home: PreferencesStartupGate(child: Text('Player')),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Player'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    final initialContainer = ProviderScope.containerOf(
      tester.element(find.text('Player')),
    );
    expect(initialContainer.read(userPreferencesProvider).isReady, isFalse);
    loaded.complete(const UserPreferences(showAnimatedLyrics: false));
    await tester.pumpAndSettle();
    expect(find.text('Player'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.text('Player')),
    );
    expect(container.read(showAnimatedLyricsProvider), isFalse);
  });

  testWidgets(
    'lyric setting applies globally and shows saving, saved, and retry',
    (tester) async {
      final repository = FakePreferencesRepository();
      repository.remote['alice'] = const UserPreferences();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesUserIdProvider.overrideWith((ref) => 'alice'),
            userPreferencesRepositoryProvider.overrideWith((ref) => repository),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const SettingsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsPage)),
      );
      final tile = find.ancestor(
        of: find.text('Animated Lyric Line'),
        matching: find.byType(ListTile),
      );
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      final release = Completer<void>();
      repository.beforeRemoteWrite = () => release.future;
      await tester.tap(
        find.descendant(of: tile, matching: find.byType(Switch)),
      );
      await tester.pump();
      expect(container.read(showAnimatedLyricsProvider), isFalse);
      expect(
        find.descendant(of: tile, matching: find.text('Saving…')),
        findsOneWidget,
      );
      release.complete();
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: tile, matching: find.text('Saved to account')),
        findsOneWidget,
      );
      expect(repository.remote['alice']!.showAnimatedLyrics, isFalse);
      repository.offline = true;
      await tester.tap(
        find.descendant(of: tile, matching: find.byType(Switch)),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: tile, matching: find.text('Saved on this device')),
        findsOneWidget,
      );
      await tester.drag(find.byType(ListView), const Offset(0, 1000));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      repository.offline = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(repository.remote['alice']!.showAnimatedLyrics, isTrue);
      expect(find.text('Retry'), findsNothing);
    },
  );

  testWidgets('existing placeholder fields remain in Settings', (tester) async {
    final repository = FakePreferencesRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesUserIdProvider.overrideWith((ref) => null),
          userPreferencesRepositoryProvider.overrideWith((ref) => repository),
        ],
        child: MaterialApp(theme: ThemeData.dark(), home: const SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();
    for (final label in [
      'Audio Quality',
      'Equalizer',
      'Auto-Downloads',
      'Dynamic Ambient Color',
      'Dark Mode Theme',
      'Clear Cache',
      'Flussic Version',
      'Check for Updates',
      'Developer Contact',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        180,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text(label), findsOneWidget);
    }
  });
}
