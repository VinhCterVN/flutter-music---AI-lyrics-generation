import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/playlist_provider.dart';
import 'package:flutter_ai_music/service/search_service.dart';
import 'package:flutter_ai_music/service/track_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final trackServiceProvider = Provider<TrackService>((ref) => TrackService(ref));

final searchServiceProvider = Provider.autoDispose<SearchService>((ref) => SearchService(ref));

final trackSearchQueryProvider = StateProvider<String>((ref) => '');

final trackSearchProvider = StreamProvider.autoDispose<List<Track>>((ref) {
  final query = ref.watch(trackSearchQueryProvider);
  return ref.read(trackServiceProvider).searchTracks(query).asStream();
});

class HomeDiscoveryData {
  final List<Track> topListenedTracks;
  final List<Track> suggestedTracks;

  const HomeDiscoveryData({required this.topListenedTracks, required this.suggestedTracks});
}

final homeDiscoveryProvider = FutureProvider.autoDispose<HomeDiscoveryData>((ref) async {
  final trackService = ref.read(trackServiceProvider);

  final results = await Future.wait([
    trackService.getTopListenedTracks(limit: 12),
    trackService.getSuggestedTracks(limit: 24),
  ]);

  return HomeDiscoveryData(topListenedTracks: results[0], suggestedTracks: results[1]);
});

final featuredTracksProvider = FutureProvider.autoDispose.family<List<Track>, int>((ref, limit) {
  return ref.read(trackServiceProvider).getFeaturedTracks(limit: limit);
});

final recentTracksProvider = StreamProvider.autoDispose.family<List<Track>, int>((ref, limit) {
  return ref.read(trackServiceProvider).streamRecentTracks(limit: limit);
});

final likedTracksProvider = FutureProvider.autoDispose<List<Track>>((ref) async {
  final ids = await ref.read(playlistServiceProvider).getFavouriteTrackIds();
  if (ids.isEmpty) return <Track>[];
  return ref.read(trackServiceProvider).getTracksByIds(ids.map((e) => e.toString()).toList());
});

final allGenresProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final tracks = await ref.read(trackServiceProvider).searchTracks('');
  final genresMap = <String, String>{}; // lowercase -> formatted
  for (final track in tracks) {
    for (final genre in track.genres) {
      final trimmed = genre.trim();
      if (trimmed.isEmpty) continue;
      final lowercase = trimmed.toLowerCase();
      if (!genresMap.containsKey(lowercase)) {
        final formatted = trimmed[0].toUpperCase() + trimmed.substring(1);
        genresMap[lowercase] = formatted;
      }
    }
  }
  final sortedGenres = genresMap.values.toList()..sort();
  return sortedGenres;
});

final tracksByGenreProvider = FutureProvider.autoDispose.family<List<Track>, String>((ref, genre) async {
  return ref.read(trackServiceProvider).getTracksByGenre(genre);
});
