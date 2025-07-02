@JS()
library google_maps_interop;

// Platform-specific import (automatically skipped on non-web platforms)
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
// Conditionally import dart:html only on web
// ignore: uri_does_not_exist
import 'dart:html' if (dart.library.io) 'package:slotted/utils/html_stub.dart' as html;
import 'dart:ui' as ui;
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:slotted/utils/logger.dart';
import 'package:latlong2/latlong.dart';

// Use conditional imports based on the platform
import 'package:slotted/utils/js_stub.dart' as js;
import 'package:slotted/utils/js_util_stub.dart' as js_util;

// JavaScript interop classes for Google Maps
@JS('google.maps.places.AutocompleteService')
class AutocompleteService {
  external AutocompleteService();
}

@JS('google.maps.places.PlacesService')
class PlacesService {
  external PlacesService(html.Element element);
}

@JS('google.maps.places.AutocompletionRequest')
class AutocompletionRequest {
  external String input;
  external List<String> types;
  
  external factory AutocompletionRequest();
}

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

/// Helper class for working with Places API via JavaScript interop
class PlacesWebInterop {
  static const String _tag = 'PlacesWebInterop';
  
  /// Check if Google Maps is available on web
  static bool get isAvailable {
    if (!kIsWeb) return false;
    
    // This will only be executed on web, so it's safe
    if (kIsWeb) {
      try {
        // Using dynamic to avoid direct type references that would fail on mobile
        return _hasGoogleMaps();
      } catch (e) {
        Logger.w('[$_tag] Error checking Maps availability: $e', tag: 'places_web_interop');
      }
    }
    return false;
  }

  /// Search for places using the query text
  static Future<List<PlacePrediction>> searchPlaces(String query) async {
    if (!kIsWeb) return [];
    if (query.isEmpty) return [];

    try {
      Logger.d('[$_tag] Searching places for: $query', tag: 'places_web_interop');
      
      if (kIsWeb) {
        return await _searchPlacesImpl(query);
      }
      
      return [];
    } catch (e) {
      Logger.w('[$_tag] Error searching places: $e', tag: 'places_web_interop');
      return [];
    }
  }

  /// Get details for a place by its placeId
  static Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    if (!kIsWeb) return null;
    if (placeId.isEmpty) return null;

    try {
      Logger.d('[$_tag] Getting place details for ID: $placeId', tag: 'places_web_interop');
      
      if (kIsWeb) {
        return await _getPlaceDetailsImpl(placeId);
      }
      
      return null;
    } catch (e) {
      Logger.w('[$_tag] Error getting place details: $e', tag: 'places_web_interop');
      return null;
    }
  }
  
  // Private implementation methods that will only be called on web
  
  static bool _hasGoogleMaps() {
    if (!kIsWeb) return false;
    
    // Using dynamic to bypass compile-time checking
    dynamic jsContext = js.context;
    return jsContext.hasProperty('google') &&
           jsContext['google'].hasProperty('maps') &&
           jsContext['google']['maps'].hasProperty('places');
  }
  
  static Future<List<PlacePrediction>> _searchPlacesImpl(String query) async {
    if (!kIsWeb) return [];
    
    // Using dynamic to bypass compile-time checking
    dynamic jsContext = js.context;
    
    // Make sure the function exists
    if (!jsContext.hasProperty('searchPlaces')) {
      Logger.d('[$_tag] searchPlaces function not found in JavaScript context', tag: 'places_web_interop');
      return [];
    }
    
    // Call the JavaScript function
    final jsPromise = jsContext.callMethod('searchPlaces', [query]);
    Logger.d('[$_tag] JavaScript promise received', tag: 'places_web_interop');
    
    // Wait for the promise to resolve
    final result = await js_util.promiseToFuture(jsPromise);
    Logger.d('[$_tag] Response received from places API', tag: 'places_web_interop');
    
    // Handle null result
    if (result == null) {
      Logger.d('[$_tag] Null result from places API', tag: 'places_web_interop');
      return [];
    }
    
    // Parse the results
    final List<dynamic> placesList = result as List<dynamic>;
    Logger.d('[$_tag] Found ${placesList.length} places', tag: 'places_web_interop');
    
    return placesList
        .map((place) {
          try {
            if (place == null) return null;
            return PlacePrediction.fromJson(
                Map<String, dynamic>.from(place as Map));
          } catch (e) {
            Logger.w('[$_tag] Error parsing prediction: $e', tag: 'places_web_interop');
            return null;
          }
        })
        .where((place) => place != null)
        .cast<PlacePrediction>()
        .toList();
  }
  
  static Future<PlaceDetails?> _getPlaceDetailsImpl(String placeId) async {
    if (!kIsWeb) return null;
    
    // Using dynamic to bypass compile-time checking
    dynamic jsContext = js.context;
    
    // Make sure the function exists
    if (!jsContext.hasProperty('getPlaceDetails')) {
      Logger.d('[$_tag] getPlaceDetails function not found in JavaScript context', tag: 'places_web_interop');
      return null;
    }
    
    // Call the JavaScript function
    final jsPromise = jsContext.callMethod('getPlaceDetails', [placeId]);
    Logger.d('[$_tag] JavaScript promise received for details', tag: 'places_web_interop');
    
    // Wait for the promise to resolve
    final result = await js_util.promiseToFuture(jsPromise);
    Logger.d('[$_tag] Response received from details API', tag: 'places_web_interop');
    
    // Handle null result
    if (result == null) {
      Logger.d('[$_tag] Null result from details API', tag: 'places_web_interop');
      return null;
    }
    
    return PlaceDetails.fromJson(Map<String, dynamic>.from(result as Map));
  }
}

