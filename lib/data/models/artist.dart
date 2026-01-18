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
      images: (json['images'] as List<dynamic>).map((imageJson) {
        return ArtistImage(url: imageJson['url'], height: imageJson['height'], width: imageJson['width']);
      }).toList(),
      popularity: json['popularity'],
      artistType: json['artist_type'] ?? ArtistType.SpotifyArtist,
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
