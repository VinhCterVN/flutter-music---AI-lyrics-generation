import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/track.dart';
import 'auth_provider.dart';
import 'track_provider.dart';

/// Loading or browsing a deck never starts playback.
final discoveryTracksProvider = FutureProvider.autoDispose
    .family<List<Track>, String?>((ref, genre) async {
      ref.watch(currentUserProvider);
      final service = ref.read(trackServiceProvider);
      final tracks = genre == null
          ? await service.getSuggestedTracks(limit: 24)
          : await service.getTracksByGenre(genre);
      final unique = <int, Track>{};
      for (final track in tracks) {
        if (track.uri.trim().isNotEmpty) unique[track.id] = track;
      }
      final deck = unique.values.toList()..shuffle();
      return deck.take(24).toList();
    });
