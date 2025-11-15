import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slotted/api/notification_service.dart';
import 'package:slotted/utils/logger.dart';

/// Enhanced notification service with smart, location-based, and personalized notifications
class SmartNotificationService {
  static final SmartNotificationService _instance = SmartNotificationService._internal();
  static SmartNotificationService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService.instance;

  // Smart notification settings
  bool _locationBasedNotifications = true;
  bool _personalizedSuggestions = true;
  bool _smartTimingEnabled = true;
  double _notificationRadiusKm = 5.0; // 5km radius for location-based notifications
  
  // User preferences and history
  List<String> _preferredCategories = [];
  List<String> _preferredTimes = [];
  Map<String, int> _categoryInteractions = {};
  
  // Location tracking
  Timer? _locationTimer;
  Timer? _suggestionTimer;

  SmartNotificationService._internal();

  /// Initialize smart notification service
  Future<void> initialize() async {
    try {
      await _loadSmartPreferences();
      await _initializeLocationTracking();
      _startSmartSuggestionTimer();
      Logger.i('Smart notification service initialized', tag: 'SmartNotifications');
    } catch (e) {
      Logger.e('Error initializing smart notifications: $e', tag: 'SmartNotifications');
    }
  }

  /// Load smart notification preferences
  Future<void> _loadSmartPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _locationBasedNotifications = prefs.getBool('location_based_notifications') ?? true;
    _personalizedSuggestions = prefs.getBool('personalized_suggestions') ?? true;
    _smartTimingEnabled = prefs.getBool('smart_timing_enabled') ?? true;
    _notificationRadiusKm = prefs.getDouble('notification_radius_km') ?? 5.0;
    
    // Load user preferences
    _preferredCategories = prefs.getStringList('preferred_categories') ?? [];
    _preferredTimes = prefs.getStringList('preferred_times') ?? [];
    
