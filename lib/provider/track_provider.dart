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
