import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/lyric_line.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/audio_provider.dart';
import 'package:flutter_ai_music/provider/lyrics_provider.dart';
import 'package:flutter_ai_music/provider/user_preferences_provider.dart';
import 'package:flutter_ai_music/ui/component/navigation/lyrics_display.dart';
import 'package:flutter_ai_music/ui/component/navigation/playing_screen/current_lyric_line.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final track = Track(
    id: 1,
    name: 'Song',
    artistId: 'artist',
    uri: 'https://example.com/song',
    images: [],
    createdAt: DateTime(2026),
  );
  final lyrics = [
    LyricsLine(
      startTime: const Duration(seconds: 2),
      endTime: const Duration(seconds: 4),
      text: 'First line',
    ),
    LyricsLine(
      startTime: const Duration(seconds: 4),
      endTime: const Duration(seconds: 6),
      text: 'Second line with a very long lyric that must stay on one line',
    ),
  ];

  testWidgets(
    'follows timestamps, slides upward, and clears gaps when seeking',
    (tester) async {
      final progress = StreamController<TrackProgress>();
      addTearDown(progress.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            showAnimatedLyricsProvider.overrideWith((ref) => true),
            progressProvider.overrideWith((ref) => progress.stream),
            lyricsStreamProvider(
              track.id,
            ).overrideWith((ref) => Stream.value(lyrics)),
            lyricsFutureProvider(track).overrideWith((ref) async => lyrics),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 220,
                child: CurrentLyricLine(
                  track: track,
                  textStyle: const TextStyle(
                    fontFamily: 'Klavika',
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      Future<void> seek(int milliseconds) async {
        progress.add(
          TrackProgress(
            Duration(milliseconds: milliseconds),
            Duration.zero,
            const Duration(seconds: 10),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();
      }

      await seek(1999);
      expect(find.text('First line'), findsNothing);
      await seek(2000);
      expect(find.text('First line'), findsOneWidget);
      final initialY = tester.getCenter(find.text('First line')).dy;
      progress.add(
        TrackProgress(
          const Duration(seconds: 4),
          Duration.zero,
          const Duration(seconds: 10),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(lyrics[1].text), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getCenter(find.text('First line')).dy, lessThan(initialY));
      await tester.pumpAndSettle();
      expect(find.text('First line'), findsNothing);
      final text = tester.widget<Text>(find.text(lyrics[1].text));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(text.style?.fontFamily, 'Klavika');
      await seek(3000);
      expect(find.text('First line'), findsOneWidget);
      await seek(6000);
      expect(find.text('First line'), findsNothing);
      expect(find.text(lyrics[1].text), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('uses fetched lyrics when the database stream is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          showAnimatedLyricsProvider.overrideWith((ref) => true),
          progressProvider.overrideWith(
            (ref) => Stream.value(
              TrackProgress(const Duration(seconds: 3), Duration.zero, null),
            ),
          ),
          lyricsStreamProvider(
            track.id,
          ).overrideWith((ref) => Stream.value([])),
          lyricsFutureProvider(track).overrideWith((ref) async => lyrics),
        ],
        child: MaterialApp(
          home: Scaffold(body: CurrentLyricLine(track: track)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('First line'), findsOneWidget);
  });

  testWidgets(
    'slider position overrides playback and tapping opens expanded lyrics',
    (tester) async {
      final observer = _RouteObserver();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            showAnimatedLyricsProvider.overrideWith((ref) => true),
            progressProvider.overrideWith(
              (ref) => Stream.value(
                TrackProgress(Duration.zero, Duration.zero, null),
              ),
            ),
            lyricsStreamProvider(
              track.id,
            ).overrideWith((ref) => Stream.value(lyrics)),
            lyricsFutureProvider(track).overrideWith((ref) async => lyrics),
          ],
          child: MaterialApp(
            navigatorObservers: [observer],
            home: Scaffold(
              body: CurrentLyricLine(
                track: track,
                position: const Duration(seconds: 3),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('First line'), findsOneWidget);
      await tester.tap(find.text('First line'));
      final route = observer.lastRoute! as MaterialPageRoute<void>;
      final screen =
          route.builder(tester.element(find.byType(CurrentLyricLine)))
              as LyricsDisplayWidget;
      expect(screen.track.id, 1);
      // Dispose before rendering the destination's external dependencies.
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('disabled preview keeps spacing without loading lyrics', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          showAnimatedLyricsProvider.overrideWith((ref) => false),
          lyricsStreamProvider(
            track.id,
          ).overrideWith((ref) => throw StateError('Lyrics must not load')),
          lyricsFutureProvider(
            track,
          ).overrideWith((ref) => throw StateError('Lyrics must not fetch')),
          progressProvider.overrideWith(
            (ref) => throw StateError('Progress must not subscribe'),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: CurrentLyricLine(track: track)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AnimatedSwitcher), findsNothing);
    expect(find.byType(GestureDetector), findsNothing);
    expect(tester.getSize(find.byType(CurrentLyricLine)).height, 50);
    expect(tester.takeException(), isNull);
  });
}

class _RouteObserver extends NavigatorObserver {
  Route<dynamic>? lastRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastRoute = route;
  }
}
