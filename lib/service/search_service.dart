import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../provider/auth_provider.dart';

class SearchService {
  final Ref ref;
  final SupabaseClient _supabase;

  SearchService(this.ref) : _supabase = ref.read(supabaseClientProvider);

  Future<void> insertSearch(String query) async {
    final res = await _supabase.from("search_logs").insert({
      "keyword": query,
    });

    if (res.error != null) {
      throw Exception('Failed to insert search log: ${res.error!.message}');
    }
  }
}