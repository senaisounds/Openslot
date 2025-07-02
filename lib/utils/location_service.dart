import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:slotted/utils/logger.dart';

/// Custom exception for location service errors
class LocationServiceException implements Exception {
  final String message;
  final dynamic originalError;

  LocationServiceException(this.message, {this.originalError});

  @override
  String toString() {
    return 'LocationServiceException: $message (Original error: $originalError)';
  }
}

/// Service for managing location functionality
class LocationService {
  static final LocationService _instance = LocationService._internal();
  static LocationService get instance => _instance;
  
  LocationService._internal();
  
  bool _initialized = false;
  bool _permissionGranted = false;
  final bool _useSimulatedLocation = false;
  LatLng? _currentSimulatedLocation;
  
  // Predefined locations for simulator testing
  static final Map<String, LatLng> simulatedLocations = {
    'New York': const LatLng(40.7128, -74.0060),
    'Los Angeles': const LatLng(34.0522, -118.2437),
    'Chicago': const LatLng(41.8781, -87.6298),
    'Miami': const LatLng(25.7617, -80.1918),
    'Austin': const LatLng(30.2672, -97.7431),
    'San Francisco': const LatLng(37.7749, -122.4194),
    'Seattle': const LatLng(47.6062, -122.3321),
    'Denver': const LatLng(39.7392, -104.9903),
    'Boston': const LatLng(42.3601, -71.0589),
    'Nashville': const LatLng(36.1627, -86.7816),
  };
  
  /// Initialize the location service
  static Future<void> initialize() async {
    // Skip on web for now
    if (kIsWeb) {
      Logger.d('Location service skipped on web platform', tag: 'Location');
      return;
    }
    
    // Continue with mobile implementation
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestedPermission = await Geolocator.requestPermission();
        if (requestedPermission == LocationPermission.denied ||
            requestedPermission == LocationPermission.deniedForever) {
          throw Exception('Location permission denied');
        }
      }
      
      // Update instance properties safely
      final instance = LocationService.instance;
      instance._permissionGranted = permission != LocationPermission.denied && 
                                permission != LocationPermission.deniedForever;
      instance._initialized = true;
      
      Logger.d('Location service initialized successfully', tag: 'Location');
    } catch (e) {
      Logger.e('Failed to initialize location service: $e', tag: 'Location');
      rethrow;
    }
  }
  
  /// Check if location permission is granted
  bool get isPermissionGranted => kIsWeb ? false : _permissionGranted;
  
  /// Get current position, gracefully handling platform differences
  Future<Position?> getCurrentPosition() async {
    if (kIsWeb) {
      // For web, return null or a mock position
      Logger.d('getCurrentPosition called on web platform', tag: 'Location');
      return null;
    }
    
    if (!_initialized) {
      await LocationService.initialize();
    }
    
    if (!_permissionGranted) {
      return null;
    }
    
    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      Logger.e('Failed to get current position: $e', tag: 'Location');
      return null;
    }
  }
  
  /// Get current location as LatLng
  Future<LatLng?> getCurrentLocation({bool forceRefresh = false}) async {
    if (kIsWeb) {
      // For web platforms, return a default location or null
      Logger.d('Web platform detected, using default location', tag: 'Location');
      return simulatedLocations['New York']; // Default to New York for web
    }
    
    if (!_initialized) {
      await LocationService.initialize();
    }
    
    if (_useSimulatedLocation && _currentSimulatedLocation != null) {
      return _currentSimulatedLocation;
    }
    
    try {
      final position = await getCurrentPosition();
      if (position == null) return null;
      
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      Logger.e('Error getting current location: $e', tag: 'Location');
      return null;
    }
  }
  
  // Set a simulated location (only works when running on simulator)
  static Future<void> setSimulatedLocation(String locationName) async {
    final instance = LocationService.instance;
    
    if (!instance._initialized) {
      await initialize();
    }
    
    try {
      if (!instance._useSimulatedLocation) {
        Logger.d('Not running on simulator, ignoring simulated location', 
                 tag: 'LocationService');
        return;
      }
      
      final location = simulatedLocations[locationName];
      if (location != null) {
        instance._currentSimulatedLocation = location;
        Logger.d('Set simulated location to $locationName: $location', 
                 tag: 'LocationService');
      }
    } catch (e) {
      Logger.e('Error setting simulated location: $e', tag: 'LocationService', error: e);
      // Don't throw - just log the error, as this is non-critical functionality
    }
  }
  
  // Check if we're using simulated location
  static bool get isUsingSimulatedLocation => _instance._useSimulatedLocation;
  
  // Get all available simulated locations
  static List<String> getAvailableSimulatedLocations() {
    return simulatedLocations.keys.toList();
  }
  
  // Get the current simulated location name
  static String getCurrentSimulatedLocationName() {
    final instance = LocationService.instance;
    final currentLocation = instance._currentSimulatedLocation;
    
    if (currentLocation == null) {
      return 'Unknown';
    }
    
    for (final entry in simulatedLocations.entries) {
      if (entry.value.latitude == currentLocation.latitude &&
          entry.value.longitude == currentLocation.longitude) {
        return entry.key;
      }
    }
    
    return 'Custom Location';
  }
} 