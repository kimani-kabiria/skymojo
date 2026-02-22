import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skymojo/services/user_profile_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleAuthService {
  static final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // iOS Client ID from environment variables
    clientId: dotenv.env['GOOGLE_IOS_CLIENT_ID'] ?? '',
  );

  // Initialize Google Sign-In
  static Future<void> initialize() async {
    /// Web Client ID that you registered with Google Cloud.
    final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';
    /// iOS Client ID that you registered with Google Cloud.
    final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID'] ?? '';
    
    print('Initializing Google Sign-In with Client ID: ${_googleSignIn.clientId}');
    print('Web Client ID: $webClientId');
    print('iOS Client ID: $iosClientId');
    
    await _googleSignIn.signInSilently();
  }

  // Sign in with Google
  static Future<void> signInWithGoogle() async {
    try {
      print('Starting Google Sign-In...');
      final googleUser = await _googleSignIn.signIn();
      print('Google user: $googleUser');
      
      if (googleUser == null) {
        print('Google Sign-In cancelled or failed');
        throw AuthException('Failed to sign in with Google.');
      }

      // Get authentication details
      print('Getting authentication details...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('Google auth: $googleAuth');
      
      final idToken = googleAuth.idToken;
      print('ID Token: $idToken');
      
      if (idToken == null) {
        print('No ID Token found');
        throw AuthException('No ID Token found.');
      }
      
      print('Signing in with Supabase...');
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );
      print('Successfully signed in with Supabase');
      
      // Create or update user profile with Google data
      await _syncUserProfile(googleUser);
    } catch (e) {
      print('Google Sign-In Error: $e');
      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      print('Google Sign-Out Error: $e');
    }
  }

  // Get current Google user
  static Future<GoogleSignInAccount?> getCurrentUser() async {
    return await _googleSignIn.signInSilently();
  }

  // Check if user is signed in with Google
  static Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  // Sync user profile with Google data
  static Future<void> _syncUserProfile(GoogleSignInAccount googleUser) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        print('No user ID found after authentication');
        return;
      }

      // Get avatar and name from Google user
      final avatarUrl = googleUser.photoUrl;
      final fullName = googleUser.displayName;

      await UserProfileService.ensureProfileExists(
        userId: userId,
        fullName: fullName,
        avatarUrl: avatarUrl,
      );
      
      print('User profile synced with Google data');
    } catch (e) {
      print('Error syncing user profile: $e');
      // Don't rethrow here as profile sync shouldn't block sign-in
    }
  }
}
