import 'package:just_audio/just_audio.dart';

class Track {
  final int id;
  final String name;
  final String uri;
  final List<String> genres;
  final String artistId;
  final ArtistType artistType;
  final List<String> images;
  final bool isFavorite;
  final DateTime createdAt;

  Track({
    required this.id,
    required this.name,
    required this.artistId,
    required this.uri,
    required this.images,
    required this.createdAt,
    this.genres = const [],
    this.isFavorite = false,
    this.artistType = ArtistType.NestArtist,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'],
      name: json['name'],
      uri: json['uri'],
      artistId: json['artistId'],
      artistType: ArtistType.values.byName(json['artistType']),
      genres: List<String>.from(json['genres'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      isFavorite: json['isFavorite'] ?? false,
    );
  }
}

enum ArtistType { SpotifyArtist, NestArtist }

class TrackProgress {
  final Duration position;
  final Duration buffered;
  final Duration? duration;

  TrackProgress(this.position, this.buffered, this.duration);
}

extension TrackToAudioSource on Track {
  AudioSource toAudioSource() {
    return AudioSource.uri(
      Uri.parse(uri),
      tag: {
        'id': id,
        'title': name,
        'artistId': artistId,
        'artistType': artistType,
        'images': images,
        'genres': genres,
      },
    );
  }
}

extension TrackListToAudioSourceList on List<Track> {
  List<AudioSource> toAudioSources() {
    return map((track) => track.toAudioSource()).toList();
  }
}
