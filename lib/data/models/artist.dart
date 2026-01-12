class SpotifyArtist {
  final String id;
  final String name;
  final List<ArtistImage> images;
  final int popularity;

  SpotifyArtist({
    required this.id,
    required this.name,
    required this.images,
    required this.popularity,
  });

  factory SpotifyArtist.fromJson(Map<String, dynamic> json) {
    return SpotifyArtist(
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