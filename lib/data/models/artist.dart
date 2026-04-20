import 'dart:convert';

import 'package:flutter_ai_music/data/models/track.dart';

class Artist {
  final String id;
  final String name;
  final List<ArtistImage> images;
  final int popularity;
  final ArtistType artistType;

  Artist({
    required this.id,
    required this.name,
    required this.images,
    required this.popularity,
    required this.artistType,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'],
      name: json['name'],
      images: ((json['images'] as List?) ?? const []).map((imageJson) {
        return ArtistImage(url: imageJson['url'], height: imageJson['height'], width: imageJson['width']);
      }).toList(),
      popularity: (json['popularity'] as num?)?.toInt() ?? 0,
      artistType: _parseArtistType(json['artist_type']),
    );
  }

  factory Artist.fromDatabase(Map<String, dynamic> json) {
    return Artist(
      id: json['id'],
      name: json['name'],
      images: (jsonDecode(json['images']) as List).map((e) => ArtistImage.fromJson(e)).toList(),
      popularity: json['popularity'],
      artistType: ArtistType.values.byName(json['artist_type']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'images': jsonEncode(
        images.map((image) {
          return {'url': image.url, 'height': image.height, 'width': image.width};
        }).toList(),
      ),
      'popularity': popularity,
      'artist_type': artistType.name,
    };
  }

  String? get primaryImageUrl => images.isEmpty ? null : images.first.url;

  static ArtistType _parseArtistType(dynamic value) {
    if (value is ArtistType) return value;
    if (value is String) {
      for (final type in ArtistType.values) {
        if (type.name == value) return type;
      }
      return ArtistType.SpotifyArtist;
    }
    return ArtistType.SpotifyArtist;
  }
}

class ArtistImage {
  final String url;
  final int height;
  final int width;

  ArtistImage({required this.url, required this.height, required this.width});

  factory ArtistImage.fromJson(Map<String, dynamic> json) {
    return ArtistImage(
      url: json['url'],
      height: json['height'],
      width: json['width'],
    );
  }
}
