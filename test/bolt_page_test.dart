import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/audio_provider.dart';
import 'package:flutter_ai_music/provider/discovery_provider.dart';
import 'package:flutter_ai_music/provider/playlist_provider.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_ai_music/ui/pages/bolt.dart';
import 'package:flutter_ai_music/ui/component/element/bolt_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Track track(int id) => Track(
  id: id,
  name: 'Track $id',
  uri: 'https://example.com/$id.mp3',
  artistId: 'artist',
  artistName: 'Artist $id',
  images: [],
  genres: ['Jazz'],
  createdAt: DateTime(2026),
);

Future<void> mount(
  WidgetTester tester,
  Future<List<Track>> Function(String?) load,
) async {
  await tester.binding.setSurfaceSize(const Size(390, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        discoveryTracksProvider.overrideWith((ref, genre) => load(genre)),
        allGenresProvider.overrideWith((ref) async => ['Jazz']),
        currentTrackProvider.overrideWith((ref) => Stream.value(null)),
        isPlayingProvider.overrideWith((ref) => Stream.value(false)),
        isBufferingProvider.overrideWith((ref) => Stream.value(false)),
        playlistServiceProvider.overrideWith(
          (ref) => throw StateError('Offline'),
        ),
        playerControllerProvider.overrideWith(
          (ref) => throw StateError('Browsing must not start playback'),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: const Scaffold(body: BoltPage()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('failed play and like actions stay recoverable', (tester) async {
    await mount(tester, (_) async => [track(1)]);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Play'));
    await tester.tap(find.byTooltip('Play'));
    await tester.pumpAndSettle();
    expect(
      find.text('Couldn’t play this track. Please try again.'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Like'));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.byTooltip('Like'), findsOneWidget);
    expect(find.byTooltip('Unlike'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('browsing advances without playback and ends without repeating', (
    tester,
  ) async {
    await mount(tester, (_) async => [track(1), track(2)]);
    await tester.pumpAndSettle();
    expect(find.text('Track 1'), findsOneWidget);
    await tester.ensureVisible(find.text('Next discovery'));
    await tester.tap(find.text('Next discovery'));
    await tester.pumpAndSettle();
    expect(find.text('Track 2'), findsOneWidget);
    await tester.tap(find.text('Next discovery'));
    await tester.pumpAndSettle();
    expect(find.text('That’s this deck explored'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('genre selection loads its own deck', (tester) async {
    final requested = <String?>[];
    await mount(tester, (genre) async {
      requested.add(genre);
      return [track(genre == null ? 1 : 2)];
    });
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Jazz'));
    await tester.pumpAndSettle();
    expect(requested, [null, 'Jazz']);
    expect(find.text('Track 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading, failure and retry recover to an empty state', (
    tester,
  ) async {
    final pending = Completer<List<Track>>();
    var requests = 0;
    await mount(tester, (_) {
      requests++;
      return requests == 1 ? pending.future : Future.value([]);
    });
    expect(find.byType(BoltSkeleton), findsOneWidget);
    pending.completeError(StateError('Offline'));
    await tester.pumpAndSettle();
    expect(find.text('Couldn’t load your discoveries'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No discoveries here yet'), findsOneWidget);
    expect(requests, 2);
  });

  testWidgets(
    'small screen with large text remains scrollable without overflow',
    (tester) async {
      await mount(tester, (_) async => [track(1)]);
      await tester.binding.setSurfaceSize(const Size(320, 568));
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Next discovery'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
