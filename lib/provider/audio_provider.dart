import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../data/controller/player_controller.dart';
import '../data/controller/queue_controller.dart';
import '../data/models/artist.dart';
import '../data/models/track.dart';
import '../service/audio_handler_service.dart';
import 'artist_provider.dart';

final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(player.dispose);
  return player;
});

final audioHandlerProvider = FutureProvider<AudioPlayerHandler>((ref) async {
  final player = ref.watch(audioPlayerProvider);
  AudioPlayerHandler? handler;
  try {
    await AudioService.init(
      builder: () {
        handler = AudioPlayerHandler(player);
        return handler!;
      },
      config: AudioServiceConfig(
        androidNotificationChannelId: 'com.flutter_ai_music.channel.audio',
        androidNotificationChannelName: 'Music Playback',
        androidNotificationChannelDescription: 'Music playback controls',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  } catch (e) {
    log("AudioHandlerProvider - Error: $e");
    rethrow;
  }

  if (handler == null) {
    throw Exception('Failed to create AudioHandler');
  }

  ref.onDispose(() {
    handler?.cleanup();
  });
  return handler!;
});

final queueProvider = StateNotifierProvider<QueueController, QueueState>((ref) {
  return QueueController();
});

final playerControllerProvider = Provider<PlayerController>((ref) {
  final player = ref.watch(audioPlayerProvider);
  final controller = PlayerController(player, ref);

  ref.listen<AsyncValue<SpotifyArtist?>>(currentArtistProvider, (_, next) {
    next.whenData((artist) {
      if (artist != null) {
        ref.read(currentTrackProvider).value?.updateArtistName(artist.name);
      }
    });
  });

  ref.listen(queueProvider, (previous, next) {
    if (previous == null || previous.tracks != next.tracks || previous.currentIndex != next.currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await controller.loadQueue();
        await controller.play();
      });
    }
  });

  return controller;
});

final currentTrackProvider = StreamProvider<Track?>((ref) {
  final player = ref.watch(audioPlayerProvider);

  return player.currentIndexStream.map((index) {
    if (index == null) return null;
    final queue = ref.read(queueProvider);
    if (index < 0 || index >= queue.tracks.length) return null;

    return queue.rawTracks[index];
  });
});

final progressProvider = StreamProvider<TrackProgress>((ref) {
  final player = ref.watch(audioPlayerProvider);

  return Rx.combineLatest3<Duration, Duration, Duration?, TrackProgress>(
    player.positionStream,
    player.bufferedPositionStream,
    player.durationStream,
    (pos, buf, dur) => TrackProgress(pos, buf, dur),
  );
});

final isPlayingProvider = StreamProvider<bool>((ref) {
  final player = ref.watch(audioPlayerProvider);
  return player.playingStream;
});

final isBufferingProvider = StreamProvider<bool>((ref) {
  final player = ref.watch(audioPlayerProvider);
  return player.processingStateStream.map(
    (state) => state == ProcessingState.buffering || state == ProcessingState.loading,
  );
});

final shuffleModeProvider = StreamProvider<bool>((ref) {
  final player = ref.watch(audioPlayerProvider);
  return player.shuffleModeEnabledStream;
});

final repeatModeProvider = StreamProvider<LoopMode>((ref) {
  final player = ref.watch(audioPlayerProvider);
  return player.loopModeStream;
});
