import 'package:flutter_ai_music/data/models/playlist.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/playlist_provider.dart';
import 'package:flutter_ai_music/provider/track_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final webPlaylistsProvider = StreamProvider.autoDispose<List<Playlist>>((ref) {
  return ref.read(playlistServiceProvider).streamPlaylists(limit: 20);
});

final webFavouriteTracksProvider = FutureProvider.autoDispose<List<Track>>((ref) async {
  final playlistService = ref.read(playlistServiceProvider);
  final trackService = ref.read(trackServiceProvider);
  final ids = await playlistService.getFavouriteTrackIds();
  if (ids.isEmpty) return const [];

  return trackService.getTracksByIds(ids.map((id) => id.toString()).toList());
});
