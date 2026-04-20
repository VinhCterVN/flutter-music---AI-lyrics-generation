import 'package:flutter_ai_music/data/database/track_database.dart';
import 'package:flutter_ai_music/data/models/track.dart';
import 'package:flutter_ai_music/provider/auth_provider.dart';
import 'package:flutter_ai_music/service/spotify_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrackService {
  final Ref ref;
  final SupabaseClient _supabase;

  TrackService(this.ref) : _supabase = ref.read(supabaseClientProvider);

  Stream<List<Track>> streamTrackList() {
    return _supabase
        .from('full_tracks_view')
        .stream(primaryKey: ['id'])
        .order('createdAt', ascending: false)
        .map((rows) => rows.map((e) => Track.fromJson(e)).toList());
  }

  /// Params:
  /// - [page]: The page number to fetch (starting from 0).
  /// - [pageSize]: The number of tracks per page.
  ///
  /// Returns a list of [Track] objects.
  Future<TrackPage> getTrackPage({int page = 0, int pageSize = 10}) async {
    final response = await _supabase
        .from("tracks")
        .select("""
            id, name, uri, artist_id, artist_type, genres, created_at, updated_at,
            images (url),
            favourites!left (id)
         """)
        .range(page * pageSize, page * pageSize + pageSize)
        .order('created_at', ascending: false);

    final list = response as List..shuffle();
    final hasNextPage = list.length > pageSize;
    final trimmedList = hasNextPage ? list.sublist(0, pageSize) : list;
    final tracksWithArtist = trimmedList.map((e) async {
      final isSpotifyArtist = e['artist_type'] == 'SpotifyArtist';
      final artist = isSpotifyArtist ? await SpotifyService.getSpotifyArtist(e['artist_id'] ?? '') : null;

      return Track.fromJson(e).copyWith(artistName: artist?.name);
    }).toList();

    final trackList = await Future.wait(tracksWithArtist);
    TrackDatabase.instance.insertTracks(trackList);
    return TrackPage(data: trackList, total: trackList.length, hasNextPage: hasNextPage);
  }

  Future<List<Track>> getTracksByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final response = await _supabase
        .from("tracks")
        .select("""
            id, name, uri, artist_id, artist_type, genres, created_at, updated_at,
            images (url),
            favourites!left (id)
              """)
        .inFilter('id', ids);
    final trackWithArtist = (response as List).map((e) async {
      final isSpotifyArtist = e['artist_type'] == 'SpotifyArtist';
      final artist = isSpotifyArtist ? await SpotifyService.getSpotifyArtist(e['artist_id'] ?? '') : null;

      return Track.fromJson(e).copyWith(artistName: artist?.name);
    }).toList();
    return await Future.wait(trackWithArtist);
  }

  Future<List<Track>> getTracksByArtistId({required String artistId, required ArtistType artistType}) async {
    if (artistId.isEmpty) return [];

    final response = await _supabase
        .from("tracks")
        .select("""
            id, name, uri, artist_id, artist_type, genres, created_at, updated_at,
            images (url),
            favourites!left (id)
              """)
        .eq('artist_id', artistId)
        .eq('artist_type', artistType.name)
        .order('created_at', ascending: false);

    final trackWithArtist = (response as List).map((e) async {
      final isSpotifyArtist = e['artist_type'] == ArtistType.SpotifyArtist.name;
      final artist = isSpotifyArtist ? await SpotifyService.getSpotifyArtist(e['artist_id'] ?? '') : null;

      return Track.fromJson(e).copyWith(artistName: artist?.name);
    }).toList();

    return await Future.wait(trackWithArtist);
  }

  Future<List<Track>> getTopListenedTracks({int limit = 12}) async {
    final response = await _supabase
        .from('listen_histories')
        .select("""
          track:tracks (
            id, name, uri, artist_id, artist_type, genres, created_at, updated_at,
            images (url),
            favourites!left (id)
          )
        """)
        .order('listened_at', ascending: false)
        .limit(200);

    final counts = <int, int>{};
    final orderedTracks = <Track>[];

    for (final row in response as List) {
      final trackData = row['track'];
      if (trackData == null) continue;

      final track = Track.fromJson(trackData);
      counts[track.id] = (counts[track.id] ?? 0) + 1;
      orderedTracks.add(track);
    }

    final uniqueTracks = <int, Track>{};
    for (final track in orderedTracks) {
      uniqueTracks.putIfAbsent(track.id, () => track);
    }

    final sorted = uniqueTracks.values.toList()
      ..sort((a, b) {
        final countCompare = (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0);
        if (countCompare != 0) return countCompare;
        return b.createdAt.compareTo(a.createdAt);
      });

    final topTracks = sorted.take(limit).toList();
    final trackWithArtist = topTracks.map((track) async {
      final isSpotifyArtist = track.artistType == ArtistType.SpotifyArtist;
      final artist = isSpotifyArtist ? await SpotifyService.getSpotifyArtist(track.artistId) : null;
      return track.copyWith(artistName: artist?.name);
    }).toList();

    return await Future.wait(trackWithArtist);
  }

  Future<List<Track>> getSuggestedTracks({int limit = 16}) async {
    final tracks = await getTrackPage(page: 0, pageSize: limit * 2);
    final shuffled = List<Track>.from(tracks.data)..shuffle();
    return shuffled.take(limit).toList();
  }

  Future<List<Track>> searchTracks(String query) async {
    if (query.isEmpty) {
      final response = await _supabase
          .from("tracks")
          .select("""
            id, name, uri, artist_id, artist_type, genres, created_at, updated_at,
            images (url),
            favourites!left (id)
              """)
          .order('created_at', ascending: false);
      return (response as List).map((e) => Track.fromJson(e)).toList();
    }

    final response = await _supabase.rpc('search_tracks_fuzzy', params: {'search_query': query});
    final result = (response as List).map((e) => Track.fromJson(e)).toList();
    return result;
  }

  Future<void> addToListenHistory(int trackId) async {
    await _supabase.from('listen_histories').insert({
      'track_id': trackId,
      'listened_at': DateTime.now().toIso8601String(),
    });
  }

  Future<TrackPage> getRecentTracks({int page = 0, int pageSize = 20}) async {
    final response = await _supabase
        .from('listen_histories')
        .select("""
          track:tracks (
            id, name, uri, artist_id, artist_type, genres, created_at, updated_at,
            images (url),
            favourites!left (id)
          )
        """)
        .order('listened_at', ascending: false)
        .range(page * pageSize, page * pageSize + pageSize - 1);
    final trackWithArtist = (response as List).map((e) async {
      final trackData = e['track'];
      final isSpotifyArtist = trackData['artist_type'] == 'SpotifyArtist';
      final artist = isSpotifyArtist ? await SpotifyService.getSpotifyArtist(trackData['artist_id'] ?? '') : null;

      return Track.fromJson(trackData).copyWith(artistName: artist?.name);
    }).toList();
    final trackList = await Future.wait(trackWithArtist);
    return TrackPage(data: trackList, total: trackList.length, hasNextPage: trackList.length == pageSize);
  }

  /// Stream recent tracks with real-time updates from Supabase.
  /// Returns distinct tracks (by track_id), sorted by listened_at desc.
  Stream<List<Track>> streamRecentTracks({int limit = 10}) {
    return _supabase
        .from('listen_histories')
        .stream(primaryKey: ['id'])
        .order('listened_at', ascending: false)
        .asyncMap((rows) async {
          // Distinct by track_id, keep the latest listened_at for each track
          final uniqueTrackIds = <int>{};
          final distinctRows = <Map<String, dynamic>>[];

          for (final row in rows) {
            final trackId = row['track_id'] as int;
            if (!uniqueTrackIds.contains(trackId)) {
              uniqueTrackIds.add(trackId);
              distinctRows.add(row);
              if (distinctRows.length >= limit) break;
            }
          }

          if (distinctRows.isEmpty) return <Track>[];

          // Fetch full track details for the distinct track_ids
          final orderedTrackIds = distinctRows.map((r) => r['track_id'].toString()).toList();
          final tracks = await getTracksByIds(orderedTrackIds);

          // Reorder tracks to match the order of orderedTrackIds (most recent first)
          final trackMap = {for (final t in tracks) t.id.toString(): t};
          return orderedTrackIds.map((id) => trackMap[id]).whereType<Track>().toList();
        });
  }
}
