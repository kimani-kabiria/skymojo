import 'package:supabase_flutter/supabase_flutter.dart';

class FavoriteLocation {
  final String id;
  final String userId;
  final String name;
  final double latitude;
  final double longitude;
  final String? city;
  final String? country;
  final DateTime createdAt;
  final bool isDefault;

  FavoriteLocation({
    required this.id,
    required this.userId,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
    required this.createdAt,
    required this.isDefault,
  });

  factory FavoriteLocation.fromMap(Map<String, dynamic> map) {
    return FavoriteLocation(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      city: map['city'] as String?,
      country: map['country'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      isDefault: map['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'country': country,
      'created_at': createdAt.toIso8601String(),
      'is_default': isDefault,
    };
  }
}

class LocationService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Get all favorite locations for current user
  static Future<List<FavoriteLocation>> getFavoriteLocations() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final response = await _client
          .from('favorite_locations')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: true);

      return (response as List)
          .map((item) => FavoriteLocation.fromMap(item))
          .toList();
    } catch (e) {
      print('Error fetching favorite locations: $e');
      return [];
    }
  }

  // Add a new favorite location
  static Future<bool> addFavoriteLocation({
    required String name,
    required double latitude,
    required double longitude,
    String? city,
    String? country,
    bool isDefault = false,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      // If setting as default, unset other defaults first
      if (isDefault) {
        await _client
            .from('favorite_locations')
            .update({'is_default': false})
            .eq('user_id', user.id);
      }

      await _client.from('favorite_locations').insert({
        'user_id': user.id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'city': city,
        'country': country,
        'is_default': isDefault,
      });

      return true;
    } catch (e) {
      print('Error adding favorite location: $e');
      return false;
    }
  }

  // Remove a favorite location
  static Future<bool> removeFavoriteLocation(String locationId) async {
    try {
      await _client
          .from('favorite_locations')
          .delete()
          .eq('id', locationId);

      return true;
    } catch (e) {
      print('Error removing favorite location: $e');
      return false;
    }
  }

  // Update a favorite location
  static Future<bool> updateFavoriteLocation(
    String locationId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _client
          .from('favorite_locations')
          .update(data)
          .eq('id', locationId);

      return true;
    } catch (e) {
      print('Error updating favorite location: $e');
      return false;
    }
  }

  // Set a location as default
  static Future<bool> setDefaultLocation(String locationId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      // First, unset all default locations for this user
      await _client
          .from('favorite_locations')
          .update({'is_default': false})
          .eq('user_id', user.id);

      // Then set the new default
      await _client
          .from('favorite_locations')
          .update({'is_default': true})
          .eq('id', locationId);

      return true;
    } catch (e) {
      print('Error setting default location: $e');
      return false;
    }
  }

  // Get the default location
  static Future<FavoriteLocation?> getDefaultLocation() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('favorite_locations')
          .select()
          .eq('user_id', user.id)
          .eq('is_default', true)
          .maybeSingle();

      if (response == null) return null;

      return FavoriteLocation.fromMap(response);
    } catch (e) {
      print('Error fetching default location: $e');
      return null;
    }
  }
}
