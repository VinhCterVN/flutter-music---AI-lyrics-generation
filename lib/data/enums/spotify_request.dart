enum SpotifyResourceType {
  artist,
  track,
  album,
}

extension SpotifyResourceTypeExt on SpotifyResourceType {
  String get path {
    switch (this) {
      case SpotifyResourceType.artist:
        return 'artists';
      case SpotifyResourceType.track:
        return 'tracks';
      case SpotifyResourceType.album:
        return 'albums';
    }
  }
}
