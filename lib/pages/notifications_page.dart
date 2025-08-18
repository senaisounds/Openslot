import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:slotted/common/event_class.dart';
import 'dart:async';
import 'package:slotted/pages/event_details.dart';
import 'package:flutter/services.dart';
import 'package:slotted/utils/logger.dart';
import 'package:slotted/common/colors.dart';
import 'package:provider/provider.dart';
import 'package:slotted/providers/theme_provider.dart';
import 'package:slotted/common/design_system.dart';

// Main Theme Colors
const Color kPrimaryColor = Color(0xFF6C4AB0); // Rich Purple - Stage Lights
const Color kSecondaryColor = Color(0xFF8D72E1); // Soft Purple - Energy
const Color kAccentColor = Color(0xFFB9E0FF); // Electric Blue - Microphone Glow
const Color kHighlightColor = Color(0xFFFFE79B); // Warm Yellow - Spotlight
const Color kBackgroundDark = Color(0xFF2D2D3A); // Dark Stage
const Color kBackgroundLight = Color(0xFFF5F5F7); // Light Mode

class NotificationsPage extends StatefulWidget {
  final User? user;

  const NotificationsPage({super.key, required this.user});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  bool _showSearchBar = true;
  double _lastScrollPosition = 0;
  late AnimationController _smokeController;
  late AnimationController _headerController;
  late AnimationController _searchAnimationController;
  
  // Cache for grouped notifications with timestamp
  Map<String, List<DocumentSnapshot>>? _cachedGroupedNotifications;
  DateTime _lastCacheUpdate = DateTime.now();
  bool _isLoadingMore = false;
  static const int initialNotificationsLimit = 20;
  int _currentLimit = initialNotificationsLimit;
  
  // Cached formatted dates to avoid recalculating
  final Map<DateTime, String> _dateFormatCache = {};
  
  // Add memory cache for notification items
  final Map<String, Widget> _notificationWidgetCache = {};
  
  // Animation controllers for optimized animations
  late AnimationController _fadeInController;
  
  // Enhanced search state
  bool _isSearchFocused = false;
  final FocusNode _searchFocusNode = FocusNode();
  
  // Pull to refresh key
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // Optimize search controller with debounce
    _searchController.addListener(_handleSearchChanged);
    
    // Setup scroll controller with debounce and infinite loading
    _setupScrollController();
    
