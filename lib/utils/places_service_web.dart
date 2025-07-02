import 'package:flutter/foundation.dart';
import 'package:slotted/utils/places_service.dart';
/// Creates a web places service
/// This function will be called when running on web
PlacesService createWebPlacesService() {
  return WebPlacesService();
}

/// Web implementation of Places service
/// This file should only be imported on web
class WebPlacesService implements PlacesService {
  @override
  Future<List<PlacePrediction>> searchPlaces(String query) async {
    if (!kIsWeb) return [];
    if (query.isEmpty) return [];

    try {
      debugPrint('Web implementation of searchPlaces called with: $query');
      // In a real implementation, this would use JavaScript interop
      // For now, just return an empty list
      return [];
    } catch (e) {
      debugPrint('Error searching places: $e');
      return [];
    }
  }

  @override
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    if (!kIsWeb) return null;
    if (placeId.isEmpty) return null;

    try {
      debugPrint('Web implementation of getPlaceDetails called with: $placeId');
      // In a real implementation, this would use JavaScript interop
      // For now, just return null
      return null;
    } catch (e) {
      debugPrint('Error getting place details: $e');
      return null;
    }
  }
} 