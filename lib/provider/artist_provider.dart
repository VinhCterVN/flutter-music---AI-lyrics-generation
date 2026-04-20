import 'package:flutter_ai_music/data/models/wikipedia_summary.dart';
import 'package:flutter_ai_music/service/api_service.dart';
import 'package:flutter_ai_music/service/artist_service.dart';
import 'package:flutter_ai_music/service/spotify_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/artist.dart';
import '../data/models/track.dart';
import 'audio_provider.dart';
import 'track_provider.dart';

final artistServiceProvider = Provider<ArtistService>((ref) => ArtistService(ref));

final currentArtistProvider = FutureProvider<Artist?>((ref) async {
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

const tempArtistRouteId = '__temp_artist__';

class ArtistRouteArgs {
  final String artistId;
  final ArtistType artistType;
  final String? fallbackName;
  final String? fallbackImageUrl;

  const ArtistRouteArgs({required this.artistId, required this.artistType, this.fallbackName, this.fallbackImageUrl});

  String get normalizedArtistId => artistId == tempArtistRouteId ? '' : artistId;

  @override
  bool operator ==(Object other) {
    return other is ArtistRouteArgs &&
        other.artistId == artistId &&
        other.artistType == artistType &&
        other.fallbackName == fallbackName &&
        other.fallbackImageUrl == fallbackImageUrl;
  }

  @override
  int get hashCode => Object.hash(artistId, artistType, fallbackName, fallbackImageUrl);
}

class ArtistPageData {
  final Artist artist;
  final WikipediaSummary? summary;
  final List<Track> tracks;
  final bool isFollowing;

  const ArtistPageData({required this.artist, required this.summary, required this.tracks, required this.isFollowing});
}

String artistRouteLocation({
  required String artistId,
  required ArtistType artistType,
  String? artistName,
  String? imageUrl,
}) {
  final normalizedId = artistId.isEmpty ? tempArtistRouteId : artistId;
  return Uri(
    path: '/artist/${artistType.name}/$normalizedId',
    queryParameters: {
      if (artistName != null && artistName.isNotEmpty) 'name': artistName,
      if (imageUrl != null && imageUrl.isNotEmpty) 'image': imageUrl,
    },
  ).toString();
}

final artistPageDataProvider = FutureProvider.autoDispose.family<ArtistPageData, ArtistRouteArgs>((ref, args) async {
  final artistService = ref.read(artistServiceProvider);
  final trackService = ref.read(trackServiceProvider);

  final artist = await artistService.resolveArtist(
    artistId: args.normalizedArtistId,
    artistType: args.artistType,
    fallbackName: args.fallbackName,
    fallbackImageUrl: args.fallbackImageUrl,
  );

  final results = await Future.wait([
    ApiService.instance.getSummary(artist.artistType == ArtistType.SpotifyArtist ? artist.name : ''),
    trackService.getTracksByArtistId(artistId: args.normalizedArtistId, artistType: args.artistType),
    artistService.getFollowStatus(args.normalizedArtistId),
  ]);

  return ArtistPageData(
    artist: artist,
    summary: results[0] as WikipediaSummary?,
    tracks: results[1] as List<Track>,
    isFollowing: results[2] as bool,
  );
});
