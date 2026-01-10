import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/models/track.dart';
import '../../provider/audio_provider.dart';

class PlayerController {
  final AudioPlayer player;
  final Ref ref;

  PlayerController(this.player, this.ref);

  Future<void> loadQueue() async {
    final queue = ref.read(queueProvider);
    final playlist = ConcatenatingAudioSource(children: queue.tracks);
    await player.setAudioSource(playlist, initialIndex: queue.currentIndex);

    // Convert AudioSource to Track and update audio handler queue
    final tracks = queue.tracks.map((audioSource) {
      if (audioSource is UriAudioSource) {
        final tag = audioSource.tag;
        if (tag is Map) {
          return Track(
            id: tag['id'],
            name: tag['title'],
            uri: audioSource.uri.toString(),
            artistId: tag['artistId'],
            artistType: tag['artistType'] ?? ArtistType.NestArtist,
            images: List<String>.from(tag['images'] ?? []),
            genres: List<String>.from(tag['genres'] ?? []),
            isFavorite: false,
            createdAt: DateTime.now(),
          );
        }
      }
      // Fallback track if tag is missing
      return Track(
        id: 0,
        name: 'Unknown',
        uri: audioSource is UriAudioSource ? audioSource.uri.toString() : '',
        artistId: 'Unknown Artist',
        images: [],
        createdAt: DateTime.now(),
      );
    }).toList();

    // Ensure audio handler is ready before updating queue
    final audioHandlerAsync = ref.read(audioHandlerProvider);
    audioHandlerAsync.whenData((handler) async {
      await handler.updateQueueFromTracks(
        tracks,
        initialIndex: queue.currentIndex,
      );
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
    ref.read(queueProvider.notifier).next();
    await player.seekToNext();
  }

  Future<void> skipPrev() async {
    ref.read(queueProvider.notifier).previous();
    await player.seekToPrevious();
  }
}
