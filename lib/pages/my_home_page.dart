import 'dart:math' as math;
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:slotted/common/event_class.dart' as EventClass;
import 'package:slotted/common/constants.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:slotted/pages/edit_event.dart';
import 'package:slotted/pages/live.dart';
import 'package:slotted/pages/event_details.dart';
import 'package:flutter/services.dart';



import 'package:maps_launcher/maps_launcher.dart';

import 'package:slotted/pages/profile_page.dart';
import 'package:slotted/pages/my_events.dart';
import 'package:slotted/pages/events_map_page.dart' hide kPrimaryColor, kSecondaryColor, kAccentColor, kHighlightColor, kBackgroundDark, kBackgroundLight;
import 'package:slotted/pages/host_payout_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slotted/utils/logger.dart';
import 'package:provider/provider.dart';
import 'package:slotted/providers/theme_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:slotted/common/city_data.dart';
import 'package:slotted/widgets/enhanced_event_card.dart';
import 'package:slotted/widgets/moving_background.dart';
import 'package:slotted/api/firebase_auth_service.dart';
class MyHomePage extends StatefulWidget {
  final User? user;
  final bool debug;
  final Future<void> Function(BuildContext, bool, VoidCallback) authAction;
  final Future<void> Function(EventClass.Event, SlottedUser) reserveAction;
  final Future<void> Function(String) deleteEvent;
  final FirebaseFirestore? firestore;
  final bool isTest;

  const MyHomePage({
    super.key,
    required this.user,
    this.debug = false,
    required this.authAction,
    required this.reserveAction,
    required this.deleteEvent,
    this.firestore,
    this.isTest = false,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// Add this class at the top level for reusable styles
class SlottedStyles {
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: Colors.black12,
      width: 1.0,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration get searchBarDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: Colors.black12,
      width: 1.0,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration gradientCardDecoration(List<Color> colors) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Colors.black12,
      width: 1.0,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

// Add this class at the top of the file, after the imports
class LiveIndicator extends StatefulWidget {
  const LiveIndicator({super.key});

  @override
  State<LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<LiveIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Make the animation repeat in reverse when it completes
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemRed.withValues(alpha: _opacityAnimation.value * 0.5),
                      blurRadius: 5,
                      spreadRadius: 1.5,
                    ),
                  ],
                ),
              ),
            ),
            // Core dot
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: CupertinoColors.systemRed.withValues(alpha: _opacityAnimation.value * 0.8),
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final FocusNode searchFocus = FocusNode();
  String query = '';
  bool actionPending = false;
  String headerTitle = 'UPCOMING';
  final ScrollController eventsScrollController = ScrollController();

  bool _showTutorial = false;
  int _currentTutorialStep = 0;
  final List<Map<String, dynamic>> _tutorialSteps = [
    {
      'title': 'Welcome to OpenSlot!',
      'description': 'Your personal event discovery platform. Let\'s take a quick tour to help you get started!',
    },
    {
      'title': 'Discover Events',
      'description': 'Browse through exciting events happening around you. Swipe up to explore more!',
    },
    {
      'title': 'Search & Filter',
      'description': 'Looking for something specific? Use the search bar to find events or apply filters to narrow down your options.',
    },
    {
      'title': 'Event Details',
      'description': 'Tap on any event card to see more details, reserve a spot, or add it to your calendar.',
    },
    {
      'title': 'Navigation',
      'description': 'Use the bottom navigation to explore the map, create events, check notifications, and access your profile.',
    },
    {
      'title': 'You\'re All Set!',
      'description': 'Now you\'re ready to discover and join amazing events. Enjoy using OpenSlot!',
    },
  ];

  late PageController _pageController;
  int _currentPage = 0;
  final List<String> _slideshowImages = [
    'lib/assets/images/default_featured.jpg',
    'lib/assets/images/dj.png',
    'lib/assets/images/s_logo.png',
  ];

  // Define a new color to replace slottedOrange
  static const Color complementaryColor = kAccent;

  String selectedFilter = ''; // Track the selected filter
  String selectedTimeFilter = ''; // Track the selected time filter

  bool _showSearchBar = true;
  double _lastScrollPosition = 0;
  int? _lastScrollTime;
  
  // Search functionality
  bool _showSearchOverlay = false;
  final TextEditingController _searchController = TextEditingController();
  List<EventClass.Event> _searchResults = [];
  bool _isSearching = false;
  
  // Location filter state
  bool _showLocationFilter = false;
  String _selectedDistanceFilter = 'All';
  final List<String> _distanceOptions = ['All', '5 mi', '10 mi', '25 mi', '50 mi', '100 mi'];
  LatLng _currentPosition = const LatLng(40.7128, -74.0060); // Default to NYC
  
  // Dynamic title tracking
  String _currentSectionTitle = 'OpenSlot';
