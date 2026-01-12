import 'package:flutter_ai_music/data/models/wikipedia_summary.dart';
import 'package:flutter_ai_music/service/api_service.dart';
import 'package:flutter_ai_music/service/spotify_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/artist.dart';
import 'audio_provider.dart';

final currentArtistProvider = FutureProvider<SpotifyArtist?>((ref) async {
  final currentTrack = ref.watch(currentTrackProvider).value;

  if (currentTrack == null) return null;

  final artistId = currentTrack.artistId;

  return await SpotifyService.getSpotifyArtist(artistId);
});

final artistSummaryProvider = FutureProvider<WikipediaSummary?>((ref) async {
  final artist = await ref.watch(currentArtistProvider.future);

  if (artist == null) return null;

  return await ApiService.instance.getSummary(artist.name);
});
