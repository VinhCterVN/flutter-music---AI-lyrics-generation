import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../data/models/track.dart';

class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player;
  final BehaviorSubject<List<MediaItem>> _queueSubject = BehaviorSubject<List<MediaItem>>();
  final BehaviorSubject<MediaItem?> _mediaItemSubject = BehaviorSubject<MediaItem?>();

  AudioPlayerHandler(this._player) {
    _init();
  }

  void _init() {
    _player.playbackEventStream.listen(_broadcastState);

    _player.durationStream.listen((duration) {
      final index = _player.currentIndex ?? 0;
      final currentQueue = _queueSubject.valueOrNull ?? [];
      if (index >= 0 && index < currentQueue.length && duration != null) {
        final newMediaItem = currentQueue[index].copyWith(duration: duration);
        _mediaItemSubject.add(newMediaItem);
        mediaItem.add(newMediaItem);

        final updatedQueue = List<MediaItem>.from(currentQueue);
        updatedQueue[index] = newMediaItem;
        _queueSubject.add(updatedQueue);
        queue.add(updatedQueue);

        _broadcastState(_player.playbackEvent);
      }
    });

    _player.currentIndexStream.listen((index) {
      final queue = _queueSubject.valueOrNull ?? [];
      if (index != null && index >= 0 && index < queue.length) {
        final mediaItem = queue[index];
        _mediaItemSubject.add(mediaItem);
        this.mediaItem.add(mediaItem);
      }
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        stop();
        _player.seek(Duration.zero, index: 0);
      }
    });

    _player.positionStream.throttleTime(const Duration(seconds: 1)).listen((position) {
      _broadcastState(_player.playbackEvent);
    });
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    final queueIndex = _player.currentIndex;

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.setSpeed,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: queueIndex,
      ),
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

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
    await _player.setShuffleModeEnabled(shuffleMode == AudioServiceShuffleMode.all);
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

  Future<void> updateQueueFromTracks(List<Track> tracks, {int? initialIndex}) async {
    log('AudioHandler: Updating queue with ${tracks.length} tracks, initialIndex: $initialIndex');
    final mediaItems = tracks.map((track) => _trackToMediaItem(track)).toList();
    _queueSubject.add(mediaItems);
    queue.value = mediaItems;

    if (initialIndex != null && initialIndex >= 0 && initialIndex < mediaItems.length) {
      final currentMediaItem = mediaItems[initialIndex];
      log('AudioHandler: Setting mediaItem: ${currentMediaItem.title}');
      _mediaItemSubject.add(currentMediaItem);
      mediaItem.add(currentMediaItem);
      // Update playback state to ensure notification shows
      playbackState.add(
        playbackState.value.copyWith(
          queueIndex: initialIndex,
          controls: [MediaControl.skipToPrevious, MediaControl.play, MediaControl.skipToNext],
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
      artist: track.artistName ?? track.artistType.name,
      album: track.name,
      duration: null,
      // Will be updated when audio loads
      artUri: track.images.isNotEmpty ? Uri.parse(track.images.first) : null,
      extras: {'id': track.id, 'uri': track.uri, 'images': track.images, 'genres': track.genres},
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
