// ignore_for_file: body_might_complete_normally_nullable
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:slotted/common/colors.dart' as app_colors;
import 'package:slotted/common/event_class.dart';
import 'package:intl/intl.dart';
import 'package:slotted/api/firebase_auth_service.dart';
import 'package:slotted/utils/logger.dart';
import 'package:flutter/services.dart';
import 'package:slotted/api/sharing_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;

/// A skeleton loading widget for EventCard that shows while content is loading
class SkeletonEventCard extends StatefulWidget {
  final EdgeInsets? customMargin;
  final bool animate;
  
  const SkeletonEventCard({
    super.key,
    this.customMargin,
    this.animate = true,
  });
  
  @override
  State<SkeletonEventCard> createState() => _SkeletonEventCardState();
}

class _SkeletonEventCardState extends State<SkeletonEventCard> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  
  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    if (!widget.animate) {
      _shimmerController.stop();
    }
  }
  
  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    
    final defaultMargin = EdgeInsets.symmetric(
      horizontal: isSmallScreen ? 10.0 : 16.0,
      vertical: isSmallScreen ? 6.0 : 8.0,
    );
    
    final margin = widget.customMargin ?? defaultMargin;
    final imageHeight = screenSize.width < 360 ? 130.0 : 
                        (screenSize.width < 400 ? 150.0 : 180.0);
    
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          _buildShimmerBox(
            height: imageHeight,
            width: double.infinity,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          
          // Content skeleton
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton
                _buildShimmerBox(
                  height: 24, 
                  width: screenSize.width * 0.7,
                  borderRadius: BorderRadius.circular(4),
                ),
                
                const SizedBox(height: 8),
                
                // Category skeleton
                _buildShimmerBox(
                  height: 16, 
                  width: screenSize.width * 0.3,
                  borderRadius: BorderRadius.circular(4),
                ),
                
                const SizedBox(height: 12),
                
                // Date skeleton
                _buildShimmerBox(
                  height: 16, 
                  width: screenSize.width * 0.5,
                  borderRadius: BorderRadius.circular(4),
                ),
                
                const SizedBox(height: 16),
                
                // Footer with attendees and actions
                Row(
                  children: [
                    // Attendee avatars skeleton
                    Row(
                      children: List.generate(3, (index) => 
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: _buildShimmerCircle(radius: 15),
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Action buttons skeleton
                    Row(
                      children: [
                        _buildShimmerCircle(radius: 12),
                        const SizedBox(width: 8),
                        _buildShimmerCircle(radius: 12),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildShimmerBox({
    required double height, 
    required double width,
    required BorderRadius borderRadius,
  }) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerValue = _shimmerController.value;
        final color = Colors.grey.shade300.withValues(alpha: 0.5 + (shimmerValue * 0.5));
        
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: color,
          ),
        );
      },
    );
  }
  
  Widget _buildShimmerCircle({required double radius}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerValue = _shimmerController.value;
        final color = Colors.grey.shade300.withValues(alpha: 0.5 + (shimmerValue * 0.5));
        
        return Container(
          height: radius * 2,
          width: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        );
      },
    );
  }
}

class EventCard extends StatefulWidget {
  final Function(String) onCardTapped;
  final Map<String, dynamic> event;
  final Function(bool) onSaveToggled;
  final Function(String)? onHostTapped;
  final EdgeInsets? customMargin;

