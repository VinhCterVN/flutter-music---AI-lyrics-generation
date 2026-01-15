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
      images: (json['images'] as List<dynamic>)
          .map((imageJson) => ArtistImage(
                url: imageJson['url'],
                height: imageJson['height'],
                width: imageJson['width'],
              ))
          .toList(),
      popularity: json['popularity'],
      artistType: ArtistType.SpotifyArtist
    );
  }
}

class ArtistImage {
  final String url;
  final int height;
  final int width;

  ArtistImage({
    required this.url,
    required this.height,
    required this.width,
  });
}