import 'package:flutter_ai_music/provider/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/user.dart' as app_user;

class UserService {
  final Ref ref;
  final SupabaseClient _supabase;

  UserService(this.ref) : _supabase = ref.read(supabaseClientProvider);

  Future<app_user.User> getUserFromId(String id) async {
    final response = await _supabase.from('users').select().eq('id', id).single();
    return app_user.User.fromJson(response);
  }
}
