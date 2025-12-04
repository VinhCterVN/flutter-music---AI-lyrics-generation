import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/track.dart';
import '../provider/audio_provider.dart';

class AudioHelper {
  static Future<bool> playTrackFromList(
    WidgetRef ref, {
    required List<Track> allTracks,
    required int selectedIndex,
    bool navigateToPlayer = true,
  }) async {
    if (allTracks.isEmpty || selectedIndex < 0 || selectedIndex >= allTracks.length) {
      throw ArgumentError('Invalid track selection');
    }
    final audioSources = allTracks.toAudioSources();
    log("Audio Helper - Selected Index; $selectedIndex");
    ref.read(queueProvider.notifier).setQueueAndPlayAt(audioSources, selectedIndex);
    ref.read(playerControllerProvider).loadQueue();
    return true;
  }

  static Future<void> playSingleTrack(
    BuildContext context,
    WidgetRef ref, {
    required Track track,
    bool navigateToPlayer = true,
  }) async {
    await playTrackFromList(ref, allTracks: [track], selectedIndex: 0, navigateToPlayer: navigateToPlayer);
  }

  static Future<void> resumePlayback(WidgetRef ref) async {
    final controller = ref.read(playerControllerProvider);
    await controller.play();
  }

  static Future<void> pausePlayback(WidgetRef ref) async {
    final controller = ref.read(playerControllerProvider);
    await controller.pause();
  }
}

extension AudioHelperExtension on WidgetRef {
  Future<void> playTrack({required List<Track> tracks, required int index}) async {
    await AudioHelper.playTrackFromList(this, allTracks: tracks, selectedIndex: index);
  }

  Future<void> playSingleTrack(BuildContext context, {required Track track}) async {
    await AudioHelper.playSingleTrack(context, this, track: track);
  }
}
