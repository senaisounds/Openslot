import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:slotted/common/event_class.dart' as event_class;
import 'package:slotted/pages/event_details.dart';
import 'package:slotted/pages/live.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slotted/utils/logger.dart';
import 'package:slotted/utils/location_service.dart';
import 'package:provider/provider.dart';
import 'package:slotted/providers/theme_provider.dart';
import 'package:flutter/material.dart';

import 'dart:ui' as ui;
import '../common/colors.dart';
import 'package:slotted/utils/widget_fix.dart';

// Main Theme Colors
const Color kPrimaryColor = Color(0xFF6C4AB0);    // Rich Purple - Stage Lights
const Color kSecondaryColor = Color(0xFF8D72E1);  // Soft Purple - Energy
const Color kAccentColor = Color(0xFFB9E0FF);     // Electric Blue - Microphone Glow
const Color kHighlightColor = Color(0xFFFFE79B);  // Warm Yellow - Spotlight
const Color kBackgroundDark = Color(0xFF2D2D3A);  // Dark Stage
const Color kBackgroundLight = Color(0xFFF5F5F7); // Light Mode

class EventsMapPage extends StatefulWidget {
  final User? user;
  final bool debug;
  final Future<void> Function(BuildContext, bool, Function()) authAction;
  final Future<void> Function(event_class.Event event, SlottedUser slottedUser) reserveAction;

  const EventsMapPage({
    super.key,
    required this.user,
    this.debug = false,
    required this.authAction,
    required this.reserveAction,
  });

  @override
  EventsMapPageState createState() => EventsMapPageState();
}

// Add a class for caching event coordinates to avoid recalculation
class EventCoordinateCache {
  final Map<String, LatLng> _cache = {};
  
  LatLng getCoordinates(String eventId, String selectedCity, LatLng baseCoordinates, Function calculator) {
    final cacheKey = '$eventId-$selectedCity';
    if (!_cache.containsKey(cacheKey)) {
      _cache[cacheKey] = calculator(eventId, baseCoordinates);
    }
    return _cache[cacheKey]!;
  }
  
  void clear() {
    _cache.clear();
  }
}

class EventsMapPageState extends State<EventsMapPage> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng _currentPosition = const LatLng(37.7749, -122.4194); // Default to San Francisco
  bool _isLoading = true;
  List<event_class.Event> _events = [];
  List<event_class.Event> _filteredEvents = [];
  event_class.Event? _selectedEvent;
  
  // Add event coordinate cache
  final EventCoordinateCache _coordinateCache = EventCoordinateCache();
  
  // Add map of pre-rendered markers to avoid rebuilding them constantly
  final Map<String, Marker> _markerCache = {};
  
  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
String _selectedCategory = 'All';
final double _maxDistance = 50.0; // in miles
  
  // Enhanced filtering
  bool _showAdvancedFilters = false;
  double _priceMin = 0;
  double _priceMax = 200;
  String _selectedTimeFilter = 'All Time';
  bool _showLiveEventsOnly = false;
  bool _showAvailableOnly = false;
  
  // Clustering
  bool _enableClustering = true;
  final Map<String, List<event_class.Event>> _eventClusters = {};
  
  // Quick filters
  final List<String> _timeFilters = ['All Time', 'Today', 'This Week', 'This Weekend', 'Next Week'];
  
