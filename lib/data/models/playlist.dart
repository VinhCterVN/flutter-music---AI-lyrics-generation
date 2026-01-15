import 'package:flutter_ai_music/data/models/track.dart';

class Playlist {
  final String id;
  final String userId;
  final String name;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Track> tracks;

  const Playlist({
    required this.id,
    required this.userId,
    required this.name,
    required this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.tracks = const [],
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