// Function to check if Google Maps is available on web
Future<bool> isGoogleMapsAvailable() async {
  if (!kIsWeb) return false;
  
  try {
    // Check if Google Maps API is loaded
    final googleMapsAvailable = hasProperty(
      html.window, 'google') && 
      hasProperty(
        getProperty(html.window, 'google'), 'maps');
    
    Logger.d('Google Maps available: $googleMapsAvailable');
    return googleMapsAvailable;
  } catch (e) {
    Logger.e('Error checking Google Maps availability: $e', error: e);
    return false;
  }
}

// Initialize the Google Maps API for Flutter Web
Future<void> initializeGoogleMapsWeb(String apiKey) async {
  if (!kIsWeb) return;
  
  try {
    // Check if already loaded
    if (await isGoogleMapsAvailable()) {
      Logger.d('Google Maps already loaded');
      return;
    }
    
    // Create a completer to wait for the script to load
    final completer = Completer<void>();
    
    // Create the script element
    final script = html.ScriptElement()
      ..src = 'https://maps.googleapis.com/maps/api/js?key=$apiKey&libraries=places'
      ..type = 'text/javascript';
    
    // Handle load events
    script.onLoad.listen((event) {
      Logger.d('Google Maps script loaded');
      completer.complete();
    });
    
    script.onError.listen((event) {
      final error = Exception('Failed to load Google Maps API script');
      Logger.e('Failed to load Google Maps API script', error: error);
      completer.completeError(error);
    });
    
    // Add script to the document
    html.document.head!.append(script);
    
    // Wait for the script to load
    await completer.future;
  } catch (e) {
    Logger.e('Error initializing Google Maps Web: $e', error: e);
  }
}

// Register a map view in the web page
// This allows Flutter to display the Google Map
Future<String> registerMapWidget(String viewType, int width, int height) async {
  if (!kIsWeb) return '';
  
  // A unique ID for this map view
  final String viewId = 'google-map-${DateTime.now().millisecondsSinceEpoch}';
  
  try {
    // Create a DOM element to host the map
    final mapElement = html.DivElement()
      ..id = viewId
      ..style.width = '${width}px'
      ..style.height = '${height}px';
    
    // Register the view factory
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      return mapElement;
    });
    
    Logger.d('Registered map widget: $viewId');
    return viewId;
  } catch (e) {
    Logger.e('Error registering map widget: $e', error: e);
    return '';
  }
}

// Enable console logging for debugging maps issues
void enableMapsDebugMode() {
  if (!kIsWeb) return;
  
  try {
    final script = html.ScriptElement()
      ..text = '''
      window.mapsDebugMode = true;
      console.log("Maps debug mode enabled");
      
      // Intercept eval errors
      window.addEventListener('error', function(event) {
        if (event.message.includes('eval')) {
          console.error('Maps eval error:', event);
        }
      });
      ''';
    
    html.document.head!.append(script);
    Logger.d('Maps debug mode enabled');
  } catch (e) {
    Logger.e('Error enabling maps debug mode: $e', error: e);
  }
}

// Add a fallback method for getting location coordinates
Future<Map<String, dynamic>?> getCoordinatesFromAddress(String address) async {
  if (!kIsWeb) return null;
  
  try {
    // Try to use the Geolocation API as a fallback
    final success = Completer<Map<String, dynamic>?>();
    
    final script = html.ScriptElement()
      ..text = '''
      function getCoords() {
        return new Promise((resolve, reject) => {
          if (!navigator.geolocation) {
            reject('Geolocation not supported');
            return;
          }
          
          navigator.geolocation.getCurrentPosition(
            (position) => {
              resolve({
                latitude: position.coords.latitude,
                longitude: position.coords.longitude
              });
            },
            (error) => {
              reject('Error getting location: ' + error.message);
            },
            { enableHighAccuracy: true, timeout: 5000, maximumAge: 0 }
          );
        });
      }
      
      window.getLocationCoords = getCoords;
      ''';
    
    html.document.head!.append(script);
    
    // Wait a moment for the script to initialize
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Try to call the JS function
    final jsPromise = callMethod(html.window, 'getLocationCoords', []);
    final result = await promiseToFuture(jsPromise);
    
    if (result != null) {
      final coords = {
        'latitude': getProperty(result, 'latitude'),
        'longitude': getProperty(result, 'longitude'),
        'address': address,
      };
      
      Logger.d('Got coordinates for address: $coords');
      return coords;
    }
    
    return null;
  } catch (e) {
    Logger.e('Error getting coordinates from address: $e', error: e);
    return null;
  }
}

// Create a helper method for instantiating the AutocompletionRequest
dynamic createAutocompleteRequest(String input, List<String> types) {
  if (!kIsWeb) return null;
  
  try {
    final request = AutocompletionRequest();
    setProperty(request, 'input', input);
    setProperty(request, 'types', types);
    return request;
  } catch (e) {
    Logger.e('Error creating autocomplete request: $e', error: e);
    return null;
  }
} 