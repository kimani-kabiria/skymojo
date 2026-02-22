import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skymojo/models/user_profile.dart';
import 'package:skymojo/services/user_profile_service.dart';
import 'package:skymojo/services/google_auth_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isLocationPickerVisible = false;

  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedTemperatureUnit = 'celsius';
  String _selectedTheme = 'auto';
  
  // Location variables
  LatLng? _selectedLocation;
  LatLng? _initialPosition;
  MapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchSuggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _locationController.dispose();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final profile = await UserProfileService.getCurrentUserProfile();
      final avatarFromMetadata = await UserProfileService.getUserAvatarFromMetadata();
      final nameFromMetadata = await UserProfileService.getUserNameFromMetadata();
      
      setState(() {
        _profile = profile;
        if (profile != null) {
          _usernameController.text = profile.username ?? '';
          _fullNameController.text = profile.fullName ?? '';
          _locationController.text = profile.defaultLocation ?? '';
          _selectedTemperatureUnit = profile.temperatureUnit;
          _selectedTheme = profile.themePreference;
          
          // Parse existing location if available
          if (profile.defaultLocation != null && profile.defaultLocation!.isNotEmpty) {
            _parseLocationFromAddress(profile.defaultLocation!);
          }
        }
        
        // If no profile avatar, try to get from metadata
        if (_profile?.avatarUrl == null && avatarFromMetadata != null) {
          _profile = _profile?.copyWith(avatarUrl: avatarFromMetadata);
        }
        
        // If no profile name, try to get from metadata
        if (_profile?.fullName == null && nameFromMetadata != null) {
          _profile = _profile?.copyWith(fullName: nameFromMetadata);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _parseLocationFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        setState(() {
          _selectedLocation = LatLng(location.latitude, location.longitude);
          _initialPosition = _selectedLocation!;
        });
      }
    } catch (e) {
      print('Error parsing location from address: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    print('DEBUG: Getting current location...');
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('DEBUG: Location service enabled: $serviceEnabled');
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      print('DEBUG: Current permission: $permission');
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('DEBUG: Permission after request: $permission');
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied')),
        );
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

      // Get address from coordinates
      print('DEBUG: Getting address from coordinates...');
      final addresses = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (addresses.isNotEmpty) {
        final address = addresses.first;
        final locationText = '${address.locality}, ${address.administrativeArea}, ${address.country}';
        print('DEBUG: Got address: $locationText');
        _locationController.text = locationText;
      }
    } catch (e) {
      print('DEBUG: Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: ${e.toString()}')),
      );
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _showSuggestions = false;
        _searchSuggestions.clear();
      });
      return;
    }
    
    try {
      print('DEBUG: Searching for location: $query');
      // Use Geoapify API for geocoding
      final url = 'https://api.geoapify.com/v1/geocode/search?text=${Uri.encodeComponent(query)}&apiKey=7ae5dc566f9f4047bd609208fae21ddb&limit=1';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG: API response: $data');
        
        // Check for FeatureCollection format (search results)
        if (data['type'] == 'FeatureCollection' && data['features'] != null && data['features'].isNotEmpty) {
          final feature = data['features'][0];
          final properties = feature['properties'];
          final geometry = feature['geometry'];
          
          if (geometry != null && geometry['coordinates'] != null) {
            final coordinates = geometry['coordinates'];
            final newLocation = LatLng(coordinates[1], coordinates[0]); // lat, lon
            
            setState(() {
              _selectedLocation = newLocation;
              _initialPosition = newLocation;
              _showSuggestions = false;
            });

            // Move map to searched location
            if (_mapController != null) {
              _mapController!.move(newLocation, 14);
            }

            // Update address field with formatted address
            _locationController.text = properties['formatted'] ?? query;
            
            print('DEBUG: Found location: ${coordinates[1]}, ${coordinates[0]}');
            print('DEBUG: Formatted address: ${properties['formatted']}');
          } else {
            print('DEBUG: No coordinates found in feature geometry');
          }
        } 
        // Check for direct results format (suggestions format)
        else if (data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final newLocation = LatLng(result['lat'], result['lon']);
          
          setState(() {
            _selectedLocation = newLocation;
            _initialPosition = newLocation;
            _showSuggestions = false;
          });

          // Move map to searched location
          if (_mapController != null) {
            _mapController!.move(newLocation, 14);
          }

          // Update address field with formatted address
          _locationController.text = result['formatted'] ?? query;
          
          print('DEBUG: Found location: ${result['lat']}, ${result['lon']}');
          print('DEBUG: Formatted address: ${result['formatted']}');
        } else {
          print('DEBUG: No results found in API response');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location not found')),
          );
        }
      } else {
        print('DEBUG: API request failed with status: ${response.statusCode}');
        throw Exception('Failed to load location data');
      }
    } catch (e) {
      print('DEBUG: Error searching location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching location: ${e.toString()}')),
      );
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
      print('DEBUG: Getting suggestions for: $query');
      // Use Geoapify API for autocomplete suggestions
      final url = 'https://api.geoapify.com/v1/geocode/search?text=${Uri.encodeComponent(query)}&apiKey=7ae5dc566f9f4047bd609208fae21ddb&limit=5&type=city&format=json';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG: Suggestions API response: $data');
        
        final suggestions = <String>[];
        
        if (data['results'] != null && data['results'].isNotEmpty) {
          for (var result in data['results']) {
            // Create a display string with city, state, country
            String display = result['city'] ?? '';
            if (result['state'] != null && result['state'] != result['city']) {
              display += display.isNotEmpty ? ', ${result['state']}' : result['state'];
            }
            if (result['country'] != null && result['country'] != result['state']) {
              display += display.isNotEmpty ? ', ${result['country']}' : result['country'];
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
      } else {
        print('DEBUG: Suggestions API failed with status: ${response.statusCode}');
        throw Exception('Failed to load suggestions');
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
    print('DEBUG: _showLocationPicker called');
    // Initialize map controller
    _mapController = MapController();
    
    // If no initial position is set, use a default location (New York)
    if (_initialPosition == null) {
      _initialPosition = const LatLng(40.7128, -74.0060);
      print('DEBUG: Set initial position to default');
    }
    print('DEBUG: Setting _isLocationPickerVisible to true');
    setState(() => _isLocationPickerVisible = true);
  }

  void _hideLocationPicker() {
    setState(() => _isLocationPickerVisible = false);
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
        final locationText = '${address.locality}, ${address.administrativeArea}, ${address.country}';
        _locationController.text = locationText;
      }
    } catch (e) {
      print('Error getting address from coordinates: $e');
    }

    _hideLocationPicker();
  }

  void _showTopToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          top: 50,
          left: 16,
          right: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_profile == null) return;

    setState(() => _isSaving = true);

    try {
      final updatedProfile = await UserProfileService.updateProfile(
        userId: _profile!.id,
        username: _usernameController.text.trim().isEmpty 
            ? null 
            : _usernameController.text.trim(),
        fullName: _fullNameController.text.trim().isEmpty 
            ? null 
            : _fullNameController.text.trim(),
        defaultLocation: _locationController.text.trim().isEmpty 
            ? null 
            : _locationController.text.trim(),
        temperatureUnit: _selectedTemperatureUnit,
        themePreference: _selectedTheme,
      );

      setState(() {
        _profile = updatedProfile;
        _isEditing = false;
      });

      if (mounted) {
        _showTopToast('Profile updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showTopToast('Error saving profile: ${e.toString()}', isError: true);
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await GoogleAuthService.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool enabled,
    required IconData icon,
    String? hintText,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            TextField(
              controller: controller,
              enabled: enabled,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: Icon(icon, color: Colors.white70),
                suffixIcon: label == 'Default Location' && enabled
                    ? const Icon(Icons.map, color: Colors.white70)
                    : null,
                filled: true,
                fillColor: enabled 
                    ? Colors.white.withOpacity(0.2) 
                    : Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (onTap != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required bool enabled,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled 
                ? Colors.white.withOpacity(0.2) 
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: ButtonTheme(
              alignedDropdown: true,
              child: DropdownButton<String>(
                value: value,
                items: items.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(
                      item.toUpperCase(),
                      style: TextStyle(
                        color: enabled ? Colors.white : Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: enabled ? onChanged : null,
                style: const TextStyle(color: Colors.white),
                dropdownColor: const Color(0xFF083235),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: enabled ? Colors.white70 : Colors.white38,
                ),
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF083235),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Location Picker Modal
    if (_isLocationPickerVisible) {
      print('DEBUG: Building location picker modal');
      return Stack(
        children: [
          ModalBarrier(
            dismissible: false,
            color: Colors.black54,
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
                        'Select Location',
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
                  // Search Bar with Suggestions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        elevation: 2,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search for a location...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: () => _searchLocation(_searchController.text),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (value) => _getLocationSuggestions(value),
                          onSubmitted: (value) => _searchLocation(value),
                        ),
                      ),
                      // Suggestions Dropdown
                      if (_showSuggestions && _searchSuggestions.isNotEmpty)
                        Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
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
                                  leading: const Icon(Icons.location_on, size: 16),
                                  title: Text(suggestion),
                                  onTap: () {
                                    _searchController.text = suggestion;
                                    _searchLocation(suggestion);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedLocation ?? const LatLng(40.7128, -74.0060),
                        initialZoom: 14,
                        onTap: _onLocationSelected,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                  // Action Buttons - Stacked Vertically
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _selectedLocation != null
                              ? () {
                                  _onLocationSelected(const TapPosition(Offset.zero, Offset.zero), _selectedLocation!);
                                }
                              : null,
                          icon: const Icon(Icons.check),
                          label: const Text('Confirm Location'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            foregroundColor: const Color(0xFF083235),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF083235),
      appBar: AppBar(
        backgroundColor: const Color(0xFF083235),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_isEditing) {
              // If in edit mode, switch to view mode instead of going back
              setState(() => _isEditing = false);
            } else {
              // If in view mode, go back (close screen/drawer)
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontFamily: 'Bellota'),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.orangeAccent,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: _profile?.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              _profile!.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Color(0xFF083235),
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 50,
                            color: Color(0xFF083235),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _profile?.fullName ?? 'SkyMojo User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Bellota',
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Profile Form
            Card(
              color: Colors.white.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Username',
                      enabled: _isEditing,
                      icon: Icons.alternate_email,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      enabled: _isEditing,
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _locationController,
                      label: 'Default Location',
                      enabled: _isEditing,
                      icon: Icons.location_on,
                      hintText: 'e.g., New York, NY',
                      onTap: () {
                        print('DEBUG: Location field tapped, _isEditing: $_isEditing');
                        if (_isEditing) {
                          _showLocationPicker();
                        } else {
                          print('DEBUG: Not in edit mode, cannot open map');
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      label: 'Theme Preference',
                      value: _selectedTheme,
                      items: const ['light', 'dark', 'auto'],
                      enabled: _isEditing,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedTheme = value);
                        }
                      },
                      icon: Icons.palette,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
