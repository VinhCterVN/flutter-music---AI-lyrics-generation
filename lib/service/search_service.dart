import 'package:flutter_ai_music/data/models/search.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../provider/auth_provider.dart';

class SearchService {
  final Ref ref;
  final SupabaseClient _supabase;

  SearchService(this.ref) : _supabase = ref.read(supabaseClientProvider);

  Future<List<Search>> getTrendingSearch() async {
    final res = await _supabase.rpc("get_trending_searches", params: {"limit_count": 20});
    return (res as List).map((e) => Search.trending(e)).toList();
  }

  Future<List<Search>> getSearchHistory({int page = 0, int pageSize = 20}) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    final res = await _supabase
        .from('search_logs')
        .select()
        .order('keyword')
        .order('created_at', ascending: false)
        .range(from, to);

    final map = <String, Map<String, dynamic>>{};
    for (final row in res) {
      map.putIfAbsent(row['keyword'], () => row);
    }

    return map.values.map((e) => Search.fromJson(e)).toList();
  }

  Future<void> insertSearch(String query) async =>
      await _supabase.from("search_logs").insert({"keyword": query.toLowerCase()});
}