    // Initialize animation controllers with reduced durations
    _smokeController = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    );
    
    _fadeInController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Setup search focus listener
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
      if (_isSearchFocused) {
        _searchAnimationController.forward();
      } else {
        _searchAnimationController.reverse();
      }
    });
    
    // Start animations
    _smokeController.repeat();
    _fadeInController.forward();
    _headerController.forward();
  }
  
  // Optimized search handling with debounce
  Timer? _searchDebounce;
  void _handleSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
    if (!mounted) return;
    setState(() {
      searchQuery = _searchController.text;
        // Clear widget cache when search changes
        _notificationWidgetCache.clear();
      });
    });
  }

  void _setupScrollController() {
    _scrollController.addListener(() {
      if (!mounted) return;
      
      // Only update if scroll position changed significantly (performance optimization)
      if ((_scrollController.position.pixels - _lastScrollPosition).abs() > 20) {
        final shouldShowSearchBar = _scrollController.position.pixels <= _lastScrollPosition || 
                                   _scrollController.position.pixels < 100;
        
        if (_showSearchBar != shouldShowSearchBar) {
        setState(() {
            _showSearchBar = shouldShowSearchBar;
            _lastScrollPosition = _scrollController.position.pixels;
          });
        } else {
          _lastScrollPosition = _scrollController.position.pixels;
        }
      }
      
      // Implement infinite loading
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoadingMore) {
        _loadMoreNotifications();
      }
    });
  }
  
  // New method to handle loading more notifications
  void _loadMoreNotifications() {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
      _currentLimit += 20;
    });
    
    // Simulate loading delay then update state
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _smokeController.dispose();
    _fadeInController.dispose();
    _headerController.dispose();
    _searchAnimationController.dispose();
    _searchFocusNode.dispose();
    // Clear all caches
    _cachedGroupedNotifications?.clear();
    _dateFormatCache.clear();
    _notificationWidgetCache.clear();
    super.dispose();
  }

  // Optimized date formatting with caching
  String _formatDate(DateTime date) {
    // Check cache first
    if (_dateFormatCache.containsKey(date)) {
      return _dateFormatCache[date]!;
    }
    
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final nowOnly = DateTime(now.year, now.month, now.day);
    final tomorrowOnly = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

    String result;
    if (dateOnly == nowOnly) {
      result = 'Today';
    } else if (dateOnly == tomorrowOnly) {
      result = 'Tomorrow';
    } else {
      result = '${date.month}/${date.day}/${date.year}';
    }
    
    // Cache the result
    _dateFormatCache[date] = result;
    return result;
  }

  // More efficient time ago calculation with caching
  final Map<DateTime, String> _timeAgoCache = {};
  final DateTime _lastTimeAgoCacheReset = DateTime.now();
  
  String _getTimeAgo(DateTime dateTime) {
    // Refresh cache every minute
    final now = DateTime.now();
    if (now.difference(_lastTimeAgoCacheReset).inMinutes > 1) {
      _timeAgoCache.clear();
    }
    
    // Check cache
    if (_timeAgoCache.containsKey(dateTime)) {
      return _timeAgoCache[dateTime]!;
    }
    
    final difference = now.difference(dateTime);
    String result;

    if (difference.inDays > 0) {
      result = '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      result = '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      result = '${difference.inMinutes}m ago';
    } else {
      result = 'Just now';
    }
    
    // Cache the result
    _timeAgoCache[dateTime] = result;
    return result;
  }

  // Add shimmer loading effect for better UX
  Widget _buildShimmerItem() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 20, right: 20),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kBackgroundDark.withValues(alpha: 0.5),
              kBackgroundDark.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: kPrimaryColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    margin: const EdgeInsets.only(right: 48),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: kBackgroundLight.withValues(alpha: 0.1),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 14,
                    margin: const EdgeInsets.only(right: 80),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: kBackgroundLight.withValues(alpha: 0.1),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: kBackgroundLight.withValues(alpha: 0.1),
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

  // Simplified and optimized background gradient with reduced complexity
  Widget _buildBackgroundGradient(Widget child) {
    return AnimatedBuilder(
      animation: _smokeController,
      builder: (context, _) {
        // Sample animation at key points for better performance
        final progress = _smokeController.value;
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                (progress * 6).floorToDouble() / 6 * 0.3, // Discretize for better performance
                (progress * 6).floorToDouble() / 6 * 0.3,
              ),
              focal: Alignment(
                (progress * 4).floorToDouble() / 4 * 0.5,
                (progress * 4).floorToDouble() / 4 * 0.5,
              ),
              colors: const [
                Color.fromRGBO(108, 74, 176, 0.15),
                Color.fromRGBO(141, 114, 225, 0.15),
                Color.fromRGBO(185, 224, 255, 0.15),
                Colors.transparent,
              ],
              stops: const [0.0, 0.3, 0.6, 1.0],
              radius: 1.8,
            ),
          ),
          child: child,
        );
      },
    );
  }
  
  // Modify the StreamBuilder to limit initial load and implement pagination
  Widget _buildNotificationsList() {
    if (widget.user == null) {
      return const Center(
        child: Text('Please sign in to view notifications'),
      );
    }

    return Column(
      children: [
        // Enhanced search bar with animations
        AnimatedBuilder(
          animation: _searchAnimationController,
          builder: (context, child) {
            return AnimatedContainer(
              duration: AnimationConstants.medium,
              height: _showSearchBar ? 70 : 0,
              margin: EdgeInsets.only(bottom: _showSearchBar ? DesignSystem.spacingM : 0),
              padding: LayoutHelpers.listItemPadding,
              child: _showSearchBar ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      DesignSystem.primaryOrange.withValues(alpha: 0.08),
                      DesignSystem.primaryOrange.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusL),
                  border: Border.all(
                    color: _isSearchFocused 
                        ? DesignSystem.primaryOrange.withValues(alpha: 0.4)
                        : DesignSystem.borderLight.withValues(alpha: 0.3),
                    width: _isSearchFocused ? 2 : 1,
                  ),
                  boxShadow: _isSearchFocused 
                      ? DesignSystem.softShadow(DesignSystem.primaryOrange)
                      : [],
                ),
                child: CupertinoSearchTextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  placeholder: 'Search notifications...',
                  style: DesignSystem.body1.copyWith(
                    color: context.watch<ThemeProvider>().textColor,
                  ),
                  backgroundColor: Colors.transparent,
                  placeholderStyle: DesignSystem.body1.copyWith(
                    color: context.watch<ThemeProvider>().textColor.withValues(alpha: 0.6),
                  ),
                  prefixIcon: Icon(
                    CupertinoIcons.search,
                    color: _isSearchFocused 
                        ? DesignSystem.primaryOrange 
                        : DesignSystem.primaryOrange.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  suffixIcon: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: _isSearchFocused 
                        ? DesignSystem.primaryOrange 
                        : DesignSystem.primaryOrange.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: DesignSystem.spacingM, 
                    horizontal: DesignSystem.spacingM
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                  },
                ),
              ) : const SizedBox.shrink(),
            );
          },
        ),
        // Notifications list with pull to refresh
        Expanded(
          child: CupertinoScrollbar(
            controller: _scrollController,
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                setState(() {
                  _cachedGroupedNotifications = null;
                  _notificationWidgetCache.clear();
                  _currentLimit = initialNotificationsLimit;
                });
                await Future.delayed(const Duration(milliseconds: 800));
                HapticFeedback.lightImpact();
              },
              color: AppColors.primary,
              backgroundColor: context.watch<ThemeProvider>().isDarkMode 
                  ? AppColors.backgroundDark 
                  : CupertinoColors.white,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.user!.uid)
                    .collection('notifications')
                    .orderBy('timestamp', descending: true)
                    .limit(_currentLimit)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && _cachedGroupedNotifications == null) {
                    return ListView.builder(
                      padding: const EdgeInsets.only(
                        top: DesignSystem.spacingL, 
                        bottom: 100
                      ),
                      itemCount: 5,
                      itemBuilder: (context, index) => _buildShimmerItem(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24), // Adjusted padding here
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.exclamationmark_triangle_fill,
                              color: kHighlightColor,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading notifications',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: kBackgroundLight.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pull down to try again',
                              style: TextStyle(
                                fontSize: 14,
                                color: kBackgroundLight.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Use cached data if available and not too old
                  final List<DocumentSnapshot> notifications = snapshot.data?.docs ?? [];
                  
                  if (notifications.isEmpty) {
                    return AnimatedBuilder(
                      animation: _headerController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _headerController.value,
                          child: Transform.translate(
                            offset: Offset(0, 50 * (1 - _headerController.value)),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 140,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            AppColors.primary.withAlpha(30),
                                            AppColors.highlight.withAlpha(20),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withAlpha(20),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        CupertinoIcons.bell_slash_fill,
                                        size: 60,
                                        color: AppColors.primary.withAlpha(150),
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    Text(
                                      'No Notifications Yet',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: context.watch<ThemeProvider>().textColor,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: Text(
                                        'You\'ll be the first to know about new events, updates, and exciting opportunities',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: context.watch<ThemeProvider>().textColor.withAlpha(180),
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }

                  // Only process notifications when data changes or cache expired
                  final now = DateTime.now();
                  final cacheAge = now.difference(_lastCacheUpdate);
                  if (_cachedGroupedNotifications == null || 
                      cacheAge.inMinutes > 5 ||
                      _cachedGroupedNotifications!.isEmpty ||
                      notifications.length != _cachedGroupedNotifications!.values.expand((e) => e).length) {
                    
                    _lastCacheUpdate = now;
                    _cachedGroupedNotifications = <String, List<DocumentSnapshot>>{};
                    
                    for (var notification in notifications) {
                      final timestamp = (notification['timestamp'] as Timestamp).toDate();
                      final dateString = _formatDate(timestamp);
                      if (!_cachedGroupedNotifications!.containsKey(dateString)) {
                        _cachedGroupedNotifications![dateString] = [];
                      }
                      _cachedGroupedNotifications![dateString]!.add(notification);
                    }
                    
                    // Clear widget cache on data change
                    _notificationWidgetCache.clear();
                  }
                  
                  final groupedNotifications = _cachedGroupedNotifications!;

                  return ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.only(
                      top: DesignSystem.spacingXL,
                      bottom: kBottomNavigationBarHeight + DesignSystem.spacingM,
                      left: DesignSystem.spacingM,
                      right: DesignSystem.spacingM,
                    ),
                    itemCount: groupedNotifications.length * 2 + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show loader at the end
                      if (_isLoadingMore && index == groupedNotifications.length * 2) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: CupertinoActivityIndicator(
                              radius: 12,
                            ),
                          ),
                        );
                      }
                      
                      if (index.isEven) {
                        // Date headers
                        final dateString = groupedNotifications.keys.elementAt(index ~/ 2);
                        
                        // Check if there are any visible notifications for this date
                        final dateNotifications = groupedNotifications[dateString]!;
                        final hasVisibleNotifications = searchQuery.isEmpty || 
                            dateNotifications.any((notification) {
                              final title = notification['title'] as String;
                              final body = notification['body'] as String;
                              return title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                                     body.toLowerCase().contains(searchQuery.toLowerCase());
                            });
                        
                        if (!hasVisibleNotifications) {
                          return const SizedBox.shrink();
                        }
                        
                        return _buildDateHeader(dateString);
                      } else {
                        // Notification items
                        final dateString = groupedNotifications.keys.elementAt(index ~/ 2);
                        final dateNotifications = groupedNotifications[dateString]!;
                        
                        // Filter notifications by search query if needed
                        final filteredNotifications = searchQuery.isEmpty 
                            ? dateNotifications 
                            : dateNotifications.where((notification) {
                                final title = notification['title'] as String;
                                final body = notification['body'] as String;
                                return title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                                       body.toLowerCase().contains(searchQuery.toLowerCase());
                              }).toList();
                        
                        if (filteredNotifications.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: filteredNotifications.map((notification) {
                            return _buildNotificationItem(notification, animate: false);
                          }).toList(),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateHeader(String date) {
    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, child) {
        return Opacity(
          opacity: _headerController.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _headerController.value)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withAlpha(40),
                          AppColors.highlight.withAlpha(30),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(60),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(20),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      date,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.watch<ThemeProvider>().textColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 16),
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.primary.withAlpha(60),
                            AppColors.primary.withAlpha(0),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  // Optimized notification item builder
  Widget _buildNotificationItem(DocumentSnapshot notification, {bool animate = true}) {
    // Check widget cache first for better performance
    final notificationId = notification.id;
    if (_notificationWidgetCache.containsKey(notificationId) && !animate) {
      return _notificationWidgetCache[notificationId]!;
    }
    
    // Extract notification data with null safety
    final data = notification.data() as Map<String, dynamic>?;
    if (data == null) return const SizedBox.shrink();
    
    final title = data['title'] as String? ?? 'New Notification';
    final body = data['body'] as String? ?? '';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final eventId = data['eventId'] as String?;
    
    // Start fade-in animation
    if (animate) {
      _fadeInController.reset();
      _fadeInController.forward();
    }
    
    // Create a stateful builder to handle the pressed state
    final notificationWidget = StatefulBuilder(
      builder: (context, setState) {
        bool isPressed = false;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16, left: 20, right: 20),
          child: GestureDetector(
            onTapDown: (_) {
              setState(() => isPressed = true);
              // Light haptic feedback on press
              HapticFeedback.lightImpact();
            },
            onTapUp: (_) {
              setState(() => isPressed = false);
            },
            onTapCancel: () {
              setState(() => isPressed = false);
            },
            onTap: () {
              // Medium haptic feedback on tap
              HapticFeedback.mediumImpact();
              
              Logger.d('Notification tapped: $title', tag: 'notifications_page');
              if (eventId != null) {
                Logger.d('EventId found: $eventId', tag: 'notifications_page');
                _handleNotificationTap(eventId);
              } else {
                Logger.d('No eventId found in notification', tag: 'notifications_page');
                // Show feedback when tapped on notification without event
                showCupertinoDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('Information'),
                    content: const Text('This notification does not have an associated event.'),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('OK'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: Matrix4.identity()..scale(isPressed ? 0.98 : 1.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.backgroundDark.withAlpha(isPressed ? 200 : 180),
                            AppColors.backgroundDark.withAlpha(isPressed ? 150 : 120),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isPressed ? [] : [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                            spreadRadius: 1,
                          )
                        ],
                        border: Border.all(
                          color: eventId != null
                              ? AppColors.primary.withAlpha(60)
                              : AppColors.primary.withAlpha(30),
                          width: eventId != null ? 2 : 1,
                        ),
                      ),
                    child: Stack(
                      children: [
                        // Main content
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.primary.withAlpha(40),
                                        AppColors.highlight.withAlpha(30),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.primary.withAlpha(60),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withAlpha(20),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    eventId != null 
                                        ? CupertinoIcons.calendar_badge_plus
                                        : CupertinoIcons.bell_fill,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: context.watch<ThemeProvider>().textColor,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        body,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: context.watch<ThemeProvider>().textColor.withAlpha(200),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.accent.withAlpha(30),
                                        AppColors.accent.withAlpha(20),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.accent.withAlpha(40),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    _getTimeAgo(timestamp),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: context.watch<ThemeProvider>().textColor.withAlpha(180),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (eventId != null)
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            AppColors.primary,
                                            AppColors.highlight,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withAlpha(40),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            CupertinoIcons.calendar_today,
                                            size: 16,
                                            color: CupertinoColors.white,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'View Event',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: CupertinoColors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    onPressed: () {
                                      HapticFeedback.mediumImpact();
                                      _handleNotificationTap(eventId);
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                        
                        // Enhanced visual indicator for tappable notifications
                        if (eventId != null)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withAlpha(80),
                                    AppColors.highlight.withAlpha(60),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withAlpha(100),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withAlpha(30),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                CupertinoIcons.arrow_up_right_circle_fill,
                                color: CupertinoColors.white,
                                size: 14,
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
      },
    );

    // Cache the widget for better performance
    _notificationWidgetCache[notificationId] = notificationWidget;

    if (animate) {
      return AnimatedBuilder(
        animation: _fadeInController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeInController.value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - _fadeInController.value)),
              child: child,
            ),
          );
        },
        child: notificationWidget,
      );
    }

    return notificationWidget;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.user == null) {
      return CupertinoPageScaffold(
        backgroundColor: kBackgroundDark,
        child: _buildBackgroundGradient(
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        kPrimaryColor.withValues(alpha: 0.2),
                        kSecondaryColor.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.bell_fill,
                    size: 50,
                    color: kPrimaryColor.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Stay in the Loop!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: kPrimaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to receive show notifications',
                  style: TextStyle(
                    fontSize: 16,
                    color: kSecondaryColor.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 32),
                CupertinoButton(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(25),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  child: const Text(
                    'Take the Stage',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    // Handle sign in
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: DesignSystem.backgroundDark,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        border: null,
        transitionBetweenRoutes: true,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: DesignSystem.spacingM),
        middle: AnimatedBuilder(
          animation: _headerController,
          builder: (context, child) {
            return Opacity(
              opacity: _headerController.value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - _headerController.value)),
                child: Text(
                  'Notifications',
                  style: DesignSystem.h2.copyWith(
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            );
          },
        ),
        trailing: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingXS),
          onPressed: () {
            showCupertinoModalPopup(
              context: context,
              builder: (context) => CupertinoActionSheet(
                title: const Text('Notification Settings'),
                actions: [
                  CupertinoActionSheetAction(
                    onPressed: () {
                      Navigator.pop(context);
                      // Open notification settings
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text('Coming Soon'),
                          content: const Text('Notification settings will be available soon!'),
                          actions: [
                            CupertinoDialogAction(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Manage Notifications'),
                  ),
                  CupertinoActionSheetAction(
                    onPressed: () {
                      Navigator.pop(context);
                      // Clear all notifications
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text('Clear All Notifications'),
                          content: const Text('Are you sure you want to clear all notifications? This cannot be undone.'),
                          actions: [
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              onPressed: () {
                                Navigator.pop(context);
                                // TODO: Implement clear all notifications
                              },
                              child: const Text('Clear All'),
                            ),
                            CupertinoDialogAction(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      );
                    },
                    isDestructiveAction: true,
                    child: const Text('Clear All'),
                  ),
                ],
                cancelButton: CupertinoActionSheetAction(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            );
          },
          child: const Icon(
            CupertinoIcons.ellipsis_circle,
            color: DesignSystem.primaryOrange,
            size: 24,
          ),
        ),
      ),
      child: SafeArea(
        child: _buildBackgroundGradient(
          _buildNotificationsList(),
        ),
      ),
    );
  }

  void _handleNotificationTap(String eventId) async {
    Logger.d('_handleNotificationTap called with eventId: $eventId', tag: 'notifications_page');
    try {
      // Show a simple loading indicator
      setState(() {
        _isLoadingMore = true;  // Reuse this state variable to show loading
      });
      
      final doc = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();
      
      // Hide loading
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
      
      if (!doc.exists) {
        Logger.d('Event not found for ID: $eventId', tag: 'notifications_page');
        throw Exception('Event not found');
      }
      
      if (!mounted) return;

      final event = Event.fromDocument(doc);
      Logger.i('Successfully loaded event: ${event.name}', tag: 'notifications_page');
      
      // Provide haptic feedback before navigation
      HapticFeedback.mediumImpact();
      
      // Direct navigation to event details page
      if (mounted) {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => EventDetailsPage(
              initialEvent: event,
              debug: false,
              authAction: (context, isLoggedIn, completion) => Future(() => null),
            ),
          ),
        );
      }
    } catch (e) {
      Logger.w('Error in _handleNotificationTap: $e', tag: 'notifications_page');
      
      // Hide loading if showing
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
      
      if (!mounted) return;
      
      // Provide error haptic feedback
      HapticFeedback.vibrate();
      
      // Show error dialog
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text('Could not open event: ${e.toString()}'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }
}
