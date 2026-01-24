import 'package:uuid/uuid.dart';

class Search {
  final String id;
  final String keyword;
  final int searchCount;

  const Search({required this.id, required this.keyword, this.searchCount = -1});

  factory Search.fromJson(Map<String, dynamic> json) {
    return Search(id: json['id'], keyword: json['keyword']);
  }

  factory Search.trending(Map<String, dynamic> json) {
    return Search(id: Uuid().v4(), keyword: json['keyword'], searchCount: json['search_count'] ?? -1);
  }
}

class SearchResult {
  final String id;
  final List<String> trackIds;
  final List<String> artistIds;
  final List<String> playlistIds;

  const SearchResult({
    required this.id,
    this.trackIds = const [],
    this.artistIds = const [],
    this.playlistIds = const [],
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: const Uuid().v4(),
      trackIds: (json['track_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      artistIds: (json['artist_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      playlistIds: (json['playlist_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
