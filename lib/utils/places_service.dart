import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

// Conditionally import the web implementation
// ignore: uri_does_not_exist
import 'places_service_web.dart' if (dart.library.io) 'places_service_stub.dart';

/// Model class for Place predictions
class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlacePrediction({
    required this.placeId,
    required this.description,
    this.mainText = '',
    this.secondaryText = '',
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['placeId'] ?? '',
      description: json['description'] ?? '',
      mainText: json['mainText'] ?? '',
      secondaryText: json['secondaryText'] ?? '',
    );
  }
}

/// Model class for Place details
class PlaceDetails {
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String name;
  final List<AddressComponent> addressComponents;

  PlaceDetails({
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    this.name = '',
    this.addressComponents = const [],
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    return PlaceDetails(
      formattedAddress: json['formattedAddress'] ?? '',
      latitude: json['latitude'] ?? 0.0,
      longitude: json['longitude'] ?? 0.0,
      name: json['name'] ?? '',
      addressComponents: (json['addressComponents'] as List?)
              ?.map((comp) => AddressComponent.fromJson(comp))
              .toList() ??
          [],
    );
  }

  LatLng get latLng => LatLng(latitude, longitude);
}

/// Model class for Address components
class AddressComponent {
  final String longName;
  final String shortName;
  final List<String> types;

  AddressComponent({
    required this.longName,
    required this.shortName,
    required this.types,
  });

  factory AddressComponent.fromJson(Map<String, dynamic> json) {
    return AddressComponent(
      longName: json['longName'] ?? '',
      shortName: json['shortName'] ?? '',
      types: (json['types'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

/// Abstract class for Places service with platform-specific implementations
abstract class PlacesService {
  static PlacesService? _instance;
  
  /// Get the singleton instance
  static PlacesService get instance {
    _instance ??= kIsWeb 
        ? createWebPlacesService()
        : MobilePlacesService();
    return _instance!;
  }

  /// Search for places using the query text
  Future<List<PlacePrediction>> searchPlaces(String query);

  /// Get details for a place by its placeId
  Future<PlaceDetails?> getPlaceDetails(String placeId);
}

/// Mobile implementation of Places service
class MobilePlacesService implements PlacesService {
  @override
  Future<List<PlacePrediction>> searchPlaces(String query) async {
    try {
      // Mobile implementation (could connect to a REST API instead of JS interop)
      // For now, just return an empty list
      debugPrint('Mobile implementation of searchPlaces called with: $query');
      return [];
    } catch (e, stackTrace) {
      debugPrint('Error in async operation: $e');
      debugPrint('Stack trace: $stackTrace');
      return []; // Return empty list on error
    }
  }

  @override
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      // Mobile implementation
      // For now, just return null
      debugPrint('Mobile implementation of getPlaceDetails called with: $placeId');
      return null;
    } catch (e, stackTrace) {
      debugPrint('Error in async operation: $e');
      debugPrint('Stack trace: $stackTrace');
      return null; // Return null on error
    }
  }
} 