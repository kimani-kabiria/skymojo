import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:skymojo/services/favorite_location_service.dart';
import 'package:skymojo/services/user_profile_service.dart';
import 'package:skymojo/models/location_tag.dart';
import 'package:geolocator/geolocator.dart';

class SelectedLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String type; // 'profile_default', 'current', 'favorite'
  final List<LocationTag> tags; // Tags from favorite locations

  const SelectedLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.tags = const [],
  });

  factory SelectedLocation.fromMap(Map<String, dynamic> map) {
    return SelectedLocation(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      type: map['type']?.toString() ?? 'favorite',
      tags: (map['tags'] as List<dynamic>?)
              ?.map((tag) => LocationTag.getById(tag.toString()))
              .whereType<LocationTag>()
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'tags': tags.map((tag) => tag.id).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SelectedLocation &&
        other.id == id &&
        other.name == name &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.type == type;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, latitude, longitude, type);
  }

  @override
  String toString() {
    return 'SelectedLocation(id: $id, name: $name, type: $type, tags: ${tags.map((t) => t.id).toList()})';
  }
}

class LocationCacheService {
  static const String _selectedLocationKey = 'selected_location';
  static final SupabaseClient _client = Supabase.instance.client;

  // Save selected location to cache
  static Future<bool> saveSelectedLocation(SelectedLocation location) async {
    try {
      print('DEBUG: Attempting to save location: ${location.toMap()}');

      final prefs = await SharedPreferences.getInstance();
      final locationJson = location.toMap();
      await prefs.setString(_selectedLocationKey, jsonEncode(locationJson));

      print('DEBUG: Saved to SharedPreferences successfully');

      // Also store in Supabase user metadata for cross-device sync
      final user = _client.auth.currentUser;
      if (user != null) {
        await _client.auth.updateUser(
          UserAttributes(data: {
            'selected_location': locationJson,
          }),
        );
        print('DEBUG: Saved to Supabase user metadata successfully');
      } else {
        print('DEBUG: No authenticated user found for Supabase sync');
      }

      print('DEBUG: Successfully saved selected location: ${location.name}');
      return true;
    } catch (e) {
      print('DEBUG: Error saving selected location: $e');
      return false;
    }
  }

  // Get cached selected location
  static Future<SelectedLocation?> getSelectedLocation() async {
    try {
      print('DEBUG: Getting cached location...');

      final prefs = await SharedPreferences.getInstance();
      final cachedLocationString = prefs.getString(_selectedLocationKey);

      if (cachedLocationString != null) {
        print('DEBUG: Found cached location string: $cachedLocationString');
        final locationJson = jsonDecode(cachedLocationString);
        final location = SelectedLocation.fromMap(locationJson);
        print('DEBUG: Successfully parsed cached location: ${location.name}');
        return location;
      } else {
        print('DEBUG: No cached location found in SharedPreferences');
      }

      // Try to get from Supabase user metadata
      final user = _client.auth.currentUser;
      if (user != null) {
        print('DEBUG: Checking Supabase user metadata...');
        final metadata = user.userMetadata;
        final selectedLocationData = metadata?['selected_location'];

        if (selectedLocationData != null) {
          print(
              'DEBUG: Found location in Supabase metadata: $selectedLocationData');
          final location = SelectedLocation.fromMap(selectedLocationData);
          // Cache locally for offline use
          await saveSelectedLocation(location);
          print(
              'DEBUG: Successfully retrieved and cached location from Supabase: ${location.name}');
          return location;
        } else {
          print('DEBUG: No location found in Supabase user metadata');
        }
      } else {
        print('DEBUG: No authenticated user found for Supabase metadata check');
      }

      print('DEBUG: No cached location found');
      return null;
    } catch (e) {
      print('DEBUG: Error getting selected location: $e');
      return null;
    }
  }

