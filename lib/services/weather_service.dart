import 'package:supabase_flutter/supabase_flutter.dart';

class WeatherCache {
  final String id;
  final double latitude;
  final double longitude;
  final Map<String, dynamic> weatherData;
  final DateTime createdAt;
  final DateTime expiresAt;

  WeatherCache({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.weatherData,
    required this.createdAt,
    required this.expiresAt,
  });

  factory WeatherCache.fromMap(Map<String, dynamic> map) {
    return WeatherCache(
      id: map['id'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      weatherData: map['weather_data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(map['created_at'] as String),
      expiresAt: DateTime.parse(map['expires_at'] as String),
    );
  }
}

class WeatherService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const Duration _cacheDuration = Duration(minutes: 30);

  // Get cached weather data
  static Future<Map<String, dynamic>?> getCachedWeather(
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await _client
          .from('weather_cache')
          .select()
          .eq('latitude', latitude)
          .eq('longitude', longitude)
          .gt('expires_at', DateTime.now().toIso8601String())
          .maybeSingle();

      if (response == null) return null;

      final cache = WeatherCache.fromMap(response);
      return cache.weatherData;
    } catch (e) {
      print('Error fetching cached weather: $e');
      return null;
    }
  }

  // Cache weather data
  static Future<bool> cacheWeatherData(
    double latitude,
    double longitude,
    Map<String, dynamic> weatherData,
  ) async {
    try {
      final expiresAt = DateTime.now().add(_cacheDuration);

      await _client.from('weather_cache').upsert({
        'latitude': latitude,
        'longitude': longitude,
        'weather_data': weatherData,
        'expires_at': expiresAt.toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error caching weather data: $e');
      return false;
    }
  }

  // Clean up expired cache entries
  static Future<void> cleanupExpiredCache() async {
    try {
      await _client
          .from('weather_cache')
          .delete()
          .lt('expires_at', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error cleaning up expired cache: $e');
    }
  }
}

class WeatherAlert {
  final String id;
  final String userId;
  final String? locationId;
  final String alertType;
  final double? thresholdValue;
  final String? condition;
  final bool isActive;
  final DateTime createdAt;

  WeatherAlert({
    required this.id,
    required this.userId,
    this.locationId,
    required this.alertType,
    this.thresholdValue,
    this.condition,
    required this.isActive,
    required this.createdAt,
  });

  factory WeatherAlert.fromMap(Map<String, dynamic> map) {
    return WeatherAlert(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      locationId: map['location_id'] as String?,
      alertType: map['alert_type'] as String,
      thresholdValue: map['threshold_value'] as double?,
      condition: map['condition'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'location_id': locationId,
      'alert_type': alertType,
      'threshold_value': thresholdValue,
      'condition': condition,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class AlertService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Get all weather alerts for current user
  static Future<List<WeatherAlert>> getWeatherAlerts() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final response = await _client
          .from('weather_alerts')
          .select()
          .eq('user_id', user.id)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => WeatherAlert.fromMap(item))
          .toList();
    } catch (e) {
      print('Error fetching weather alerts: $e');
      return [];
    }
  }

  // Add a new weather alert
  static Future<bool> addWeatherAlert({
    required String alertType,
    double? thresholdValue,
    String? condition,
    String? locationId,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      await _client.from('weather_alerts').insert({
        'user_id': user.id,
        'location_id': locationId,
        'alert_type': alertType,
        'threshold_value': thresholdValue,
        'condition': condition,
      });

      return true;
    } catch (e) {
      print('Error adding weather alert: $e');
      return false;
    }
  }

  // Remove a weather alert
  static Future<bool> removeWeatherAlert(String alertId) async {
    try {
      await _client
          .from('weather_alerts')
          .delete()
          .eq('id', alertId);

      return true;
    } catch (e) {
      print('Error removing weather alert: $e');
      return false;
    }
  }

  // Toggle alert active status
  static Future<bool> toggleAlertStatus(String alertId, bool isActive) async {
    try {
      await _client
          .from('weather_alerts')
          .update({'is_active': isActive})
          .eq('id', alertId);

      return true;
    } catch (e) {
      print('Error toggling alert status: $e');
      return false;
    }
  }
}
