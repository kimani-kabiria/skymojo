import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';
import 'package:skymojo/services/location_cache_service.dart';
import 'package:skymojo/services/notification_service.dart';

class LocationSelector extends StatefulWidget {
  final Function(SelectedLocation)? onLocationChanged;
  final SelectedLocation? initialLocation;

  const LocationSelector({
    super.key,
    this.onLocationChanged,
    this.initialLocation,
  });

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  SelectedLocation? _selectedLocation;
  List<SelectedLocation> _availableLocations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    print('DEBUG: LocationSelector: Starting to load locations...');
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all available locations first (profile default is always first)
      print('DEBUG: LocationSelector: Getting available locations...');
      final availableLocations =
          await LocationCacheService.getAvailableLocations();
      print(
          'DEBUG: LocationSelector: Found ${availableLocations.length} available locations');

      // Get cached location
      print('DEBUG: LocationSelector: Getting cached location...');
      final cachedLocation = widget.initialLocation ??
          await LocationCacheService.getSelectedLocation();

      print(
          'DEBUG: LocationSelector: Cached location: ${cachedLocation?.name}');

      // Find matching location in available locations
      SelectedLocation? selectedLocation = cachedLocation;
      if (cachedLocation != null) {
        // Try to find exact match in available locations
        final matchingLocation = availableLocations
            .where((loc) =>
                loc.id == cachedLocation.id ||
                (loc.name == cachedLocation.name &&
                    loc.type == cachedLocation.type))
            .firstOrNull;

        if (matchingLocation != null) {
          selectedLocation = matchingLocation;
          print(
              'DEBUG: LocationSelector: Found matching location in available list: ${matchingLocation.name}');
        } else {
          print(
              'DEBUG: LocationSelector: No exact match found, using cached location');
        }
      }

      // If no cached location exists, set one based on priority
      if (selectedLocation == null && availableLocations.isNotEmpty) {
        print(
            'DEBUG: LocationSelector: No cached location, setting default...');
        selectedLocation = await LocationCacheService.getOrSetDefaultLocation();
        print(
            'DEBUG: LocationSelector: Set default location: ${selectedLocation?.name}');
      }

      setState(() {
        _selectedLocation = selectedLocation;
        _availableLocations = availableLocations;
        _isLoading = false;
      });

      print(
          'DEBUG: LocationSelector: Final selected location: ${_selectedLocation?.name}');

      // Notify parent widget of the loaded/selected location
      if (selectedLocation != null) {
        widget.onLocationChanged?.call(selectedLocation);
      }
    } catch (e) {
      print('DEBUG: LocationSelector: Error loading locations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onLocationSelected(SelectedLocation location) async {
    // Only block selection if it's the old placeholder type
    // Allow profile default locations to be selected even if they need coordinate resolution
    if (location.id == 'profile_default_placeholder') {
      // Show a toast message that the user needs to set the actual location
      NotificationService.showWarningToast(
          'Please set the actual location for your profile default in the Favorite Locations screen');
      return;
    }

    // For profile default locations that need coordinates, we'll allow selection
    // and handle coordinate resolution in the weather service
    if (location.id == 'profile_default_needs_coords') {
      print(
          'DEBUG: Selected profile default that needs coordinate resolution: ${location.name}');
    }

    setState(() {
      _selectedLocation = location;
    });

    // Cache the selected location
    final success = await LocationCacheService.saveSelectedLocation(location);

    if (success) {
      print('Successfully cached location: ${location.name}');
      NotificationService.showSuccessToast(
          'Location changed: ${location.name}');
    } else {
      print('Failed to cache location: ${location.name}');
      NotificationService.showErrorToast('Failed to save location');
    }

    // Notify parent widget
    widget.onLocationChanged?.call(location);
  }

  IconData _getLocationIcon(String type) {
    switch (type) {
      case 'profile_default':
        return UniconsLine.home;
      case 'current':
        return UniconsLine.location_point;
      case 'favorite':
        return UniconsLine.heart;
      default:
        return UniconsLine.map_marker;
    }
  }

  Color _getLocationIconColor(String type) {
    switch (type) {
      case 'profile_default':
        return Colors.blue;
      case 'current':
        return Colors.green;
      case 'favorite':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getLocationDisplayName(String name, String type) {
    // Return the name as-is since we're not adding type labels to the display name
    return name;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading locations...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SelectedLocation>(
          value: _selectedLocation,
          isExpanded: true,
          hint: Text(
            'Select location',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          icon: Icon(
            UniconsLine.angle_down,
            color: Colors.grey.shade600,
            size: 20,
          ),
          items: _availableLocations.map((location) {
            return DropdownMenuItem<SelectedLocation>(
              value: location,
              child: Row(
                children: [
                  Icon(
                    _getLocationIcon(location.type),
                    color: _getLocationIconColor(location.type),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getLocationDisplayName(location.name, location.type),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (SelectedLocation? newLocation) {
            if (newLocation != null) {
              _onLocationSelected(newLocation);
            }
          },
        ),
      ),
    );
  }
}
