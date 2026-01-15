import 'package:flutter_riverpod/legacy.dart';
import 'package:just_audio/just_audio.dart';

import '../models/track.dart';

class QueueState {
  final List<AudioSource> tracks;
  final List<Track> rawTracks;
  final int currentIndex;

  QueueState({required this.tracks, required this.rawTracks, required this.currentIndex});

  QueueState copyWith({List<AudioSource>? tracks, List<Track>? rawTracks, int? currentIndex}) => QueueState(
    tracks: tracks ?? this.tracks,
    rawTracks: rawTracks ?? this.rawTracks,
    currentIndex: currentIndex ?? this.currentIndex,
  );
}

class QueueController extends StateNotifier<QueueState> {
  QueueController() : super(QueueState(tracks: [], rawTracks: [], currentIndex: 0));

  void setQueue(List<AudioSource> list) {
    state = state.copyWith(tracks: list, currentIndex: 0);
  }

  void setQueueAndPlayAt(List<AudioSource> tracks, List<Track> rawTracks, int currentIndex) {
    state = state.copyWith(tracks: tracks, rawTracks: rawTracks, currentIndex: currentIndex);
  }

  void next() {
    if (state.currentIndex < state.tracks.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void previous() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
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