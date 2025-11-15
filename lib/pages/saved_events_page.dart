import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:provider/provider.dart';
import 'package:slotted/api/firebase_auth_service.dart';
import 'package:slotted/common/colors.dart' as app_colors;
import 'package:slotted/common/event_class.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:slotted/pages/event_details.dart';
import 'package:slotted/providers/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:slotted/utils/logger.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:slotted/utils/connectivity_service.dart';
import 'package:slotted/utils/event_cache_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:slotted/widgets/enhanced_event_card.dart';
import 'package:slotted/utils/safe_state_mixin.dart';

// Custom painter for grid pattern - moved outside the class
class GridPainter extends CustomPainter {
  final double gridSpacing;
  final Color lineColor;
  
  GridPainter({
    required this.gridSpacing,
    required this.lineColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;
    
    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class SavedEventsPage extends StatefulWidget {
  const SavedEventsPage({super.key});

  @override
  State<SavedEventsPage> createState() => _SavedEventsPageState();
}

class _SavedEventsPageState extends State<SavedEventsPage> with SingleTickerProviderStateMixin, SafeStateMixin {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EventCacheService _eventCacheService = EventCacheService.instance;
  
  SlottedUser? _user;
  List<Event> _savedEvents = [];
  bool _isLoading = true;
  bool _isOffline = false;
  
  // Animation controller for background
  AnimationController? _animationController;
  
  // Map to cache user profile data
  final Map<String, SlottedUser> _userProfiles = {};
  
  // Map to track removal animations
  final Map<String, bool> _eventBeingRemoved = {};
  
  // Event category colors
  final Map<String, Color> eventCategoryColors = {
    'COMEDY': const Color(0xFFFF6B6B),
    'DJ': const Color(0xFF4ECDC4),
    'POETRY': const Color(0xFFFFBE0B),
    'MUSIC': const Color(0xFF9B89B3),
    'OTHER': const Color(0xFF8338EC),
  };
  
  // Add pagination variables
  final int _pageSize = 10;
  bool _hasMoreEvents = true;
  bool _isLoadingMore = false;
  final List<String> _loadedEventIds = [];
  final ScrollController _scrollController = ScrollController();
  
  // Offline mode indicator
  bool _showOfflineBanner = false;
  
  // Pull-to-refresh related variables
  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller immediately
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    
    // Start the animation after initialization
    _animationController?.repeat();
    
    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
    
    // Check connectivity status
    _checkConnectivityAndLoadData();
    
    // Clear the image cache to prevent memory issues
    _clearImageCache();
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    
    // Subscribe to connectivity changes
    ConnectivityService.instance.addListener(_onConnectivityChanged);
  }
  
  void _onConnectivityChanged() {
    final isOnline = ConnectivityService.instance.isOnline;
    if (mounted) {
      setState(() {
        _isOffline = !isOnline;
        _showOfflineBanner = !isOnline;
      });
      
      // Hide the offline banner after a delay
      if (!isOnline) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showOfflineBanner = false;
            });
          }
        });
      }
      
      // If we're back online and have loaded events, sync with backend
      if (isOnline && ConnectivityService.instance.wasOffline && _savedEvents.isNotEmpty) {
        _syncOfflineActions();
      }
    }
  }
  
  Future<void> _checkConnectivityAndLoadData() async {
    // Check connection status
    final isOnline = await ConnectivityService.instance.checkConnection();
    
    if (mounted) {
      setState(() {
        _isOffline = !isOnline;
        _showOfflineBanner = !isOnline;
      });
      
      // Load data - will use cached data if offline
      _loadUserData();
      
      // Hide the offline banner after a delay
      if (!isOnline) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showOfflineBanner = false;
            });
          }
        });
      }
    }
  }
  
  void _scrollListener() {
    // When user scrolls near the end, load more events
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 500) {
      _loadMoreEvents();
    }
  }
  
  void _clearImageCache() {
    // Limit memory cache size to prevent OOM errors
    PaintingBinding.instance.imageCache.maximumSize = 100;
    // Clear old cached images from memory to free up space
    PaintingBinding.instance.imageCache.clear();
    // Clear disk cache after a delay to ensure current images are still available
    Future.delayed(const Duration(milliseconds: 500), () {
      // Limit disk cache to reasonable size (50MB)
      PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024;
    });
  }
  
  @override
  void dispose() {
    _animationController?.dispose();
    _scrollController.dispose();
    
    // Clear any profile image references to free memory
    _userProfiles.clear();
    
    // Remove connectivity listener
    ConnectivityService.instance.removeListener(_onConnectivityChanged);
    
    // Complete the refresh completer if it's still pending when the widget is disposed
    _completeRefreshIfNeeded();
    
    super.dispose();
  }
  
  // Complete the refresh completer if it's still pending when the widget is disposed
  void _completeRefreshIfNeeded() {
    if (_isRefreshing && _refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      _refreshCompleter!.complete();
      _isRefreshing = false;
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when the page is opened
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    // Don't reload if we already have data and are not refreshing
    if (_isLoading && !_isRefreshing && _savedEvents.isNotEmpty) return;
    
    setState(() {
      _isLoading = true;
      _hasMoreEvents = true;
      _loadedEventIds.clear();
      _savedEvents.clear();
    });
    
    try {
      final currentUser = _authService.currentUser;
      Logger.d('Loading user data for saved events. Current user: ${currentUser?.uid}', tag: 'SavedEvents_page');
      
      if (currentUser != null) {
        SlottedUser? slottedUser;
        
        if (_isOffline) {
          // Load cached events directly when offline
          final cachedEvents = await _eventCacheService.getCachedSavedEvents();
          
          setState(() {
            _savedEvents = cachedEvents;
            _isLoading = false;
            _hasMoreEvents = false; // No pagination in offline mode
            _loadedEventIds.addAll(cachedEvents.map((e) => e.id));
          });
          
          Logger.d('Loaded ${cachedEvents.length} saved events from cache (offline mode)', 
                   tag: 'SavedEvents_page');
          
          if (_isRefreshing) {
            _refreshCompleter?.complete();
            setState(() {
              _isRefreshing = false;
            });
          }
          
          return;
        }
        
        // Online mode - load from Firebase
        slottedUser = await _authService.getSlottedUser(currentUser.uid);
        
        setState(() {
          _user = slottedUser;
        });
        
        if (slottedUser != null) {
          Logger.d('User loaded: ${slottedUser.username}, Saved events count: ${slottedUser.savedEvents.length}', tag: 'SavedEvents_page');
          
          // Cache the saved event IDs for offline access
          await _eventCacheService.cacheSavedEventIds(slottedUser.savedEvents);
          
          if (slottedUser.savedEvents.isNotEmpty) {
            // Load only the first page initially for faster UI rendering
            await _loadSavedEventsBatch(slottedUser.savedEvents);
          } else {
            Logger.d('No saved events for user', tag: 'SavedEvents_page');
            setState(() {
              _savedEvents = [];
              _isLoading = false;
              _hasMoreEvents = false;
            });
          }
        } else {
          Logger.d('Slotted user is null', tag: 'SavedEvents_page');
          setState(() {
            _isLoading = false;
            _hasMoreEvents = false;
          });
        }
      } else {
        Logger.d('User is not logged in', tag: 'SavedEvents_page');
        setState(() {
          _isLoading = false;
          _hasMoreEvents = false;
        });
      }
      
      if (_isRefreshing) {
        _refreshCompleter?.complete();
        setState(() {
          _isRefreshing = false;
        });
      }
      
    } catch (e) {
      Logger.e('Error loading user data: $e', tag: 'SavedEvents_page');
      
      // Determine error type and show appropriate message
      String errorMessage = _getErrorMessage(e);
      bool shouldRetry = true;
      
      // Handle specific error types
      if (e.toString().contains('GeoPoint') || e.toString().contains('Converting object')) {
        Logger.w('Cache corruption detected, clearing cache', tag: 'SavedEvents_page');
        errorMessage = 'Cache data corrupted. Clearing cache and retrying...';
        try {
          await _eventCacheService.clearCache();
          _showToast('Cache cleared. Please pull to refresh.', isError: false);
        } catch (clearError) {
          Logger.e('Error clearing cache: $clearError', tag: 'SavedEvents_page');
          _showToast('Unable to clear cache. Please restart the app.', isError: true);
        }
        shouldRetry = false; // Don't auto-retry cache corruption
      } else if (e.toString().contains('firebase_auth') || e.toString().contains('unauthorized')) {
        errorMessage = 'Authentication error. Please sign in again.';
        shouldRetry = false;
      } else if (e.toString().contains('network') || e.toString().contains('socket')) {
        errorMessage = 'Network error. Please check your connection.';
      }
      
      setState(() {
        _isLoading = false;
        _hasMoreEvents = false;
      });
      
      // Show user-friendly error message with retry option
      if (mounted && !_isRefreshing) {
        if (shouldRetry) {
          _showErrorDialog(
            'Loading Error',
            errorMessage,
            onRetry: () => _loadUserData(),
          );
        } else {
          _showToast(errorMessage, isError: true);
        }
      }
      
      if (_isRefreshing) {
        _refreshCompleter?.complete();
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }
  
  Future<void> _loadMoreEvents() async {
    // Don't load more if already loading, has no more events, or no user data
    if (_isLoadingMore || !_hasMoreEvents || _user == null) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    try {
      final remainingEventIds = _user!.savedEvents
          .where((id) => !_loadedEventIds.contains(id))
          .toList();
          
      if (remainingEventIds.isEmpty) {
        setState(() {
          _hasMoreEvents = false;
          _isLoadingMore = false;
        });
        return;
      }
      
      await _loadSavedEventsBatch(remainingEventIds);
      
    } catch (e) {
      Logger.e('Error loading more events: $e', tag: 'SavedEvents_page');
      
      setState(() {
        _isLoadingMore = false;
      });
      
      final errorMessage = _getErrorMessage(e);
      _showToast('Failed to load more events: $errorMessage', isError: true);
    }
  }
  
  Future<void> _loadSavedEventsBatch(List<String> eventIds) async {
    try {
      // If no events to load or all events are loaded, mark as complete
      if (eventIds.isEmpty || eventIds.every((id) => _loadedEventIds.contains(id))) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _hasMoreEvents = false;
        });
        return;
      }
      
      // Get IDs not yet loaded
      final unloadedEventIds = eventIds
          .where((id) => !_loadedEventIds.contains(id))
          .toList();
          
      // Calculate next batch size
      final batchSize = math.min(_pageSize, unloadedEventIds.length);
      final nextBatch = unloadedEventIds.sublist(0, batchSize);
      
      Logger.d('Loading batch of ${nextBatch.length} saved events', tag: 'SavedEvents_page');
      
      // Use a batch query for better network performance with timeout
      final List<Future<DocumentSnapshot>> batchQueries = nextBatch
          .map((eventId) => _firestore.collection('events').doc(eventId).get())
          .toList();
          
      final results = await _executeWithTimeout(
        () => Future.wait(batchQueries),
        timeout: const Duration(seconds: 20),
        operationName: 'Loading saved events batch',
      );
      
      // Process results
      final List<Event> newEvents = [];
      final List<String> validEventIds = [];
      final List<String> invalidEventIds = [];
      
      for (int i = 0; i < results.length; i++) {
        final doc = results[i];
        final eventId = nextBatch[i];
        
        if (doc.exists) {
          final event = Event.fromDocument(doc);
          newEvents.add(event);
          validEventIds.add(eventId);
          
          // Cache the event for offline access
          await _eventCacheService.cacheEvent(event);
          
          // Preload attendee profiles in the background
          if (event.attendees.isNotEmpty) {
            _preloadAttendeeProfiles(event.attendees);
          }
        } else {
          Logger.d('Event $eventId does not exist', tag: 'SavedEvents_page');
          invalidEventIds.add(eventId);
        }
      }
      
      // Remove invalid events from user's saved list
      if (invalidEventIds.isNotEmpty && _user != null) {
        _user!.savedEvents.removeWhere((id) => invalidEventIds.contains(id));
        await _firestore.collection('users').doc(_user!.id).update({
          'savedEvents': FieldValue.arrayRemove(invalidEventIds),
        });
        
        // Update the cache with the new list
        await _eventCacheService.cacheSavedEventIds(_user!.savedEvents);
        
        Logger.d('Removed ${invalidEventIds.length} non-existent events from user saved events', tag: 'SavedEvents_page');
      }
      
      // Update state with new events
      if (mounted) {
        setState(() {
          _savedEvents.addAll(newEvents);
          _loadedEventIds.addAll(validEventIds);
          _isLoading = false;
          _isLoadingMore = false;
          _hasMoreEvents = _loadedEventIds.length < eventIds.length;
        });
        Logger.d('Loaded ${newEvents.length} saved events. Total now: ${_savedEvents.length}', tag: 'SavedEvents_page');
      }
    } catch (e) {
      Logger.e('Error loading saved events batch: $e', tag: 'SavedEvents_page');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
        
        final errorMessage = _getErrorMessage(e);
        _showErrorDialog(
          'Loading Error',
          'Failed to load saved events: $errorMessage',
          onRetry: () => _loadSavedEventsBatch(eventIds),
        );
      }
    }
  }
  
  // Preload attendee profiles to cache
  Future<void> _preloadAttendeeProfiles(List<String> attendeeIds) async {
    try {
      // Take only attendees we haven't loaded yet
      final idsToLoad = attendeeIds.where((id) => !_userProfiles.containsKey(id)).toList();
      
      if (idsToLoad.isEmpty) return;
      
      Logger.d('Preloading ${idsToLoad.length} attendee profiles', tag: 'SavedEvents_page');
      
      // Batch queries for better performance, max 10 at a time
      for (int i = 0; i < idsToLoad.length; i += 10) {
        final endIndex = (i + 10 > idsToLoad.length) ? idsToLoad.length : i + 10;
        final batch = idsToLoad.sublist(i, endIndex);
        
        // Use a batched approach to reduce network calls
        final List<Future<DocumentSnapshot>> profileQueries = batch
            .map((id) => _firestore.collection('users').doc(id).get())
            .toList();
            
        final results = await Future.wait(profileQueries);
        
        for (int j = 0; j < results.length; j++) {
          final doc = results[j];
          if (doc.exists && doc.data() != null) {
            final userData = SlottedUser.fromDocument(doc);
            _userProfiles[batch[j]] = userData;
          }
        }
      }
      
      // Only update state if we loaded any profiles and component is still mounted
      if (_userProfiles.isNotEmpty && mounted) {
        setState(() {});
      }
    } catch (e) {
      Logger.e('Error preloading attendee profiles: $e', tag: 'SavedEvents_page');
    }
  }
  
  Future<void> _removeFromSaved(String eventId) async {
    try {
      if (_user == null) return;
      
      // Mark this event as being removed (for animation)
      setState(() {
        _eventBeingRemoved[eventId] = true;
      });
      
      // Wait for animation to complete
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Update local state first for immediate feedback
      setState(() {
        _savedEvents.removeWhere((event) => event.id == eventId);
        _user!.savedEvents.remove(eventId);
      });
      
      if (_isOffline) {
        // In offline mode, just record the action for later
        await _eventCacheService.recordOfflineAction(eventId, 'unsave');
        
        // Update local cache to reflect changes
        await _eventCacheService.cacheSavedEventIds(_user!.savedEvents);
        
        // Show success message
        if (mounted) {
          _showToast('Event removed from saved (offline mode)');
        }
      } else {
        // Online mode - update Firestore
        await _firestore.collection('users').doc(_user!.id).update({
          'savedEvents': FieldValue.arrayRemove([eventId]),
        });
        
        // Update cache to stay in sync
        await _eventCacheService.cacheSavedEventIds(_user!.savedEvents);
        
        // Show success message
        if (mounted) {
          _showToast('Event removed from saved');
        }
      }
      
      // Remove from tracking map after processing
      setState(() {
        _eventBeingRemoved.remove(eventId);
      });
      
    } catch (e) {
      Logger.e('Error removing event from saved: $e', tag: 'SavedEvents_page');
      
      // Revert the UI change on error
      setState(() {
        _eventBeingRemoved.remove(eventId);
      });
      
      // Re-fetch user data to ensure UI matches server state
      if (!_isOffline) {
        try {
          await _loadUserData();
        } catch (reloadError) {
          Logger.e('Error reloading data after failed removal: $reloadError', tag: 'SavedEvents_page');
        }
      }
      
      // Show detailed error message
      if (mounted) {
        final errorMessage = _getErrorMessage(e);
        _showErrorDialog(
          'Remove Failed',
          'Could not remove event from saved: $errorMessage',
          onRetry: () => _removeFromSaved(eventId),
        );
      }
    }
  }

  Future<void> _handleReservation(Event event) async {
    if (_user == null) {
      _showToast('Please sign in to reserve events');
      return;
    }
    
    try {
      // Import the main_nav.dart reserveAction method
      final response = await http.post(
        Uri.parse('https://us-central1-open-mic-5cc8e.cloudfunctions.net/reserveAction'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'paymentIntent': '',
          'eventId': event.id,
          'userId': _user!.id,
          'userEmail': _user!.email,
          'userName': _user!.username,
        }),
      );

      if (response.statusCode == 200) {
        // Refresh the event data to reflect the new reservation status
        final eventDoc = await _firestore.collection('events').doc(event.id).get();
        if (eventDoc.exists) {
          final updatedEvent = Event.fromDocument(eventDoc);
          setState(() {
            final index = _savedEvents.indexWhere((e) => e.id == event.id);
            if (index != -1) {
              _savedEvents[index] = updatedEvent;
            }
          });
        }
        
        _showToast('Reservation updated successfully');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to reserve');
      }
    } catch (e) {
      Logger.e('Error handling reservation: $e', tag: 'SavedEvents_page');
      
      final errorMessage = _getErrorMessage(e);
      _showErrorDialog(
        'Reservation Failed',
        'Could not process reservation: $errorMessage',
        onRetry: () => _handleReservation(event),
      );
    }
  }
  
  void _showToast(String message, {bool isError = false}) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          content: Row(
            children: [
              Icon(
                isError ? CupertinoIcons.exclamationmark_triangle : CupertinoIcons.checkmark_circle,
                color: isError ? CupertinoColors.systemRed : CupertinoColors.systemGreen,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
    
    Future.delayed(Duration(seconds: isError ? 3 : 2), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showErrorDialog(String title, String message, {VoidCallback? onRetry}) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (onRetry != null)
              CupertinoDialogAction(
                child: const Text('Retry'),
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
              ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || 
        errorString.contains('socket') ||
        errorString.contains('connection') ||
        errorString.contains('host lookup failed') ||
        errorString.contains('failed host lookup')) {
      return 'Network connection error. Please check your internet connection.';
    } else if (errorString.contains('permission') || 
               errorString.contains('unauthorized') ||
               errorString.contains('forbidden') ||
               errorString.contains('firebase_auth')) {
      return 'Access denied. Please sign in again.';
    } else if (errorString.contains('timeout') || 
               errorString.contains('deadline exceeded')) {
      return 'Request timed out. Please try again.';
    } else if (errorString.contains('not-found') || 
               errorString.contains('document does not exist')) {
      return 'The requested data was not found.';
    } else if (errorString.contains('quota') || 
               errorString.contains('rate limit')) {
      return 'Too many requests. Please wait a moment and try again.';
    } else if (errorString.contains('geopoint') || 
               errorString.contains('converting object')) {
      return 'Data format error. Cache will be cleared automatically.';
    } else {
      return 'An unexpected error occurred. Please try again later.';
    }
  }



  Future<T> _executeWithTimeout<T>(Future<T> Function() operation, {
    Duration timeout = const Duration(seconds: 30),
    String operationName = 'operation',
  }) async {
    try {
      return await operation().timeout(timeout);
    } on TimeoutException {
      throw Exception('$operationName timed out after ${timeout.inSeconds} seconds');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: app_colors.AppColors.backgroundDark,
      navigationBar: CupertinoNavigationBar(
        border: null,
        backgroundColor: app_colors.AppColors.backgroundDark.withValues(alpha: 0.8),
        automaticallyImplyLeading: false,
        transitionBetweenRoutes: true,
        previousPageTitle: 'Profile',
        middle: const Text(
          'Saved Events',
          style: TextStyle(
            color: CupertinoColors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Navigator.of(context).canPop() ? CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(
            CupertinoIcons.back,
            color: CupertinoColors.white,
            size: 22,
          ),
        ) : null,
      ),
      child: Stack(
        children: [
          // Animated Background
          _buildAnimatedBackground(),
          
          // Content
          SafeArea(
            bottom: false,
            child: _isLoading
              ? Center(
                  child: CupertinoActivityIndicator(
                    color: context.watch<ThemeProvider>().primaryColor,
                  ),
                )
              : _savedEvents.isEmpty
                ? _buildEmptyState()
                : _buildEventsList(),
          ),
          
          // Offline Banner - only shown when needed
          if (_showOfflineBanner)
            Positioned(
              top: MediaQuery.of(context).padding.top + 55,
              left: 0,
              right: 0,
              child: _buildOfflineBanner(),
            ),
        ],
      ),
    );
  }
  
  Widget _buildAnimatedBackground() {
    // Safely check if controller exists before using it
    if (_animationController == null) {
      return Container(color: app_colors.AppColors.backgroundDark);
    }
    
    return AnimatedBuilder(
      animation: _animationController!,
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            // Use a more subtle gradient that matches the app's dark theme
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1E1E2E), // Dark purple-blue at top
                Color(0xFF252538), // Slight variation in middle
                Color(0xFF1A1A27), // Darker at bottom
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Subtle grid pattern overlay
              CustomPaint(
                size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
                painter: GridPainter(
                  gridSpacing: 30,
                  lineColor: Colors.white.withValues(alpha: 0.03),
                ),
              ),
              
              // Very subtle animated accents that move slowly
              ...List.generate(3, (index) {
                final random = math.Random(index);
                final size = MediaQuery.of(context).size.width * 0.8;
                final position = random.nextDouble();
                
                return Positioned(
                  top: MediaQuery.of(context).size.height * 
                    (position + _animationController!.value * 0.05) % 1.2 - 0.2,
                  left: MediaQuery.of(context).size.width * 0.5 - size * 0.5,
                  child: Transform.rotate(
                    angle: _animationController!.value * math.pi * 2 * (index % 2 == 0 ? 0.02 : -0.02),
                    child: Opacity(
                      opacity: 0.02 + (index * 0.01),
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              app_colors.AppColors.primary.withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                            stops: const [0.1, 1.0],
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.bookmark,
            size: 60,
            color: context.watch<ThemeProvider>().textColor.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No Saved Events',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.watch<ThemeProvider>().textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Events you save will appear here',
            style: TextStyle(
              fontSize: 16,
              color: context.watch<ThemeProvider>().textColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEventsList() {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            // Create a new completer
            _refreshCompleter = Completer<void>();
            
            // Set refreshing state
            setState(() {
              _isRefreshing = true;
            });
            
            // If we're online, check for pending sync actions
            if (!_isOffline && ConnectivityService.instance.wasOffline) {
              await _syncOfflineActions();
            }
            
            // Reload data
            await _loadUserData();
            
            // Return the future from the completer
            return _refreshCompleter!.future;
          },
        ),
        SliverPadding(
          padding: EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 120,
          ),
          sliver: SliverList(
            // Use SliverChildBuilderDelegate for virtual scrolling
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Display loading skeleton at the end when loading more
                if (index == _savedEvents.length && (_isLoading || _isLoadingMore) && _hasMoreEvents) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: CupertinoActivityIndicator(),
                    ),
                  );
                }
                
                // Show "no more events" indicator when reached the end
                if (index == _savedEvents.length && !_hasMoreEvents && _savedEvents.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: Text(
                        _isOffline ? 'Offline mode - Pull to refresh when online' : 'No more saved events',
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }
                
                // Safety check
                if (index >= _savedEvents.length) return const SizedBox();
                
                final event = _savedEvents[index];
                
                // Skip if the event is being removed with animation
                if (_eventBeingRemoved[event.id] == true) {
                  return const SizedBox();
                }
                
                // Implement memory-efficient event card with caching
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: KeepAliveWrapper(
                    // Use KeepAlive only for visible items
                    child: EnhancedEventCard(
                      event: event,
                      currentUser: _user,
                      onTap: () => _navigateToEventDetails(event),
                      onSave: () => _removeFromSaved(event.id),
                      onReserve: _user != null ? (event) => _handleReservation(event) : null,
                      isCompact: true,
                      customMargin: EdgeInsets.zero, // Remove default margin since we handle it in Padding
                    ),
                  ),
                );
              },
              // Add extra item for loading indicator or end-of-list message when needed
              childCount: _savedEvents.isEmpty ? 0 : _savedEvents.length + 1,
              // Add findChildIndexCallback for more efficient item finding
              findChildIndexCallback: (Key key) {
                if (key is ValueKey<String>) {
                  final index = _savedEvents.indexWhere((event) => event.id == key.value);
                  if (index != -1) {
                    return index;
                  }
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }
  
  void _navigateToEventDetails(Event event) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => EventDetailsPage(
          initialEvent: event,
          debug: false,
          authAction: (context, isSignUp, onComplete) async {
            // Handle auth if needed
            onComplete();
          },
        ),
      ),
    );
  }

  // Sync offline actions when reconnecting to internet
  Future<void> _syncOfflineActions() async {
    try {
      final offlineActions = await _eventCacheService.getPendingOfflineActions();
      if (offlineActions.isEmpty) return;
      
      Logger.d('Syncing ${offlineActions.length} offline actions', tag: 'SavedEvents_page');
      
      final List<String> processedIds = [];
      
      for (final entry in offlineActions.entries) {
        final eventId = entry.key;
        final actionData = entry.value;
        final action = actionData['action'] as String;
        
        if (action == 'unsave') {
          // Process unsave action
          if (_user != null) {
            await _authService.unsaveEvent(_user!.id, eventId);
            processedIds.add(eventId);
            Logger.d('Synced offline unsave for event $eventId', tag: 'SavedEvents_page');
          }
        }
      }
      
      // Clear processed actions
      if (processedIds.isNotEmpty) {
        await _eventCacheService.clearOfflineActions(processedIds);
      }
      
      // Update the cached events list
      if (_user != null) {
        final userDoc = await _firestore.collection('users').doc(_user!.id).get();
        if (userDoc.exists) {
          final userData = SlottedUser.fromDocument(userDoc);
          _user = userData;
          await _eventCacheService.cacheSavedEventIds(userData.savedEvents);
        }
      }
      
      // Refresh the UI if needed
      if (processedIds.isNotEmpty && mounted) {
        _loadUserData();
      }
      
    } catch (e) {
      Logger.e('Error syncing offline actions: $e', tag: 'SavedEvents_page');
    }
  }
  
  Widget _buildOfflineBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: app_colors.AppColors.slottedOrange.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.wifi_slash,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'You\'re offline. Some features may be limited.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: () {
              setState(() {
                _showOfflineBanner = false;
              });
            },
            child: const Icon(
              CupertinoIcons.xmark,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget to keep items alive when they're visible for better performance
class KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const KeepAliveWrapper({
    super.key,
    required this.child,
  });

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
} 