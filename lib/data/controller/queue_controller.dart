import 'package:flutter_riverpod/legacy.dart';
import 'package:just_audio/just_audio.dart';

import '../models/track.dart';

class QueueState {
  final List<AudioSource> tracks;
  final List<Track> rawTracks;
  final int currentIndex;
  final int queuedUpNextCount;

  const QueueState({
    required this.tracks,
    required this.rawTracks,
    required this.currentIndex,
    required this.queuedUpNextCount,
  });

  QueueState copyWith({List<AudioSource>? tracks, List<Track>? rawTracks, int? currentIndex, int? queuedUpNextCount}) =>
      QueueState(
        tracks: tracks ?? this.tracks,
        rawTracks: rawTracks ?? this.rawTracks,
        currentIndex: currentIndex ?? this.currentIndex,
        queuedUpNextCount: queuedUpNextCount ?? this.queuedUpNextCount,
      );

  int get nextInsertionIndex {
    if (tracks.isEmpty) return 0;
    final candidate = currentIndex + 1 + queuedUpNextCount;
    return candidate.clamp(0, tracks.length);
  }
}

class QueueController extends StateNotifier<QueueState> {
  QueueController() : super(const QueueState(tracks: [], rawTracks: [], currentIndex: 0, queuedUpNextCount: 0));

  void replaceQueue(List<AudioSource> tracks, List<Track> rawTracks, int currentIndex) {
    state = QueueState(tracks: tracks, rawTracks: rawTracks, currentIndex: currentIndex, queuedUpNextCount: 0);
  }

  void syncCurrentIndex(int currentIndex) {
    final previousIndex = state.currentIndex;
    var queuedUpNextCount = state.queuedUpNextCount;

    if (currentIndex > previousIndex && queuedUpNextCount > 0) {
      final consumedQueuedItems = currentIndex - previousIndex;
      queuedUpNextCount = (queuedUpNextCount - consumedQueuedItems).clamp(0, queuedUpNextCount);
    }

    state = state.copyWith(currentIndex: currentIndex, queuedUpNextCount: queuedUpNextCount);
  }

  void insertNext(List<AudioSource> tracks, List<Track> rawTracks) {
    if (tracks.isEmpty || rawTracks.isEmpty) return;

    final insertIndex = state.nextInsertionIndex;
    final updatedTracks = List<AudioSource>.from(state.tracks)..insertAll(insertIndex, tracks);
    final updatedRawTracks = List<Track>.from(state.rawTracks)..insertAll(insertIndex, rawTracks);

    state = state.copyWith(
      tracks: updatedTracks,
      rawTracks: updatedRawTracks,
      queuedUpNextCount: state.queuedUpNextCount + tracks.length,
    );
  }

  void updateTrackAtIndex(int index, Track updatedTrack) {
    final newRawTracks = List<Track>.from(state.rawTracks);
    newRawTracks[index] = updatedTrack;
    state = state.copyWith(rawTracks: newRawTracks);
  }

  void toggleFavoriteAtIndex(int index) {
    final track = state.rawTracks[index];
    final updatedTrack = Track(
      id: track.id,
      name: track.name,
      artistId: track.artistId,
      uri: track.uri,
      images: track.images,
      createdAt: track.createdAt,
      artistName: track.artistName,
      genres: track.genres,
      isFavorite: !track.isFavorite,
      artistType: track.artistType,
    );
    updateTrackAtIndex(index, updatedTrack);
  }
}
