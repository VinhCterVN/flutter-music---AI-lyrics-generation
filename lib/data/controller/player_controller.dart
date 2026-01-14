import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../provider/audio_provider.dart';

class PlayerController {
  final AudioPlayer player;
  final Ref ref;

  PlayerController(this.player, this.ref);

  Future<void> loadQueue() async {
    final queue = ref.read(queueProvider);
    final playlist = ConcatenatingAudioSource(children: queue.tracks);
    await player.setAudioSource(playlist, initialIndex: queue.currentIndex);

    final audioHandlerAsync = ref.read(audioHandlerProvider);
    audioHandlerAsync.whenData((handler) async {
      await handler.updateQueueFromTracks(queue.rawTracks, initialIndex: queue.currentIndex);
    });
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
