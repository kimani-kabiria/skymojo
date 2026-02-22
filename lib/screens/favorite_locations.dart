import 'package:flutter/material.dart';
import 'package:skymojo/models/favorite_location.dart';
import 'package:skymojo/services/favorite_location_service.dart';
import 'package:skymojo/models/user_profile.dart';
import 'package:skymojo/services/user_profile_service.dart';
import 'package:skymojo/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FavoriteLocationsScreen extends StatefulWidget {
  const FavoriteLocationsScreen({super.key});

  @override
  State<FavoriteLocationsScreen> createState() =>
      _FavoriteLocationsScreenState();
}

class _FavoriteLocationsScreenState extends State<FavoriteLocationsScreen> {
  List<FavoriteLocation> _favoriteLocations = [];
  bool _isLoading = true;
  bool _isLocationPickerVisible = false;
  FavoriteLocation? _defaultLocation;
  UserProfile? _userProfile;
  String _currentLocationName = 'Current Location';
  LatLng? _currentLocationCoords;

  // Location picker variables
  LatLng? _selectedLocation;
  LatLng? _initialPosition;
  MapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  List<String> _searchSuggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load favorite locations and profile data
      final locations = await FavoriteLocationService.getFavoriteLocations();
      final defaultLoc = await FavoriteLocationService.getDefaultLocation();
      final profile = await UserProfileService.getCurrentUserProfile();

      // Also fetch current location
      await _getCurrentLocationForDisplay();

