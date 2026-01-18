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
