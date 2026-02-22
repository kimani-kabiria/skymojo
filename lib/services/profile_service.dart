import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String id;
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final String? defaultLocation;
  final String temperatureUnit;
  final String themePreference;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    this.username,
    this.fullName,
    this.avatarUrl,
    this.defaultLocation,
    required this.temperatureUnit,
    required this.themePreference,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      username: map['username'] as String?,
      fullName: map['full_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      defaultLocation: map['default_location'] as String?,
      temperatureUnit: map['temperature_unit'] as String? ?? 'celsius',
      themePreference: map['theme_preference'] as String? ?? 'auto',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'default_location': defaultLocation,
      'temperature_unit': temperatureUnit,
      'theme_preference': themePreference,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ProfileService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Get current user profile
  static Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .single();

      return UserProfile.fromMap(response);
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  // Update user profile
  static Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      await _client
          .from('user_profiles')
          .update(data)
          .eq('id', user.id);

      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Update temperature unit preference
  static Future<bool> updateTemperatureUnit(String unit) async {
    return await updateProfile({'temperature_unit': unit});
  }

  // Update theme preference
  static Future<bool> updateThemePreference(String theme) async {
    return await updateProfile({'theme_preference': theme});
  }

  // Update default location
  static Future<bool> updateDefaultLocation(String location) async {
    return await updateProfile({'default_location': location});
  }
}