// Initialize animation controllers and animations
  late AnimationController _gradientController;
  late AnimationController _navAnimationController;  // Add separate controller for nav animations



  // Initialize Firestore early
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _slideshowTimer;
  
  // Cache the events stream to prevent rebuilds
  late final Stream<QuerySnapshot> _eventsStream;

  // Add these variables for bottom nav
  int _selectedIndex = 0;
  bool _isBottomNavVisible = true;
  DateTime? _lastHomeTapTime;

  // Remove redundant cities list and coordinates map since we're importing them
  String selectedCity = 'Near Me';

  @override
  bool get wantKeepAlive => true;

  KeyboardActionsConfig _buildConfig(BuildContext context) {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      keyboardBarColor: kBackgroundDark.withValues(alpha: 0.9),
      nextFocus: false,
      actions: [
        KeyboardActionsItem(focusNode: searchFocus, toolbarButtons: [
          (node) {
            return CupertinoButton(
              padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
              onPressed: () {
                node.unfocus();
                if (mounted) setState(() {});
              },
              child: const Text(
                'Done',
                style: TextStyle(
                  color: kAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
        ]),
      ],
    );
  }

  /// Safe velocity calculation without accessing protected members
  double _calculateScrollVelocity() {
    if (!eventsScrollController.hasClients) return 0.0;
    
    try {
      // Try to get velocity from scroll activity if available
      final activity = eventsScrollController.position.activity;
      if (activity != null) {
        return activity.velocity;
      }
    } catch (e) {
      // Fallback to manual calculation if activity access fails
    }
    
    // Calculate velocity based on scroll position changes over time
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final currentPosition = eventsScrollController.position.pixels;
    
    if (_lastScrollTime != null) {
      final timeDelta = currentTime - _lastScrollTime!;
      final positionDelta = currentPosition - _lastScrollPosition;
      
      if (timeDelta > 0) {
        _lastScrollTime = currentTime;
        return (positionDelta / timeDelta) * 1000; // Convert to pixels per second
      }
    }
    
    _lastScrollTime = currentTime;
    return 0.0;
  }

  void _initializeLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Logger.d('Location services are disabled', tag: 'Location');
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Logger.d('Location permissions are denied', tag: 'Location');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Logger.d('Location permissions are permanently denied', tag: 'Location');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        Logger.d('Current location: ${position.latitude}, ${position.longitude}', tag: 'Location');
      }
    } catch (e) {
      Logger.e('Error getting location: $e', tag: 'Location');
    }
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize the stream FIRST to prevent late initialization errors
    _eventsStream = _firestore.collection('events').snapshots();
    
    // Set system UI overlay style for transparent status bar and navigation bar
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    // Initialize animation controllers
    _gradientController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _navAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);



    // Initialize scroll controller with optimized debounced updates
    eventsScrollController.addListener(() {
      if (eventsScrollController.hasClients) {
        final currentScrollPosition = eventsScrollController.position.pixels;
        final scrollDelta = currentScrollPosition - _lastScrollPosition;
        
        // Only process if scroll delta is significant (reduces 90% of calls)
        if (scrollDelta.abs() < 10) return;
        
        // Safe velocity calculation without accessing protected members
        final velocity = _calculateScrollVelocity();
        final isAtTop = currentScrollPosition <= 0;
        final isScrollingUp = scrollDelta < 0;
        
        // Track state changes to minimize setState calls
        bool needsUpdate = false;
        String newTitle = _currentSectionTitle;
        bool newBottomNavVisible = _isBottomNavVisible;
        bool newShowSearchBar = _showSearchBar;
        
        // Update dynamic title based on scroll position with hysteresis for smooth transitions
        // Define thresholds with hysteresis (different thresholds for scrolling up vs down)
        // Adjusted for larger event cards - more conservative thresholds
        final isScrollingDown = scrollDelta > 0;
        final todayThreshold = isScrollingDown ? 700 : 600;
        final tomorrowThreshold = isScrollingDown ? 1200 : 1000;
        final upcomingThreshold = isScrollingDown ? 1800 : 1500;
        final endedThreshold = isScrollingDown ? 2400 : 2100;
        
        if (currentScrollPosition >= endedThreshold) {
          newTitle = 'Ended';
        } else if (currentScrollPosition >= upcomingThreshold) {
          newTitle = 'Upcoming';
        } else if (currentScrollPosition >= tomorrowThreshold) {
          newTitle = 'Tomorrow';
        } else if (currentScrollPosition >= todayThreshold) {
          newTitle = 'Today';
        } else {
          newTitle = 'OpenSlot';
        }
        
        if (newTitle != _currentSectionTitle) {
          _currentSectionTitle = newTitle;
          needsUpdate = true;
        }
        
        // Show nav bar when:
        // 1. At the top of the page
        // 2. Scrolling slowly (velocity <= 1000)
        // 3. Not actively scrolling (velocity == 0)
        // 4. Scrolling upward (any speed)
        if (isAtTop || 
            velocity.abs() <= 1000 || 
            velocity == 0 || 
            isScrollingUp) {
          if (!_isBottomNavVisible) {
            newBottomNavVisible = true;
            needsUpdate = true;
          }
        } else if (scrollDelta > 0 && velocity.abs() > 1000) {
          // Only hide during fast downward scroll
          if (_isBottomNavVisible) {
            newBottomNavVisible = false;
            needsUpdate = true;
          }
          
          // Add a delayed check to show the nav bar when scrolling stops
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              final currentVelocity = _calculateScrollVelocity();
              if (currentVelocity == 0 && !_isBottomNavVisible) {
                setState(() {
                  _isBottomNavVisible = true;
                });
              }
            }
          });
        }
        
        // Update search bar visibility
        final shouldShowSearchBar = scrollDelta <= 0;
        if (shouldShowSearchBar != _showSearchBar) {
          newShowSearchBar = shouldShowSearchBar;
          needsUpdate = true;
        }
        
        // Update last scroll position (always update this)
        _lastScrollPosition = currentScrollPosition;
        
        // Only call setState if something actually changed
        if (needsUpdate) {
          setState(() {
            _isBottomNavVisible = newBottomNavVisible;
            _showSearchBar = newShowSearchBar;
          });
        }
      }
    });

    // Check if this is a first-time user
    _checkFirstTimeUser();

    // Initialize other components
    // Calendar initialization removed as unused
    selectedTimeFilter = '';
    
    // Initialize location
    _initializeLocation();
    
    // Initialize page controller EARLY to prevent lookup failures
    _pageController = PageController(initialPage: 0);
    
    // Only start animations if not in test mode
    if (!widget.isTest) {
      _gradientController.repeat();
      Future.delayed(kAnimationDurationShort, () {
        if (mounted) {
          _startSlideshow();
        }
      });
    }
    
    // Fix any events with invalid dates
    _firestore.collection('events').get().then((snapshot) {
      final batch = _firestore.batch();
      bool hasChanges = false;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final effectiveYear = today.year < 2025 ? 2025 : today.year;
      
      for (var doc in snapshot.docs) {
        final event = EventClass.Event.fromDocument(doc);
        if (event.date.year < 2025) {
          final newDate = DateTime(
            effectiveYear,
            event.date.month,
            event.date.day,
            event.date.hour,
            event.date.minute,
          );
          batch.update(doc.reference, {'date': Timestamp.fromDate(newDate)});
          hasChanges = true;
        }
      }
      
      if (hasChanges) {
        batch.commit().then((_) {
          if (mounted) setState(() {});
        });
      }
    });
  }

  Future<void> _checkFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool('has_seen_home_tutorial') ?? false;
    
    if (!hasSeenTutorial) {
      // Delay showing tutorial to allow the page to load first
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _showTutorial = true;
          });
        }
      });
    }
  }

  Future<void> _markTutorialComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_home_tutorial', true);
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

  void _startSlideshow() {
    if (!mounted) return;
    
    _slideshowTimer?.cancel();
    _slideshowTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _pageController.hasClients) {
        try {
          setState(() {
            _currentPage = (_currentPage + 1) % _slideshowImages.length;
          });
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          _startSlideshow();
        } catch (e) {
          Logger.e('Error in slideshow animation: $e', tag: 'MyHomePage');
          // Restart slideshow after error
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) _startSlideshow();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _navAnimationController.dispose();
    _pageController.dispose();
    eventsScrollController.dispose();
    _slideshowTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Pull-to-refresh functionality
  Future<void> _refreshEvents() async {
    try {
      // Add haptic feedback
      HapticFeedback.lightImpact();
      
      // Force refresh by clearing cache and reloading
      setState(() {
        // This will trigger a rebuild and reload events from Firestore
      });
      
      // Add a small delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));
      
      Logger.d('Events refreshed via pull-to-refresh', tag: 'MyHomePage');
    } catch (e) {
      Logger.e('Error refreshing events: $e', tag: 'MyHomePage');
    }
  }

  // Optimize event filtering
  List<EventClass.Event> _filterEvents(List<EventClass.Event> events, String query) {
    List<EventClass.Event> filteredEvents = events;
    
    // Create separate lists for category, time, and location filters
    List<EventClass.Event> categoryFilteredEvents = [];
    List<EventClass.Event> timeFilteredEvents = [];
    List<EventClass.Event> locationFilteredEvents = [];
    List<EventClass.Event> distanceFilteredEvents = [];
    bool hasTimeFilter = selectedTimeFilter.isNotEmpty;
    bool hasCategoryFilter = query.isNotEmpty;
    bool hasLocationFilter = false; // Temporarily disable location filtering to debug loading issue
    bool hasDistanceFilter = _selectedDistanceFilter != 'All';
    
    Logger.d('Filtering events:', tag: 'My_home_page');
    Logger.d('Total events before filtering: ${events.length}', tag: 'My_home_page');
    Logger.d('Selected city: $selectedCity', tag: 'My_home_page');
    Logger.d('Selected category filter: $query', tag: 'My_home_page');
    
    // Apply location filter if a specific city is selected
    if (hasLocationFilter) {
      final cityCoords = cityCoordinates[selectedCity];
      if (cityCoords != null) {
        Logger.d('Filtering events for city: $selectedCity', tag: 'My_home_page');
        Logger.d('City coordinates: ${cityCoords.latitude}, ${cityCoords.longitude}', tag: 'My_home_page');
        Logger.d('Total events before location filter: ${events.length}', tag: 'My_home_page');
        
        // For all cities, use the standard distance-based filtering
        // Filter events within roughly 50mi of the city center
        const double maxDistance = 50.0; // miles
        locationFilteredEvents = events.where((event) {
          // Skip events with invalid coordinates (0,0)
          if (event.location.latitude == 0 && event.location.longitude == 0) {
            Logger.d('Event has invalid coordinates: ${event.name}', tag: 'My_home_page');
            return false;
          }
          
          // More flexible city name matching
          String citySearchTerm = selectedCity;
          // For compound city names, also try matching just the first word
          if (selectedCity.contains(' ')) {
            citySearchTerm = selectedCity.split(' ')[0];
          }
          
          // Check if the event address contains the city name (case insensitive)
          final bool addressMatch = event.address.toLowerCase().contains(citySearchTerm.toLowerCase());
          
          // Also check distance for events with valid coordinates
          final distance = _calculateDistance(
            cityCoords.latitude,
            cityCoords.longitude,
            event.location.latitude,
            event.location.longitude,
          );
          
          Logger.d('Event: ${event.name}', tag: 'My_home_page');
          Logger.d('  Location: (${event.location.latitude}, ${event.location.longitude})', tag: 'My_home_page');
          Logger.d('  Address: ${event.address}', tag: 'My_home_page');
          Logger.d('  Distance from city center: ${distance.toStringAsFixed(2)}mi', tag: 'My_home_page');
          Logger.d('  Address match: $addressMatch', tag: 'My_home_page');
          Logger.d('  City search term: $citySearchTerm', tag: 'My_home_page');
          Logger.d('  Will include event: ${distance <= maxDistance || addressMatch}', tag: 'My_home_page');
          
          // Return true if either the distance is within range OR the address contains the city
          return distance <= maxDistance || addressMatch;
        }).toList();
        
        Logger.d('Events after location filter: ${locationFilteredEvents.length}', tag: 'My_home_page');
        for (var event in locationFilteredEvents) {
          Logger.d('  Included event: ${event.name}', tag: 'My_home_page');
          Logger.d('    Address: ${event.address}', tag: 'My_home_page');
          Logger.d('    Location: (${event.location.latitude}, ${event.location.longitude})', tag: 'My_home_page');
        }
      }
    }
    
    // Apply distance filter if active
    if (hasDistanceFilter) {
      Logger.d('Applying distance filter: $_selectedDistanceFilter', tag: 'My_home_page');
      
      // Parse the selected distance (e.g., "5 mi" -> 5.0)
      final maxDistanceMi = double.tryParse(_selectedDistanceFilter.split(' ')[0]) ?? 50.0;
      
      distanceFilteredEvents = events.where((event) {
        // Skip events with invalid coordinates (0,0)
        if (event.location.latitude == 0 && event.location.longitude == 0) {
          Logger.d('Event has invalid coordinates for distance filter: ${event.name}', tag: 'My_home_page');
          return false;
        }
        
        // Calculate distance from current position
        final distance = _calculateDistance(
          _currentPosition.latitude,
          _currentPosition.longitude,
          event.location.latitude,
          event.location.longitude,
        );
        
        Logger.d('Event: ${event.name}', tag: 'My_home_page');
        Logger.d('  Distance from current location: ${distance.toStringAsFixed(2)}mi', tag: 'My_home_page');
        Logger.d('  Max distance: ${maxDistanceMi}mi', tag: 'My_home_page');
        Logger.d('  Will include: ${distance <= maxDistanceMi}', tag: 'My_home_page');
        
        return distance <= maxDistanceMi;
      }).toList();
      
      Logger.d('Events after distance filter: ${distanceFilteredEvents.length}', tag: 'My_home_page');
    }
    
    // Apply category filter if present
    if (hasCategoryFilter) {
      Logger.d('Applying category filter with query: "$query"', tag: 'My_home_page');
      
      categoryFilteredEvents = events.where((event) {
        // Match only the first word of the category (COMEDY, DJ, POETRY, MUSIC)
        final eventCategory = event.category.split(' ')[0].toUpperCase().trim();
        final queryCategory = query.split(' ')[0].toUpperCase().trim(); // Split to handle emojis
        
        Logger.d('Event: "${event.name}"', tag: 'My_home_page');
        Logger.d('  Category: "$eventCategory"', tag: 'My_home_page');
        Logger.d('  Query: "$queryCategory"', tag: 'My_home_page');
        Logger.d('  Match: ${eventCategory == queryCategory}', tag: 'My_home_page');
        
        return eventCategory == queryCategory;
      }).toList();
      
      Logger.d('Events after category filter: ${categoryFilteredEvents.length}', tag: 'My_home_page');
      Logger.d('Filtered events:', tag: 'My_home_page');
      for (var event in categoryFilteredEvents) {
        Logger.d('  ${event.name} (${event.category})', tag: 'My_home_page');
      }
      
      // If no events found after category filter, show a notification
      if (mounted && categoryFilteredEvents.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showNoEventsNotification(query);
          }
        });
      }
    }
    
    // Apply time filter if present
    if (hasTimeFilter) {
      Logger.d('Applying time filter: $selectedTimeFilter', tag: 'My_home_page');
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final effectiveYear = today.year < 2025 ? 2025 : today.year;
      final baseDate = DateTime(effectiveYear, today.month, today.day);
      final tomorrow = baseDate.add(const Duration(days: 1));
      
      timeFilteredEvents = events.where((event) {
        if (event.ended) {
          Logger.d('  ${event.name} is ended, filtering out', tag: 'My_home_page');
          return false;
        }
        
        final eventDate = DateTime(
          event.date.year,
          event.date.month,
          event.date.day,
        );
        
        bool matches = false;
        switch (selectedTimeFilter) {
          case 'Today':
            matches = eventDate.isAtSameMomentAs(baseDate) || event.live;
            Logger.d('  ${event.name} - Today filter: $matches', tag: 'My_home_page');
            break;
          case 'Tomorrow':
            matches = eventDate.isAtSameMomentAs(tomorrow);
            Logger.d('  ${event.name} - Tomorrow filter: $matches', tag: 'My_home_page');
            break;
          case 'Upcoming':
            matches = eventDate.isAfter(tomorrow);
            Logger.d('  ${event.name} - Upcoming filter: $matches', tag: 'My_home_page');
            break;
          default:
            matches = false;
            Logger.d('  ${event.name} - Unknown time filter', tag: 'My_home_page');
        }
        return matches;
      }).toList();
      
      Logger.d('Events after time filter: ${timeFilteredEvents.length}', tag: 'My_home_page');
      Logger.d('Time filtered events:', tag: 'My_home_page');
      for (var event in timeFilteredEvents) {
        Logger.d('  ${event.name} (${event.date})', tag: 'My_home_page');
      }
    }
    
    // Combine all active filters
    if (hasLocationFilter) {
      filteredEvents = locationFilteredEvents;
      Logger.d('Applied location filter', tag: 'My_home_page');
    }
    
    if (hasDistanceFilter) {
      filteredEvents = filteredEvents.where((event) {
        return distanceFilteredEvents.any((e) => e.id == event.id);
      }).toList();
      Logger.d('Applied distance filter', tag: 'My_home_page');
    }
    
    if (hasCategoryFilter) {
      filteredEvents = filteredEvents.where((event) {
        return categoryFilteredEvents.any((e) => e.id == event.id);
      }).toList();
      Logger.d('Applied category filter', tag: 'My_home_page');
    }
    
    if (hasTimeFilter) {
      filteredEvents = filteredEvents.where((event) {
        return timeFilteredEvents.any((e) => e.id == event.id);
      }).toList();
      Logger.d('Applied time filter', tag: 'My_home_page');
    }
    
    Logger.d('Final filtered events count: ${filteredEvents.length}', tag: 'My_home_page');
    return filteredEvents;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 3959.0; // Earth's radius in miles
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) * 
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }

  // Optimize event list building
  Widget _buildEventsList(List<EventClass.Event> events, SlottedUser? slottedUser) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final effectiveYear = today.year < 2025 ? 2025 : today.year;
    final baseDate = DateTime(effectiveYear, today.month, today.day);
    final tomorrow = DateTime(baseDate.year, baseDate.month, baseDate.day + 1);

    // Log event categories before filtering
    Logger.d('Events before filtering:', tag: 'My_home_page');
    for (var event in events) {
      Logger.d('  Event: ${event.name}, Category: ${event.category}', tag: 'My_home_page');
    }

    final filteredEvents = _filterEvents(events, query);
    
    // Log event categories after filtering
    Logger.d('Events after filtering (Total: ${filteredEvents.length}):', tag: 'My_home_page');
    for (var event in filteredEvents) {
      Logger.d('  Event: ${event.name}, Category: ${event.category}', tag: 'My_home_page');
    }
    
    if (filteredEvents.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(kSpacingLarge).copyWith(bottom: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      kPrimary.withValues(alpha: 0.1),
                      kSecondary.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: kPrimary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      CupertinoIcons.calendar,
                      size: 48,
                      color: kAccent.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: kSpacingMedium),
                    const Text(
                      'No events found',
                      style: TextStyle(
                        color: kBackgroundLight,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedTimeFilter.isNotEmpty || query.isNotEmpty || selectedCity != 'Near Me'
                          ? 'Try adjusting your filters'
                          : 'Check back later for upcoming events',
                      style: TextStyle(
                        color: kBackgroundLight.withValues(alpha: 0.7),
                        fontSize: 16,
                      ),
                    ),
                    if (selectedTimeFilter.isNotEmpty || query.isNotEmpty || selectedCity != 'Near Me') ...[
                      const SizedBox(height: 24),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        color: kPrimary.withValues(alpha: 0.2),
                        onPressed: () {
                          setState(() {
                            selectedTimeFilter = '';
                            query = '';
                            selectedCity = 'Near Me';
                            selectedFilter = '';
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.refresh,
                              color: kAccent.withValues(alpha: 0.8),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Reset Filters',
                              style: TextStyle(
                                color: kBackgroundLight,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    final todayEvents = filteredEvents.where((event) {
      if (event.ended) return false;
      final eventDate = DateTime(event.date.year, event.date.month, event.date.day);
      return eventDate.isAtSameMomentAs(today) || event.live;
    }).toList();

    final tomorrowEvents = filteredEvents.where((event) {
      if (event.ended || event.live) return false;
      final eventDate = DateTime(event.date.year, event.date.month, event.date.day);
      return eventDate.isAtSameMomentAs(tomorrow);
    }).toList();

    final upcomingEvents = filteredEvents.where((event) {
      if (event.ended || event.live) return false;
      final eventDate = DateTime(event.date.year, event.date.month, event.date.day);
      return eventDate.isAfter(tomorrow);
    }).toList();

    final endedEvents = filteredEvents.where((event) => event.ended).toList();

    // Calculate total items based on selected filter
    int totalItems = 2; // Slideshow and filter row
    
    // Only show the section that matches the selected filter
    if (selectedTimeFilter.isEmpty) {
      if (todayEvents.isNotEmpty) totalItems += todayEvents.length + 1;
      if (tomorrowEvents.isNotEmpty) totalItems += tomorrowEvents.length + 1;
      if (upcomingEvents.isNotEmpty) totalItems += upcomingEvents.length + 1;
      if (endedEvents.isNotEmpty) totalItems += endedEvents.length + 1;
    } else {
      switch (selectedTimeFilter) {
        case 'Today':
          if (todayEvents.isNotEmpty) totalItems += todayEvents.length + 1;
          break;
        case 'Tomorrow':
          if (tomorrowEvents.isNotEmpty) totalItems += tomorrowEvents.length + 1;
          break;
        case 'Upcoming':
          if (upcomingEvents.isNotEmpty) totalItems += upcomingEvents.length + 1;
          break;
      }
    }

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 80), // Reduced from 150
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              return _buildSlideshow(filteredEvents);
            } else if (index == 1) {
              return _buildFilterRow();
            }

            // Adjust index to account for header items
            index -= 2;

            // Show all sections if no filter is selected
            if (selectedTimeFilter.isEmpty) {
              var currentIndex = index;

              // Today section
              if (todayEvents.isNotEmpty) {
                if (currentIndex == 0) {
                  return _buildHeader('Today');
                }
                currentIndex--;
                if (currentIndex < todayEvents.length) {
                  return _buildListItem(todayEvents[currentIndex], slottedUser);
                }
                currentIndex -= todayEvents.length;
              }

              // Tomorrow section
              if (tomorrowEvents.isNotEmpty) {
                if (currentIndex == 0) {
                  return _buildHeader('Tomorrow');
                }
                currentIndex--;
                if (currentIndex < tomorrowEvents.length) {
                  return _buildListItem(tomorrowEvents[currentIndex], slottedUser);
                }
                currentIndex -= tomorrowEvents.length;
              }

              // Upcoming section
              if (upcomingEvents.isNotEmpty) {
                if (currentIndex == 0) {
                  return _buildHeader('Upcoming');
                }
                currentIndex--;
                if (currentIndex < upcomingEvents.length) {
                  return _buildListItem(upcomingEvents[currentIndex], slottedUser);
                }
                currentIndex -= upcomingEvents.length;
              }

              // Ended section
              if (endedEvents.isNotEmpty) {
                if (currentIndex == 0) {
                  return _buildHeader('Ended');
                }
                currentIndex--;
                if (currentIndex < endedEvents.length) {
                  return _buildListItem(endedEvents[currentIndex], slottedUser);
                }
              }
            } else {
              // Show only the selected filter section
              switch (selectedTimeFilter) {
                case 'Today':
                  if (todayEvents.isEmpty) return null;
                  if (index == 0) return _buildHeader('Today');
                  if (index - 1 < todayEvents.length) {
                    return _buildListItem(todayEvents[index - 1], slottedUser);
                  }
                  break;
                case 'Tomorrow':
                  if (tomorrowEvents.isEmpty) return null;
                  if (index == 0) return _buildHeader('Tomorrow');
                  if (index - 1 < tomorrowEvents.length) {
                    return _buildListItem(tomorrowEvents[index - 1], slottedUser);
                  }
                  break;
                case 'Upcoming':
                  if (upcomingEvents.isEmpty) return null;
                  if (index == 0) return _buildHeader('Upcoming');
                  if (index - 1 < upcomingEvents.length) {
                    return _buildListItem(upcomingEvents[index - 1], slottedUser);
                  }
                  break;
              }
            }
            return null;
          },
          childCount: totalItems,
        ),
      ),
    );
  }

  Widget _buildSlideshow(List<EventClass.Event> events) {
    if (_slideshowImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kSpacingMedium,
            vertical: kSpacingSmall,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kBorderRadiusLarge),
            child: Container(
              height: kSpacingLayout * 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kPrimary.withValues(alpha: 0.1),
                    kSecondary.withValues(alpha: 0.1),
                  ],
                ),
                boxShadow: kShadowLarge,
              ),
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _slideshowImages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Image.asset(
                        _slideshowImages[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.photo,
                                  size: 48,
                                  color: kPrimary.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: kSpacingSmall),
                                Text(
                                  'Image not found',
                                  style: TextStyle(
                                    color: kPrimary.withValues(alpha: 0.5),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  Positioned(
                    bottom: kSpacingMedium,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slideshowImages.length,
                        (index) => Container(
                          width: kSpacingXSmall,
                          height: kSpacingXSmall,
                          margin: const EdgeInsets.symmetric(horizontal: kSpacingXXSmall),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index
                                ? kPrimary
                                : kPrimary.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        children: [
          // Time filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeFilterBubble('Today'),
                const SizedBox(width: 8),
                _buildTimeFilterBubble('Tomorrow'),
                const SizedBox(width: 8),
                _buildTimeFilterBubble('Upcoming'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Category filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFilterBubble('Comedy 🤣'),
                const SizedBox(width: 8),
                _buildFilterBubble('DJ 🎧'),
                const SizedBox(width: 8),
                _buildFilterBubble('Poetry ✍️'),
                const SizedBox(width: 8),
                _buildFilterBubble('Music 🎼'),
              ],
            ),
          ),
          
          // Location filter indicator
          if (_selectedDistanceFilter != 'All')
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedDistanceFilter = 'All';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          kAccent.withValues(alpha: 0.8),
                          kAccent.withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: kAccent.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.location_solid,
                          size: 14,
                          color: kBackgroundLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Within $_selectedDistanceFilter',
                          style: const TextStyle(
                            color: kBackgroundLight,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          CupertinoIcons.xmark,
                          size: 12,
                          color: kBackgroundLight,
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

  Widget _buildTimeFilterBubble(String timeFilter) {
    final isSelected = selectedTimeFilter == timeFilter;
    const Color timeColor = kPrimary;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (isSelected) {
            selectedTimeFilter = '';
            Logger.d('Deselected time filter: $timeFilter', tag: 'My_home_page');
          } else {
            selectedTimeFilter = timeFilter;
            Logger.d('Selected time filter: $timeFilter', tag: 'My_home_page');
          }
        });
        
        // Log for debugging
        Logger.d('Time filter bubble tapped: $timeFilter', tag: 'My_home_page');
        Logger.d('Selected time filter: $selectedTimeFilter', tag: 'My_home_page');
        Logger.d('Selected category filter: $selectedFilter', tag: 'My_home_page');
        Logger.d('Query: $query', tag: 'My_home_page');
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: isSelected ? 1 : 0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return Transform.scale(
            scale: 0.95 + (0.05 * value),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12 + (2 * value),
                vertical: 6 + (1 * value),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isSelected 
                      ? timeColor.withValues(alpha: 0.8 + (0.2 * value))
                      : kBackgroundDark.withValues(alpha: 0.8),
                    isSelected 
                      ? timeColor.withValues(alpha: 0.6 + (0.2 * value))
                      : kBackgroundDark.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected 
                    ? timeColor.withValues(alpha: 0.8)
                    : timeColor.withValues(alpha: 0.3),
                  width: 1.5 + (0.5 * value),
                ),
                boxShadow: [
                  BoxShadow(
                    color: timeColor.withValues(alpha: 0.2 * value),
                    blurRadius: 12 + (8 * value),
                    offset: Offset(0, 4 * (1 - value)),
                    spreadRadius: 2 * value,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 1 + (0.2 * value),
                    child: Icon(
                      _getTimeFilterIcon(timeFilter),
                      size: 14,
                      color: isSelected ? kBackgroundLight : timeColor,
                    ),
                  ),
                  SizedBox(width: 6 + (1 * value)),
                  Text(
                    timeFilter,
                    style: TextStyle(
                      color: isSelected ? kBackgroundLight : timeColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13 + (1 * value),
                      letterSpacing: -0.3 * value,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getTimeFilterIcon(String timeFilter) {
    switch (timeFilter) {
      case 'Today':
        return CupertinoIcons.sun_max_fill;
      case 'Tomorrow':
        return CupertinoIcons.sunrise_fill;
      case 'Upcoming':
        return CupertinoIcons.calendar;
      default:
        return CupertinoIcons.calendar;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return KeyboardActions(
      config: _buildConfig(context),
      disableScroll: true,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
              child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.black,
        resizeToAvoidBottomInset: false,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Vibrant animated background
              Positioned.fill(
                child: Container(
                  color: CupertinoColors.black,
                  child: const MovingBackground(),
                ),
              ),
                
                // Main content
                StreamBuilder<DocumentSnapshot>(
                  stream: widget.user == null
                      ? null
                      : _firestore.doc('users/${widget.user!.uid}').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      Logger.d('Error loading user data: ${snapshot.error}', tag: 'My_home_page');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.exclamationmark_circle,
                              color: kPrimary,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading data',
                              style: TextStyle(
                                color: kPrimary.withValues(alpha: 0.8),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                                                            CupertinoButton(
                                  onPressed: () {
                                    if (mounted) setState(() {});
                                  },
                                  child: const Text('Try Again'),
                                ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData && widget.user != null) {
                      return const Center(
                        child: CupertinoActivityIndicator(
                          color: complementaryColor,
                          radius: 16,
                        ),
                      );
                    }

                    final SlottedUser? slottedUser =
                        snapshot.data == null || widget.user == null
                            ? null
                            : SlottedUser.fromDocument(snapshot.data!);

                    return StreamBuilder<QuerySnapshot>(
                      stream: _eventsStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          Logger.d('Error loading events: ${snapshot.error}', tag: 'My_home_page');
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  CupertinoIcons.exclamationmark_circle,
                                  color: kPrimary,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading events',
                                  style: TextStyle(
                                    color: kPrimary.withValues(alpha: 0.8),
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                CupertinoButton(
                                  onPressed: () {
                                    if (mounted) setState(() {});
                                  },
                                  child: const Text('Try Again'),
                                ),
                              ],
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data == null) {
                          Logger.d('No events data available - hasData: ${snapshot.hasData}, data: ${snapshot.data}', tag: 'My_home_page');
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CupertinoActivityIndicator(
                                  radius: 16,
                                  color: kAccent,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading events...',
                                  style: TextStyle(
                                    color: kBackgroundLight.withValues(alpha: 0.8),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          Logger.d('Stream is still waiting for data', tag: 'My_home_page');
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CupertinoActivityIndicator(
                                  radius: 16,
                                  color: kAccent,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Connecting to database...',
                                  style: TextStyle(
                                    color: kBackgroundLight.withValues(alpha: 0.8),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        Logger.d('Raw events count: ${snapshot.data!.docs.length}', tag: 'My_home_page');
                        
                        final events = _convertQuerySnapshotToEvents(snapshot.data!);
                        Logger.d('Converted events count: ${events.length}', tag: 'My_home_page');
                        
                        // Log a few sample events
                        for (var i = 0; i < math.min(3, events.length); i++) {
                          final event = events[i];
                          Logger.d('Sample event $i:', tag: 'My_home_page');
                          Logger.d('  Name: ${event.name}', tag: 'My_home_page');
                          Logger.d('  Location: ${event.location.latitude}, ${event.location.longitude}', tag: 'My_home_page');
                          Logger.d('  Address: ${event.address}', tag: 'My_home_page');
                        }

                        final filteredEvents = _filterEvents(events, selectedFilter);

                        return RefreshIndicator(
                          onRefresh: _refreshEvents,
                          color: kAccent,
                          backgroundColor: kBackgroundDark,
                          child: CustomScrollView(
                            controller: eventsScrollController,
                            physics: const ClampingScrollPhysics(),
                            slivers: [
                            // Add top padding to account for navigation bar  
                            const SliverPadding(
                              padding: EdgeInsets.only(top: kSpacingLayout + kSpacingLarge),
                              sliver: SliverToBoxAdapter(child: SizedBox()),
                            ),

                            _buildEventsList(filteredEvents, slottedUser),
                          ],
                          ),
                        );
                      },
                    );
                  },
                ),
                
                // Bottom navigation bar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildBottomNav(),
                ),
                
                // Tutorial overlay
                if (_showTutorial)
                  _buildTutorialOverlay(),
                
                // Top Navigation Bar (placed before search overlay when not searching)
                if (!_showSearchOverlay)
                  _buildTopNavigationBar(),
                
                // Location filter overlay
                if (_showLocationFilter)
                  _buildLocationFilterOverlay(),
                
                // Search overlay (placed last to stay on top when active)
                if (_showSearchOverlay)
                  _buildSearchOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopNavigationBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 110, // Increased height to accommodate content
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withAlpha(240),
              Colors.black.withAlpha(200),
              Colors.transparent,
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kSpacingMedium,
              vertical: 4,
            ),
            child: Row(
              children: [
                // App Logo/Title
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return SlideTransition(
                            position: animation.drive(
                              Tween<Offset>(
                                begin: const Offset(0.0, -0.5),
                                end: Offset.zero,
                              ).chain(CurveTween(curve: Curves.easeOutCubic)),
                            ),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          _currentSectionTitle,
                          key: ValueKey(_currentSectionTitle),
                          style: const TextStyle(
                            fontSize: 24, // Slightly reduced font size
                            fontWeight: FontWeight.bold,
                            color: kBackgroundLight,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      Text(
                        'Find your next open slot',
                        style: TextStyle(
                          fontSize: 12, // Slightly reduced font size
                          color: kBackgroundLight.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Action buttons
                Row(
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
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF2DD4BF).withAlpha(51), // Teal accent for location
                              const Color(0xFF2DD4BF).withAlpha(25),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF2DD4BF).withAlpha(76),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.location_circle,
                          color: Color(0xFF2DD4BF), // Matching teal icon
                          size: 20,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Search button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _showSearchOverlay = true;
                        });
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF4A90E2).withAlpha(51), // Blue accent for search
                              const Color(0xFF4A90E2).withAlpha(25),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF4A90E2).withAlpha(76),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.search,
                          color: Color(0xFF4A90E2), // Matching blue icon
                          size: 20,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Explorer button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => EventsMapPage(
                              user: widget.user,
                              debug: widget.debug,
                              authAction: widget.authAction,
                              reserveAction: widget.reserveAction,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF8B5CF6).withAlpha(51), // Purple accent for exploration
                              const Color(0xFF8B5CF6).withAlpha(25),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF8B5CF6).withAlpha(76),
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            CupertinoIcons.compass,
                            color: Color(0xFF8B5CF6), // Matching purple icon
                            size: 20,
                          ),
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
    );
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
            kPrimary.withValues(alpha: 0.9),
            kSecondary.withValues(alpha: 0.9),
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
                          ? kHighlight
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
                    color: kHighlight,
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
      case 'top':
        return Stack(
          children: [
            GestureDetector(
              onTap: _nextTutorialStep,
              child: Container(
                color: kBackgroundDark.withValues(alpha: 0.7),
                width: screenSize.width,
                height: screenSize.height,
              ),
            ),
            Positioned(
              top: screenSize.height * 0.15,
              left: (screenSize.width - (screenSize.width * 0.85)) / 2,
              child: tutorialCard,
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
                width: screenSize.width,
                height: screenSize.height,
              ),
            ),
            Positioned(
              bottom: screenSize.height * 0.15,
              left: (screenSize.width - (screenSize.width * 0.85)) / 2,
              child: tutorialCard,
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
                width: screenSize.width,
                height: screenSize.height,
              ),
            ),
            Positioned(
              top: (screenSize.height - 300) / 2,
              left: (screenSize.width - (screenSize.width * 0.85)) / 2,
              child: tutorialCard,
            ),
          ],
        );
    }
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  kPrimary.withValues(alpha: 0.12),
                  kPrimary.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: kPrimary.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: kBackgroundLight,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 28, top: 2),
            width: 1.5,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  kPrimary.withValues(alpha: 0.2),
                  kPrimary.withValues(alpha: 0),
                ],
                stops: const [0.0, 0.9],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(EventClass.Event event, SlottedUser? slottedUser) {
    return Center( // Added Center widget to center the event card
      child: SizedBox(
        width: MediaQuery.of(context).size.width > 600 
            ? 600 // Maximum width for larger screens
            : MediaQuery.of(context).size.width * 0.9, // 90% of screen width for smaller screens
        child: Stack(
          children: [
            // Timeline line
            Positioned(
              top: 0,
              bottom: 0,
              left: 32,
              child: Container(
                width: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      kPrimary.withValues(alpha: 0.2),
                      kSecondary.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
            ),
            // Event card with margin for the line
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                builder: (context, fadeValue, child) {
                  return Opacity(
                    opacity: fadeValue,
                          child: EnhancedEventCard(
                        event: event,
                        currentUser: slottedUser,
                        onTap: () => _navigateToEventDetails(event),
                        onShare: () => _handleQuickShare(event),
                        onSave: () => _handleQuickSave(event),
                        onReserve: slottedUser != null ? (event) => widget.reserveAction(event, slottedUser) : null,
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

  

  // Improved event card helper methods
  


  Widget _buildCompactAttendeeAvatar(String attendeeId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.doc('users/$attendeeId').get(),
      builder: (context, snapshot) {
        Widget avatarContent;
        
        if (snapshot.hasData && snapshot.data != null) {
          try {
            final user = SlottedUser.fromDocument(snapshot.data!);
            
            // Debug logging
            Logger.d('Avatar for user ${user.username}: photoUrl="${user.photoUrl}"', tag: 'Avatar');
            
            // Check for test profile picture first, then user's actual photo
            String? imageUrl = user.photoUrl.isNotEmpty ? user.photoUrl : _getTestProfilePicture(user.username);
            
            // Check if we have a valid photo URL
            if (imageUrl != null && imageUrl.isNotEmpty && _isValidImageUrl(imageUrl)) {
              avatarContent = CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 56,   // 2x for retina displays
                memCacheHeight: 56,  // Optimizes memory usage
                placeholder: (context, url) => _buildLoadingAvatar(),
                errorWidget: (context, url, error) {
                  Logger.w('Failed to load avatar image: $error', tag: 'Avatar');
                  return _buildColorfulInitialAvatar(user.username, attendeeId);
                },
              );
            } else {
              // Use colorful initial avatar for users without valid photos
              Logger.d('Using initial avatar for ${user.username} (no valid photo)', tag: 'Avatar');
              avatarContent = _buildColorfulInitialAvatar(user.username, attendeeId);
            }
          } catch (e) {
            Logger.w('Error loading user data for avatar: $e', tag: 'Avatar');
            // Use colorful initial avatar with fallback
            avatarContent = _buildColorfulInitialAvatar('', attendeeId);
          }
        } else {
          // Loading or error state - show loading placeholder
          avatarContent = _buildLoadingAvatar();
        }

        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: avatarContent,
          ),
        );
      },
    );
  }

  // Helper method to validate image URLs
  bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    
    // Check if it's a valid URL format
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http') && !uri.scheme.startsWith('https'))) {
        return false;
      }
      
      // Check if it has a valid host
      if (uri.host.isEmpty) {
        return false;
      }
      
      return true;
    } catch (e) {
      Logger.w('Invalid URL format: $url', tag: 'Avatar');
      return false;
    }
  }

  // Search functionality
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
                                kPrimary.withValues(alpha: 0.3),
                                kPrimary.withValues(alpha: 0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: kPrimary.withValues(alpha: 0.4),
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
                            color: kPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: kPrimary.withValues(alpha: 0.3),
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
              color: kAccent,
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
              _buildSuggestionChip('Free Events'),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Recent Searches',
            style: TextStyle(
              color: kBackgroundLight.withValues(alpha: 0.8),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // You can implement recent searches storage here
          Text(
            'No recent searches',
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
          color: kPrimary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: kPrimary.withValues(alpha: 0.3),
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

  Widget _buildSearchResultCard(EventClass.Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kPrimary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          HapticFeedback.lightImpact();
                     Navigator.of(context).push(
             CupertinoPageRoute(
               builder: (context) => EventDetailsPage(
                 initialEvent: event,
                 debug: widget.debug,
                 authAction: widget.authAction,
               ),
             ),
           );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Event image or category icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _getCategoryColor(event.category).withValues(alpha: 0.2),
                ),
                child: event.coverUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: event.coverUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Icon(
                            _getCategoryIcon(event.category),
                            color: _getCategoryColor(event.category),
                            size: 24,
                          ),
                          errorWidget: (context, url, error) => Icon(
                            _getCategoryIcon(event.category),
                            color: _getCategoryColor(event.category),
                            size: 24,
                          ),
                        ),
                      )
                    : Icon(
                        _getCategoryIcon(event.category),
                        color: _getCategoryColor(event.category),
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
                          DateFormat('MMM dd • h:mm a').format(event.date),
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
                  color: _getCategoryColor(event.category).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  event.category.toUpperCase(),
                  style: TextStyle(
                    color: _getCategoryColor(event.category),
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
      // Get all events from Firestore
      final snapshot = await FirebaseFirestore.instance.collection('events').get();
      final allEvents = _convertQuerySnapshotToEvents(snapshot);

      // Filter events based on search term
      final results = allEvents.where((event) {
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
      Logger.e('Error performing search: $e', tag: 'Search');
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'COMEDY':
        return const Color(0xFFE53E3E); // Red
      case 'DJ':
        return const Color(0xFF3182CE); // Blue
      case 'POETRY':
        return const Color(0xFFD69E2E); // Amber
      case 'MUSIC':
        return const Color(0xFF9F7AEA); // Purple
      default:
        return const Color(0xFF38A169); // Green
    }
  }

  // Location filter functionality
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
                                kAccent.withValues(alpha: 0.3),
                                kAccent.withValues(alpha: 0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: kAccent.withValues(alpha: 0.4),
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
                    color: kAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kAccent.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.location_solid,
                        color: kAccent,
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
                              selectedCity,
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
                            _applyLocationFilter();
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
                                        kAccent.withValues(alpha: 0.3),
                                        kAccent.withValues(alpha: 0.2),
                                      ],
                                    )
                                  : null,
                              color: isSelected ? null : kPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                    ? kAccent.withValues(alpha: 0.5)
                                    : kPrimary.withValues(alpha: 0.2),
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
                                      ? kAccent 
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
                                    color: kAccent,
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
                      color: kHighlight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: kHighlight.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.info_circle,
                          color: kHighlight,
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

  void _applyLocationFilter() {
    // This will trigger a rebuild and filter events based on distance
    // The filtering logic will be applied in the event building methods
    setState(() {});
  }

  

  // Helper method for loading state
  Widget _buildLoadingAvatar() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      ),
    );
  }

  // Helper method to create colorful initial avatars
  Widget _buildColorfulInitialAvatar(String username, String userId) {
    // Get the first letter of the username, or use 'U' for unknown
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';
    
    // Generate a consistent color based on the user ID
    final colorIndex = userId.hashCode.abs() % _avatarColors.length;
    final backgroundColor = _avatarColors[colorIndex];
    
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // Define a set of vibrant colors for avatars
  static const List<Color> _avatarColors = [
    Color(0xFFE53E3E), // Red
    Color(0xFF9F7AEA), // Purple  
    Color(0xFF38A169), // Green
    Color(0xFF3182CE), // Blue
    Color(0xFFD69E2E), // Orange/Yellow
    Color(0xFFE53E3E), // Red variant
    Color(0xFF805AD5), // Purple variant
    Color(0xFF319795), // Teal
    Color(0xFFDD6B20), // Orange
    Color(0xFF2B6CB0), // Blue variant
    Color(0xFFD53F8C), // Pink
    Color(0xFF38B2AC), // Teal variant
  ];

  Widget _buildPrimaryActionButton(EventClass.Event event, SlottedUser? slottedUser, Color categoryColor) {
    String buttonText = 'View Details';
    Color buttonColor = categoryColor;
    IconData buttonIcon = CupertinoIcons.eye_fill;
    
    if (event.live) {
      buttonText = 'Join Live';
      buttonColor = CupertinoColors.systemRed;
      buttonIcon = CupertinoIcons.video_camera_solid;
    } else if (event.isFull) {
      buttonText = 'Join Waitlist';
      buttonColor = CupertinoColors.systemGrey;
      buttonIcon = CupertinoIcons.clock_fill;
    } else if (!event.ended && event.date.isAfter(DateTime.now())) {
      buttonText = event.price > 0 ? 'Book Now' : 'Join Free';
      buttonIcon = event.price > 0 ? CupertinoIcons.creditcard_fill : CupertinoIcons.checkmark_circle_fill;
    }
    
    return Container(
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            buttonColor,
            buttonColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: buttonColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        onPressed: () => _handlePrimaryAction(event, slottedUser),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              buttonIcon,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              buttonText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePrimaryAction(EventClass.Event event, SlottedUser? slottedUser) {
    HapticFeedback.selectionClick();
    
    if (event.live) {
      // TODO: Navigate to live stream
      _navigateToEventDetails(event);
    } else if (event.isFull) {
      // TODO: Join waitlist
      _navigateToEventDetails(event);
    } else if (!event.ended && event.date.isAfter(DateTime.now())) {
      // TODO: Handle booking/joining
      _navigateToEventDetails(event);
    } else {
      _navigateToEventDetails(event);
    }
  }

  Widget _buildQuickActionButtons(EventClass.Event event, Color categoryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildQuickActionButton(
          icon: CupertinoIcons.heart,
          label: 'Save',
          onTap: () => _handleQuickSave(event),
          categoryColor: categoryColor,
        ),
        _buildQuickActionButton(
          icon: CupertinoIcons.share,
          label: 'Share',
          onTap: () => _handleQuickShare(event),
          categoryColor: categoryColor,
        ),
        _buildQuickActionButton(
          icon: CupertinoIcons.calendar_badge_plus,
          label: 'Calendar',
          onTap: () => _handleAddToCalendar(event),
          categoryColor: categoryColor,
        ),
        _buildQuickActionButton(
          icon: CupertinoIcons.location,
          label: 'Directions',
          onTap: () => _handleDirections(event),
          categoryColor: categoryColor,
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color categoryColor,
  }) {
    return Expanded(
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 8),
        onPressed: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: categoryColor.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 18,
                color: categoryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleQuickSave(EventClass.Event event) async {
    if (widget.user == null) {
      _showToast('Please log in to save events');
      return;
    }
    
    try {
      final authService = FirebaseAuthService();
      final eventId = event.id;
      final userId = widget.user!.uid;
      
      // Check if event is currently saved by checking Firebase
      final isCurrentlySaved = await authService.isEventSaved(userId, eventId);
      
      if (isCurrentlySaved) {
        // Unsave the event
        await authService.unsaveEvent(userId, eventId);
        _showToast('Event removed from saved');
      } else {
        // Save the event
        await authService.saveEvent(userId, eventId);
        _showToast('Event saved!');
      }
      
      // Force a rebuild to update the UI
      setState(() {});
      
    } catch (e) {
      Logger.e('Error toggling save state: $e', tag: 'MyHomePage');
      _showToast('Failed to save event. Please try again.');
    }
  }

  void _handleQuickShare(EventClass.Event event) {
    // TODO: Implement quick share functionality
    _showToast('Sharing event...');
  }

  void _handleAddToCalendar(EventClass.Event event) {
    // TODO: Implement add to calendar functionality
    _showToast('Added to calendar!');
  }

  void _handleDirections(EventClass.Event event) {
    HapticFeedback.selectionClick();
    MapsLauncher.launchQuery(event.address);
  }

  void _showToast(String message) {
    // Use a more reliable toast method that works with CupertinoApp
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        // Auto-dismiss after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && context.mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
        
        return CupertinoAlertDialog(
          content: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: CupertinoColors.systemGreen,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Comedy':
        return CupertinoIcons.smiley_fill;
      case 'DJ':
        return CupertinoIcons.music_note_2;
      case 'Poetry':
        return CupertinoIcons.text_quote;
      case 'Music':
        return CupertinoIcons.music_mic;
      default:
        return CupertinoIcons.star_fill;
    }
  }

  

  void _navigateToEventDetails(EventClass.Event event) {
    // Navigate to event details page
    Logger.d('Navigating to event details for: ${event.name}', tag: 'My_home_page');
    
    // Add haptic feedback when navigating to event details
    HapticFeedback.selectionClick();
    
    // Always navigate to LivePage regardless of event status
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
  }

  // Update the bottom nav method
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withAlpha(0),
            Colors.black.withAlpha(240),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 84, // Slightly larger to accommodate content
          padding: const EdgeInsets.only(bottom: kSpacingSmall),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                CupertinoIcons.house_fill,
                'Home',
                _selectedIndex == 0,
                () => _onItemTapped(0),
              ),
              _buildNavItem(
                CupertinoIcons.money_dollar_circle,
                'Payout',
                _selectedIndex == 1,
                () => _onItemTapped(1),
              ),
              _buildCreateButton(),
              _buildNavItem(
                CupertinoIcons.calendar,
                'My Events',
                _selectedIndex == 3,
                () => _onItemTapped(3),
              ),
              _buildNavItem(
                CupertinoIcons.person,
                'Profile',
                _selectedIndex == 4,
                () => _onItemTapped(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kSpacingMedium,
          vertical: 4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFFF8C00) : Colors.white.withAlpha(180),
              size: 26,
            ),
            const SizedBox(height: 4),
                          Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFFFF8C00) : Colors.white.withAlpha(180),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }



  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: () => _onItemTapped(2),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF8C00), Color(0xFFFF6B35)],
          ),
          borderRadius: BorderRadius.circular(kBorderRadiusLarge + 4),
                      boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8C00).withAlpha(76),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
        ),
        child: const Icon(
          CupertinoIcons.add,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }



  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      HapticFeedback.selectionClick();
    });
    
    switch (index) {
      case 0: // Home
        final now = DateTime.now();
        if (_lastHomeTapTime != null && 
            now.difference(_lastHomeTapTime!) < const Duration(milliseconds: 300)) {
          // Double tap detected - scroll to top
          eventsScrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
          _lastHomeTapTime = null;
        } else {
          _lastHomeTapTime = now;
        }
        break;
      case 1: // Payout
        if (widget.user == null) {
          widget.authAction(context, false, () {});
        } else {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => HostPayoutPage(
                user: widget.user,
              ),
            ),
          );
        }
        break;
      case 2: // Create
        if (widget.user == null) {
          widget.authAction(context, false, () {});
        } else {
          _handleCreateEvent();
        }
        break;
      case 3: // My Events
        if (widget.user == null) {
          widget.authAction(context, false, () {});
        } else {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => MyEventsPage(
                user: widget.user,
                debug: widget.debug,
                authAction: widget.authAction,
                reserveAction: widget.reserveAction,
                deleteEvent: widget.deleteEvent,
              ),
            ),
          );
        }
        break;
      case 4: // Profile
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => ProfilePage(
              userId: widget.user?.uid,
            ),
          ),
        );
        break;
    }
  }

  void _handleCreateEvent() async {
    try {
      final userDoc = await _firestore.doc('users/${widget.user!.uid}').get();
      if (!userDoc.exists) return;
      
      final user = SlottedUser.fromDocument(userDoc);
      
      if (mounted) {
        final result = await Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => EditEventPage(
              user: user,
              event: null,
            ),
          ),
        );
        
        // Check if user wants to view the newly created event
        if (result != null && result is Map && result["viewEvent"] == true) {
          final eventId = result["eventId"];
          if (eventId != null && mounted) {
            // Fetch the event data
            final eventDoc = await _firestore.collection('events').doc(eventId).get();
            if (eventDoc.exists && mounted) {
              final event = EventClass.Event.fromDocument(eventDoc);
              
              // Navigate to event details page
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => EventDetailsPage(
                    initialEvent: event,
                    debug: false,
                    authAction: widget.authAction,
                  ),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      Logger.d('Error loading user data: $e', tag: 'My_home_page');
    }
  }

  Widget _buildFilterBubble(String category) {
    final isSelected = selectedFilter == category;
    final rawCategory = category.split(' ')[0]; // Don't convert to uppercase here
    final categoryColor = eventCategoryColors[rawCategory.toUpperCase()] ?? kPrimary;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (isSelected) {
            // Reset filter when tapping the same filter again
            selectedFilter = '';
            query = '';
            selectedTimeFilter = '';
            Logger.d('Deselected filter: $category', tag: 'My_home_page');
          } else {
            // First reset any existing time filter to avoid conflicts
            selectedTimeFilter = '';
            
            // Then set the category filter
            selectedFilter = category;
            query = rawCategory; // Use just the category name without emoji
            Logger.d('Selected filter: $category', tag: 'My_home_page');
            Logger.d('Query set to: $query', tag: 'My_home_page');
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [categoryColor, categoryColor.withValues(alpha: 0.7)]
                : [categoryColor.withValues(alpha: 0.15), categoryColor.withValues(alpha: 0.25)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? CupertinoColors.white : CupertinoColors.white.withValues(alpha: 0.8),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
  
  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'COMEDY':
        return '🤣';
      case 'DJ':
        return '🎧';
      case 'POETRY':
        return '✍️';
      case 'MUSIC':
        return '🎼';
      default:
        return '🎭';
    }
  }
  
  List<EventClass.Event> _convertQuerySnapshotToEvents(QuerySnapshot snapshot) {
    Logger.d('Converting QuerySnapshot to Events', tag: 'My_home_page');
    Logger.d('Document count: ${snapshot.docs.length}', tag: 'My_home_page');
    
    final events = snapshot.docs.map((doc) {
      try {
        Logger.d('Converting document: ${doc.id}', tag: 'My_home_page');
        final data = doc.data() as Map<String, dynamic>;
        Logger.d('Document data:', tag: 'My_home_page');
        Logger.d('  Name: ${data['name']}', tag: 'My_home_page');
        Logger.d('  Location: ${data['location']}', tag: 'My_home_page');
        Logger.d('  Address: ${data['address']}', tag: 'My_home_page');
        
        final event = EventClass.Event.fromDocument(doc);
        Logger.d('Successfully converted to Event object', tag: 'My_home_page');
        return event;
      } catch (e) {
        Logger.d('Error converting document: $e', tag: 'My_home_page');
        return EventClass.Event.empty();
      }
    })
    .where((event) => event.id.isNotEmpty)
    .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
    
    Logger.d('Final converted events count: ${events.length}', tag: 'My_home_page');
    return events;
  }

  

  

  // Add this new method to show a notification when no events are found
  void _showNoEventsNotification(String city) {
    // Only show if mounted
    if (!mounted) return;
    
    // Create a simple overlay that fades in and out
    OverlayState? overlayState = Overlay.of(context);
    OverlayEntry? overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: context.read<ThemeProvider>().isDarkMode 
                      ? const Color(0xFF2C2C2E).withValues(alpha: 0.95)
                      : const Color(0xFF1C1C1E).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.read<ThemeProvider>().primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        CupertinoIcons.location_slash,
                        color: context.read<ThemeProvider>().primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No events found in $city. Returning to home view.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        overlayEntry?.remove();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          CupertinoIcons.xmark,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    
    // Add the overlay
    overlayState.insert(overlayEntry);
    
    // Remove after a short duration
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry?.mounted ?? false) {
        overlayEntry?.remove();
      }
    });
  }



  // Add this method to handle favoriting an event with animation and feedback




  // Helper method to get test profile pictures for demonstration
  String? _getTestProfilePicture(String username) {
    // Add some test profile pictures for demonstration
    final testProfiles = {
      'senai': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
      'john': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face',
      'sarah': 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face',
      'mike': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
      'emma': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
    };
    
    return testProfiles[username.toLowerCase()];
  }
}

class ButtonConfig {
  final String text;
  final List<Color> gradientColors;
  final Color textColor;

  const ButtonConfig({
    required this.text,
    required this.gradientColors,
    required this.textColor,
  });
}



extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

// Create a reusable badge design method for visual consistency
extension BadgeDesign on SlottedStyles {
  static BoxDecoration badgeDecoration({required Color color, double opacity = 0.2}) => BoxDecoration(
    color: CupertinoColors.black.withValues(alpha: opacity),
    border: Border.all(
      color: color.withValues(alpha: 0.4),
      width: 1,
    ),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: color.withValues(alpha: 0.1),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
    ],
  );
}

