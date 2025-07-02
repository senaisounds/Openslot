import 'dart:async';
import 'package:flutter/material.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/utils/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:slotted/utils/event_cache_service.dart';
import 'package:flutter/services.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  // Constants
  static const String _appDomain = 'openslot.app'; // Updated to use new app domain name
  
  // For App Links/Universal Links config
  static const String _appScheme = 'openslot';

  // Platform channel for handling deep links
  static const MethodChannel _channel = MethodChannel('app.openslot/deep_links');
  
  // For handling URI streams
  final StreamController<String> _deepLinkStreamController = StreamController<String>.broadcast();
  Stream<String> get deepLinkStream => _deepLinkStreamController.stream;

  // Event handler callback
  Function(Event event)? _eventOpenedCallback;
  void setEventOpenedCallback(Function(Event event) callback) {
    _eventOpenedCallback = callback;
  }

  /// Initialize deep linking
  Future<void> initialize() async {
    try {
      // Set up platform channel method handler
      _channel.setMethodCallHandler((MethodCall call) async {
        try {
          if (call.method == 'handleDeepLink') {
            final String link = call.arguments as String;
            _handleIncomingLink(link);
          }
        } catch (e) {
          Logger.d('Error handling method call: $e', tag: 'DeepLinkService');
        }
      });
      
      // Check for any initial link
      try {
        final String? initialLink = await _channel.invokeMethod<String>('getInitialLink');
        if (initialLink != null && initialLink.isNotEmpty) {
          _handleIncomingLink(initialLink);
        }
      } catch (e) {
        // Silently handle cases where initial link method isn't available
        Logger.d('Initial link not available: $e', tag: 'DeepLinkService');
      }
    } catch (e) {
      Logger.d('Error initializing deep links: $e', tag: 'DeepLinkService');
    }
  }

  /// Dispose resources
  void dispose() {
    _deepLinkStreamController.close();
  }

  /// Create a deep link for an event
  Future<String> createEventShareLink(Event event) async {
    final String eventId = event.id;
    if (eventId.isEmpty) {
      throw Exception('Cannot create link for event with empty ID');
    }

    // Create a standard web URL - Universal Links/App Links will handle redirection
    final String linkUrl = 'https://$_appDomain/event/$eventId';
    
    return linkUrl;
  }

  /// Share an event using platform share dialog
  Future<void> shareEvent(Event event, BuildContext context) async {
    final String shareLink = await createEventShareLink(event);
    
    final String shareText = 'Check out "${event.name}" on Open Slot!\n\n$shareLink';
    
    // Use SharePlus instance with ShareParams
    await SharePlus.instance.share(
      ShareParams(
        text: shareText,
        subject: 'Join me at ${event.name}',
      ),
    );
  }

  /// Handle an incoming deep link
  void _handleIncomingLink(String link) async {
    Logger.d('Received deep link: $link', tag: 'DeepLinkService');
    
    // Extract event ID from URL
    try {
      final Uri uri = Uri.parse(link);
      
      // For App/Universal Links (https://openslot.app/event/123)
      if (uri.host == _appDomain && 
          uri.pathSegments.length >= 2 && 
          uri.pathSegments[0] == 'event') {
        _handleEventLink(uri.pathSegments[1]);
      } 
      // For custom scheme (openslot://event/123)
      else if (uri.scheme == _appScheme && 
               uri.host == 'event' && 
               uri.pathSegments.isNotEmpty) {
        _handleEventLink(uri.pathSegments[0]);
      }
    } catch (e) {
      Logger.d('Error handling deep link: $e', tag: 'DeepLinkService');
    }
  }
  
  /// Handle event link after ID extraction
  void _handleEventLink(String eventId) async {
    // Broadcast the event ID
    _deepLinkStreamController.add(eventId);
    
    // Load the event data
    final Event? event = await getEventById(eventId);
    if (event != null && _eventOpenedCallback != null) {
      _eventOpenedCallback!(event);
    }
  }

  /// Get an event by ID from Firestore
  Future<Event?> getEventById(String eventId) async {
    try {
      // First check if we have the event in the local cache
      final cacheService = EventCacheService.instance;
      final cachedEvents = await cacheService.getCachedEvents();
      final cachedEvent = cachedEvents.firstWhere(
        (event) => event.id == eventId,
        orElse: () => Event.empty(),
      );
      
      // If we found a valid cached event, return it
      if (cachedEvent.id == eventId) {
        Logger.d('Retrieved event $eventId from cache', tag: 'DeepLinkService');
        return cachedEvent;
      }
      
      // If not in cache, fetch from Firestore
      final docSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();
      
      if (docSnapshot.exists) {
        final event = Event.fromDocument(docSnapshot);
        
        // Cache the event for future use
        await cacheService.cacheEvent(event);
        
        return event;
      }
      return null;
    } catch (e) {
      Logger.d('Error getting event: $e', tag: 'DeepLinkService');
      return null;
    }
  }


}

/// Types of deep links the app can handle
enum DeepLinkType {
  home,
  events,
  event,
  profile,
  myProfile,
  other,
}

/// Data structure for deep link information
class DeepLinkData {
  final DeepLinkType type;
  final String? eventId;
  final String? userId;
  final Map<String, dynamic>? extraData;
  
  DeepLinkData({
    required this.type,
    this.eventId,
    this.userId,
    this.extraData,
  });
  
  @override
  String toString() {
    return 'DeepLinkData(type: $type, eventId: $eventId, userId: $userId, extraData: $extraData)';
  }
} 