import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Get current user
  static User? get currentUser => _client.auth.currentUser;

  // Sign out
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // Update user metadata
  static Future<void> updateUserMetadata(Map<String, dynamic> metadata) async {
    await _client.auth.updateUser(
      UserAttributes(data: metadata),
    );
  }

  // Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;
}
