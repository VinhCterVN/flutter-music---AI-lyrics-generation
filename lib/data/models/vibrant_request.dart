class VibrantRequest {
  final String imageUrl;

  VibrantRequest(this.imageUrl);

  Map<String, dynamic> toJson() => {"imageUrl": imageUrl};
}

class Palette {
  final PaletteColor vibrant;
  final PaletteColor darkVibrant;
  final PaletteColor lightVibrant;
  final PaletteColor muted;
  final PaletteColor darkMuted;
  final PaletteColor lightMuted;

  Palette({
    required this.vibrant,
    required this.darkVibrant,
    required this.lightVibrant,
    required this.muted,
    required this.darkMuted,
    required this.lightMuted,
  });

  factory Palette.fromJson(Map<String, dynamic> json) {
    return Palette(
      vibrant: PaletteColor.fromJson(json["Vibrant"]),
      darkVibrant: PaletteColor.fromJson(json["DarkVibrant"]),
      lightVibrant: PaletteColor.fromJson(json["LightVibrant"]),
      muted: PaletteColor.fromJson(json["Muted"]),
      darkMuted: PaletteColor.fromJson(json["DarkMuted"]),
      lightMuted: PaletteColor.fromJson(json["LightMuted"]),
    );
  }
}

class PaletteColor {
  final List<num> rgb;

  PaletteColor({required this.rgb});

  factory PaletteColor.fromJson(Map<String, dynamic> json) {
    return PaletteColor(rgb: List<num>.from(json["rgb"]));
  }
}
