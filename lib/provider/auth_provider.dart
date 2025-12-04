import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../service/auth_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final authenticationServiceProvider = Provider<AuthenticationService>((ref) {
  return AuthenticationService(ref.watch(supabaseClientProvider));
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authenticationServiceProvider).authStateChanges;
});

final currentUserProvider = StateProvider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});
