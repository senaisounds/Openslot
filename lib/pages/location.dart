import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:slotted/utils/logger.dart';

// Import JS stubs for conditional imports
import 'package:slotted/utils/js_stub.dart' as js;
import 'package:slotted/utils/js_util_stub.dart' as js_util;

/// Simple suggestion model class for addresses
class AddressSuggestion {
  final String text;
  final String id;

  AddressSuggestion({required this.text, required this.id});
  
  factory AddressSuggestion.fromJson(Map<String, dynamic> json) {
    return AddressSuggestion(
      text: json['text'] as String,
      id: json['id'] as String,
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
  final LatLong? eventLocation;

  @override
  LocationPageState createState() => LocationPageState();
}

class LocationPageState extends State<LocationPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<AddressSuggestion> _suggestions = [];
  bool _isSearching = false;
  Timer? _debounce;
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeCache();
    
    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
    );
    _animationController.forward();
    
    // Listen for changes to search field
    _searchController.addListener(_onSearchTextChanged);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _debounce?.cancel();
    _animationController.dispose();
    super.dispose();
  }
  
  void _onSearchTextChanged() {
    // Apply debounce to avoid too many searches
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _getAddressSuggestions(_searchController.text);
    });
  }

  Future<void> _initializeCache() async {
    if (!kIsWeb) {
      final cacheDir = await getTemporaryDirectory();
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      // Make sure the directory is writable
      if (!await cacheDir.exists()) {
        await cacheDir.create();
      }
    }
  }
  
  /// Get address suggestions from the JavaScript API
  Future<void> _getAddressSuggestions(String query) async {
    if (!kIsWeb || query.length < 3) {
      setState(() {
        _suggestions = [];
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      // Check if the simplified autocomplete is available
      final hasAutocomplete = kIsWeb && js.context.hasProperty('hasSimpleAutocomplete') 
          && js.context['hasSimpleAutocomplete'] == true;
          
      List<AddressSuggestion> results = [];
      
      if (hasAutocomplete) {
        // Call the JavaScript function to get suggestions
        final jsPromise = js.context.callMethod('getAddressSuggestions', [query]);
        final jsResults = await js_util.promiseToFuture(jsPromise);
        
        if (jsResults != null) {
          final List<dynamic> suggestionsList = jsResults as List<dynamic>;
          results = suggestionsList.map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            return AddressSuggestion.fromJson(map);
          }).toList();
        }
      } else {
        // Fallback to simple suggestions
        if (query.startsWith(RegExp(r'\d+'))) {
          results.add(AddressSuggestion(
            text: '$query Main St, New York, NY',
            id: 'fallback_1',
          ));
          results.add(AddressSuggestion(
            text: '$query Broadway, New York, NY',
            id: 'fallback_2',
          ));
        }
        
        results.add(AddressSuggestion(
          text: '$query, New York, NY',
          id: 'fallback_3',
        ));
        
        results.add(AddressSuggestion(
          text: '$query, Los Angeles, CA',
          id: 'fallback_4',
        ));
      }
      
      setState(() {
        _suggestions = results;
        _isSearching = false;
      });
    } catch (e) {
      Logger.w('Error getting address suggestions: $e', tag: 'location');
      setState(() {
        _isSearching = false;
      });
    }
  }
  
  // Play a haptic feedback when selecting suggestion
  void _selectSuggestion(AddressSuggestion suggestion) {
    HapticFeedback.lightImpact();
    _searchController.text = suggestion.text;
    setState(() {
      _suggestions = [];
    });
  }
  
  void _submitAddress() {
    if (_searchController.text.isNotEmpty) {
      HapticFeedback.mediumImpact();
      widget.onPicked({
        'address': _searchController.text,
        'latlng': null, // No coordinates on web
      });
      // Don't automatically pop - let the calling page handle navigation
      // The EditEventPage will handle popping this page
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Web: Enhanced UI with simple suggestions
      return CupertinoPageScaffold(
        backgroundColor: const Color(0xFF272733),
        navigationBar: CupertinoNavigationBar(
          backgroundColor: const Color(0xFF272733),
          border: Border.all(color: Colors.transparent),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: const Icon(CupertinoIcons.back, color: Colors.white),
          ),
          middle: const Text(
            'Pick Location',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  // Title with emoji
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Where's your event?",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "📍",
                        style: TextStyle(fontSize: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Text input with custom styling
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF383844),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          offset: const Offset(0, 3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: CupertinoTextField(
                      controller: _searchController,
                      placeholder: 'Search for an address...',
                      placeholderStyle: const TextStyle(
                        color: Color(0xFF9E9EA9),
                        fontSize: 16,
                      ),
                      padding: const EdgeInsets.all(14),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 14),
                        child: Icon(
                          CupertinoIcons.search,
                          color: Color(0xFF9E9EA9),
                          size: 20,
                        ),
                      ),
                      clearButtonMode: OverlayVisibilityMode.editing,
                      onSubmitted: (_) => _submitAddress(),
                    ),
                  ),
                  
                  // Search status indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _isSearching ? 40 : 0,
                    child: Center(
                      child: _isSearching
                          ? const CupertinoActivityIndicator(color: Colors.white)
                          : null,
                    ),
                  ),
                  
                  // Suggestions list with animation
                  if (_suggestions.isNotEmpty)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF383844),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ListView.builder(
                            itemCount: _suggestions.length,
                            padding: EdgeInsets.zero,
                            itemBuilder: (context, index) {
                              final suggestion = _suggestions[index];
                              // Animate each item
                              return TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                duration: Duration(milliseconds: 200 + (index * 50)),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 20 * (1 - value)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () => _selectSuggestion(suggestion),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                          vertical: 14.0,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              CupertinoIcons.location_solid,
                                              color: Color(0xFFF2A97B),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                suggestion.text,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (index < _suggestions.length - 1)
                                      const Divider(
                                        height: 1,
                                        color: Color(0xFF4A4A58),
                                        indent: 46,
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  
                  // Map preview unavailable message (shown when no suggestions)
                  if (_suggestions.isEmpty && !_isSearching)
                    Expanded(
                      child: Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutBack,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.scale(
                                scale: 0.6 + (0.4 * value),
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF383844),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      offset: const Offset(0, 4),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  CupertinoIcons.map_fill,
                                  size: 60,
                                  color: Color(0xFFF2A97B),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Start typing to find a location',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 32.0),
                                child: Text(
                                  'Please include street, city and state for best results',
                                  style: TextStyle(
                                    color: Color(0xFF9E9EA9),
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  // Use address button
                  AnimatedOpacity(
                    opacity: _searchController.text.isNotEmpty ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        onPressed: _searchController.text.isNotEmpty ? _submitAddress : null,
                        color: const Color(0xFFF2A97B),
                        borderRadius: BorderRadius.circular(16),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.checkmark_circle,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Use This Address',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        backgroundColor: const Color(0xFF272733),
        actions: [
          IconButton(
            icon: Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  buildLocationPicker(),
                  // Add error handler overlay
                  Builder(
                    builder: (context) => FutureBuilder<bool>(
                      future: Future.delayed(const Duration(seconds: 3), () => true),
                      builder: (context, snapshot) {
                        // If map fails to load after 3 seconds, show fallback UI
                        if (snapshot.hasData && _hasMapError) {
                          return buildMapErrorFallback(context);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Track if map has an error
  bool _hasMapError = false;
  
  // Build fallback UI when map fails to load
  Widget buildMapErrorFallback(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.location_off,
            color: Colors.white,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Map unavailable',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please enter your location manually',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[800],
              hintText: 'Enter address',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_searchController.text.isNotEmpty) {
                HapticFeedback.mediumImpact();
                widget.onPicked({
                  'address': _searchController.text,
                  'latlng': null, // No coordinates on web
                });
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Use This Location'),
          ),
        ],
      ),
    );
  }
  
  // Add this method to use the JavaScript error handler on web
  void _showCustomLocationError(String message) {
    if (kIsWeb) {
      try {
        // Call the JavaScript function directly
        js.context.callMethod('handleLocationError', [message]);
      } catch (e) {
        Logger.e('Error showing custom location error: $e', error: e);
        // Fallback to standard setState if JS fails
        setState(() {
          _hasMapError = true;
        });
      }
    } else {
      // Set flag for non-web platforms
      setState(() {
        _hasMapError = true;
      });
    }
  }
  
  // Handle map/location errors
  void _handleLocationError() {
    _showCustomLocationError('Unable to select location');
  }
  
  Widget buildLocationPicker() {
    try {
      if (kIsWeb) {
        // On web, immediately show the fallback UI to avoid Maps issues
        return Container(
          color: Colors.grey[900],
          child: Center(
            child: buildMapErrorFallback(context),
          ),
        );
      }
      
      return FlutterLocationPicker(
        initPosition: widget.eventLocation != null
            ? LatLong(widget.eventLocation!.latitude, widget.eventLocation!.longitude)
            : const LatLong(37.7749, -122.4194), // Default to San Francisco
        selectLocationButtonStyle: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(const Color(0xFF6C4AB0)),
        ),
        mapLanguage: 'en',
        onError: (error) {
          _handleLocationError();
        },
        onPicked: (pickedData) {
          widget.onPicked({
            'address': pickedData.address,
            'latlng': LatLong(
              pickedData.latLong.latitude,
              pickedData.latLong.longitude,
            ),
          });
          // Don't pop automatically - let the parent handle navigation
        },
      );
    } catch (e) {
      Logger.e('Error building location picker: $e', error: e);
      _handleLocationError();
      return Container(
        color: Colors.grey[900],
        child: Center(
          child: buildMapErrorFallback(context),
        ),
      );
    }
  }
}
