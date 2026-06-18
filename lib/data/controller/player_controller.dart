import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../provider/audio_provider.dart';
import '../models/track.dart';

class PlayerController {
  final AudioPlayer player;
  final Ref ref;
  Timer? _sleepTimer;

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

    final insertIndex = queue.nextInsertionIndex;
    final newSources = tracks.toAudioSources();
    ref.read(queueProvider.notifier).insertNext(newSources, tracks);

    await player.insertAudioSources(insertIndex, newSources);
    final updatedQueue = ref.read(queueProvider);
    final audioHandlerAsync = ref.read(audioHandlerProvider);
    audioHandlerAsync.whenData((handler) async {
      await handler.updateQueueFromTracks(
        updatedQueue.rawTracks,
        initialIndex: player.currentIndex ?? updatedQueue.currentIndex,
      );
    });
  }

  /// Moves a queued track from [oldIndex] to [newIndex] (both absolute indices
  /// into the full queue). Mutates the live playlist in place so the currently
  /// playing track keeps going without a reload.
  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    ref.read(queueProvider.notifier).reorder(oldIndex, newIndex);
    await player.moveAudioSource(oldIndex, newIndex);

    final updatedQueue = ref.read(queueProvider);
    final audioHandlerAsync = ref.read(audioHandlerProvider);
    audioHandlerAsync.whenData((handler) async {
      await handler.updateQueueFromTracks(
        updatedQueue.rawTracks,
        initialIndex: player.currentIndex ?? updatedQueue.currentIndex,
      );
    });
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

  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepTimer = Timer(duration, () {
      unawaited(player.pause());
      _sleepTimer = null;
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
  }

  void dispose() {
    cancelSleepTimer();
  }

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
