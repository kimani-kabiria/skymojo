import 'package:flutter/material.dart';
import 'package:skymojo/models/favorite_location.dart';
import 'package:skymojo/services/favorite_location_service.dart';
import 'package:skymojo/models/user_profile.dart';
import 'package:skymojo/services/user_profile_service.dart';
import 'package:skymojo/services/notification_service.dart';
import 'package:skymojo/components/tag_selector.dart';
import 'package:skymojo/models/location_tag.dart';
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
  State<FavoriteLocationsScreen> createState() => _FavoriteLocationsScreenState();
}

class _FavoriteLocationsScreenState extends State<FavoriteLocationsScreen> {
  List<FavoriteLocation> _favoriteLocations = [];
  bool _isLoading = true;
  bool _isLocationPickerVisible = false;
  bool _isAdding = false;
  bool _isEditModalVisible = false;
  FavoriteLocation? _defaultLocation;
  UserProfile? _userProfile;
  String _currentLocationName = 'Current Location';
  LatLng? _currentLocationCoords;

  // Picker state
  LatLng? _selectedLocation;
  MapController? _mapController;
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  List<String> _searchSuggestions = [];
  bool _showSuggestions = false;
  List<String> _selectedTags = [];
  FavoriteLocation? _editingLocation;

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
      final locations = await FavoriteLocationService.getFavoriteLocations();
      final defaultLoc = await FavoriteLocationService.getDefaultLocation();
      final profile = await UserProfileService.getCurrentUserProfile();
      await _refreshCurrentLocationDisplay();

      setState(() {
        _favoriteLocations = locations;
        _defaultLocation = defaultLoc;
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      NotificationService.showErrorToast('Failed to load locations');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshCurrentLocationDisplay() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return;
      }
      if (perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final places = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      String name = 'Current Location';
      if (places.isNotEmpty) {
        name = _buildLocationName(places.first);
      }

      setState(() {
        _currentLocationName = name;
        _currentLocationCoords = LatLng(pos.latitude, pos.longitude);
      });
    } catch (e) {
      print('Current location display error: $e');
    }
  }

  String _buildLocationName(Placemark place) {
    final parts = <String>[];

    if (place.name?.isNotEmpty == true && place.name != 'Unnamed Road') {
      parts.add(place.name!);
    } else if (place.street?.isNotEmpty == true) {
      parts.add(place.street!);
    }

    if (place.subLocality?.isNotEmpty == true) parts.add(place.subLocality!);
    if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
    if (place.administrativeArea?.isNotEmpty == true) parts.add(place.administrativeArea!);
    if (place.country?.isNotEmpty == true) parts.add(place.country!);

    return parts.isNotEmpty ? parts.join(', ') : 'Current Location';
  }

  Future<void> _getCurrentForPicker() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        NotificationService.showWarningToast('Location services disabled');
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          NotificationService.showWarningToast('Permission denied');
          return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        NotificationService.showErrorToast('Permission permanently denied');
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      final point = LatLng(pos.latitude, pos.longitude);

      setState(() {
        _selectedLocation = point;
      });
      _mapController?.move(point, 15);