  // Get available locations for selector
  static Future<List<SelectedLocation>> getAvailableLocations() async {
    final List<SelectedLocation> locations = [];
    final Set<String> addedLocationIds = {}; // Track to avoid duplicates

    try {
      // 1. Get user profile default location first (highest priority)
      final userProfile = await UserProfileService.getCurrentUserProfile();
      if (userProfile?.defaultLocation != null &&
          userProfile!.defaultLocation!.isNotEmpty) {
        // Try to find this location in favorites to get coordinates
        final favoriteLocations =
            await FavoriteLocationService.getFavoriteLocations();
        final matchingFavorite = favoriteLocations
            .where((fav) =>
                fav.name == userProfile.defaultLocation ||
                fav.id == userProfile.defaultLocation)
            .firstOrNull;

        if (matchingFavorite != null) {
          final profileDefaultLocation = SelectedLocation(
            id: matchingFavorite.id,
            name: matchingFavorite.name,
            latitude: matchingFavorite.latitude,
            longitude: matchingFavorite.longitude,
            type: 'profile_default',
            tags: matchingFavorite.tagObjects,
          );
          locations.add(profileDefaultLocation);
          addedLocationIds.add(matchingFavorite.id);
        } else {
          // If profile default location is not in favorites, we need to handle it differently
          // Let's try to geocode the location name to get coordinates
          try {
            print(
                'DEBUG: Profile default "${userProfile.defaultLocation}" not found in favorites, attempting to geocode...');

            // For now, create a selectable entry but note that coordinates need to be resolved
            // The user can still select this, and we'll handle coordinate resolution in the weather service
            final profileDefaultLocation = SelectedLocation(
              id: 'profile_default_needs_coords',
              name: userProfile.defaultLocation!,
              latitude: 0.0, // Will be resolved when needed for weather
              longitude: 0.0, // Will be resolved when needed for weather
              type: 'profile_default',
            );
            locations.add(profileDefaultLocation);
            addedLocationIds.add('profile_default_needs_coords');
            print(
                'DEBUG: Created profile default entry that needs coordinate resolution');
          } catch (e) {
            print('DEBUG: Error handling profile default location: $e');
          }
        }
      }

      // 2. Get favorite location marked as default (if different from profile default)
      final defaultFavoriteLocation =
          await FavoriteLocationService.getDefaultLocation();
      if (defaultFavoriteLocation != null) {
        // Check if this is different from profile default we already added
        if (!addedLocationIds.contains(defaultFavoriteLocation.id)) {
          locations.add(SelectedLocation(
            id: defaultFavoriteLocation.id,
            name: defaultFavoriteLocation.name,
            latitude: defaultFavoriteLocation.latitude,
            longitude: defaultFavoriteLocation.longitude,
            type: 'favorite',
            tags: defaultFavoriteLocation.tagObjects,
          ));
          addedLocationIds.add(defaultFavoriteLocation.id);
        }
      }

      // 3. Get current location
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Check if current location exists as favorite
        final currentLocationFavorite =
            await FavoriteLocationService.getCurrentLocationFavorite();

        final currentLocation = SelectedLocation(
          id: 'current_location',
          name: currentLocationFavorite?.name ?? 'Current Location',
          latitude: position.latitude,
          longitude: position.longitude,
          type: 'current',
          tags: currentLocationFavorite?.tagObjects ?? [],
        );
        locations.add(currentLocation);
        addedLocationIds.add('current_location');
      } catch (e) {
        print('Could not get current location: $e');
      }

      // 4. Get other favorite locations (excluding ones already added)
      final favoriteLocations =
          await FavoriteLocationService.getFavoriteLocations();
      for (final favorite in favoriteLocations) {
        // Skip if already added
        if (!addedLocationIds.contains(favorite.id)) {
          locations.add(SelectedLocation(
            id: favorite.id,
            name: favorite.name,
            latitude: favorite.latitude,
            longitude: favorite.longitude,
            type: 'favorite',
            tags: favorite.tagObjects,
          ));
          addedLocationIds.add(favorite.id);
        }
      }

      return locations;
    } catch (e) {
      print('Error getting available locations: $e');
      return [];
    }
  }

  // Clear cached location
  static Future<bool> clearSelectedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_selectedLocationKey);

      // Also clear from Supabase user metadata
      final user = _client.auth.currentUser;
      if (user != null) {
        await _client.auth.updateUser(
          UserAttributes(data: {'selected_location': null}),
        );
      }

      return true;
    } catch (e) {
      print('Error clearing selected location: $e');
      return false;
    }
  }

  // Get or set default selected location if none exists
  static Future<SelectedLocation?> getOrSetDefaultLocation() async {
    try {
      // Try to get cached location first
      final cached = await getSelectedLocation();
      if (cached != null) return cached;

      // If no cached location, try to set a default
      final available = await getAvailableLocations();

      // Priority: profile default > current location > first favorite
      for (final location in available) {
        if (location.type == 'profile_default') {
          await saveSelectedLocation(location);
          return location;
        }
      }

      for (final location in available) {
        if (location.type == 'current') {
          await saveSelectedLocation(location);
          return location;
        }
      }

      if (available.isNotEmpty) {
        await saveSelectedLocation(available.first);
        return available.first;
      }

      return null;
    } catch (e) {
      print('Error getting or setting default location: $e');
      return null;
    }
  }
}