  const EventCard({
    super.key,
    required this.onCardTapped,
    required this.event,
    required this.onSaveToggled,
    this.onHostTapped,
    this.customMargin,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isSaved = false;
  final FirebaseAuthService _authService = FirebaseAuthService();
  
  // Keys for image caching
  late final String _coverImageKey;
  final List<String> _attendeeImageKeys = [];
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _isSaved = widget.event['isSaved'] ?? false;
    _checkIfSaved();
    
    // Generate cache keys for images
    _coverImageKey = 'event_${widget.event['id']}_cover';
    
    // Precache images for smoother scrolling
    _precacheImages();
  }
  
  void _precacheImages() {
    // Precache cover image
    if (widget.event['coverUrl'].isNotEmpty) {
      precacheImage(
        CachedNetworkImageProvider(widget.event['coverUrl'], cacheKey: _coverImageKey),
        context,
      );
    }
    
    // Precache up to 3 attendee avatars
    if (widget.event['attendees'].isNotEmpty) {
      final avatarsToCache = widget.event['attendees'].length > 3 
          ? widget.event['attendees'].sublist(0, 3) 
          : widget.event['attendees'];
          
      for (final avatar in avatarsToCache) {
        final key = 'attendee_${avatar.hashCode}';
        _attendeeImageKeys.add(key);
        precacheImage(
          CachedNetworkImageProvider(avatar, cacheKey: key),
          context,
        );
      }
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    // Clear memory cache for this card's images when the card is disposed
    // This helps prevent memory leaks when scrolling through many event cards
    super.dispose();
  }

  Future<void> _checkIfSaved() async {
    if (_authService.currentUser != null) {
      try {
        final isSaved = await _authService.isEventSaved(
          _authService.currentUser!.uid, 
          widget.event['id']
        );
        
        if (mounted && isSaved != _isSaved) {
          setState(() {
            _isSaved = isSaved;
          });
        }
      } catch (e) {
        Logger.d('Error checking if event is saved: $e', tag: 'EventCard');
      }
    }
  }

  Future<void> _toggleSaved() async {
    if (_authService.currentUser == null) {
      _showToast('Please log in to save events');
      return;
    }
    
    final userId = _authService.currentUser!.uid;
    final eventId = widget.event['id'];
    
    // Update UI immediately for better feedback
    setState(() {
      _isSaved = !_isSaved;
    });
    
    try {
      if (_isSaved) {
        await _authService.saveEvent(userId, eventId);
      } else {
        await _authService.unsaveEvent(userId, eventId);
      }
      
      // Call the callback after the operation is successful
      widget.onSaveToggled(_isSaved);
        } catch (e) {
      // Revert state if operation failed
      setState(() {
        _isSaved = !_isSaved;
      });
      
      _showToast('Failed to ${_isSaved ? 'save' : 'unsave'} event');
      Logger.e('Error toggling saved state: $e', tag: 'EventCard');
    }
  }
  
  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareEvent(BuildContext context, Event event) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Share Event'),
        message: const Text('Choose how you want to share this event'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _performShare(event, ShareMethod.copyToClipboard);
            },
            child: const Text('Copy to Clipboard'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _performShare(event, ShareMethod.sms);
            },
            child: const Text('Send via SMS'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _performShare(event, ShareMethod.email);
            },
            child: const Text('Send via Email'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _performShare(event, ShareMethod.twitter);
            },
            child: const Text('Share on Twitter'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _performShare(event, ShareMethod.facebook);
            },
            child: const Text('Share on Facebook'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }
  
  Future<void> _performShare(Event event, ShareMethod method) async {
    try {
      final success = await SharingService.instance.shareEvent(event, method: method);
      
      if (success) {
        _showToast('Event shared successfully!');
      } else {
        _showToast('Couldn\'t share event. Try another method.');
      }
    } catch (e) {
      _showToast('Error sharing event');
    }
  }

  Color _getCategoryColor() {
    final normalizedCategory = widget.event['category'].toUpperCase().split(' ')[0];
    return app_colors.AppColors.eventCategory[normalizedCategory] ?? app_colors.AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    // Get device metrics for responsive layout
    final screenSize = MediaQuery.of(context).size;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final isSmallScreen = screenSize.width < 360;
    final isMediumScreen = screenSize.width >= 360 && screenSize.width < 400;
    final isLargeScreen = screenSize.width >= 400;
    final isTablet = screenSize.width > 600;
    
    // Adjust margins based on screen size
    final defaultMargin = EdgeInsets.symmetric(
      horizontal: isSmallScreen ? 10.0 : isTablet ? 24.0 : 16.0,
      vertical: isSmallScreen ? 6.0 : isTablet ? 12.0 : 8.0,
    );
    
    final margin = widget.customMargin ?? defaultMargin;
    
    // Calculate optimal image height
    final imageHeight = isSmallScreen ? 160.0 : 
                        isMediumScreen ? 200.0 : 
                        isTablet ? 280.0 : 230.0;
    
    // Dynamic font sizes based on screen width
    final titleFontSize = isSmallScreen ? 20.0 : (isMediumScreen ? 24.0 : isTablet ? 28.0 : 25.0);
    final categoryFontSize = isSmallScreen ? 16.0 : isTablet ? 21.0 : 18.0;
    final dateFontSize = isSmallScreen ? 16.0 : isTablet ? 21.0 : 18.0;
    
    // Dynamic icon sizes based on screen width
    final iconSize = isSmallScreen ? 28.0 : isTablet ? 38.0 : 32.0;
    
    // Dynamic padding based on screen width
    final contentPadding = isSmallScreen 
        ? const EdgeInsets.all(18.0)
        : isTablet 
            ? const EdgeInsets.all(30.0)
            : const EdgeInsets.all(24.0);
    
    // Dynamic spacing between elements
    final verticalSpacing = isSmallScreen ? 12.0 : isTablet ? 20.0 : 16.0;
    
    // Adjust avatar size for different screens
    final avatarSize = isSmallScreen ? 36.0 : isTablet ? 52.0 : 44.0;
    final avatarSpacing = isSmallScreen ? 12.0 : isTablet ? 20.0 : 16.0;
    
    return RepaintBoundary(
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onCardTapped(widget.event['id'].toString());
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section with optimized size based on screen
                _buildImageSection(iconSize, imageHeight),
                
                // Content Section
                Padding(
                  padding: contentPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Category
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.event['title'] ?? 'No Title',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: titleFontSize,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: verticalSpacing / 2),
                                Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.tag_fill,
                                      size: isSmallScreen ? 12 : isTablet ? 16 : 14,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getCategoryName(),
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: categoryFontSize,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: verticalSpacing),
                      
                      // Date and Time
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.calendar,
                            size: isSmallScreen ? 12 : isTablet ? 16 : 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getFormattedStartDate(),
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: dateFontSize,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: verticalSpacing),
                      
                      // Attendees
                      Row(
                        children: [
                          SizedBox(
                            height: avatarSize,
                            child: Row(
                              children: [
                                for (int i = 0; i < math.min(isSmallScreen ? 3 : isTablet ? 5 : 4, widget.event['attendees'].length); i++)
                                  Align(
                                    widthFactor: 0.7,
                                    child: _buildAttendeeAvatar(widget.event['attendees'][i], size: avatarSize),
                                  ),
                                if (widget.event['attendees'].length > (isSmallScreen ? 3 : isTablet ? 5 : 4))
                                  Align(
                                    widthFactor: 0.7,
                                    child: CircleAvatar(
                                      radius: avatarSize / 2,
                                      backgroundColor: Theme.of(context).primaryColor,
                                      child: Text(
                                        "+${widget.event['attendees'].length - (isSmallScreen ? 3 : isTablet ? 5 : 4)}",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isSmallScreen ? 10 : isTablet ? 14 : 12,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Spacer to push action buttons to the right
                          const Spacer(),
                          // Action buttons
                          Row(
                            children: [
                              // Save button
                              _buildSaveButton(iconSize),
                              SizedBox(width: avatarSpacing),
                              // Share button
                              _buildShareButton(iconSize),
                            ],
                          ),
                        ],
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
  
  Widget _buildImageSection(double iconSize, double imageHeight) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          child: widget.event['coverUrl'].isNotEmpty
              ? SizedBox(
                  width: double.infinity,
                  height: imageHeight,
                  child: CachedNetworkImage(
                    imageUrl: widget.event['coverUrl'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: imageHeight,
                    fadeInDuration: const Duration(milliseconds: 250),
                    fadeOutDuration: const Duration(milliseconds: 150),
                    memCacheWidth: (MediaQuery.of(context).size.width * 1.5).toInt(),
                    maxWidthDiskCache: 800,
                    placeholder: (context, url) => _buildShimmerPlaceholder(),
                    errorWidget: (context, url, error) {
                      Logger.d('Error loading event image: $error', tag: 'EventCard');
                      return Container(
                        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                        child: Icon(
                          CupertinoIcons.photo,
                          color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.3),
                          size: iconSize,
                        ),
                      );
                    },
                    cacheKey: _coverImageKey,
                  ),
                )
              : Container(
                  width: double.infinity,
                  height: imageHeight,
                  color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                  child: Icon(
                    CupertinoIcons.photo,
                    color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.3),
                    size: iconSize,
                  ),
                ),
        ),
        // Host info overlay at bottom of image
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: GestureDetector(
              onTap: () {
                if (widget.onHostTapped != null) {
                  widget.onHostTapped!(widget.event['host']['uid']);
                }
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage: widget.event['host']['photoURL'] != null && 
                                   widget.event['host']['photoURL'].toString().isNotEmpty &&
                                   _isValidImageUrl(widget.event['host']['photoURL'].toString())
                        ? CachedNetworkImageProvider(widget.event['host']['photoURL'])
                        : null,
                    child: widget.event['host']['photoURL'] == null ||
                           widget.event['host']['photoURL'].toString().isEmpty ||
                           !_isValidImageUrl(widget.event['host']['photoURL'].toString())
                        ? const Icon(CupertinoIcons.person, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.event['host']['name'] ?? 'Unknown Host',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getCategoryName() {
    final category = widget.event['category'] ?? '';
    return category.toUpperCase();
  }

  String _getFormattedStartDate() {
    final date = widget.event['date'] ?? DateTime.now();
    return DateFormat.jm().format(date);
  }

  Widget _buildAttendeeAvatar(String avatarUrl, {double size = 30.0}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).primaryColor,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 200),
          memCacheWidth: 64, // Double the display size for high-res devices
          maxWidthDiskCache: 128,
          placeholder: (context, url) => Container(
            color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.3),
            child: Center(
              child: CupertinoActivityIndicator(
                radius: 8,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          errorWidget: (context, url, error) {
            Logger.d('Error loading attendee avatar: $error', tag: 'EventCard');
            return Container(
              color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.3),
              child: Center(
                child: Icon(
                  CupertinoIcons.person_fill,
                  size: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            );
          },
          cacheKey: 'attendee_${avatarUrl.hashCode}',
        ),
      ),
    );
  }

  Widget _buildSaveButton(double iconSize) {
    return GestureDetector(
      onTap: () {
        _toggleSaved();
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isSaved
            ? Icon(
                CupertinoIcons.bookmark_fill,
                color: Theme.of(context).primaryColor,
                size: iconSize,
              )
            : Icon(
                CupertinoIcons.bookmark,
                color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.3),
                size: iconSize,
              ),
      ),
    );
  }

  Widget _buildShareButton(double iconSize) {
    return GestureDetector(
      onTap: () {
        // Create Event from the widget event Map
        final event = Event(
          id: widget.event['id'] ?? '',
          name: widget.event['title'] ?? '',
          host: widget.event['host']?['uid'] ?? '',
          hostName: widget.event['host']?['name'] ?? '',
          date: widget.event['date'] ?? DateTime.now(),
          address: widget.event['location'] ?? '',
          category: widget.event['category'] ?? '',
          coverUrl: widget.event['coverUrl'] ?? '',
          attendees: List<String>.from(widget.event['attendees'] ?? []),
          slots: widget.event['slots'] ?? 0,
        );
        _shareEvent(context, event);
      },
      child: Icon(
        CupertinoIcons.share,
        color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.3),
        size: iconSize,
      ),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      ),
      child: Center(
        child: CupertinoActivityIndicator(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          radius: 12,
        ),
      ),
    );
  }

  // Helper method to validate image URLs
  bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && 
             (uri.scheme == 'http' || uri.scheme == 'https') &&
             uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

// Helper extension to scale gradients
extension GradientScaling on LinearGradient {
  LinearGradient scale(double opacity) {
    return LinearGradient(
      begin: begin,
      end: end,
      stops: stops,
      colors: colors.map((color) {
        return (color).withValues(alpha: opacity);
      }).toList(),
    );
  }
} 