      final places = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      setState(() {
        _nameController.text = places.isNotEmpty ? _buildLocationName(places.first) : 'Current Location';
      });
    } catch (e) {
      NotificationService.showErrorToast('Could not get current location');
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;

    try {
      // ← Replace with your real key or move to constants/env
      const apiKey = '7ae5dc566f9f4047bd609208fae21ddb';
      final uri = Uri.parse(
        'https://api.geoapify.com/v1/geocode/search?text=${Uri.encodeComponent(query)}&apiKey=$apiKey&limit=1',
      );

      final res = await http.get(uri);
      if (res.statusCode != 200) throw Exception('Geocode failed');

      final data = jsonDecode(res.body);

      if (data['features']?.isNotEmpty == true) {
        final f = data['features'][0];
        final coords = f['geometry']['coordinates'];
        final props = f['properties'];

        final latLng = LatLng(coords[1], coords[0]);
        String name = props['formatted'] ?? query;
        if (props['name']?.isNotEmpty == true) name = props['name'];

        setState(() {
          _selectedLocation = latLng;
          _nameController.text = name;
          _showSuggestions = false;
        });

        _mapController?.move(latLng, 15);
      } else {
        NotificationService.showWarningToast('Location not found');
      }
    } catch (e) {
      print('Search failed: $e');
      NotificationService.showErrorToast('Search failed');
    }
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _searchSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    try {
      const apiKey = '7ae5dc566f9f4047bd609208fae21ddb';
      final uri = Uri.parse(
        'https://api.geoapify.com/v1/geocode/search?text=${Uri.encodeComponent(query)}&apiKey=$apiKey&limit=5',
      );

      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final suggestions = <String>[];

        if (data['features'] != null) {
          for (final f in data['features']) {
            final p = f['properties'];
            suggestions.add(p['formatted'] ?? p['name'] ?? query);
          }
        }

        setState(() {
          _searchSuggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty;
        });
      }
    } catch (_) {
      setState(() {
        _searchSuggestions = [];
        _showSuggestions = false;
      });
    }
  }

  void _openPicker() {
    _mapController = MapController();
    setState(() {
      _isLocationPickerVisible = true;
      _selectedLocation = null;
      _nameController.clear();
      _selectedTags = [];
      _searchController.clear();
      _showSuggestions = false;
    });
  }

  void _closePicker() {
    setState(() => _isLocationPickerVisible = false);
  }

  void _openEdit(FavoriteLocation loc) {
    setState(() {
      _editingLocation = loc;
      _nameController.text = loc.name;
      _selectedTags = List.from(loc.tags);
      _isEditModalVisible = true;
    });
  }

  void _closeEdit() {
    setState(() {
      _isEditModalVisible = false;
      _editingLocation = null;
      _nameController.clear();
      _selectedTags = [];
    });
  }

  Future<void> _saveNewLocation() async {
    if (_selectedLocation == null) {
      NotificationService.showWarningToast('No location selected');
      return;
    }
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      NotificationService.showWarningToast('Name is required');
      return;
    }

    setState(() => _isAdding = true);

    try {
      await FavoriteLocationService.addFavoriteLocation(
        name: name,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        tags: _selectedTags,
      );
      _closePicker();
      await _loadData();
      NotificationService.showSuccessToast('Location added');
    } catch (e) {
      NotificationService.showErrorToast('Failed to save location');
    } finally {
      setState(() => _isAdding = false);
    }
  }

  Future<void> _saveEdit() async {
    if (_editingLocation == null || _nameController.text.trim().isEmpty) return;

    try {
      await FavoriteLocationService.updateFavoriteLocation(
        id: _editingLocation!.id,
        name: _nameController.text.trim(),
        tags: _selectedTags,
      );
      _closeEdit();
      await _loadData();
      NotificationService.showSuccessToast('Updated');
    } catch (e) {
      NotificationService.showErrorToast('Update failed');
    }
  }

  Future<void> _delete(FavoriteLocation loc) async {
    try {
      await FavoriteLocationService.deleteFavoriteLocation(loc.id);
      await _loadData();
      NotificationService.showSuccessToast('Removed');
    } catch (e) {
      NotificationService.showErrorToast('Delete failed');
    }
  }

  Future<void> _makeDefault(FavoriteLocation loc) async {
    try {
      await FavoriteLocationService.setDefaultLocation(loc.id);
      await _loadData();
      NotificationService.showSuccessToast('Now default');
    } catch (e) {
      NotificationService.showErrorToast('Failed to set default');
    }
  }

  Future<void> _setAsProfileDefault(FavoriteLocation loc) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    try {
      await UserProfileService.updateProfile(userId: uid, defaultLocation: loc.name);
      await _loadData();
      NotificationService.showSuccessToast('Profile default updated');
    } catch (e) {
      NotificationService.showErrorToast('Profile update failed');
    }
  }

  Future<void> _onMapTap(TapPosition _, LatLng point) async {
    setState(() => _selectedLocation = point);

    try {
      final places = await placemarkFromCoordinates(point.latitude, point.longitude);
      setState(() {
        _nameController.text = places.isNotEmpty ? _buildLocationName(places.first) : 'Selected Location';
      });
    } catch (_) {
      setState(() => _nameController.text = 'Selected Location');
    }
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: _openPicker,
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildMainContent(),
          if (_isLocationPickerVisible) _buildPickerOverlay(),
          if (_isEditModalVisible) _buildEditDialog(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_defaultLocation != null) _buildDefaultCard(),
            if (_userProfile?.defaultLocation != null &&
                (_defaultLocation == null || _defaultLocation!.name != _userProfile!.defaultLocation))
              _buildProfileDefaultCard(),
            _buildCurrentCard(),
            _buildFavoritesList(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.star, color: Colors.orange),
              SizedBox(width: 8),
              Text('Default', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_defaultLocation!.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildProfileDefaultCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.home, color: Colors.white70),
              SizedBox(width: 8),
              Text('Profile Default', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_userProfile!.defaultLocation!, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildCurrentCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.my_location, color: Colors.blue),
              SizedBox(width: 8),
              Text('Current', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_currentLocationName, style: const TextStyle(color: Colors.white, fontSize: 16)),
          if (_currentLocationCoords != null)
            Text(
              'Lat: ${_currentLocationCoords!.latitude.toStringAsFixed(4)}  Lng: ${_currentLocationCoords!.longitude.toStringAsFixed(4)}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    if (_favoriteLocations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off_outlined, size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              const Text('No favorites yet', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('Add places you visit often', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Location'),
                onPressed: _openPicker,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.orangeAccent),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            'Favorites',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        ..._favoriteLocations.map(_buildLocationItem),
      ],
    );
  }

  Widget _buildLocationItem(FavoriteLocation loc) {
    final isDef = loc.isDefault;
    final isCurr = loc.name == 'Current Location';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.white.withOpacity(0.92),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isDef ? Icons.star : Icons.location_on, color: isDef ? Colors.orange : Colors.grey[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.name,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
                if (isDef)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(12)),
                    child: const Text('DEFAULT', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            if (loc.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: loc.tagObjects.map((t) => Chip(
                      backgroundColor: t.color.withOpacity(0.12),
                      side: BorderSide(color: t.color.withOpacity(0.4)),
                      avatar: Text(t.icon),
                      label: Text(t.name, style: TextStyle(color: t.color)),
                      visualDensity: VisualDensity.compact,
                    )).toList(),
              ),
            ],

            // ────────────────────────────────────────────────
            // FIXED: Overflowing button row
            // ────────────────────────────────────────────────
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true, // Makes "Delete" visible first when overflowing
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isCurr) ...[
                      TextButton.icon(
                        onPressed: () => _openEdit(loc),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit', style: TextStyle(fontSize: 13)),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (!isDef && !isCurr) ...[
                      TextButton.icon(
                        onPressed: () => _makeDefault(loc),
                        icon: const Icon(Icons.star_border, size: 16),
                        label: const Text('Default', style: TextStyle(fontSize: 13)),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (!isCurr) ...[
                      TextButton.icon(
                        onPressed: () => _setAsProfileDefault(loc),
                        icon: const Icon(Icons.home_outlined, size: 16),
                        label: const Text('Profile', style: TextStyle(fontSize: 13)),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (!isCurr)
                      TextButton.icon(
                        onPressed: () => _delete(loc),
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        label: const Text('Delete', style: TextStyle(color: Colors.red, fontSize: 13)),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOverlay() {
    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Text('Add Favorite', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: _closePicker),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search location...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: _fetchSuggestions,
                onSubmitted: (v) {
                  _search(v);
                  _searchController.clear();
                },
              ),
            ),
            if (_showSuggestions && _searchSuggestions.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchSuggestions.length,
                  itemBuilder: (c, i) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on, size: 20),
                    title: Text(_searchSuggestions[i]),
                    onTap: () {
                      _searchController.text = _searchSuggestions[i];
                      _showSuggestions = false;
                      Future.microtask(() => _search(_searchSuggestions[i]));
                    },
                  ),
                ),
              ),
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedLocation ?? const LatLng(1.2921, 36.8219),
                  initialZoom: 12,
                  onTap: _onMapTap,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  if (_selectedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation!,
                          width: 48,
                          height: 48,
                          child: const Icon(Icons.location_pin, color: Colors.red, size: 48),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_nameController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Selected: ${_nameController.text}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  TagSelector(
                    selectedTags: _selectedTags,
                    onTagsChanged: (tags) => setState(() => _selectedTags = tags),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.my_location),
                          label: const Text('Current'),
                          onPressed: _getCurrentForPicker,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: _isAdding
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
                              : const Icon(Icons.add),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                          onPressed: _isAdding || _selectedLocation == null ? null : _saveNewLocation,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                IconButton(icon: const Icon(Icons.close), onPressed: _closeEdit),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TagSelector(
              selectedTags: _selectedTags,
              onTagsChanged: (tags) => setState(() => _selectedTags = tags),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _closeEdit,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveEdit,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}