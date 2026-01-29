import 'package:flutter_ai_music/data/models/track.dart';

class Playlist {
  final String id;
  final String userId;
  final String name;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Track> tracks;
  final List<int> trackIds;

  const Playlist({
    required this.id,
    required this.userId,
    required this.name,
    required this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.tracks = const [],
    this.trackIds = const [],
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final playlistsTracks = json['playlists_tracks'] as List?;
    final trackIds = playlistsTracks?.map((e) => e['track_id'] as int).toList() ?? [];

    return Playlist(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      trackIds: trackIds,
    );
  }

  bool containsTrack(int trackId) => trackIds.contains(trackId);
}

class WeeklyHistory {
  final List<int> trackIds;
  final DateTime listenedAt;

  const WeeklyHistory({
    required this.trackIds,
    required this.listenedAt,
  });

  factory WeeklyHistory.fromJson(Map<String, dynamic> json) {
    final trackIds = (json['track_ids'] as List).map((e) => e as int).toList();
    return WeeklyHistory(
      trackIds: trackIds,
      listenedAt: DateTime.parse(json['listened_at'] as String),
    );
  }

  @override
  String toString() {
    return 'WeeklyHistory(trackIds: $trackIds, listenedAt: $listenedAt)';
  }
}