    // Load interaction history
    final interactionData = prefs.getString('category_interactions');
    if (interactionData != null) {
      try {
        // Parse stored interaction data (simplified for now)
        _categoryInteractions = {}; // Could load from JSON if needed
      } catch (e) {
        Logger.w('Could not load interaction data: $e', tag: 'SmartNotifications');
      }
    }
  }

  /// Initialize location tracking for proximity notifications
  Future<void> _initializeLocationTracking() async {
    if (!_locationBasedNotifications) return;

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        // Start periodic location updates (every 5 minutes)
        _locationTimer = Timer.periodic(const Duration(minutes: 5), (_) {
          _updateLocationAndCheckNearbyEvents();
        });
      }
    } catch (e) {
      Logger.w('Could not initialize location tracking: $e', tag: 'SmartNotifications');
    }
  }

  /// Update location and check for nearby events
  Future<void> _updateLocationAndCheckNearbyEvents() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      // Check for nearby events
      await _checkNearbyEvents(position);
    } catch (e) {
      Logger.w('Error updating location: $e', tag: 'SmartNotifications');
    }
  }

  /// Check for events near user's current location
  Future<void> _checkNearbyEvents(Position userPosition) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Query events in the area (simplified - in production would use geohashing)
      // Use a simpler query that doesn't require a composite index
      final eventsQuery = await _firestore
          .collection('events')
          .where('date', isGreaterThan: DateTime.now())
          .limit(20)
          .get();

      for (final doc in eventsQuery.docs) {
        final eventData = doc.data();
        final eventId = doc.id;
        final eventStatus = eventData['status'] ?? '';
        
        // Skip inactive events
        if (eventStatus != 'active') continue;
        
        final eventName = eventData['name'] ?? 'Event';
        final eventCategory = eventData['category'] ?? 'General';
        final latitude = eventData['latitude'] as double?;
        final longitude = eventData['longitude'] as double?;
        final attendeeCount = eventData['attendeeCount'] ?? 0;
        final maxAttendees = eventData['maxAttendees'] ?? 10;
        
        // Calculate distance to event
        if (latitude != null && longitude != null) {
          final distance = Geolocator.distanceBetween(
            userPosition.latitude,
            userPosition.longitude,
            latitude,
            longitude,
          ) / 1000; // Convert to kilometers

          // If event is within notification radius and user isn't already attending
          if (distance <= _notificationRadiusKm) {
            await _checkAndSendNearbyEventNotification(
              eventId, eventName, eventCategory, distance, attendeeCount, maxAttendees);
          }
        }
      }
    } catch (e) {
      Logger.w('Error checking nearby events: $e', tag: 'SmartNotifications');
    }
  }

  /// Send notification for nearby events (with smart timing)
  Future<void> _checkAndSendNearbyEventNotification(
    String eventId, String eventName, String eventCategory, double distance, int attendeeCount, int maxAttendees) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check if user is already registered for this event
      final attendeeDoc = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('attendees')
          .doc(user.uid)
          .get();

      if (attendeeDoc.exists) return; // User already registered

      // Check if we've already sent a notification for this event recently
      final prefs = await SharedPreferences.getInstance();
      final sentKey = 'nearby_notification_$eventId';
      final lastSent = prefs.getInt(sentKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Don't send more than once per day for the same event
      if (now - lastSent < 24 * 60 * 60 * 1000) return;

      // Calculate optimal notification timing based on user behavior
      if (_shouldSendNearbyNotification(eventCategory, distance)) {
        await _sendNearbyEventNotification(eventId, eventName, distance, attendeeCount, maxAttendees);
        await prefs.setInt(sentKey, now);
      }
    } catch (e) {
      Logger.w('Error sending nearby event notification: $e', tag: 'SmartNotifications');
    }
  }

  /// Determine if we should send a nearby event notification based on smart timing
  bool _shouldSendNearbyNotification(String eventCategory, double distance) {
    if (!_smartTimingEnabled) return true;

    final now = DateTime.now();
    final hour = now.hour;

    // Don't send notifications during quiet hours (10 PM - 8 AM)
    if (hour >= 22 || hour < 8) return false;

    // Higher relevance for preferred categories
    final categoryRelevance = _preferredCategories.contains(eventCategory) ? 2.0 : 1.0;
    
    // Higher relevance for closer events
    final distanceRelevance = distance < 1.0 ? 2.0 : (distance < 3.0 ? 1.5 : 1.0);
    
    // Higher relevance during preferred times
    final timeRelevance = _preferredTimes.contains('$hour:00') ? 1.5 : 1.0;

    final relevanceScore = categoryRelevance * distanceRelevance * timeRelevance;
    
    // Send if relevance score is above threshold
    return relevanceScore >= 1.5;
  }

  /// Send notification for nearby event
  Future<void> _sendNearbyEventNotification(String eventId, String eventName, double distance, int attendeeCount, int maxAttendees) async {
    final distanceText = distance < 1.0 
        ? '${(distance * 1000).round()}m away'
        : '${distance.toStringAsFixed(1)}km away';

    await _notificationService.showCustomNotification(
      id: 40000 + Random().nextInt(9999),
      title: '🌟 Event Near You!',
      body: '$eventName is $distanceText. $attendeeCount/$maxAttendees spots filled.',
      payload: eventId,
      channelId: 'nearby_events',
      channelName: 'Nearby Events',
      channelDescription: 'Notifications for events near your location',
    );

    // Track interaction for personalization
    _trackCategoryInteraction(eventName.split(' ').first); // Simple category tracking
  }

  /// Start timer for personalized suggestions
  void _startSmartSuggestionTimer() {
    if (!_personalizedSuggestions) return;

    // Send personalized suggestions twice a week
    _suggestionTimer = Timer.periodic(const Duration(days: 3), (_) {
      _sendPersonalizedSuggestions();
    });
  }

  /// Send personalized event suggestions based on user behavior
  Future<void> _sendPersonalizedSuggestions() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get user's event history to learn preferences
      final userEvents = await _firestore
          .collection('events')
          .where('attendees', arrayContains: user.uid)
          .orderBy('date', descending: true)
          .limit(10)
          .get();

      // Analyze patterns
      final preferredCategories = <String, int>{};
      final preferredTimes = <int, int>{};
      
      for (final doc in userEvents.docs) {
        final eventData = doc.data();
        final category = eventData['category'] ?? 'General';
        final date = (eventData['date'] as Timestamp).toDate();
        preferredCategories[category] = (preferredCategories[category] ?? 0) + 1;
        preferredTimes[date.hour] = (preferredTimes[date.hour] ?? 0) + 1;
      }

      // Find events matching user preferences
      if (preferredCategories.isNotEmpty) {
        final topCategory = preferredCategories.entries.reduce((a, b) => a.value > b.value ? a : b).key;
        await _findAndSuggestSimilarEvents(topCategory);
      }
    } catch (e) {
      Logger.w('Error sending personalized suggestions: $e', tag: 'SmartNotifications');
    }
  }

  /// Find and suggest events similar to user preferences
  Future<void> _findAndSuggestSimilarEvents(String preferredCategory) async {
    try {
      final upcomingEvents = await _firestore
          .collection('events')
          .where('category', isEqualTo: preferredCategory)
          .where('status', isEqualTo: 'active')
          .where('date', isGreaterThan: DateTime.now())
          .where('attendeeCount', isLessThan: 10) // Focus on events with availability
          .limit(5)
          .get();

      if (upcomingEvents.docs.isNotEmpty) {
        final eventData = upcomingEvents.docs.first.data();
        final eventId = upcomingEvents.docs.first.id;
        final eventName = eventData['name'] ?? 'Event';
        
        await _notificationService.showCustomNotification(
          id: 50000 + Random().nextInt(9999),
          title: '💡 Perfect Match!',
          body: 'New $preferredCategory event: $eventName. Based on your interests!',
          payload: eventId,
          channelId: 'personalized_suggestions',
          channelName: 'Personalized Suggestions',
          channelDescription: 'Event suggestions based on your preferences',
        );
      }
    } catch (e) {
      Logger.w('Error finding similar events: $e', tag: 'SmartNotifications');
    }
  }

  /// Track user interaction with event categories for personalization
  void _trackCategoryInteraction(String category) {
    _categoryInteractions[category] = (_categoryInteractions[category] ?? 0) + 1;
    _saveInteractionData();
  }

  /// Save interaction data for future personalization
  Future<void> _saveInteractionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Simple storage - in production might use more sophisticated approach
      final topCategories = _categoryInteractions.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
      
      await prefs.setStringList('top_categories', 
          topCategories
              .take(5)
              .map((e) => e.key)
              .toList());
    } catch (e) {
      Logger.w('Error saving interaction data: $e', tag: 'SmartNotifications');
    }
  }

  /// Enable/disable location-based notifications
  Future<void> setLocationBasedNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_based_notifications', enabled);
    _locationBasedNotifications = enabled;

    if (enabled) {
      await _initializeLocationTracking();
    } else {
      _locationTimer?.cancel();
      _locationTimer = null;
    }
  }

  /// Enable/disable personalized suggestions
  Future<void> setPersonalizedSuggestions(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('personalized_suggestions', enabled);
    _personalizedSuggestions = enabled;

    if (enabled) {
      _startSmartSuggestionTimer();
    } else {
      _suggestionTimer?.cancel();
      _suggestionTimer = null;
    }
  }

  /// Set notification radius for location-based notifications
  Future<void> setNotificationRadius(double radiusKm) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('notification_radius_km', radiusKm);
    _notificationRadiusKm = radiusKm;
  }

  /// Getters for settings
  bool get isLocationBasedEnabled => _locationBasedNotifications;
  bool get isPersonalizedSuggestionsEnabled => _personalizedSuggestions;
  bool get isSmartTimingEnabled => _smartTimingEnabled;
  double get notificationRadiusKm => _notificationRadiusKm;

  /// Cleanup when service is disposed
  void dispose() {
    _locationTimer?.cancel();
    _suggestionTimer?.cancel();
  }
}
