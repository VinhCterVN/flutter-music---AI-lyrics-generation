import 'package:flutter_ai_music/service/user_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../service/auth_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final authenticationServiceProvider = Provider<AuthenticationService>((ref) {
  return AuthenticationService(ref.watch(supabaseClientProvider));
});

final authStateProvider = StreamProvider<User?>((ref) async* {
  final authService = ref.watch(authenticationServiceProvider);
  yield authService.currentUser;
  yield* authService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

final userServiceProvider = Provider<UserService>((ref) => UserService(ref));
