import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skymojo/models/favorite_location.dart';
import 'package:uuid/uuid.dart';

class FavoriteLocationService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const Uuid _uuid = Uuid();

  static Future<List<FavoriteLocation>> getFavoriteLocations() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        print('No authenticated user found');
        return [];
      }

      final response = await _client
          .from('favorite_locations')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: true);

      final locations = response
          .map<FavoriteLocation>((item) => FavoriteLocation.fromMap(item))
          .toList();
      print('Found ${locations.length} favorite locations');
      return locations;
    } catch (e) {
      print('Error fetching favorite locations: $e');
      return [];
    }
  }

  static Future<FavoriteLocation> addFavoriteLocation({
    required String name,
    required double latitude,
    required double longitude,
    List<String> tags = const [],
    bool isDefault = false,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      // If setting as default, unset other defaults
      if (isDefault) {
        await _unsetAllDefaultLocations(userId);
      }

      final locationData = {
        'id': _uuid.v4(),
        'user_id': userId,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'tags': tags,
        'is_default': isDefault,
      };

      final response = await _client
          .from('favorite_locations')
          .insert(locationData)
          .select()
          .single();

      // Safely create FavoriteLocation with null checks
      final favoriteLocation = FavoriteLocation(
        id: response['id']?.toString() ?? '',
        userId: response['user_id']?.toString() ?? '',
        name: response['name']?.toString() ?? name,
        latitude: (response['latitude'] as num?)?.toDouble() ?? latitude,
        longitude: (response['longitude'] as num?)?.toDouble() ?? longitude,
        isDefault: response['is_default'] as bool? ?? false,
        tags: (response['tags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            tags,
        createdAt: response['created_at'] != null
            ? DateTime.parse(response['created_at'].toString())
            : DateTime.now(),
        updatedAt: response['updated_at'] != null
            ? DateTime.parse(response['updated_at'].toString())
            : DateTime.now(),
      );

      return favoriteLocation;
    } catch (e) {
      print('Error adding favorite location: $e');
      rethrow;
    }
  }

  static Future<FavoriteLocation> updateFavoriteLocation({
    required String id,
    String? name,
    double? latitude,
    double? longitude,
    List<String>? tags,
    bool? isDefault,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      // If setting as default, unset other defaults
      if (isDefault == true) {
        await _unsetAllDefaultLocations(userId);
      }

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;
      if (tags != null) updateData['tags'] = tags;
      if (isDefault != null) updateData['is_default'] = isDefault;

      final response = await _client
          .from('favorite_locations')
          .update(updateData)
          .eq('id', id)
          .eq('user_id', userId)
          .select()
          .single();

      return FavoriteLocation.fromMap(response);
    } catch (e) {
      print('Error updating favorite location: $e');
      rethrow;
    }
  }

  static Future<bool> deleteFavoriteLocation(String id) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      final response = await _client
          .from('favorite_locations')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);

      print('Deleted favorite location: $id');
      return response.error == null;
    } catch (e) {
      print('Error deleting favorite location: $e');
      return false;
    }
  }

  static Future<FavoriteLocation?> setDefaultLocation(String id) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      // Unset all default locations first
      await _unsetAllDefaultLocations(userId);

      // Set new default
      return await updateFavoriteLocation(id: id, isDefault: true);
    } catch (e) {
      print('Error setting default location: $e');
      return null;
    }
  }

  static Future<FavoriteLocation?> getDefaultLocation() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return null;
      }

      final response = await _client
          .from('favorite_locations')
          .select()
          .eq('user_id', userId)
          .eq('is_default', true)
          .maybeSingle();

      if (response != null) {
        return FavoriteLocation.fromMap(response);
      }
      return null;
    } catch (e) {
      print('Error getting default location: $e');
      return null;
    }
  }

  static Future<void> _unsetAllDefaultLocations(String userId) async {
    try {
      await _client
          .from('favorite_locations')
          .update({'is_default': false})
          .eq('user_id', userId)
          .eq('is_default', true);
    } catch (e) {
      print('Error unsetting default locations: $e');
      rethrow;
    }
  }

  static Future<FavoriteLocation?> getCurrentLocationFavorite() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return null;
      }

      final response = await _client
          .from('favorite_locations')
          .select()
          .eq('user_id', userId)
          .eq('name', 'Current Location')
          .maybeSingle();

      if (response != null) {
        return FavoriteLocation.fromMap(response);
      }
      return null;
    } catch (e) {
      print('Error getting current location favorite: $e');
      return null;
    }
  }

  static Future<FavoriteLocation> addOrUpdateCurrentLocation({
    required double latitude,
    required double longitude,
    required String name,
  }) async {
    try {
      final existing = await getCurrentLocationFavorite();

      if (existing != null) {
        return await updateFavoriteLocation(
          id: existing.id,
          name: name,
          latitude: latitude,
          longitude: longitude,
        );
      } else {
        return await addFavoriteLocation(
          name: name,
          latitude: latitude,
          longitude: longitude,
          isDefault: false,
        );
      }
    } catch (e) {
      print('Error adding/updating current location: $e');
      rethrow;
    }
  }
}
