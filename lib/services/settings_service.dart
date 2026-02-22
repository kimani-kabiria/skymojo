import 'package:supabase_flutter/supabase_flutter.dart';

class UserSettings {
  final String id;
  final String userId;
  final bool pushNotifications;
  final bool emailAlerts;
  final int weatherRefreshInterval;
  final bool autoLocation;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSettings({
    required this.id,
    required this.userId,
    required this.pushNotifications,
    required this.emailAlerts,
    required this.weatherRefreshInterval,
    required this.autoLocation,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      pushNotifications: map['push_notifications'] as bool? ?? true,
      emailAlerts: map['email_alerts'] as bool? ?? true,
      weatherRefreshInterval: map['weather_refresh_interval'] as int? ?? 30,
      autoLocation: map['auto_location'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'push_notifications': pushNotifications,
      'email_alerts': emailAlerts,
      'weather_refresh_interval': weatherRefreshInterval,
      'auto_location': autoLocation,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class SettingsService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Get user settings
  static Future<UserSettings?> getUserSettings() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('user_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        // Create default settings if none exist
        return await createDefaultSettings();
      }

      return UserSettings.fromMap(response);
    } catch (e) {
      print('Error fetching user settings: $e');
      return null;
    }
  }

  // Create default settings for new user
  static Future<UserSettings> createDefaultSettings() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _client
          .from('user_settings')
          .insert({
            'user_id': user.id,
            'push_notifications': true,
            'email_alerts': true,
            'weather_refresh_interval': 30,
            'auto_location': false,
          })
          .select()
          .single();

      return UserSettings.fromMap(response);
    } catch (e) {
      print('Error creating default settings: $e');
      rethrow;
    }
  }

  // Update user settings
  static Future<bool> updateSettings(Map<String, dynamic> data) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      await _client
          .from('user_settings')
          .update(data)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      print('Error updating settings: $e');
      return false;
    }
  }

  // Toggle push notifications
  static Future<bool> togglePushNotifications(bool enabled) async {
    return await updateSettings({'push_notifications': enabled});
  }

  // Toggle email alerts
  static Future<bool> toggleEmailAlerts(bool enabled) async {
    return await updateSettings({'email_alerts': enabled});
  }

  // Update weather refresh interval
  static Future<bool> updateRefreshInterval(int minutes) async {
    return await updateSettings({'weather_refresh_interval': minutes});
  }

  // Toggle auto location
  static Future<bool> toggleAutoLocation(bool enabled) async {
    return await updateSettings({'auto_location': enabled});
  }
}
