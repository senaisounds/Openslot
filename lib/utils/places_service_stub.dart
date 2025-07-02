import 'package:slotted/utils/places_service.dart';

/// Creates a web places service (stub implementation)
/// This function will be called when running on mobile
PlacesService createWebPlacesService() {
  throw UnsupportedError('Cannot create web places service on non-web platform');
} 