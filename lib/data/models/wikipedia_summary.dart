class WikipediaSummary {
  final String type;
  final String title;
  final String displayTitle;
  final Map<String, String> titles;
  final WikipediaImage thumbnail;
  final WikipediaImage originalImage;
  final String description;
  final String extract;

  WikipediaSummary({
    required this.type,
    required this.title,
    required this.displayTitle,
    required this.titles,
    required this.thumbnail,
    required this.originalImage,
    required this.description,
    required this.extract,
  });

  factory WikipediaSummary.fromJson(Map<String, dynamic> json) {
    return WikipediaSummary(
      type: json['type'],
      title: json['title'],
      displayTitle: json['displaytitle'],
      titles: Map<String, String>.from(json['titles']),
      thumbnail: WikipediaImage(
        source: json['thumbnail']['source'],
        width: json['thumbnail']['width'],
        height: json['thumbnail']['height'],
      ),
      originalImage: WikipediaImage(
        source: json['originalimage']['source'],
        width: json['originalimage']['width'],
        height: json['originalimage']['height'],
      ),
      description: json['description'],
      extract: json['extract'],
    );
  }
}

class WikipediaImage {
  final String source;
  final int width;
  final int height;

  WikipediaImage({required this.source, required this.width, required this.height});
}
