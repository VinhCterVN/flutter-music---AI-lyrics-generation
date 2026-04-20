import 'package:flutter_ai_music/data/models/track.dart';
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

  return HomeDiscoveryData(
    topListenedTracks: results[0],
    suggestedTracks: results[1],
  );
});
