import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skymojo/models/user_profile.dart';

class UserProfileService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        print('No authenticated user found');
        return null;
      }

      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfile.fromMap(response);
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  static Future<String?> getUserAvatarFromMetadata() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      // Try to get avatar from user metadata (could be from Google, Apple, etc.)
      final avatarUrl = user.userMetadata?['avatar_url'] ?? 
                       user.userMetadata?['picture'] ?? 
                       user.userMetadata?['photo_url'];
      
      print('Found avatar in metadata: $avatarUrl');
      return avatarUrl;
    } catch (e) {
      print('Error fetching avatar from metadata: $e');
      return null;
    }
  }

  static Future<String?> getUserNameFromMetadata() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      // Try to get name from user metadata with fallbacks
      final fullName = user.userMetadata?['full_name'] ?? 
                      user.userMetadata?['name'] ?? 
                      user.userMetadata?['display_name'];
      
      print('Found name in metadata: $fullName');
      return fullName;
    } catch (e) {
      print('Error fetching name from metadata: $e');
      return null;
    }
  }

  static Future<UserProfile> createProfile({
    required String userId,
    String? username,
    String? fullName,
    String? avatarUrl,
    String? defaultLocation,
    String temperatureUnit = 'celsius',
    String themePreference = 'auto',
  }) async {
    try {
      final profileData = {
        'id': userId,
        'username': username,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'default_location': defaultLocation,
        'temperature_unit': temperatureUnit,
        'theme_preference': themePreference,
      };

      final response = await _client
          .from('user_profiles')
          .insert(profileData)
          .select()
          .single();

      return UserProfile.fromMap(response);
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }

  static Future<UserProfile> updateProfile({
    required String userId,
    String? username,
    String? fullName,
    String? avatarUrl,
    String? defaultLocation,
    String? temperatureUnit,
    String? themePreference,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (username != null) updateData['username'] = username;
      if (fullName != null) updateData['full_name'] = fullName;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
      if (defaultLocation != null) updateData['default_location'] = defaultLocation;
      if (temperatureUnit != null) updateData['temperature_unit'] = temperatureUnit;
      if (themePreference != null) updateData['theme_preference'] = themePreference;

      final response = await _client
          .from('user_profiles')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

      return UserProfile.fromMap(response);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  static Future<UserProfile> ensureProfileExists({
    required String userId,
    String? username,
    String? fullName,
    String? avatarUrl,
  }) async {
    try {
      UserProfile? profile = await getCurrentUserProfile();
      
      if (profile == null) {
        print('Creating new profile for user: $userId');
        profile = await createProfile(
          userId: userId,
          username: username,
          fullName: fullName,
          avatarUrl: avatarUrl,
        );
      } else {
        print('Profile already exists for user: $userId');
        if (fullName != null && profile.fullName != fullName) {
          profile = await updateProfile(
            userId: userId,
            fullName: fullName,
            avatarUrl: avatarUrl,
          );
        }
      }
      
      return profile;
    } catch (e) {
      print('Error ensuring profile exists: $e');
      rethrow;
    }
  }

  static Future<bool> deleteProfile(String userId) async {
    try {
      final response = await _client
          .from('user_profiles')
          .delete()
          .eq('id', userId);
      
      return response.error == null;
    } catch (e) {
      print('Error deleting user profile: $e');
      return false;
    }
  }

  static Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select('username')
          .eq('username', username)
          .maybeSingle();
      
      return response == null;
    } catch (e) {
      print('Error checking username availability: $e');
      return false;
    }
  }
}
