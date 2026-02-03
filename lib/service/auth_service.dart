import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthenticationService {
  final SupabaseClient _supabase;

  AuthenticationService(this._supabase);

  Stream<User?> get authStateChanges => _supabase.auth.onAuthStateChange.map((event) => event.session?.user);

  User? get currentUser => _supabase.auth.currentUser;

  Future<String?> signIn({required String email, required String password}) async {
    try {
      final response = await _supabase.auth.signInWithPassword(email: email, password: password);
      if (response.user != null) {
        await saveUserData(response.user!);
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An error occurred during sign-in: $e';
    }
  }

  Future<String?> signUp({required String name, required String email, required String password}) async {
    try {
      final response = await _supabase.auth.signUp(email: email, password: password);
      if (response.user != null) {
        await saveUserData(response.user!);
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An error occurred during sign-up: $e';
    }
  }

  Future<String?> updateUserDisplayName(String displayName) async {
    try {
      final user = currentUser;
      if (user == null) return 'No user is currently signed in.';

      final updates = UserAttributes(data: {'displayName': displayName.trim()});
      await _supabase.auth.updateUser(updates);

      final updatedUser = _supabase.auth.currentUser!;
      await saveUserData(updatedUser);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  Future<String?> sendVerificationEmail(String email) async {
    try {
      await _supabase.auth.resend(type: OtpType.signup, email: email);
      log("Verification email sent to $email");
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> saveUserData(User user) async {
    try {
      final displayName = user.userMetadata?['displayName'] ?? '';
      final photoUrl = user.userMetadata?['photoUrl'] ?? '';

      final data = {
        'id': user.id,
        'email': user.email,
        'display_name': displayName,
        'photo_url': photoUrl,
        'email_verified': user.emailConfirmedAt != null,
        'last_active': DateTime.now().toIso8601String(),
      };

      await _supabase.from('users').upsert(data, onConflict: 'id');

      return null;
    } catch (e) {
      log("Error saving user data: $e");
      return 'Failed to save user data: $e';
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
