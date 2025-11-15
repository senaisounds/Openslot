import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'package:slotted/utils/logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/utils/safe_state_mixin.dart';

/// Address suggestion model
class AddressSuggestion {
  final String text;
  final String id;
  final double? latitude;
  final double? longitude;

  AddressSuggestion({
    required this.text, 
    required this.id,
    this.latitude,
    this.longitude,
  });
  
  factory AddressSuggestion.fromNominatim(Map<String, dynamic> json) {
    return AddressSuggestion(
      text: json['display_name'] as String,
      id: json['place_id'].toString(),
      latitude: double.tryParse(json['lat'].toString()),
      longitude: double.tryParse(json['lon'].toString()),
    );
  }
}

class LocationPage extends StatefulWidget {
  const LocationPage({
    super.key,
    required this.onPicked,
    this.eventLocation,
  });

  final Function(Map<String, dynamic>) onPicked;
  final LatLng? eventLocation;

  @override
  LocationPageState createState() => LocationPageState();
}

class LocationPageState extends State<LocationPage> with SafeStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  List<AddressSuggestion> _suggestions = [];
  bool _isSearching = false;
  Timer? _debounce;
  LatLng _selectedLocation = const LatLng(37.7749, -122.4194);
  String? _selectedAddress;
  bool _isLoadingLocation = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.eventLocation != null) {
      _selectedLocation = widget.eventLocation!;
      _reverseGeocode(_selectedLocation.latitude, _selectedLocation.longitude);
    } else {
      // When creating a new event, automatically get user's current location
      _getCurrentLocation();
    }
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
  
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_searchController.text.length >= 3) {
        _searchLocation(_searchController.text);
      } else {
        safeSetState(() => _suggestions = []);
      }
    });
  }
  
  /// Search for locations using Nominatim (US only)
  Future<void> _searchLocation(String query) async {
    safeSetState(() => _isSearching = true);
    
    try {
      // Restrict search to United States using bounding box
      // US approximate bounds: West: -125, South: 24, East: -66, North: 50
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?'
        'q=${Uri.encodeComponent(query)}&'
        'format=json&'
        'countrycodes=us&'  // Restrict to US
        'limit=5&'
        'addressdetails=1'
      );
      
      final response = await http.get(
        url,
        headers: {'User-Agent': 'OpenSlot/1.0'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        safeSetState(() {
          _suggestions = data.map((item) {
            return AddressSuggestion.fromNominatim(item as Map<String, dynamic>);
          }).toList();
        });
      }
    } catch (e) {
      Logger.w('Search error: $e', tag: 'location');
    } finally {
      safeSetState(() => _isSearching = false);
    }
  }
  
  /// Select suggestion from search results
  void _selectSuggestion(AddressSuggestion suggestion) {
    safeSetState(() {
      _searchController.text = suggestion.text;
      _selectedAddress = suggestion.text;
      _suggestions = [];
      if (suggestion.latitude != null && suggestion.longitude != null) {
        _selectedLocation = LatLng(suggestion.latitude!, suggestion.longitude!);
        _mapController.move(_selectedLocation, 15.0);
      }
    });
  }
  
  /// Get current location
  Future<void> _getCurrentLocation() async {
    if (_isLoadingLocation) return;
    
    safeSetState(() => _isLoadingLocation = true);
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _showError('Location permission denied');
        return;
      }
      
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      
      safeSetState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _mapController.move(_selectedLocation, 15.0);
      });
      
      await _reverseGeocode(position.latitude, position.longitude);
    } catch (e) {
      Logger.e('Location error: $e', tag: 'location');
      _showError('Unable to get location');
    } finally {
      safeSetState(() => _isLoadingLocation = false);
    }
  }
  
  /// Reverse geocode coordinates to address
  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?'
        'lat=$lat&lon=$lng&format=json'
      );
      
      final response = await http.get(
        url,
        headers: {'User-Agent': 'OpenSlot/1.0'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        safeSetState(() {
          _selectedAddress = data['display_name'] as String;
          _searchController.text = _selectedAddress!;
        });
      }
    } catch (e) {
      Logger.w('Reverse geocode error: $e', tag: 'location');
      safeSetState(() {
        _selectedAddress = 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
        _searchController.text = _selectedAddress!;
      });
    }
  }
  
  /// Confirm selection
  void _confirm() {
    widget.onPicked({
      'address': _selectedAddress ?? _searchController.text,
      'latlng': _selectedLocation,
    });
    Navigator.of(context).pop();
  }
  
  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.back, color: CupertinoColors.white),
        ),
        middle: const Text(
          'Pick Location',
          style: TextStyle(color: CupertinoColors.white),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _confirm,
          child: const Icon(
            CupertinoIcons.check_mark_circled_solid,
            color: AppColors.primary,
          ),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Map
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedLocation,
                initialZoom: 13.0,
                onTap: (tapPosition, point) async {
                  safeSetState(() => _selectedLocation = point);
                  await _reverseGeocode(point.latitude, point.longitude);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.slotted.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 50,
                      height: 50,
                      point: _selectedLocation,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.location_solid,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Search overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: CupertinoColors.black.withValues(alpha: 0.95),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search bar
                    Row(
                      children: [
                        // Current location button
                        CupertinoButton(
                          padding: const EdgeInsets.all(12),
                          onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                          color: AppColors.backgroundCard,
                          child: _isLoadingLocation
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CupertinoActivityIndicator(color: AppColors.primary),
                                )
                              : const Icon(
                                  CupertinoIcons.placemark_fill,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                        ),
                        const SizedBox(width: 12),
                        // Search field
                        Expanded(
                          child: CupertinoTextField(
                            controller: _searchController,
                            placeholder: 'Search address...',
                            placeholderStyle: const TextStyle(color: AppColors.textSecondary),
                            style: const TextStyle(color: CupertinoColors.white),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundCard,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(12),
                            prefix: const Padding(
                              padding: EdgeInsets.only(left: 12),
                              child: Icon(CupertinoIcons.search, color: AppColors.textSecondary, size: 20),
                            ),
                            clearButtonMode: OverlayVisibilityMode.editing,
                            suffix: _isSearching
                                ? const Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: CupertinoActivityIndicator(),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                    
                    // Suggestions
                    if (_suggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _suggestions.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: AppColors.divider,
                          ),
                          itemBuilder: (context, index) {
                            final suggestion = _suggestions[index];
                            return CupertinoButton(
                              padding: const EdgeInsets.all(12),
                              onPressed: () => _selectSuggestion(suggestion),
                              child: Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.location,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      suggestion.text,
                                      style: const TextStyle(
                                        color: CupertinoColors.white,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Selected location info
            if (_selectedAddress != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.getPrimaryGradient(),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(CupertinoIcons.location_solid, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Selected Location',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedAddress!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
}
