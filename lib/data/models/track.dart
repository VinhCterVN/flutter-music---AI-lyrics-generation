import 'dart:convert';

import 'package:just_audio/just_audio.dart';

class Track {
  final int id;
  final String name;
  final String uri;
  final List<String> genres;
  String? artistName;
  final String artistId;
  final ArtistType artistType;
  final List<String> images;
  bool isFavorite;
  final DateTime createdAt;

  Track({
    required this.id,
    required this.name,
    required this.artistId,
    required this.uri,
    required this.images,
    required this.createdAt,
    this.artistName,
    this.genres = const [],
    this.isFavorite = false,
    this.artistType = ArtistType.NestArtist,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'],
      name: json['name'],
      uri: json['uri'],
      artistId: json['artist_id'],
      artistType: ArtistType.values.byName(json['artist_type']),
      genres: List<String>.from(json['genres'] ?? []),
      images: (json['images'] as List?)?.map((img) => img['url'] as String).toList() ?? [],
      isFavorite: (json['favourites'] as List?)?.isNotEmpty ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'uri': uri,
      'artistId': artistId,
      'artistName': artistName,
      'artistType': artistType.name,
      'genres': jsonEncode(genres),
      'images': jsonEncode(images),
      'isFavorite': isFavorite ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  void updateArtistName(String name) {
    artistName = name;
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