      setState(() {
        _favoriteLocations = locations;
        _defaultLocation = defaultLoc;
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocationForDisplay() async {
    try {
      print('DEBUG: Getting current location for display...');

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('DEBUG: Location services disabled for display');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('DEBUG: Location permissions denied for display');
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      print(
          'DEBUG: Got current position for display: ${position.latitude}, ${position.longitude}');

      // Get address from coordinates
      final addresses = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (addresses.isNotEmpty) {
        final address = addresses.first;
        String locationName = '';

        // Build a proper location name
        if (address.name != null &&
            address.name!.isNotEmpty &&
            address.name != 'Unnamed Road') {
          locationName = address.name!;
        } else if (address.street != null && address.street!.isNotEmpty) {
          locationName = address.street!;
        }

        // Add more context if available
        if (address.subLocality != null && address.subLocality!.isNotEmpty) {
          if (locationName.isNotEmpty) locationName += ', ';
          locationName += address.subLocality!;
        }
        if (address.locality != null && address.locality!.isNotEmpty) {
          if (locationName.isNotEmpty) locationName += ', ';
          locationName += address.locality!;
        }
        if (address.administrativeArea != null &&
            address.administrativeArea!.isNotEmpty) {
          if (locationName.isNotEmpty) locationName += ', ';
          locationName += address.administrativeArea!;
        }
        if (address.country != null && address.country!.isNotEmpty) {
          if (locationName.isNotEmpty) locationName += ', ';
          locationName += address.country!;
        }

        final finalName =
            locationName.isNotEmpty ? locationName : 'Current Location';
        print('DEBUG: Current location name for display: $finalName');

        // Update the current location display
        setState(() {
          _currentLocationName = finalName;
          _currentLocationCoords =
              LatLng(position.latitude, position.longitude);
        });
      } else {
        setState(() {
          _currentLocationName = 'Current Location';
          _currentLocationCoords =
              LatLng(position.latitude, position.longitude);
        });
        print('DEBUG: No address found for current location display');
      }
    } catch (e) {
      print('DEBUG: Error getting current location for display: $e');
      setState(() {
        _currentLocationName = 'Current Location';
        _currentLocationCoords = null;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    print('DEBUG: _getCurrentLocation called');
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('DEBUG: Location service enabled: $serviceEnabled');
      if (!serviceEnabled) {
        NotificationService.showWarningToast('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      print('DEBUG: Current permission: $permission');
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('DEBUG: Permission after request: $permission');
        if (permission == LocationPermission.denied) {
          NotificationService.showWarningToast(
              'Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        NotificationService.showErrorToast(
            'Location permissions are permanently denied');
        return;
      }

      print('DEBUG: Getting current position...');
      final position = await Geolocator.getCurrentPosition();
      print('DEBUG: Got position: ${position.latitude}, ${position.longitude}');

      final newLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedLocation = newLocation;
        _initialPosition = newLocation;
      });

      // Move map to new location
      if (_mapController != null) {
        _mapController!.move(newLocation, 14);
      }

      // Get address from coordinates and set as name
      print('DEBUG: Getting address from coordinates...');
      final addresses = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      print('DEBUG: Got ${addresses.length} addresses');

      if (addresses.isNotEmpty) {
        final address = addresses.first;
        print('DEBUG: First address: ${address.toString()}');

        String locationName = '';

        // Build a proper location name
        if (address.name != null &&
            address.name!.isNotEmpty &&
            address.name != 'Unnamed Road') {
          locationName = address.name!;
          print('DEBUG: Using address.name: $locationName');
        } else if (address.street != null && address.street!.isNotEmpty) {
          locationName = address.street!;
          print('DEBUG: Using address.street: $locationName');
        }

        // Add more context if available
        if (address.subLocality != null && address.subLocality!.isNotEmpty) {
          if (locationName.isNotEmpty) locationName += ', ';
          locationName += address.subLocality!;
        }
        if (address.locality != null && address.locality!.isNotEmpty) {
          if (locationName.isNotEmpty) locationName += ', ';
          locationName += address.locality!;
        }
        if (address.administrativeArea != null &&
            address.administrativeArea!.isNotEmpty) {
          if (locationName.isNotEmpty) locationName += ', ';
          locationName += address.administrativeArea!;
        }
        if (address.country != null && address.country!.isNotEmpty) {
          if (locationName.isNotEmpty) locationName += ', ';
          locationName += address.country!;
        }

        final finalName =
            locationName.isNotEmpty ? locationName : 'Current Location';
        setState(() {
          _nameController.text = finalName;
        });
        print('DEBUG: Set location name to: $finalName');
      } else {
        setState(() {
          _nameController.text = 'Current Location';
        });
        print('DEBUG: No address found, using default name');
      }
    } catch (e) {
      print('DEBUG: Error getting location: $e');
      NotificationService.showErrorToast(
          'Error getting location: ${e.toString()}');
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;

    print('DEBUG: Starting search for: $query');

    try {
      // Use Geoapify API for geocoding
      final url =
          'https://api.geoapify.com/v1/geocode/search?text=${Uri.encodeComponent(query)}&apiKey=7ae5dc566f9f4047bd609208fae21ddb&limit=1';

      print('DEBUG: Making API request to: $url');
      final response = await http.get(Uri.parse(url));

      print('DEBUG: API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG: API response type: ${data['type']}');

        // Handle both response formats
        if (data['type'] == 'FeatureCollection' &&
            data['features'] != null &&
            data['features'].isNotEmpty) {
          final feature = data['features'][0];
          final properties = feature['properties'];
          final geometry = feature['geometry'];

          print('DEBUG: Processing FeatureCollection format');
          print('DEBUG: Properties: ${properties.toString()}');

          if (geometry != null && geometry['coordinates'] != null) {
            final coordinates = geometry['coordinates'];
            final newLocation = LatLng(coordinates[1], coordinates[0]);

            print(
                'DEBUG: Found location: ${coordinates[1]}, ${coordinates[0]}');

            // Build location name from API components
            String locationName = '';

            // Use the name field if available, otherwise build from components
            if (properties['name'] != null && properties['name']!.isNotEmpty) {
              locationName = properties['name'];
              print('DEBUG: Using API name field: $locationName');
            } else {
              // Build from address components
              if (properties['housenumber'] != null &&
                  properties['housenumber']!.isNotEmpty) {
                locationName = properties['housenumber'];
              }
              if (properties['street'] != null &&
                  properties['street']!.isNotEmpty) {
                if (locationName.isNotEmpty) locationName += ' ';
                locationName += properties['street'];
              }
              if (properties['suburb'] != null &&
                  properties['suburb']!.isNotEmpty) {
                if (locationName.isNotEmpty) locationName += ', ';
                locationName += properties['suburb'];
              }
              if (properties['district'] != null &&
                  properties['district']!.isNotEmpty) {
                if (locationName.isNotEmpty) locationName += ', ';
                locationName += properties['district'];
              }
              if (properties['city'] != null &&
                  properties['city']!.isNotEmpty) {
                if (locationName.isNotEmpty) locationName += ', ';
                locationName += properties['city'];
              }
              if (properties['county'] != null &&
                  properties['county']!.isNotEmpty) {
                if (locationName.isNotEmpty) locationName += ', ';
                locationName += properties['county'];
              }
              if (properties['state'] != null &&
                  properties['state']!.isNotEmpty) {
                if (locationName.isNotEmpty) locationName += ', ';
                locationName += properties['state'];
              }
              if (properties['country'] != null &&
                  properties['country']!.isNotEmpty) {
                if (locationName.isNotEmpty) locationName += ', ';
                locationName += properties['country'];
              }
              print(
                  'DEBUG: Built location name from components: $locationName');
            }

            // Fallback to formatted if we couldn't build a good name
            if (locationName.isEmpty && properties['formatted'] != null) {
              locationName = properties['formatted'];
              print('DEBUG: Using formatted field as fallback: $locationName');
            }

            // Final fallback
            if (locationName.isEmpty) {
              locationName = query;
              print('DEBUG: Using query as final fallback: $locationName');
            }

            setState(() {
              _selectedLocation = newLocation;
              _initialPosition = newLocation;
              _showSuggestions = false;
              _nameController.text = locationName;
            });

            if (_mapController != null) {
              _mapController!.move(newLocation, 14);
            }

            print(
                'DEBUG: Search completed successfully - Set location name to: $locationName');
          } else {
            print('DEBUG: No coordinates found in feature geometry');
          }
        } else if (data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final newLocation = LatLng(result['lat'], result['lon']);

          print('DEBUG: Processing results format');
          print('DEBUG: Found location: ${result['lat']}, ${result['lon']}');

          // Build location name from API components
          String locationName = '';

          // Use the name field if available, otherwise build from components
          if (result['name'] != null && result['name']!.isNotEmpty) {
            locationName = result['name'];
            print('DEBUG: Using API name field: $locationName');
          } else {
            // Build from address components (same logic as above)
            if (result['housenumber'] != null &&
                result['housenumber']!.isNotEmpty) {
              locationName = result['housenumber'];
            }
            if (result['street'] != null && result['street']!.isNotEmpty) {
              if (locationName.isNotEmpty) locationName += ' ';
              locationName += result['street'];
            }
            if (result['suburb'] != null && result['suburb']!.isNotEmpty) {
              if (locationName.isNotEmpty) locationName += ', ';
              locationName += result['suburb'];
            }
            if (result['district'] != null && result['district']!.isNotEmpty) {
              if (locationName.isNotEmpty) locationName += ', ';
              locationName += result['district'];
            }
            if (result['city'] != null && result['city']!.isNotEmpty) {
              if (locationName.isNotEmpty) locationName += ', ';
              locationName += result['city'];
            }
            if (result['county'] != null && result['county']!.isNotEmpty) {
              if (locationName.isNotEmpty) locationName += ', ';
              locationName += result['county'];
            }
            if (result['state'] != null && result['state']!.isNotEmpty) {
              if (locationName.isNotEmpty) locationName += ', ';
              locationName += result['state'];
            }
            if (result['country'] != null && result['country']!.isNotEmpty) {
              if (locationName.isNotEmpty) locationName += ', ';
              locationName += result['country'];
            }
            print('DEBUG: Built location name from components: $locationName');
          }

          // Fallback to formatted if we couldn't build a good name
          if (locationName.isEmpty && result['formatted'] != null) {
            locationName = result['formatted'];
            print('DEBUG: Using formatted field as fallback: $locationName');
          }

          // Final fallback
          if (locationName.isEmpty) {
            locationName = query;
            print('DEBUG: Using query as final fallback: $locationName');
          }

          setState(() {
            _selectedLocation = newLocation;
            _initialPosition = newLocation;
            _showSuggestions = false;
            _nameController.text = locationName;
          });

          if (_mapController != null) {
            _mapController!.move(newLocation, 14);
          }

          print(
              'DEBUG: Search completed successfully - Set location name to: $locationName');
        } else {
          print('DEBUG: No results found in API response');
          NotificationService.showWarningToast('Location not found');
        }
      } else {
        print('DEBUG: API request failed with status: ${response.statusCode}');
        throw Exception(
            'API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error searching location: $e');
      NotificationService.showErrorToast(
          'Error searching location: ${e.toString()}');
    }
  }

  Future<void> _getLocationSuggestions(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _showSuggestions = false;
        _searchSuggestions.clear();
      });
      return;
    }

    try {
      final url =
          'https://api.geoapify.com/v1/geocode/search?text=${Uri.encodeComponent(query)}&apiKey=7ae5dc566f9f4047bd609208fae21ddb&limit=5&type=city&format=json';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final suggestions = <String>[];

        if (data['results'] != null && data['results'].isNotEmpty) {
          for (var result in data['results']) {
            // Build suggestion from API components
            String display = '';

            // Use name if available, otherwise build from components
            if (result['name'] != null && result['name']!.isNotEmpty) {
              display = result['name'];
            } else {
              // Build from city, state, country
              if (result['city'] != null && result['city']!.isNotEmpty) {
                display = result['city'];
              }
              if (result['state'] != null &&
                  result['state']!.isNotEmpty &&
                  result['state'] != result['city']) {
                if (display.isNotEmpty) display += ', ';
                display += result['state'];
              }
              if (result['country'] != null &&
                  result['country']!.isNotEmpty &&
                  result['country'] != result['state']) {
                if (display.isNotEmpty) display += ', ';
                display += result['country'];
              }
            }

            // Fallback to formatted if we couldn't build a good display
            if (display.isEmpty && result['formatted'] != null) {
              display = result['formatted'];
            }

            if (display.isNotEmpty) {
              suggestions.add(display);
            }
          }
        }

        setState(() {
          _searchSuggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty;
        });

        print('DEBUG: Found ${suggestions.length} suggestions: $suggestions');
      }
    } catch (e) {
      print('DEBUG: Error getting suggestions: $e');
      // Fallback to empty suggestions if API fails
      setState(() {
        _showSuggestions = false;
        _searchSuggestions.clear();
      });
    }
  }

  void _showLocationPicker() {
    _mapController = MapController();

    if (_initialPosition == null) {
      _initialPosition = const LatLng(40.7128, -74.0060);
    }
    setState(() => _isLocationPickerVisible = true);
  }

  void _hideLocationPicker() {
    setState(() => _isLocationPickerVisible = false);
    _nameController.clear();
    _searchController.clear();
    _selectedLocation = null;
  }

  void _onLocationSelected(TapPosition tapPosition, LatLng location) async {
    setState(() {
      _selectedLocation = location;
    });

    // Get address from coordinates
    try {
      final addresses = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (addresses.isNotEmpty) {
        final address = addresses.first;
        String locationName = '';

        // Build a proper location name
        if (address.name != null &&
            address.name!.isNotEmpty &&
            address.name != 'Unnamed Road') {
          locationName = address.name!;
        } else if (address.street != null && address.street!.isNotEmpty) {
          locationName = address.street!;
        }

        // Add more context if available
        if (address.subLocality != null && address.subLocality!.isNotEmpty) {
          if (locationName.isNotEmpty) locationName += ', ';
          locationName += address.subLocality!;
        }
        if (address.locality != null && address.locality!.isNotEmpty) {
          if (locationName.isNotEmpty) locationName += ', ';
          locationName += address.locality!;
        }
        if (address.administrativeArea != null &&
            address.administrativeArea!.isNotEmpty) {
          if (locationName.isNotEmpty) locationName += ', ';
          locationName += address.administrativeArea!;
        }
        if (address.country != null && address.country!.isNotEmpty) {
          if (locationName.isNotEmpty) locationName += ', ';
          locationName += address.country!;
        }

        final finalName =
            locationName.isNotEmpty ? locationName : 'Selected Location';
        setState(() {
          _nameController.text = finalName;
        });
        print('DEBUG: Map tap - Set location name to: $finalName');
      } else {
        setState(() {
          _nameController.text = 'Selected Location';
        });
        print('DEBUG: Map tap - No address found, using default name');
      }
    } catch (e) {
      print('DEBUG: Error getting address from coordinates: $e');
      setState(() {
        _nameController.text = 'Selected Location';
      });
    }
  }

  Future<void> _addFavoriteLocation() async {
    if (_selectedLocation == null) {
      NotificationService.showWarningToast('Please select a location');
      return;
    }

    try {
      final locationName = _nameController.text.isNotEmpty
          ? _nameController.text
          : 'Selected Location';

      print('DEBUG: Adding favorite location with name: $locationName');
      print(
          'DEBUG: Coordinates: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}');

      await FavoriteLocationService.addFavoriteLocation(
        name: locationName,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
      );

      _hideLocationPicker();
      _loadData();

      NotificationService.showSuccessToast('Location added to favorites');
    } catch (e) {
      print('DEBUG: Error adding location: $e');
      NotificationService.showErrorToast(
          'Error adding location: ${e.toString()}');
    }
  }

  Future<void> _deleteLocation(FavoriteLocation location) async {
    try {
      await FavoriteLocationService.deleteFavoriteLocation(location.id);
      _loadData();

      NotificationService.showSuccessToast('Location removed from favorites');
    } catch (e) {
      NotificationService.showErrorToast(
          'Error removing location: ${e.toString()}');
    }
  }

  Future<void> _setDefaultLocation(FavoriteLocation location) async {
    try {
      await FavoriteLocationService.setDefaultLocation(location.id);
      _loadData();

      NotificationService.showSuccessToast('${location.name} set as default');
    } catch (e) {
      NotificationService.showErrorToast(
          'Error setting default: ${e.toString()}');
    }
  }

  Future<void> _setAsProfileDefault(FavoriteLocation location) async {
    try {
      await UserProfileService.updateProfile(
        userId: Supabase.instance.client.auth.currentUser!.id,
        defaultLocation: location.name,
      );

      _loadData();

      NotificationService.showSuccessToast(
          '${location.name} set as profile default');
    } catch (e) {
      NotificationService.showErrorToast(
          'Error setting profile default: ${e.toString()}');
    }
  }

  Widget _buildLocationCard(FavoriteLocation location) {
    final isDefault = location.isDefault;
    final isCurrentLocation = location.name == 'Current Location';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isDefault ? Icons.star : Icons.location_on,
                  color: isDefault ? Colors.orange : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isDefault)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'DEFAULT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isDefault && !isCurrentLocation)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: TextButton.icon(
                        onPressed: () => _setDefaultLocation(location),
                        icon: const Icon(Icons.star, size: 16),
                        label: const Text('Default',
                            style: TextStyle(fontSize: 14)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                        ),
                      ),
                    ),
                  ),
                if (!isCurrentLocation)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: TextButton.icon(
                        onPressed: () => _setAsProfileDefault(location),
                        icon: const Icon(Icons.home, size: 16),
                        label: const Text('Profile',
                            style: TextStyle(fontSize: 14)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                        ),
                      ),
                    ),
                  ),
                if (!isCurrentLocation)
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _deleteLocation(location),
                      icon:
                          const Icon(Icons.delete, size: 16, color: Colors.red),
                      label: const Text('Delete',
                          style: TextStyle(color: Colors.red, fontSize: 14)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocationPickerVisible) {
      return Material(
        color: Colors.black54,
        child: Stack(
          children: [
            ModalBarrier(
              dismissible: false,
              color: Colors.transparent,
            ),
            Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Favorite Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF083235),
                          ),
                        ),
                        IconButton(
                          onPressed: _hideLocationPicker,
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Display selected location name
                    if (_nameController.text.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected Location:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _nameController.text,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF083235),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search for a location...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: () =>
                                  _searchLocation(_searchController.text),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            print('DEBUG: Search field changed to: $value');
                            _getLocationSuggestions(value);
                          },
                          onSubmitted: (value) {
                            print('DEBUG: Search submitted: $value');
                            setState(() {
                              _showSuggestions = false;
                            });
                            _searchLocation(value);
                          },
                        ),
                        if (_showSuggestions && _searchSuggestions.isNotEmpty)
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _searchSuggestions.length,
                              itemBuilder: (context, index) {
                                final suggestion = _searchSuggestions[index];
                                return ListTile(
                                  dense: true,
                                  leading:
                                      const Icon(Icons.location_on, size: 16),
                                  title: Text(suggestion),
                                  onTap: () {
                                    print(
                                        'DEBUG: Suggestion tapped: $suggestion');
                                    setState(() {
                                      _searchController.text = suggestion;
                                      _showSuggestions = false;
                                    });
                                    // Use a small delay to let the UI update before searching
                                    Future.delayed(
                                        const Duration(milliseconds: 100), () {
                                      _searchLocation(suggestion);
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _selectedLocation ??
                              const LatLng(40.7128, -74.0060),
                          initialZoom: 14,
                          onTap: _onLocationSelected,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'org.openstreetmap.api',
                            maxZoom: 19,
                          ),
                          if (_selectedLocation != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _selectedLocation!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _getCurrentLocation,
                            icon: const Icon(Icons.my_location),
                            label: const Text('Use Current Location'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF083235),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _selectedLocation != null
                                ? _addFavoriteLocation
                                : null,
                            icon: const Icon(Icons.add),
                            label: const Text('Add to Favorites'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              foregroundColor: const Color(0xFF083235),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF083235),
      appBar: AppBar(
        backgroundColor: const Color(0xFF083235),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Favorite Locations',
          style: TextStyle(color: Colors.white, fontFamily: 'Bellota'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showLocationPicker,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Default Location Section
                    if (_defaultLocation != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.orange),
                                const SizedBox(width: 8),
                                const Text(
                                  'Default Location',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _defaultLocation!.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _defaultLocation!.name,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Profile Default Location (if exists and different)
                    if (_userProfile?.defaultLocation != null &&
                        _userProfile!.defaultLocation!.isNotEmpty &&
                        (_defaultLocation == null ||
                            _defaultLocation!.name !=
                                _userProfile!.defaultLocation))
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.home, color: Colors.white70),
                                const SizedBox(width: 8),
                                const Text(
                                  'Profile Default',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _userProfile!.defaultLocation!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Current Location Section
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.my_location, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text(
                                'Current Location',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentLocationName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          if (_currentLocationCoords != null)
                            Text(
                              'GPS: ${_currentLocationCoords!.latitude.toStringAsFixed(4)}, ${_currentLocationCoords!.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Favorite Locations List
                    if (_favoriteLocations.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(
                              'Favorite Locations',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ..._favoriteLocations
                              .map((location) => _buildLocationCard(location)),
                        ],
                      )
                    else
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 64,
                              color: Colors.white54,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No favorite locations yet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Add your first favorite location to get started',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _showLocationPicker,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Location'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                foregroundColor: const Color(0xFF083235),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