// Enhanced search functionality
  bool _showSearchOverlay = false;
  List<event_class.Event> _searchResults = [];
  bool _isSearching = false;
  
  // Location filter state
  bool _showLocationFilter = false;
  String _selectedDistanceFilter = 'All';
  final List<String> _distanceOptions = ['All', '5 mi', '10 mi', '25 mi', '50 mi', '100 mi'];
  
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  // Add debouncing for map moves to avoid excessive refiltering
  Timer? _mapMoveDebounce;
  
  // Cache for distance calculations
  final Map<String, double> _distanceCache = {};
  
  // Tutorial state
  bool _showTutorial = false;
  int _currentTutorialStep = 0;
  final List<Map<String, dynamic>> _tutorialSteps = [
    {
      'title': 'Welcome to Open Slot! 🎭',
      'description': 'Discover amazing events happening around you. Let\'s get started!',
      'position': 'center',
      'icon': CupertinoIcons.map_fill,
    },
    {
      'title': 'Choose Your City 🎯',
      'description': 'Select your location or use "Near Me" to find events in your area.',
      'position': 'top-left',
      'icon': CupertinoIcons.location_circle_fill,
    },
    {
      'title': 'Filter Events 🎵',
      'description': 'Use the category chips to find exactly what you\'re looking for.',
      'position': 'center',
      'icon': CupertinoIcons.tag_fill,
    },
    {
      'title': 'Explore Events 🎪',
      'description': 'Tap any pin to see event details and join the fun!',
      'position': 'center',
      'icon': CupertinoIcons.pin_fill,
    },
    {
      'title': 'Live Events 🔥',
      'description': 'Pulsing pins show events happening right now. Don\'t miss out!',
      'position': 'center',
      'icon': CupertinoIcons.dot_radiowaves_left_right,
    },
  ];

  double _toRadians(double degree) {
    return degree * (pi / 180);
  }

  final List<String> cities = [
    'Near Me',
    'New York',
    'Los Angeles',
    'Austin',
    'Chicago',
    'Houston',
    'Philadelphia',
    'Phoenix',
    'San Antonio',
    'San Diego',
    'Dallas',
    'San Francisco',
    'Miami',
    'Seattle',
    'Boston',
    'Denver',
    'Atlanta',
    'Nashville',
    'Portland',
    'Washington',
    'Las Vegas',
    'Detroit',
    'Minneapolis',
  ];

  String selectedCity = 'New York';

  // City coordinates
  final Map<String, LatLng> cityCoordinates = {
    'New York': const LatLng(40.7128, -74.0060),
    'Los Angeles': const LatLng(34.0522, -118.2437),
    'Austin': const LatLng(30.2672, -97.7431),
    'Chicago': const LatLng(41.8781, -87.6298),
    'Houston': const LatLng(29.7604, -95.3698),
    'Philadelphia': const LatLng(39.9526, -75.1652),
    'Phoenix': const LatLng(33.4484, -112.0740),
    'San Antonio': const LatLng(29.4241, -98.4936),
    'San Diego': const LatLng(32.7157, -117.1611),
    'Dallas': const LatLng(32.7767, -96.7970),
    'San Francisco': const LatLng(37.7749, -122.4194),
    'Miami': const LatLng(25.7617, -80.1918),
    'Seattle': const LatLng(47.6062, -122.3321),
    'Boston': const LatLng(42.3601, -71.0589),
    'Denver': const LatLng(39.7392, -104.9903),
    'Atlanta': const LatLng(33.7490, -84.3880),
    'Nashville': const LatLng(36.1627, -86.7816),
    'Portland': const LatLng(45.5152, -122.6784),
    'Washington': const LatLng(38.9072, -77.0369),
    'Las Vegas': const LatLng(36.1699, -115.1398),
    'Detroit': const LatLng(42.3314, -83.0458),
    'Minneapolis': const LatLng(44.9778, -93.2650),
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
    );
    
    _getCurrentLocation();
    _fetchEvents();
    _checkFirstTimeUser();
    
    // Add listener to search controller
    _searchController.addListener(_filterEvents);
    
    // Initialize clustering
    _updateClusters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _mapMoveDebounce?.cancel();
    super.dispose();
  }

  // Add didUpdateWidget to handle hot reload
  @override
  void didUpdateWidget(EventsMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Reset loading state on hot reload if it's been loading for too long
    if (_isLoading) {
      // Give the loading a short grace period to finish naturally
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Use the LocationService to get the current location (real or simulated)
      final location = await LocationService.instance.getCurrentLocation();
      
      setState(() {
        if (location != null) {
          _currentPosition = location;
          _mapController.move(_currentPosition, 11);
        } else {
          // If location is null, use New York as fallback
          _currentPosition = LocationService.simulatedLocations['New York']!;
          _mapController.move(_currentPosition, 11);
        }
      });
      
      // If we're on simulator, show a message
      if (LocationService.isUsingSimulatedLocation) {
        _showSimulatedLocationBanner();
      }
    } catch (e) {
      Logger.d('Error getting location: $e', tag: 'Events_map_page');
    }
  }

  Future<void> _fetchEvents() async {
    // Reset any previous loading state
    setState(() {
      _isLoading = true;
    });
    
    // Add timeout to prevent stuck loading state
    final timeout = Timer(const Duration(seconds: 15), () {
      if (mounted && _isLoading) {
        Logger.d('Event fetch timeout - resetting loading state', tag: 'Events_map_page');
        setState(() {
          _isLoading = false;
        });
      }
    });
    
    try {
      // Use a more efficient query with limit and order
      final eventsSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('ended', isEqualTo: false)
          .orderBy('startTime', descending: false) // Order by start time for better performance
          .limit(100) // Limit to prevent loading too many events
          .get();
      
      final events = eventsSnapshot.docs
          .map((doc) => event_class.Event.fromDocument(doc))
          .toList();
      
      // Cancel timeout since we got the data
      timeout.cancel();
      
      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
        
        // Apply filters immediately after loading events
        _filterEvents();
        
        // Clear the marker cache to ensure fresh rendering
        _coordinateCache.clear();
        _markerCache.clear();
        
        Logger.d('Loaded ${events.length} events, filtered to ${_filteredEvents.length} for $selectedCity', tag: 'Events_map_page');
      }
    } catch (e) {
      Logger.d('Error fetching events: $e', tag: 'Events_map_page');
      
      // Cancel timeout since we got an error
      timeout.cancel();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Update _getEventCoordinates to use the actual event location
  LatLng _getEventCoordinates(event_class.Event event) {
    // Check if the event has a valid location first
    if (event.location.latitude != 0 && event.location.longitude != 0) {
      return event.location;
    }
    
    // Only generate coordinates for events that match the selected city
    if (!_hasEventInCity(event, selectedCity) && selectedCity != 'Near Me') {
      // Return a far-away coordinate that won't show on the map
      // This effectively hides events that don't belong in the selected city
      return const LatLng(-90, -180); // Antarctica point
    }
    
    // Use the cache to avoid recalculating coordinates
    final baseCoordinates = selectedCity == 'Near Me'
        ? _currentPosition
        : cityCoordinates[selectedCity] ?? const LatLng(40.7128, -74.0060);
    
    // For legacy events without proper locations or for testing, use a generated location
    return _coordinateCache.getCoordinates(
      event.id, 
      selectedCity, 
      baseCoordinates, 
      (eventId, baseCoords) {
        // This will only be called if the coordinate is not in cache
        Logger.d('Generating location for event ${event.name} (${event.id})', tag: 'Events_map_page');
        final random = Random(eventId.hashCode);
        
        // Use a smaller radius to keep events closer to the actual city
        final latOffset = (random.nextDouble() - 0.5) * 0.05;
        final lngOffset = (random.nextDouble() - 0.5) * 0.05;
        
        return LatLng(
          baseCoords.latitude + latOffset,
          baseCoords.longitude + lngOffset
        );
      }
    );
  }

  void _triggerHapticFeedback() {
    HapticFeedback.mediumImpact();
  }

  Future<void> _checkFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool('has_seen_map_tutorial') ?? false;
    
    if (!hasSeenTutorial) {
      // Delay showing tutorial to allow map to load first
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _showTutorial = true;
        });
      });
    }
  }

  Future<void> _markTutorialComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_map_tutorial', true);
  }

  void _nextTutorialStep() {
    if (_currentTutorialStep < _tutorialSteps.length - 1) {
      setState(() {
        _currentTutorialStep++;
      });
    } else {
      setState(() {
        _showTutorial = false;
      });
      _markTutorialComplete();
    }
  }

  void _skipTutorial() {
    setState(() {
      _showTutorial = false;
    });
    _markTutorialComplete();
  }
  
  // Enhanced clustering algorithm
  void _updateClusters() {
    if (!_enableClustering || _filteredEvents.isEmpty) {
      _eventClusters.clear();
      return;
    }
    
    const double clusterRadius = 0.01; // ~1km in degrees
    _eventClusters.clear();
    
    for (final event in _filteredEvents) {
      final eventCoords = _getEventCoordinates(event);
      String? foundCluster;
      
      // Find existing cluster within radius
      for (final clusterKey in _eventClusters.keys) {
        final clusterCoords = _parseClusterKey(clusterKey);
        if (_calculateDistance(
          eventCoords.latitude, eventCoords.longitude,
          clusterCoords.latitude, clusterCoords.longitude,
        ) <= clusterRadius * 111) { // Convert degrees to km
          foundCluster = clusterKey;
          break;
        }
      }
      
      if (foundCluster != null) {
        _eventClusters[foundCluster]!.add(event);
      } else {
        final clusterKey = '${eventCoords.latitude.toStringAsFixed(4)},${eventCoords.longitude.toStringAsFixed(4)}';
        _eventClusters[clusterKey] = [event];
      }
    }
  }
  
  LatLng _parseClusterKey(String key) {
    final parts = key.split(',');
    return LatLng(double.parse(parts[0]), double.parse(parts[1]));
  }
  
  List<Marker> _buildClusteredMarkers() {
    final markers = <Marker>[];
    
    for (final clusterEntry in _eventClusters.entries) {
      final clusterCoords = _parseClusterKey(clusterEntry.key);
      final events = clusterEntry.value;
      
      if (events.length == 1) {
        // Single event - render normally
        final event = events.first;
        final isSelected = _selectedEvent?.id == event.id;
        markers.add(_buildSingleEventMarker(event, clusterCoords, isSelected));
      } else {
        // Multiple events - render cluster
        markers.add(_buildClusterMarker(events, clusterCoords));
      }
    }
    
    return markers;
  }
  
  List<Marker> _buildIndividualMarkers() {
    return _filteredEvents.map((event) {
      final coordinates = _getEventCoordinates(event);
      final isSelected = _selectedEvent?.id == event.id;
      
      // Use cached marker if available
      final cacheKey = '$event.id-$isSelected';
      if (_markerCache.containsKey(cacheKey)) {
        return _markerCache[cacheKey] as Marker;
      }
      
      final marker = _buildSingleEventMarker(event, coordinates, isSelected);
      _markerCache[cacheKey] = marker;
      return marker;
    }).toList();
  }
  
  Marker _buildSingleEventMarker(event_class.Event event, LatLng coordinates, bool isSelected) {
    return Marker(
      width: isSelected ? 60 : 48,
      height: isSelected ? 60 : 48,
      point: coordinates,
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () {
          _triggerHapticFeedback();
          setState(() {
            _selectedEvent = event;
          });
          _mapController.move(coordinates, 14);
        },
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            // Enhanced animations for live events
            final isLive = event.live;
            final scale = isSelected 
                ? 1.0 + (_pulseAnimation.value * 0.15)
                : isLive 
                    ? 1.0 + (_pulseAnimation.value * 0.08)
                    : 1.0;
            
            return Transform.scale(
              scale: scale,
              child: Stack(
                children: [
                  // Live event pulse ring
                  if (isLive && !isSelected)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: kHighlightColor.withValues(alpha: _pulseAnimation.value * 0.6),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  
                  // Main marker
                  Container(
                    width: isSelected ? 50 : 40,
                    height: isSelected ? 50 : 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isLive
                            ? [kHighlightColor, const Color(0xFFFF6B35)]
                            : _getCategoryColors(event.category),
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: kBackgroundLight,
                        width: isSelected ? 3 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isLive 
                              ? kHighlightColor.withValues(alpha: 0.4)
                              : kPrimaryColor.withValues(alpha: 0.3),
                          blurRadius: isSelected ? 12 : 8,
                          spreadRadius: isSelected ? 3 : 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            isLive 
                                ? CupertinoIcons.dot_radiowaves_left_right
                                : _getCategoryIcon(event.category),
                            color: kBackgroundLight,
                            size: isSelected ? 24 : 20,
                          ),
                        ),
                        
                        // Availability indicator
                        if (!event.isFull && !isLive)
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: kHighlightColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          
                        // Full event indicator
                        if (event.isFull && !isLive)
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: kBackgroundLight, width: 1),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  Marker _buildClusterMarker(List<event_class.Event> events, LatLng coordinates) {
    final liveCount = events.where((e) => e.live).length;
    final hasLiveEvents = liveCount > 0;
    
    return Marker(
      width: 60,
      height: 60,
      point: coordinates,
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () {
          _triggerHapticFeedback();
          _showClusterDetails(events, coordinates);
        },
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final scale = hasLiveEvents 
                ? 1.0 + (_pulseAnimation.value * 0.1)
                : 1.0;
            
            return Transform.scale(
              scale: scale,
              child: Stack(
                children: [
                  // Pulse ring for live events
                  if (hasLiveEvents)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: kHighlightColor.withValues(alpha: _pulseAnimation.value * 0.5),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  
                  // Main cluster circle
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: hasLiveEvents
                            ? [kHighlightColor, const Color(0xFFFF6B35)]
                            : [kSecondaryColor, kPrimaryColor],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: kBackgroundLight,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: hasLiveEvents 
                              ? kHighlightColor.withValues(alpha: 0.4)
                              : kSecondaryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${events.length}',
                            style: const TextStyle(
                              color: kBackgroundLight,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (hasLiveEvents)
                            Text(
                              '$liveCount LIVE',
                              style: TextStyle(
                                color: kBackgroundLight.withValues(alpha: 0.9),
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  void _showClusterDetails(List<event_class.Event> events, LatLng coordinates) {
    _mapController.move(coordinates, 15);
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 400,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: kBackgroundDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: kPrimaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.location_fill,
                    color: kAccentColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${events.length} Events Here',
                    style: const TextStyle(
                      color: kBackgroundLight,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      color: kPrimaryColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            
            // Events list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedEvent = event;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              kPrimaryColor.withValues(alpha: 0.1),
                              kSecondaryColor.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: event.live 
                                ? kHighlightColor.withValues(alpha: 0.5)
                                : kPrimaryColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: event.live
                                      ? [kHighlightColor, const Color(0xFFFF6B35)]
                                      : _getCategoryColors(event.category),
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                event.live 
                                    ? CupertinoIcons.dot_radiowaves_left_right
                                    : _getCategoryIcon(event.category),
                                color: kBackgroundLight,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (event.live)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: kHighlightColor,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'LIVE',
                                            style: TextStyle(
                                              color: kBackgroundDark,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      if (event.live) const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          event.name,
                                          style: const TextStyle(
                                            color: kBackgroundLight,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${event.formattedPrice} • ${event.category}',
                                    style: TextStyle(
                                      color: kBackgroundLight.withValues(alpha: 0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              CupertinoIcons.chevron_right,
                              color: kPrimaryColor,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Optimize distance calculation with caching
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    final cacheKey = '${lat1.toStringAsFixed(6)}-${lon1.toStringAsFixed(6)}-'
                   '${lat2.toStringAsFixed(6)}-${lon2.toStringAsFixed(6)}';
    
    if (_distanceCache.containsKey(cacheKey)) {
      return _distanceCache[cacheKey]!;
    }
    
    // Haversine formula to calculate distance between two points
    const R = 3959.0; // Earth radius in miles
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * 
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = R * c;
    
    // Cache the result - limit cache size to prevent memory issues
    if (_distanceCache.length > 1000) {
      _distanceCache.clear();
    }
    _distanceCache[cacheKey] = distance;
    
    return distance;
  }

  // Handle map move with debounce to prevent excessive filtering
  void _handleMapMove(MapEventMove event) {
    // Update current position immediately
    setState(() {
      _currentPosition = event.camera.center;
    });
    
    // Debounce the filtering to avoid excessive calculations
    _mapMoveDebounce?.cancel();
    _mapMoveDebounce = Timer(const Duration(milliseconds: 300), () {
      _filterEvents();
    });
  }

  // Enhanced event filtering with advanced options
  void _filterEvents() {
    if (_events.isEmpty) return;
    
    // Prepare data for efficient filtering
    final searchText = _searchController.text.toLowerCase();
    final mapCenter = _mapController.camera.center;
    
    setState(() {
      _filteredEvents = _events.where((event) {
        // Apply search filter
        final searchMatch = searchText.isEmpty ||
            event.name.toLowerCase().contains(searchText) ||
            event.hostName.toLowerCase().contains(searchText) ||
            event.category.toLowerCase().contains(searchText);
        
        if (!searchMatch) return false;
        
        // Apply category filter
        final categoryMatch = _selectedCategory == 'All' ||
            event.category.split(' ')[0] == _selectedCategory;
        
        if (!categoryMatch) return false;
        
        // Live events only filter
        if (_showLiveEventsOnly && !event.live) {
          return false;
        }
        
        // Available spots only filter
        if (_showAvailableOnly && event.attendees.length >= event.capacity) {
          return false;
        }
        
        // Price range filter
        if (event.price < _priceMin || event.price > _priceMax) {
          return false;
        }
        
        // Time/date filters
        if (!_matchesTimeFilter(event)) {
          return false;
        }
        
        // Apply distance filter based on selected distance filter
        if (_selectedDistanceFilter != 'All') {
          final eventCoords = _getEventCoordinates(event);
          final distance = _calculateDistance(
            _currentPosition.latitude,
            _currentPosition.longitude,
            eventCoords.latitude,
            eventCoords.longitude,
          );
          
          // Parse the selected distance (e.g., "5 mi" -> 5.0)
          final maxDistanceMi = double.tryParse(_selectedDistanceFilter.split(' ')[0]) ?? _maxDistance;
          
          if (distance > maxDistanceMi) return false;
        }
        
        // Apply general distance filter - use map center point
        final eventCoords = _getEventCoordinates(event);
        final distance = _calculateDistance(
          mapCenter.latitude,
          mapCenter.longitude,
          eventCoords.latitude,
          eventCoords.longitude,
        );
        
        // For events with generated locations (not real locations),
        // only include them if they have a valid location OR explicitly match the selected city
        final isRealLocation = event.location.latitude != 0 && event.location.longitude != 0;
        final cityMatch = event.address.toLowerCase().contains(selectedCity.toLowerCase());
        
        // If this is a real location (not 0,0), use it normally
        if (isRealLocation) {
          return distance <= _maxDistance;
        }
        
        // For generated locations, only include if the address actually mentions the city
        // or if the event has a known association with the selected city
        return (distance <= _maxDistance) && (cityMatch || _hasEventInCity(event, selectedCity));
      }).toList();
      
      // Update clusters after filtering
      _updateClusters();
    });
  }
  
  bool _matchesTimeFilter(event_class.Event event) {
    final now = DateTime.now();
    final eventTime = event.date;
    
    switch (_selectedTimeFilter) {
      case 'Today':
        return eventTime.year == now.year && 
               eventTime.month == now.month && 
               eventTime.day == now.day;
      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return eventTime.isAfter(startOfWeek) && eventTime.isBefore(endOfWeek);
      case 'This Weekend':
        final saturday = now.add(Duration(days: 6 - now.weekday));
        final sunday = saturday.add(const Duration(days: 1));
        return (eventTime.year == saturday.year && 
                eventTime.month == saturday.month && 
                eventTime.day == saturday.day) ||
               (eventTime.year == sunday.year && 
                eventTime.month == sunday.month && 
                eventTime.day == sunday.day);
      case 'Next Week':
        final nextWeekStart = now.add(Duration(days: 8 - now.weekday));
        final nextWeekEnd = nextWeekStart.add(const Duration(days: 6));
        return eventTime.isAfter(nextWeekStart) && eventTime.isBefore(nextWeekEnd);
      default:
        return true;
    }
  }
  
  // Helper method to determine if an event is actually in the selected city
  bool _hasEventInCity(event_class.Event event, String city) {
    // If city is "Near Me", we have no strict city requirement
    if (city == 'Near Me') return true;
    
    // Check if the event address contains the city name (case insensitive)
    // For compound city names like "New York City", also check "New York"
    final String citySearchTerm = city.contains(' ') ? city.split(' ')[0] : city;
    return event.address.toLowerCase().contains(citySearchTerm.toLowerCase());
  }

  void _moveToCity(String cityName) {
    final coordinates = cityCoordinates[cityName];
    if (coordinates != null) {
      setState(() {
        selectedCity = cityName;
        _currentPosition = coordinates;
        _mapController.move(coordinates, 12);
      });
      
      // Clear caches to ensure fresh coordinates and markers
      _coordinateCache.clear();
      _markerCache.clear();
      
      _filterEvents();
      
      Logger.d('Moved to city: $cityName', tag: 'Events_map_page');
      Logger.d('Filtered to ${_filteredEvents.length} events for this city', tag: 'Events_map_page');
    }
  }

  Widget _buildLocationSelector() {
    return GestureDetector(
      onTap: () {
        showCupertinoModalPopup(
          context: context,
          builder: (BuildContext context) => BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 400,
              padding: const EdgeInsets.only(top: 6.0),
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              color: context.watch<ThemeProvider>().isDarkMode
                  ? const Color(0xFF1C1C1E)
                  : CupertinoColors.white,
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: context.watch<ThemeProvider>().isDarkMode
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 17,
                                color: context.watch<ThemeProvider>().primaryColor,
                              ),
                            ),
                          ),
                          Text(
                            'Select Location',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: context.watch<ThemeProvider>().textColor,
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              _moveToCity(selectedCity);
                              Navigator.pop(context);
                              _filterEvents(); // Re-filter events after changing city
                            },
                            child: Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: context.watch<ThemeProvider>().primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        magnification: 1.22,
                        squeeze: 1.2,
                        useMagnifier: true,
                        itemExtent: 42,
                        scrollController: FixedExtentScrollController(
                          initialItem: cities.indexOf(selectedCity),
                        ),
                        onSelectedItemChanged: (int selectedItem) {
                          setState(() {
                            selectedCity = cities[selectedItem];
                            if (selectedCity == 'Near Me') {
                              _getCurrentLocation(); // Update current location and move map there
                            }
                          });
                        },
                        children: cities.map((String city) {
                          return Center(
                            child: Text(
                              city,
                              style: TextStyle(
                                fontSize: 20,
                                color: context.watch<ThemeProvider>().textColor,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.watch<ThemeProvider>().isDarkMode
              ? const Color(0xFF1C1C1E).withValues(alpha: 0.9)
              : CupertinoColors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.watch<ThemeProvider>().isDarkMode
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  CupertinoIcons.location_solid,
                  color: context.watch<ThemeProvider>().primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  LocationService.isUsingSimulatedLocation && selectedCity == 'Near Me'
                      ? 'Near Me (${LocationService.getCurrentSimulatedLocationName()})'
                      : selectedCity,
                  style: TextStyle(
                    fontSize: 17,
                    color: context.watch<ThemeProvider>().textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Icon(
              CupertinoIcons.chevron_down,
              color: context.watch<ThemeProvider>().textColor.withValues(alpha: 0.7),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Explore Events',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: context.watch<ThemeProvider>().isDarkMode
            ? kBackgroundDark.withValues(alpha: 0.9)
            : CupertinoColors.white.withValues(alpha: 0.9),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Location filter button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _showLocationFilter = true;
                });
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      kAccentColor.withValues(alpha: 0.2),
                      kAccentColor.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: kAccentColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  CupertinoIcons.location_circle,
                  color: kBackgroundLight,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Search button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _showSearchOverlay = true;
                });
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      kPrimaryColor.withValues(alpha: 0.2),
                      kPrimaryColor.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: kPrimaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  CupertinoIcons.search,
                  color: kBackgroundLight,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Advanced filters button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _showAdvancedFilters = true;
                });
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      kSecondaryColor.withValues(alpha: 0.2),
                      kSecondaryColor.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: kSecondaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        CupertinoIcons.slider_horizontal_3,
                        color: kBackgroundLight,
                        size: 18,
                      ),
                    ),
                    // Active indicator
                    if (_showLiveEventsOnly || _showAvailableOnly || _selectedTimeFilter != 'All Time')
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: kHighlightColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        border: null, // Remove border for cleaner look
      ),
      backgroundColor: context.watch<ThemeProvider>().isDarkMode
          ? kBackgroundDark
          : CupertinoColors.white,
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshEvents,
            color: kHighlightColor,
            backgroundColor: kBackgroundDark,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition,
                initialZoom: 11.0,
                minZoom: 3,
                maxZoom: 18,
                onMapEvent: (MapEvent event) {
                  if (event is MapEventMove) {
                    _handleMapMove(event);
                  }
                },
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.slotted.app',
                  retinaMode: false,
                  keepBuffer: 3,
                  tileProvider: NetworkTileProvider(),
                  additionalOptions: const {
                    'attribution': '© OpenStreetMap contributors',
                  },
                ),
                MarkerLayer(
                  markers: _enableClustering ? _buildClusteredMarkers() : _buildIndividualMarkers(),
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 24,
                      height: 24,
                      point: _currentPosition,
                      alignment: Alignment.center,
                      child: WidgetStructureHelper.safeRepaintBoundary(
                        Container(
                          decoration: BoxDecoration(
                            color: kAccentColor.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: kBackgroundLight,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimaryColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.location_fill,
                            color: kBackgroundDark,
                            size: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Location selector
          Positioned(
            top: 12, // Adjusted position to account for the navigation bar
            left: 0,
            right: 0,
            child: WidgetStructureHelper.safeRepaintBoundary(
              _buildLocationSelector(),
            ),
          ),

          // Move filter chips down to match new city selector position with adaptive spacing
          Positioned(
            top: _buildLocationSelectorHeight() + 100, // Increased from 36 to 100 to move bubbles lower on screen
            left: 0,
            right: 0,
            child: WidgetStructureHelper.safeRepaintBoundary(
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: _buildFilterChips(),
                ),
              ),
            ),
          ),

          if (_showTutorial)
            _buildTutorialOverlay(),
            
          // Search overlay
          if (_showSearchOverlay)
            _buildSearchOverlay(),
            
          // Location filter overlay
          if (_showLocationFilter)
            _buildLocationFilterOverlay(),
            
          // Advanced filters overlay
          if (_showAdvancedFilters)
            _buildAdvancedFiltersOverlay(),
            
          // Add loading indicator overlay
          if (_isLoading)
            Positioned.fill(
              child: WidgetStructureHelper.safeRepaintBoundary(
                Container(
                  color: kBackgroundDark.withValues(alpha: 0.7),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CupertinoActivityIndicator(
                          radius: 20,
                          color: kHighlightColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading Events...',
                          style: TextStyle(
                            color: kBackgroundLight.withValues(alpha: 0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
          if (_selectedEvent != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: WidgetStructureHelper.safeRepaintBoundary(
                GestureDetector(
                  onTap: () => _navigateToEventDetails(_selectedEvent!),
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          kPrimaryColor.withValues(alpha: 0.9),
                          kSecondaryColor.withValues(alpha: 0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: kBackgroundDark.withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _selectedEvent!.name,
                                style: const TextStyle(
                                  color: kBackgroundLight,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getCategoryColors(_selectedEvent!.category)[0],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _selectedEvent!.category,
                                    style: const TextStyle(
                                      color: kBackgroundLight,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedEvent = null;
                                    });
                                  },
                                  child: const Icon(
                                    CupertinoIcons.clear_circled_solid,
                                    color: kBackgroundLight,
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.person_fill,
                              color: kBackgroundLight,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _selectedEvent!.hostName,
                              style: TextStyle(
                                color: kBackgroundLight.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.calendar,
                                  color: kBackgroundLight,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatEventDate(_selectedEvent!.date),
                                  style: const TextStyle(
                                    color: kBackgroundLight,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              color: kHighlightColor,
                              borderRadius: BorderRadius.circular(12),
                              onPressed: () => _navigateToEventDetails(_selectedEvent!),
                              child: Text(
                                _selectedEvent!.live ? 'Join Now' : 'View Details',
                                style: const TextStyle(
                                  color: kPrimaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper method to format date
  String _formatEventDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final eventDate = DateTime(date.year, date.month, date.day);
    
    if (eventDate == today) {
      return 'Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (eventDate == tomorrow) {
      return 'Tomorrow, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.month}/${date.day}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildTutorialOverlay() {
    final step = _tutorialSteps[_currentTutorialStep];
    final screenSize = MediaQuery.of(context).size;
    
    Widget tutorialCard = Container(
      width: screenSize.width * 0.85,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kPrimaryColor.withValues(alpha: 0.9),
            kSecondaryColor.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kBackgroundDark.withValues(alpha: 0.5),
            blurRadius: 15,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            step['icon'],
            color: kBackgroundLight,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            step['title'],
            style: const TextStyle(
              color: kBackgroundLight,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            step['description'],
            style: TextStyle(
              color: kBackgroundLight.withValues(alpha: 0.9),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _skipTutorial,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: kBackgroundLight.withValues(alpha: 0.8),
                    fontSize: 16,
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  _tutorialSteps.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentTutorialStep == index
                          ? kHighlightColor
                          : kBackgroundLight.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _nextTutorialStep,
                child: Text(
                  _currentTutorialStep == _tutorialSteps.length - 1 ? 'Done' : 'Next',
                  style: const TextStyle(
                    color: kHighlightColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    
    // Position the tutorial card based on the step
    switch (step['position']) {
      case 'top-left':
        return Stack(
          children: [
            GestureDetector(
              onTap: _nextTutorialStep,
              child: Container(
                color: kBackgroundDark.withValues(alpha: 0.7),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              top: 70,
              left: 20,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  tutorialCard,
                  Positioned(
                    top: -15,
                    left: 20,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case 'top-right':
        return Stack(
          children: [
            GestureDetector(
              onTap: _nextTutorialStep,
              child: Container(
                color: kBackgroundDark.withValues(alpha: 0.7),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              top: 70,
              right: 20,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  tutorialCard,
                  Positioned(
                    top: -15,
                    right: 20,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case 'bottom':
        return Stack(
          children: [
            GestureDetector(
              onTap: _nextTutorialStep,
              child: Container(
                color: kBackgroundDark.withValues(alpha: 0.7),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              bottom: 100,
              left: (screenSize.width - screenSize.width * 0.85) / 2,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  tutorialCard,
                  Positioned(
                    bottom: -15,
                    left: screenSize.width * 0.85 / 2 - 15,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case 'center':
      default:
        return Stack(
          children: [
            GestureDetector(
              onTap: _nextTutorialStep,
              child: Container(
                color: kBackgroundDark.withValues(alpha: 0.7),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Center(
              child: tutorialCard,
            ),
          ],
        );
    }
  }



  List<Widget> _buildFilterChips() {
    final chips = <Widget>[];
    
    // Add location filter chip if active
    if (_selectedDistanceFilter != 'All') {
      chips.add(_buildLocationFilterChip());
      chips.add(const SizedBox(width: 8));
    }
    
    // Add category filter chips
    chips.addAll(['All', 'Comedy', 'DJ', 'Poetry', 'Music'].map((category) {
      final isSelected = _selectedCategory == category;
      final colors = category == 'All' 
          ? [kPrimaryColor, kSecondaryColor] 
          : _getCategoryColors(category);
      
      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategory = category;
          });
          _filterEvents();
        },
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors[0],
                      colors[1],
                    ],
                  )
                : null,
            color: isSelected ? null : kBackgroundDark.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? kBackgroundLight : colors[0].withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colors[0].withValues(alpha: 0.12),
                blurRadius: 4,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (category != 'All')
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    _getCategoryIcon(category),
                    color: isSelected ? kBackgroundLight : colors[0],
                    size: 16,
                  ),
                ),
              Text(
                category,
                style: TextStyle(
                  color: isSelected ? kBackgroundLight : colors[0],
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      );
    }));
    
    return chips;
  }

  Widget _buildLocationFilterChip() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _showLocationFilter = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kAccentColor.withValues(alpha: 0.8),
              kAccentColor.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: kBackgroundLight,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: kAccentColor.withValues(alpha: 0.3),
              blurRadius: 4,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.location_circle_fill,
              color: kBackgroundLight,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              _selectedDistanceFilter,
              style: const TextStyle(
                color: kBackgroundLight,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.xmark_circle_fill,
              color: kBackgroundLight.withValues(alpha: 0.8),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getCategoryColors(String category) {
    final categoryUpper = category.toUpperCase();
    switch (categoryUpper) {
      case 'COMEDY':
        return [const Color(0xFFDC2626), const Color(0xFFEF4444)]; // Red
      case 'DJ':
        return [const Color(0xFF2563EB), const Color(0xFF3B82F6)]; // Blue
      case 'POETRY':
        return [const Color(0xFFD97706), const Color(0xFFF59E0B)]; // Amber
      case 'MUSIC':
        return [const Color(0xFF7C3AED), const Color(0xFF8B5CF6)]; // Purple
      case 'OTHER':
        return [const Color(0xFF059669), const Color(0xFF10B981)]; // Green
      default:
        return [kPrimaryColor, kSecondaryColor];
    }
  }

  IconData _getCategoryIcon(String category) {
    return AppColors.getCategoryIconCupertino(category);
  }

  void _navigateToEventDetails(event_class.Event event) {
    if (event.live) {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => LivePage(
            event: event,
            debug: widget.debug,
            user: widget.user,
            authAction: widget.authAction,
            reserveAction: widget.reserveAction,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => EventDetailsPage(
            initialEvent: event,
            debug: widget.debug,
            authAction: widget.authAction,
          ),
        ),
      );
    }
  }
  


  // Show a banner indicating we're using simulated location
  void _showSimulatedLocationBanner() {
    final locationName = LocationService.getCurrentSimulatedLocationName();
    
    // Create a custom location picker button
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use showCupertinoModalPopup instead of SnackBar since this is a Cupertino app
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Row(
            children: [
              const Icon(
                CupertinoIcons.location_fill,
                color: kPrimaryColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text('Using simulated location: $locationName'),
            ],
          ),
          content: const Text(
            'You can change the simulated location for testing.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Change Location'),
              onPressed: () {
                Navigator.of(context).pop();
                _showLocationSelectionDialog();
              },
            ),
            CupertinoDialogAction(
              child: const Text('Dismiss'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    });
  }
  
  // Show a dialog to select a simulated location
  void _showLocationSelectionDialog() {
    if (!LocationService.isUsingSimulatedLocation) return;
    
    final locations = LocationService.getAvailableSimulatedLocations();
    final currentLocation = LocationService.getCurrentSimulatedLocationName();
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Select Simulated Location'),
        content: SizedBox(
          height: 200,
          child: CupertinoScrollbar(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: locations.map((location) {
                  final isSelected = location == currentLocation;
                  return CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    onPressed: () async {
                      final navigatorContext = context;
                      await LocationService.setSimulatedLocation(location);
                      if (mounted && navigatorContext.mounted) {
                        Navigator.pop(navigatorContext);
                        await _getCurrentLocation();
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          location,
                          style: TextStyle(
                            color: isSelected ? kPrimaryColor : null,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            CupertinoIcons.check_mark,
                            color: kPrimaryColor,
                            size: 18,
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // Calculate the height of the location selector for better positioning
  double _buildLocationSelectorHeight() {
    // Approximate height based on content and padding
    return 46; // Adjusted from 50 to 46 for more precise calculation
  }

  // Enhanced search functionality
  Widget _buildSearchOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          // Tap anywhere on background to dismiss search
          HapticFeedback.lightImpact();
          _closeSearch();
        },
        child: Container(
          color: kBackgroundDark.withValues(alpha: 0.98),
          child: SafeArea(
            child: Column(
              children: [
                // Search header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _closeSearch();
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                kPrimaryColor.withValues(alpha: 0.3),
                                kPrimaryColor.withValues(alpha: 0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: kPrimaryColor.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            CupertinoIcons.xmark,
                            color: kBackgroundLight,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Search field
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: kPrimaryColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: CupertinoTextField(
                            controller: _searchController,
                            placeholder: 'Search events, hosts, locations...',
                            placeholderStyle: TextStyle(
                              color: kBackgroundLight.withValues(alpha: 0.6),
                              fontSize: 16,
                            ),
                            style: const TextStyle(
                              color: kBackgroundLight,
                              fontSize: 16,
                            ),
                            decoration: const BoxDecoration(),
                            prefix: Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Icon(
                                CupertinoIcons.search,
                                color: kBackgroundLight.withValues(alpha: 0.6),
                                size: 20,
                              ),
                            ),
                            suffix: _searchController.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      _performSearch('');
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Icon(
                                        CupertinoIcons.clear_circled_solid,
                                        color: kBackgroundLight.withValues(alpha: 0.6),
                                        size: 20,
                                      ),
                                    ),
                                  )
                                : null,
                            onChanged: _performSearch,
                            autofocus: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Search results
                Expanded(
                  child: _buildSearchResults(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchController.text.isEmpty) {
      return _buildSearchSuggestions();
    }

    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(
              radius: 16,
              color: kHighlightColor,
            ),
            SizedBox(height: 16),
            Text(
              'Searching...',
              style: TextStyle(
                color: kBackgroundLight,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.search,
              size: 64,
              color: kBackgroundLight.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No events found',
              style: TextStyle(
                color: kBackgroundLight.withValues(alpha: 0.8),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                color: kBackgroundLight.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final event = _searchResults[index];
        return _buildSearchResultCard(event);
      },
    );
  }

  Widget _buildSearchSuggestions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Suggestions',
            style: TextStyle(
              color: kBackgroundLight.withValues(alpha: 0.8),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSuggestionChip('Comedy'),
              _buildSuggestionChip('Music'),
              _buildSuggestionChip('DJ'),
              _buildSuggestionChip('Poetry'),
              _buildSuggestionChip('Tonight'),
              _buildSuggestionChip('This Weekend'),
              _buildSuggestionChip('Near Me'),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Popular Categories',
            style: TextStyle(
              color: kBackgroundLight.withValues(alpha: 0.8),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap on map pins to explore events',
            style: TextStyle(
              color: kBackgroundLight.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String suggestion) {
    return GestureDetector(
      onTap: () {
        _searchController.text = suggestion;
        _performSearch(suggestion);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: kPrimaryColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: kPrimaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          suggestion,
          style: TextStyle(
            color: kBackgroundLight.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(event_class.Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kPrimaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          HapticFeedback.lightImpact();
          _closeSearch();
          setState(() {
            _selectedEvent = event;
          });
          final coordinates = _getEventCoordinates(event);
          _mapController.move(coordinates, 12);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Event category icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _getCategoryColors(event.category)[0].withValues(alpha: 0.2),
                ),
                child: Icon(
                  _getCategoryIcon(event.category),
                  color: _getCategoryColors(event.category)[0],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Event details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: const TextStyle(
                        color: kBackgroundLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.hostName.isNotEmpty ? 'by ${event.hostName}' : 'Unknown Host',
                      style: TextStyle(
                        color: kBackgroundLight.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.calendar,
                          size: 14,
                          color: kBackgroundLight.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatEventDate(event.date),
                          style: TextStyle(
                            color: kBackgroundLight.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          CupertinoIcons.location,
                          size: 14,
                          color: kBackgroundLight.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.address.isNotEmpty ? event.address : 'Location TBA',
                            style: TextStyle(
                              color: kBackgroundLight.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Category badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColors(event.category)[0].withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  event.category.toUpperCase(),
                  style: TextStyle(
                    color: _getCategoryColors(event.category)[0],
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _closeSearch() {
    setState(() {
      _showSearchOverlay = false;
      _searchController.clear();
      _searchResults.clear();
      _isSearching = false;
    });
  }

  Future<void> _refreshEvents() async {
    HapticFeedback.lightImpact();
    
    // Add a small delay for better UX
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Refresh events
    await _fetchEvents();
  }

  Widget _buildLocationFilterOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _closeLocationFilter();
        },
        child: Container(
          color: kBackgroundDark.withValues(alpha: 0.95),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _closeLocationFilter();
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                kAccentColor.withValues(alpha: 0.3),
                                kAccentColor.withValues(alpha: 0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: kAccentColor.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            CupertinoIcons.xmark,
                            color: kBackgroundLight,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Location Filter',
                              style: TextStyle(
                                color: kBackgroundLight,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Filter events by distance from your location',
                              style: TextStyle(
                                color: kBackgroundLight.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Current location info
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kAccentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kAccentColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.location_solid,
                        color: kAccentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Location',
                              style: TextStyle(
                                color: kBackgroundLight,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              LocationService.isUsingSimulatedLocation && selectedCity == 'Near Me'
                                  ? 'Near Me (${LocationService.getCurrentSimulatedLocationName()})'
                                  : selectedCity,
                              style: TextStyle(
                                color: kBackgroundLight.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Distance options
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _distanceOptions.length,
                    itemBuilder: (context, index) {
                      final option = _distanceOptions[index];
                      final isSelected = _selectedDistanceFilter == option;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedDistanceFilter = option;
                            });
                            _filterEvents();
                            _closeLocationFilter();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        kAccentColor.withValues(alpha: 0.3),
                                        kAccentColor.withValues(alpha: 0.2),
                                      ],
                                    )
                                  : null,
                              color: isSelected ? null : kPrimaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                    ? kAccentColor.withValues(alpha: 0.5)
                                    : kPrimaryColor.withValues(alpha: 0.2),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  option == 'All' 
                                      ? CupertinoIcons.globe
                                      : CupertinoIcons.location_circle,
                                  color: isSelected 
                                      ? kAccentColor 
                                      : kBackgroundLight.withValues(alpha: 0.7),
                                  size: 20,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option == 'All' ? 'Show All Events' : 'Within $option',
                                        style: TextStyle(
                                          color: kBackgroundLight,
                                          fontSize: 16,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        ),
                                      ),
                                      if (option != 'All') ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Events within ${option.toLowerCase()} from your location',
                                          style: TextStyle(
                                            color: kBackgroundLight.withValues(alpha: 0.6),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    CupertinoIcons.check_mark_circled_solid,
                                    color: kAccentColor,
                                    size: 24,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Active filter indicator
                if (_selectedDistanceFilter != 'All')
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kHighlightColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: kHighlightColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.info_circle,
                          color: kHighlightColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Showing events within $_selectedDistanceFilter',
                            style: TextStyle(
                              color: kBackgroundLight.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _closeLocationFilter() {
    setState(() {
      _showLocationFilter = false;
    });
  }
  
  Widget _buildAdvancedFiltersOverlay() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: kBackgroundDark.withValues(alpha: 0.85),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _showAdvancedFilters = false;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: kPrimaryColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            CupertinoIcons.xmark,
                            color: kBackgroundLight,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Advanced Filters',
                        style: TextStyle(
                          color: kBackgroundLight,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _resetAdvancedFilters();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: kHighlightColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: kHighlightColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              color: kHighlightColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Filters content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick filters
                        _buildQuickFilters(),
                        const SizedBox(height: 24),
                        
                        // Price range
                        _buildPriceRangeFilter(),
                        const SizedBox(height: 24),
                        
                        // Time filters
                        _buildTimeFilters(),
                        const SizedBox(height: 24),
                        
                        // Event status filters
                        _buildStatusFilters(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuickFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Filters',
          style: TextStyle(
            color: kBackgroundLight,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildToggleFilter(
              'Live Now',
              _showLiveEventsOnly,
              CupertinoIcons.dot_radiowaves_left_right,
              (value) => setState(() => _showLiveEventsOnly = value),
            ),
            const SizedBox(width: 12),
            _buildToggleFilter(
              'Available',
              _showAvailableOnly,
              CupertinoIcons.checkmark_circle,
              (value) => setState(() => _showAvailableOnly = value),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildToggleFilter(String label, bool isActive, IconData icon, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!isActive);
        _filterEvents();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kAccentColor.withValues(alpha: 0.8),
                    kAccentColor.withValues(alpha: 0.6),
                  ],
                )
              : null,
          color: isActive ? null : kPrimaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive 
                ? kAccentColor.withValues(alpha: 0.5)
                : kPrimaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? kBackgroundLight : kAccentColor,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? kBackgroundLight : kAccentColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPriceRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price Range',
          style: TextStyle(
            color: kBackgroundLight,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kPrimaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: kPrimaryColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${_priceMin.toInt()}',
                    style: const TextStyle(
                      color: kBackgroundLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '\$${_priceMax.toInt()}+',
                    style: const TextStyle(
                      color: kBackgroundLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Note: For now showing text input since custom range slider is complex
              Text(
                'Showing events from \$${_priceMin.toInt()} to \$${_priceMax.toInt()}',
                style: TextStyle(
                  color: kBackgroundLight.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTimeFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'When',
          style: TextStyle(
            color: kBackgroundLight,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _timeFilters.map((timeFilter) {
            final isSelected = _selectedTimeFilter == timeFilter;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedTimeFilter = timeFilter;
                });
                _filterEvents();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            kSecondaryColor.withValues(alpha: 0.8),
                            kSecondaryColor.withValues(alpha: 0.6),
                          ],
                        )
                      : null,
                  color: isSelected ? null : kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected 
                        ? kSecondaryColor.withValues(alpha: 0.5)
                        : kPrimaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  timeFilter,
                  style: TextStyle(
                    color: isSelected ? kBackgroundLight : kSecondaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildStatusFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Event Status',
          style: TextStyle(
            color: kBackgroundLight,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kPrimaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: kPrimaryColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Clustering',
                    style: TextStyle(
                      color: kBackgroundLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _enableClustering = !_enableClustering;
                      });
                      _updateClusters();
                    },
                    child: Container(
                      width: 50,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _enableClustering ? kAccentColor : kBackgroundDark.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        alignment: _enableClustering ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          width: 26,
                          height: 26,
                          margin: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: kBackgroundLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _enableClustering 
                    ? 'Events are grouped when close together'
                    : 'All events shown individually',
                style: TextStyle(
                  color: kBackgroundLight.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  void _resetAdvancedFilters() {
    setState(() {
      _showLiveEventsOnly = false;
      _showAvailableOnly = false;
      _priceMin = 0;
      _priceMax = 200;
      _selectedTimeFilter = 'All Time';
      _enableClustering = true;
    });
    _filterEvents();
  }

  void _performSearch(String searchTerm) async {
    if (searchTerm.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Filter events based on search term
      final results = _events.where((event) {
        final searchLower = searchTerm.toLowerCase();
        return event.name.toLowerCase().contains(searchLower) ||
               event.description.toLowerCase().contains(searchLower) ||
               event.category.toLowerCase().contains(searchLower) ||
               event.hostName.toLowerCase().contains(searchLower) ||
               event.address.toLowerCase().contains(searchLower);
      }).toList();

      // Sort by relevance (events starting with search term first, then by date)
      results.sort((a, b) {
        final aStartsWith = a.name.toLowerCase().startsWith(searchTerm.toLowerCase());
        final bStartsWith = b.name.toLowerCase().startsWith(searchTerm.toLowerCase());
        
        if (aStartsWith && !bStartsWith) return -1;
        if (!aStartsWith && bStartsWith) return 1;
        
        return a.date.compareTo(b.date);
      });

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      Logger.d('Error performing search: $e', tag: 'Events_map_page');
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
    }
  }

} 