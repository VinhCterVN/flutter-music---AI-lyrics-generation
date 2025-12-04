import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../data/models/track.dart';

class AudioPlayerHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player;
  final BehaviorSubject<List<MediaItem>> _queueSubject =
      BehaviorSubject<List<MediaItem>>();
  final BehaviorSubject<MediaItem?> _mediaItemSubject =
      BehaviorSubject<MediaItem?>();

  AudioPlayerHandler(this._player) {
    // Initialize playback state
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.idle,
        playing: false,
        updatePosition: Duration.zero,
        speed: 1.0,
        queueIndex: null,
      ),
    );
    _init();
  }

  void _init() {
    // Listen to player state changes
    _player.playingStream.listen((playing) {
      playbackState.add(
        playbackState.value.copyWith(
          playing: playing,
          controls: [
            MediaControl.skipToPrevious,
            playing ? MediaControl.pause : MediaControl.play,
            MediaControl.skipToNext,
          ],
        ),
      );
    });

    _player.processingStateStream.listen((state) {
      playbackState.add(
        playbackState.value.copyWith(
          processingState: _processingStateToAudioProcessingState(state),
        ),
      );
    });

    _player.positionStream.listen((position) {
      playbackState.add(
        playbackState.value.copyWith(
          updatePosition: position,
          speed: _player.speed,
          queueIndex: _player.currentIndex,
        ),
      );
    });

    _player.durationStream.listen((duration) {
      final index = _player.currentIndex ?? 0;
      final queue = _queueSubject.valueOrNull ?? [];
      if (index >= 0 && index < queue.length) {
        final newMediaItem = queue[index].copyWith(duration: duration);
        _mediaItemSubject.add(newMediaItem);
        mediaItem.add(newMediaItem);
      }
    });

    _player.currentIndexStream.listen((index) {
      final queue = _queueSubject.valueOrNull ?? [];
      if (index != null && index >= 0 && index < queue.length) {
        final mediaItem = queue[index];
        _mediaItemSubject.add(mediaItem);
        this.mediaItem.add(mediaItem);
        playbackState.add(playbackState.value.copyWith(queueIndex: index));
      }
    });
  }

  AudioProcessingState _processingStateToAudioProcessingState(
    ProcessingState state,
  ) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  @override
  Future<void> play() async {
    log('AudioHandler: play() called');
    await _player.play();
    // Ensure notification is visible when playing starts
    if (mediaItem.value != null) {
      log('AudioHandler: Updating playbackState to playing');
      playbackState.add(
        playbackState.value.copyWith(
          playing: true,
          controls: [
            MediaControl.skipToPrevious,
            MediaControl.pause,
            MediaControl.skipToNext,
          ],
        ),
      );
    } else {
      log(
        'AudioHandler: WARNING - mediaItem is null, notification may not show',
      );
    }
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
        ],
      ),
    );
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= (_queueSubject.valueOrNull ?? []).length) {
      return;
    }
    await _player.seek(Duration.zero, index: index);
  }

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await _player.setShuffleModeEnabled(
      shuffleMode == AudioServiceShuffleMode.all,
    );
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
  }

  Future<void> updateQueueFromTracks(
    List<Track> tracks, {
    int? initialIndex,
  }) async {
    log(
      'AudioHandler: Updating queue with ${tracks.length} tracks, initialIndex: $initialIndex',
    );
    final mediaItems = tracks.map((track) => _trackToMediaItem(track)).toList();
    _queueSubject.add(mediaItems);
    queue.value = mediaItems;

    if (initialIndex != null &&
        initialIndex >= 0 &&
        initialIndex < mediaItems.length) {
      final currentMediaItem = mediaItems[initialIndex];
      log('AudioHandler: Setting mediaItem: ${currentMediaItem.title}');
      _mediaItemSubject.add(currentMediaItem);
      mediaItem.add(currentMediaItem);
      // Update playback state to ensure notification shows
      playbackState.add(
        playbackState.value.copyWith(
          queueIndex: initialIndex,
          controls: [
            MediaControl.skipToPrevious,
            MediaControl.play,
            MediaControl.skipToNext,
          ],
          processingState: AudioProcessingState.ready,
        ),
      );
    }
  }

  Future<void> updateCurrentTrack(Track track) async {
    final mediaItem = _trackToMediaItem(track);
    _mediaItemSubject.add(mediaItem);
    this.mediaItem.add(mediaItem);
  }

  MediaItem _trackToMediaItem(Track track) {
    return MediaItem(
      id: track.id.toString(),
      title: track.name,
      artist: track.artistId,
      album: track.name,
      duration: null, // Will be updated when audio loads
      artUri: track.images.isNotEmpty ? Uri.parse(track.images.first) : null,
      extras: {
        'id': track.id,
        'uri': track.uri,
        'images': track.images,
        'genres': track.genres,
      },
    );
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    await super.onTaskRemoved();
  }

  void cleanup() {
    _queueSubject.close();
    _mediaItemSubject.close();
  }
}
