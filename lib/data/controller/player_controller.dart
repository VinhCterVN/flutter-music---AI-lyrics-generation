import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../provider/audio_provider.dart';
import '../models/track.dart';

class PlayerController {
  final AudioPlayer player;
  final Ref ref;

  PlayerController(this.player, this.ref);

  Future<void> replaceQueueAndPlayAt({required List<Track> rawTracks, required int currentIndex}) async {
    final audioSources = rawTracks.toAudioSources();
    ref.read(queueProvider.notifier).replaceQueue(audioSources, rawTracks, currentIndex);
    await _reloadQueue(initialIndex: currentIndex, initialPosition: Duration.zero, autoPlay: true);
  }

  Future<void> addTrackToQueue(Track track) async => addTracksToQueue([track]);

  Future<void> addTracksToQueue(List<Track> tracks) async {
    if (tracks.isEmpty) return;

    final queue = ref.read(queueProvider);
    if (queue.tracks.isEmpty) {
      await replaceQueueAndPlayAt(rawTracks: tracks, currentIndex: 0);
      return;
    }

    final wasPlaying = player.playing;
    final currentPosition = player.position;
    final currentIndex = player.currentIndex ?? queue.currentIndex;

    ref.read(queueProvider.notifier).insertNext(tracks.toAudioSources(), tracks);
    await _reloadQueue(initialIndex: currentIndex, initialPosition: currentPosition, autoPlay: wasPlaying);
  }

  Future<void> loadQueue() async {
    final queue = ref.read(queueProvider);
    if (queue.tracks.isEmpty) return;
    await _reloadQueue(initialIndex: queue.currentIndex, initialPosition: Duration.zero, autoPlay: false);
  }

  Future<void> _reloadQueue({
    required int initialIndex,
    required Duration initialPosition,
    required bool autoPlay,
  }) async {
    final queue = ref.read(queueProvider);
    await player.setAudioSources(queue.tracks, initialIndex: initialIndex, initialPosition: initialPosition);

    final audioHandlerAsync = ref.read(audioHandlerProvider);
    audioHandlerAsync.whenData((handler) async {
      await handler.updateQueueFromTracks(queue.rawTracks, initialIndex: initialIndex);
    });

    if (autoPlay) {
      await player.play();
    }
  }

  Future<void> play() => player.play();

  Future<void> pause() => player.pause();

  Future<void> toggleShuffle() async {
    final isEnabled = player.shuffleModeEnabled;
    await player.setShuffleModeEnabled(!isEnabled);
  }

  Future<void> switchRepeatMode() async {
    final mode = player.loopMode;
    LoopMode newMode;
    switch (mode) {
      case LoopMode.off:
        newMode = LoopMode.all;
        break;
      case LoopMode.all:
        newMode = LoopMode.one;
        break;
      case LoopMode.one:
        newMode = LoopMode.off;
        break;
    }
    await player.setLoopMode(newMode);
  }

  Future<void> skipNext() async {
    await player.seekToNext();
  }

  Future<void> skipPrev() async {
    await player.seekToPrevious();
  }
}
