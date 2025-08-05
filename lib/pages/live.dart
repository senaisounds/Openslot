// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/common/constants.dart' hide kPrimaryColor, kSecondaryColor, kAccentColor, kHighlightColor, kBackgroundDark, kBackgroundLight, eventCategoryColors;
import 'package:slotted/common/event_class.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:slotted/pages/event_details.dart';
import 'package:slotted/pages/profile_page.dart';
import 'package:torch_light/torch_light.dart';
import 'package:confetti/confetti.dart';
import 'package:slotted/pages/event_chat.dart';
import 'package:slotted/utils/logger.dart';
import 'package:slotted/widgets/moving_background.dart';
import 'package:google_fonts/google_fonts.dart';

// Add these constants at the top of the file
const int maxRetries = 3;
const Duration retryDelay = Duration(seconds: 1);

// Enhanced drag and drop constants
enum DropZoneType { performer, nextUp, waitlist, remove }
const double dragFeedbackSize = 80.0;
const double dropZoneHighlightOpacity = 0.3;

class LivePage extends StatefulWidget {
  const LivePage({
    super.key,
    required this.event,
    this.debug = false,
    required this.user,
    required this.authAction,
    required this.reserveAction,
  });

  final bool debug;
  final User? user;
  final Future<void> Function(BuildContext, bool, Function()) authAction;
  final Future<void> Function(Event event, SlottedUser slottedUser)
      reserveAction;

  final Event event;

  @override
  LivePageState createState() => LivePageState();
}

class LivePageState extends State<LivePage> with TickerProviderStateMixin {
  Timer? timer;
  bool _isFlashlightOn = false;
  bool _disposed = false;
  bool _isDroppingPerformer = false;
  ConfettiController? _confettiController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  // Removed: double? _dragDistance;
  // Removed: final double _dragX = 0.0;
  // Removed: final bool _isDragging = false;
  // Removed: final double _dragVelocity = 0.0;
  // Removed: DateTime? _lastTimerUpdate;

  // Add variables for scroll button
  bool _isAtBottom = false;
  bool _showScrollButton = false;

  // Add variables for chat notification count
  int _unreadMessagesCount = 0;
  StreamSubscription<QuerySnapshot>? _messagesSubscription;

  // Add these constants for pagination
  static const int performersPerPage = 20;
  static const Duration imageCacheDuration = Duration(hours: 24);

  // Removed: final int _currentPage = 0;
  // Removed: final bool _isLoadingMore = false;
  // Removed: final bool _hasMorePerformers = true;
  final ScrollController _scrollController = ScrollController();

  // Add this map for image caching
  final Map<String, CachedNetworkImageProvider> _imageCache = {};

  // Add this as a class variable at the top of LivePageState
  Timer? _autoScrollTimer;

  // Enhanced drag and drop state variables
  bool _isDraggingPerformer = false;
  String? _draggingPerformerId;
  DropZoneType? _activeDropZone;
  // Removed: Offset? _dragPosition;
  late AnimationController _dragAnimationController;
  late Animation<double> _dragScaleAnimation;
  late Animation<double> _dragRotationAnimation;

  // Drop zone animations
  late AnimationController _dropZoneAnimationController;
  // Removed: late Animation<double> _dropZoneScaleAnimation;
  // Removed: late Animation<double> _dropZoneOpacityAnimation;

  // Add this variable to track if we've performed a fling
  bool _hasPerformedFling = false;

  // Add a boolean to track the expanded state of the waitlist section
  bool _isWaitlistExpanded = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize all animation controllers
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _pulseController.forward();
      }
    });
    _pulseController.forward();
    
    // Initialize enhanced drag and drop animations
    _dragAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _dragScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _dragAnimationController, curve: Curves.elasticOut),
    );
    _dragRotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _dragAnimationController, curve: Curves.easeInOut),
    );
    
    // Initialize drop zone animations
    _dropZoneAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    // _dropZoneScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
    //   CurvedAnimation(parent: _dropZoneAnimationController, curve: Curves.easeOut),
    // );
    // _dropZoneOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
    //   CurvedAnimation(parent: _dropZoneAnimationController, curve: Curves.easeIn),
    // );
    
    // Add scroll controller listener to detect scroll position
    _scrollController.addListener(_handleScroll);
    
    // Initialize event data immediately
    _fetchEventData();
    
    // Subscribe to chat messages to get unread count
    _subscribeToMessages();
    
    // Start timer for countdown updates
    _startTimer();
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_disposed && mounted && widget.event.performerStart != null) {
        // Calculate if we need to update
        final now = DateTime.now();
        final elapsedMs = now.difference(widget.event.performerStart!).inMilliseconds;
        final totalMs = widget.event.timeLimit * 60000;
        
        // Only update if timer hasn't finished and enough time has passed
        if (elapsedMs < totalMs) {
          setState(() {
            // _lastTimerUpdate = now;
          });
        } else if (widget.event.performerStart != null && widget.event.timeLimit > 0) {
          // Timer finished, stop updates and reset performer start
          _stopPerforming();
        }
      }
    });
  }

  @override
  void dispose() {
    // Mark as disposed first to prevent further updates
    _disposed = true;
    
    // Cancel all timers
    timer?.cancel();
    _autoScrollTimer?.cancel();
    
    // Dispose all animation controllers
    if (_confettiController != null) {
      _confettiController!.stop();
      _confettiController!.dispose();
    }
    
    if (_pulseController.isAnimating) {
      _pulseController.stop();
    }
    _pulseController.dispose();
    
    // Dispose enhanced drag and drop animations
    _dragAnimationController.dispose();
    _dropZoneAnimationController.dispose();
    
    // Cancel all subscriptions
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    
    // Clear all caches
    _imageCache.clear();
    _timeFormatCache.clear();
    
    super.dispose();
  }

  // Cache time formatting results
  final Map<DateTime, String> _timeFormatCache = {};
  
  // Enhanced drag and drop helper methods
  void _handleDragStarted(String performerId) {
    HapticFeedback.heavyImpact();
    setState(() {
      _isDraggingPerformer = true;
      _draggingPerformerId = performerId;
    });
    _dragAnimationController.forward();
  }
  

  
  void _handleDragEnd(DragEndDetails details) {
    _stopAutoScroll();
    _dragAnimationController.reverse();
    
    if (_activeDropZone != null) {
      _handleDropAction(_activeDropZone!);
    }
    
    setState(() {
      _isDraggingPerformer = false;
      _draggingPerformerId = null;
      _activeDropZone = null;
      // _dragPosition = null;
    });
  }
  
  void _updateActiveDropZone(Offset position) {
    // This will be implemented to detect which drop zone is active
    // For now, we'll just highlight the performer zone
    setState(() {
      _activeDropZone = DropZoneType.performer;
    });
    _dropZoneAnimationController.forward();
  }
  
  void _handleDropAction(DropZoneType dropZone) {
    if (_draggingPerformerId == null) return;
    
    switch (dropZone) {
      case DropZoneType.performer:
        _setPerformer(_draggingPerformerId!);
        break;
      case DropZoneType.nextUp:
        _setNextUp(_draggingPerformerId!);
        break;
      case DropZoneType.waitlist:
        _moveToWaitlist(_draggingPerformerId!);
        break;
      case DropZoneType.remove:
        _removePerformer(_draggingPerformerId!);
        break;
    }
  }
  
  Future<void> _setPerformer(String performerId) async {
    try {
      await _retryOperation(
        operation: () => FirebaseFirestore.instance
            .doc('events/${widget.event.id}')
            .update({
          'performer': performerId,
          'performerStart': Timestamp.now(),
        }),
        operationName: 'setPerformer',
      );
      
      HapticFeedback.mediumImpact();
      _confettiController?.play();
      
    } catch (e) {
      Logger.e('Failed to set performer: $e', tag: 'Live');
      _showErrorDialog('Failed to set performer. Please try again.');
    }
  }
  
  Future<void> _setNextUp(String performerId) async {
    try {
      await _retryOperation(
        operation: () => FirebaseFirestore.instance
            .doc('events/${widget.event.id}')
            .update({'upNext': performerId}),
        operationName: 'setNextUp',
      );
      
      HapticFeedback.lightImpact();
      
    } catch (e) {
      Logger.e('Failed to set next up: $e', tag: 'Live');
      _showErrorDialog('Failed to set next performer. Please try again.');
    }
  }
  
  Future<void> _moveToWaitlist(String performerId) async {
    try {
      // Remove from attendees and add to waitlist
      List<String> updatedAttendees = List<String>.from(widget.event.attendees);
      List<String> updatedWaitlist = List<String>.from(widget.event.waitlist);
      
      if (updatedAttendees.contains(performerId)) {
        updatedAttendees.remove(performerId);
        if (!updatedWaitlist.contains(performerId)) {
          updatedWaitlist.add(performerId);
        }
        
        await _retryOperation(
          operation: () => FirebaseFirestore.instance
              .doc('events/${widget.event.id}')
              .update({
            'attendees': updatedAttendees,
            'waitlist': updatedWaitlist,
          }),
          operationName: 'moveToWaitlist',
        );
        
        HapticFeedback.lightImpact();
      }
      
    } catch (e) {
      Logger.e('Failed to move to waitlist: $e', tag: 'Live');
      _showErrorDialog('Failed to move performer to waitlist. Please try again.');
    }
  }
  
  Future<void> _removePerformer(String performerId) async {
    try {
      // Remove from both attendees and waitlist
      List<String> updatedAttendees = List<String>.from(widget.event.attendees);
      List<String> updatedWaitlist = List<String>.from(widget.event.waitlist);
      
      updatedAttendees.remove(performerId);
      updatedWaitlist.remove(performerId);
      
      await _retryOperation(
        operation: () => FirebaseFirestore.instance
            .doc('events/${widget.event.id}')
            .update({
          'attendees': updatedAttendees,
          'waitlist': updatedWaitlist,
        }),
        operationName: 'removePerformer',
      );
      
      HapticFeedback.heavyImpact();
      
    } catch (e) {
      Logger.e('Failed to remove performer: $e', tag: 'Live');
      _showErrorDialog('Failed to remove performer. Please try again.');
    }
  }
  
  String _formatTimeSince(DateTime timestamp) {
    // Check cache first
    if (_timeFormatCache.containsKey(timestamp)) {
      return _timeFormatCache[timestamp]!;
    }

    final duration = DateTime.now().difference(timestamp);
    String result;
    
    if (duration.inSeconds < 60) {
      result = duration.inSeconds == 0 ? 'Now' : '${duration.inSeconds}s ago';
    } else if (duration.inMinutes < 60) {
      result = '${duration.inMinutes}m ago';
    } else if (duration.inHours < 24) {
      result = '${duration.inHours}h ago';
    } else if (duration.inDays < 7) {
      result = '${duration.inDays}d ago';
    } else if (duration.inDays < 365) {
      result = '${(duration.inDays / 7).floor()}w ago';
    } else {
      result = '${(duration.inDays / 365).floor()}y ago';
    }

    // Cache the result
    _timeFormatCache[timestamp] = result;
    return result;
  }



  Future<void> _adjustTimeLimit(
      Event event, BuildContext context, String currentTime) async {
    
    final timeOptions = [1, 2, 3, 5, 10, 15];
    int selectedTime = int.tryParse(currentTime) ?? 5;
    selectedTime = selectedTime == 0 ? 1 : selectedTime;
    bool isInfinite = event.timeLimit == 0;
    final TextEditingController customTimeController = TextEditingController(
      text: isInfinite ? '' : selectedTime.toString()
    );

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
                          color: AppColors.backgroundDark,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 10,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
          children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
            const Text(
                    "Set Performance Time",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Quick select buttons in a grid
                  Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      // Infinite option
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isInfinite = true;
                            customTimeController.clear();
                          });
                        },
                        child: Container(
                          width: 80,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isInfinite ? AppColors.slottedOrange : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isInfinite ? AppColors.slottedOrange : Colors.grey.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                CupertinoIcons.infinite,
                                color: isInfinite ? Colors.black : Colors.grey,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "∞",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isInfinite ? Colors.black : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Time options
                      ...timeOptions.map((time) {
                        final isSelected = !isInfinite && selectedTime == time && customTimeController.text == time.toString();
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              isInfinite = false;
                              selectedTime = time;
                              customTimeController.text = time.toString();
                            });
                          },
                          child: Container(
                            width: 80,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.slottedOrange : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.slottedOrange : Colors.grey.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  CupertinoIcons.timer,
                                  color: isSelected ? Colors.black : Colors.grey,
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${time}m",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.black : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Custom time input
                  if (!isInfinite) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.time,
                            color: Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CupertinoTextField(
                              controller: customTimeController,
              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              placeholder: "Custom time in minutes",
                              placeholderStyle: TextStyle(
                                color: Colors.grey.withValues(alpha: 0.7),
                              ),
                              decoration: null,
                              onChanged: (value) {
                                final customTime = int.tryParse(value);
                                if (customTime != null) {
                                  setState(() {
                                    selectedTime = customTime;
                                  });
                                }
                              },
                            ),
                          ),
                          const Text(
                            "min",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
            ),
          ],
        ),
                    ),
                  ],
                  
                  const SizedBox(height: 30),
                  
                  // Save button
                  CupertinoButton(
                    padding: EdgeInsets.zero,
            onPressed: () async {
                      try {
                        int timeLimit;
                        if (isInfinite) {
                          timeLimit = 0;
                        } else {
                          final customTime = int.tryParse(customTimeController.text);
                          if (customTime == null || customTime < 1) {
                            _showErrorDialog(
                              'Please enter a valid time (minimum 1 minute)',
                            );
                            return;
                          }
                          timeLimit = customTime;
                        }
                        
                        await _retryOperation(
                          operation: () => FirebaseFirestore.instance
                              .doc('events/${widget.event.id}')
                  .update({
                'timeLimit': timeLimit,
                'performerStart':
                                widget.event.performerStart != null ? DateTime.now() : null,
                          }),
                          operationName: 'adjustTimeLimit',
                        );
                        if (!mounted) return;
              Navigator.of(context).pop();
                      } catch (e) {
                        if (!mounted) return;
                        Logger.e('Failed to adjust time limit: $e', tag: 'Live');
                        _showErrorDialog(
                          'Failed to set time limit. Please check your connection and try again.',
                          retryAction: () => _adjustTimeLimit(widget.event, context, currentTime),
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.slottedOrange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "Save",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
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

  Future<void> _stopPerforming() async {
    try {
    await FirebaseFirestore.instance.doc('events/${widget.event.id}').update({
      'performerStart': null,
    });
      setState(() {
        widget.event.performerStart = null;
        // _lastTimerUpdate = null;
      });
    } catch (e) {
      Logger.e('Failed to stop performing: $e', tag: 'Live');
      _showErrorDialog('Failed to stop performance');
    }
  }

  Future<void> _startPerforming() async {
    try {
      final now = DateTime.now();
    await FirebaseFirestore.instance.doc('events/${widget.event.id}').update({
        'performerStart': now,
      });
      setState(() {
        widget.event.performerStart = now;
        // _lastTimerUpdate = now;
      });
      _confettiController?.play();
      _startTimer(); // Restart timer when performance starts
    } catch (e) {
      Logger.e('Failed to start performing: $e', tag: 'Live');
      _showErrorDialog('Failed to start performance');
    }
  }

  Future<void> _lineupPerformer(Event event, String? currentPerformer,
      String performer, String username) async {
    bool isCurrentPerformer =
        currentPerformer == performer || currentPerformer == username;

    // First fetch the user's profile to get their username
    try {
      final userDoc = await FirebaseFirestore.instance.doc('users/$performer').get();
      final displayName = userDoc.exists ? userDoc.get('username') as String? ?? username : username;

    final confirmation = await showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: Text(
                isCurrentPerformer ? "Change Performer?" : "Next Performer"),
            content: Column(
              children: [
                const SizedBox(height: 8),
                Text(isCurrentPerformer
                      ? "$displayName is currently performing. What would you like to do?"
                      : "Is $displayName performing now?"),
              ],
            ),
            actions: [
                if (isCurrentPerformer && widget.event.performerStart == null) ...[
                CupertinoDialogAction(
                  child: const Text("Remove"),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                CupertinoDialogAction(
                  child: Text(isCurrentPerformer ? "Cancel" : "Yes"),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
                if (isCurrentPerformer && widget.event.performerStart != null) ...[
                CupertinoDialogAction(
                  child: const Text("Remove"),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                CupertinoDialogAction(
                  child: Text(isCurrentPerformer ? "Cancel" : "Yes"),
                  onPressed: () => Navigator.of(context).pop(true),
                )
              ],
              if (!isCurrentPerformer) ...[
                CupertinoDialogAction(
                    child: const Text("Set as Current"),
                  onPressed: () => Navigator.of(context).pop(true),
                  ),
                  CupertinoDialogAction(
                    child: const Text("Mark as Up Next"),
                    onPressed: () => Navigator.of(context).pop("up_next"),
                  ),
                ],
                if ((widget.event.performerStart != null && widget.event.timeLimit != 0) ||
                  !isCurrentPerformer)
                CupertinoDialogAction(
                    child: const Text("Cancel"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              if (performer != username) ...[
                CupertinoDialogAction(
                  child: const Text("View Profile"),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await Navigator.of(context).push(
                      CupertinoPageRoute(
                          builder: (context) => ProfilePage(userId: performer),
                      ),
                    );
                  },
                ),
              ]
            ],
          );
        });

      if (confirmation == null) return;

      try {
    switch (confirmation) {
      case true:
        if (!isCurrentPerformer) {
              HapticFeedback.mediumImpact();
              
              await _retryOperation(
                operation: () => FirebaseFirestore.instance.doc('events/${widget.event.id}').update({
            'performer': performer,
            'performerStart': null,
                  // If this person was up next, clear the up_next field
                  if (widget.event.upNext == performer) 'upNext': null,
                }),
                operationName: 'lineupPerformer',
              );

              if (!mounted) return;
              
          setState(() {
            widget.event.performer = performer;
            widget.event.performerStart = null;
                if (widget.event.upNext == performer) {
                  widget.event.upNext = null;
                }
          });
        }
        break;
          case "up_next":
            HapticFeedback.mediumImpact();
            
            await _retryOperation(
              operation: () => FirebaseFirestore.instance.doc('events/${widget.event.id}').update({
                'upNext': performer,
              }),
              operationName: 'setUpNext',
            );
            
            if (!mounted) return;
            
            setState(() {
              widget.event.upNext = performer;
            });
        break;
      case null:
        if (isCurrentPerformer) {
              HapticFeedback.selectionClick();
              
              await _retryOperation(
                operation: () => FirebaseFirestore.instance.doc('events/${widget.event.id}').update({
                  'performerStart': widget.event.performerStart != null ? DateTime.now() : null,
                }),
                operationName: 'restartPerformer',
              );

              if (!mounted) return;
              
          setState(() {
            widget.event.performer = null;
            widget.event.performerStart =
                    widget.event.performerStart != null ? DateTime.now() : null;
          });
        }
        break;
      case false:
            HapticFeedback.lightImpact();
            
            await _retryOperation(
              operation: () => FirebaseFirestore.instance.doc('events/${widget.event.id}').update({
          'performer': null,
          'performerStart': null,
              }),
              operationName: 'removePerformer',
            );

            if (!mounted) return;
            
        setState(() {
          widget.event.performer = null;
          widget.event.performerStart = null;
        });
        break;
      default:
        break;
        }
      } catch (e) {
        if (!mounted) return;
        
        Logger.e('Failed to lineup performer: $e', tag: 'Live');
        _showErrorDialog(
          'Failed to update performer. Please check your connection and try again.',
          retryAction: () => _lineupPerformer(widget.event, widget.event.performer, performer, displayName),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Logger.e('Failed to fetch user profile: $e', tag: 'Live');
      _showErrorDialog(
        'Failed to fetch user profile. Please try again.',
        retryAction: () => _lineupPerformer(widget.event, widget.event.performer, performer, username),
      );
    }
  }

  Future<void> _clearUpNext() async {
    try {
      await _retryOperation(
        operation: () => FirebaseFirestore.instance.doc('events/${widget.event.id}').update({
          'upNext': null,
        }),
        operationName: 'clearUpNext',
      );
      
      if (!mounted) return;
      
      setState(() {
        widget.event.upNext = null;
      });
    } catch (e) {
      if (!mounted) return;
      
      Logger.e('Failed to clear up next: $e', tag: 'Live');
      _showErrorDialog(
        'Failed to clear up next performer. Please check your connection and try again.',
        retryAction: _clearUpNext,
      );
    }
  }

  Future<void> _endEvent() async {
    final confirmation = await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("End Event"),
        content: const Column(
          children: [
            SizedBox(height: 8),
            Text("Are you sure you want to end this event?"),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("End"),
            onPressed: () => Navigator.of(context).pop(true),
          ),
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );

    if (confirmation != true) {
      return;
    }

    try {
      await _retryOperation(
        operation: () => FirebaseFirestore.instance.doc('events/${widget.event.id}').update({
      'live': false,
      'ended': true,
      'performer': null,
      'performerStart': null,
        }),
        operationName: 'endEvent',
      );

      if (!mounted) return;

    setState(() {
      widget.event.live = false;
      widget.event.ended = true;
      widget.event.performer = null;
      widget.event.performerStart = null;
    });
    } catch (e) {
      if (!mounted) return;
      
      Logger.e('Failed to end event: $e', tag: 'Live');
      _showErrorDialog(
        'Failed to end event. Please check your connection and try again.',
        retryAction: _endEvent,
      );
    }
  }



  Future<void> _toggleFlashlight() async {
    try {
      await _retryOperation(
        operation: () async {
      if (_isFlashlightOn) {
        await TorchLight.disableTorch();
      } else {
        await TorchLight.enableTorch();
      }
        },
        operationName: 'toggleFlashlight',
      );

      if (!mounted) return;
      
      setState(() {
        _isFlashlightOn = !_isFlashlightOn;
      });
    } catch (e) {
      String errorMessage = 'Unable to toggle flashlight';
      if (e.toString().contains('not available')) {
        errorMessage = 'Flashlight is not available on this device';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission to use flashlight was denied';
      }
      
      if (!mounted) return;
      
      Logger.e('Error toggling flashlight: $e', tag: 'Live');
      _showErrorDialog(
        errorMessage,
        retryAction: _toggleFlashlight,
      );
      
      // Reset flashlight state if error occurs
      setState(() {
        _isFlashlightOn = false;
      });
    }
  }

  Future<void> _startEvent() async {
    try {
      // Add strong haptic feedback when starting an event
      HapticFeedback.heavyImpact();
      
      await _retryOperation(
        operation: () => FirebaseFirestore.instance.doc('events/${widget.event.id}').update({
          'live': true,
        }),
        operationName: 'startEvent',
      );

      if (!mounted) return;
      
      setState(() {
        widget.event.live = true;
      });
      _confettiController?.play();
    } catch (e) {
      if (!mounted) return;
      
      Logger.e('Failed to start event: $e', tag: 'Live');
      _showErrorDialog(
        'Failed to start event. Please check your connection and try again.',
        retryAction: _startEvent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .doc('events/${widget.event.id}')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        
        final event = Event.fromDocument(snapshot.data!);
        final bool isHost = event.host == widget.user?.uid;

        return CupertinoPageScaffold(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              // Background
              const Positioned.fill(
                child: MovingBackground(),
              ),
              
              // Content
              Column(
                children: [
                  // Top section with event name and controls
                  Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 16,
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.9),
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button and Event name on the same line
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CupertinoButton(
                              padding: const EdgeInsets.all(4),
                              minSize: 28,
                              onPressed: () => Navigator.of(context).maybePop(),
                              child: const Icon(
                                CupertinoIcons.chevron_left,
                                color: AppColors.slottedOrange,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                event.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: CupertinoColors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Host info
                        FutureBuilder(
                          future: FirebaseFirestore.instance
                              .doc('users/${event.host}')
                              .get(),
                          builder: (context, snapshot) {
                            final hostName = snapshot.data?.exists ?? false
                                ? snapshot.data?.get('username') as String? ?? 'Host'
                                : 'Host';
                            return Row(
                              children: [
                                Icon(
                                  CupertinoIcons.person_crop_circle_fill,
                                  size: 18,
                                  color: CupertinoColors.white.withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Hosted by $hostName',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: CupertinoColors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        
                        // Timer control for host
                        if (isHost && !event.ended && event.performer != null) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _adjustTimeLimit(event, context, event.timeLimit.toString()),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: AppColors.slottedOrange.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.slottedOrange.withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppColors.slottedOrange.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                CupertinoIcons.timer,
                                                color: AppColors.slottedOrange,
                                                size: 22,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Performance Time",
                                                  style: TextStyle(
                                                    color: AppColors.slottedOrange,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Text(
                                                  "Tap to adjust",
                                                  style: TextStyle(
                                                    color: CupertinoColors.systemGrey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppColors.slottedOrange.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
              child: Text(
                                            event.timeLimit == 0 ? "∞" : "${event.timeLimit}m",
                                            style: const TextStyle(
                                              color: AppColors.slottedOrange,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 18,
              ),
            ),
          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: _toggleFlashlight,
          child: Container(
                                  padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                                    color: _isFlashlightOn 
                                      ? AppColors.slottedOrange 
                                      : AppColors.slottedOrange.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.slottedOrange.withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    _isFlashlightOn 
                                      ? CupertinoIcons.lightbulb_fill
                                      : CupertinoIcons.lightbulb,
                                    color: _isFlashlightOn 
                                      ? CupertinoColors.white
                                      : AppColors.slottedOrange,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Rest of the content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      child: Column(
                children: [
                          _buildTimerSection(event, isHost, Duration.zero),
                          if (isHost && !event.ended)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: _buildEventControls(event),
                            ),
                          if (event.upNext != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              child: _buildUpNextSection(event, isHost),
                            ),
                          if (event.rules.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: _buildRulesSection(event),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: isHost && !event.ended
                                ? _buildHostView(event, context)
                                : _buildAttendeeView(event, context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Add drag indicator when dragging
              if (_isDraggingPerformer)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _buildDragIndicator(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimerSection(Event event, bool isHost, Duration duration) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      child: FutureBuilder<DocumentSnapshot>(
                    future: event.performer == null
                        ? null
                        : FirebaseFirestore.instance
                            .doc('users/${event.performer}')
                            .get(),
                    builder: (context, snapshot) {
                      final username = snapshot.hasError
                          ? ''
                          : event.performer != null
                              ? snapshot.data?.exists ?? false
                                  ? snapshot.data?.get('username') as String? ??
                                      event.performer!
                                  : event.performer!
                              : 'No Performer';

          // Calculate progress and duration
          double progress = 1.0;
          Duration remainingDuration = Duration.zero;
          
          if (event.performerStart != null && event.timeLimit > 0) {
            final now = DateTime.now();
            final elapsedMs = now.difference(event.performerStart!).inMilliseconds;
            final totalMs = event.timeLimit * 60000;
            final remainingMs = totalMs - elapsedMs;
            
            // Calculate progress (1.0 to 0.0)
            progress = (remainingMs / totalMs).clamp(0.0, 1.0);
            
            // Calculate remaining duration in seconds for smoother display
            if (remainingMs > 0) {
              remainingDuration = Duration(milliseconds: remainingMs);
            }
          }

          return _buildTimerCircle(event, isHost, remainingDuration, username, progress);
        },
      ),
    );
  }

  Widget _buildTimerCircle(Event event, bool isHost, Duration duration,
      String username, double progress) {
    return SizedBox(
                                  width: 240,
                                  height: 240,
                                  child: Stack(
        alignment: Alignment.center,
                                    children: [
          if (_confettiController != null) ...[
            ConfettiWidget(
              confettiController: _confettiController!,
              blastDirection: -math.pi / 2,
              emissionFrequency: 0.02,
              numberOfParticles: 50,
              maxBlastForce: 80,
              minBlastForce: 40,
              gravity: 0.3,
              particleDrag: 0.05,
              colors: const [
                AppColors.slottedOrange,
                CupertinoColors.systemPink,
                CupertinoColors.systemIndigo,
                CupertinoColors.systemTeal,
                CupertinoColors.systemYellow,
                CupertinoColors.systemGreen,
              ],
              minimumSize: const Size(8, 8),
              maximumSize: const Size(12, 12),
              shouldLoop: false,
              blastDirectionality: BlastDirectionality.explosive,
            ),
            ConfettiWidget(
              confettiController: _confettiController!,
              blastDirection: math.pi,
              emissionFrequency: 0.01,
              numberOfParticles: 30,
              maxBlastForce: 60,
              minBlastForce: 30,
              gravity: 0.25,
              particleDrag: 0.05,
              colors: const [
                AppColors.slottedOrange,
                CupertinoColors.systemPink,
                CupertinoColors.systemIndigo,
                CupertinoColors.systemTeal,
                CupertinoColors.systemYellow,
                CupertinoColors.systemGreen,
              ],
              minimumSize: const Size(6, 6),
              maximumSize: const Size(10, 10),
              shouldLoop: false,
              blastDirectionality: BlastDirectionality.explosive,
            ),
          ],
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Transform.scale(
              scale: event.performer != null && event.performerStart != null && event.timeLimit > 0
                  ? _pulseAnimation.value 
                  : 1.0,
              child: SizedBox(
                                              width: 240,
                                              height: 240,
                child: DragTarget<String>(
                  onWillAcceptWithDetails: (data) {
                    if (isHost && !event.ended) {
                      setState(() => _isDroppingPerformer = true);
                      return true;
                    }
                    return false;
                  },
                  onLeave: (_) => setState(() => _isDroppingPerformer = false),
                  onAcceptWithDetails: (details) async {
                    setState(() => _isDroppingPerformer = false);
                    if (!mounted) return;
                    
                    try {
                      if (!mounted) return;
                      
                      // Remove the user profile check and directly call _lineupPerformer
                      _lineupPerformer(event, event.performer, details.data, details.data);
                    } catch (e) {
                      if (!mounted) return;
                      _showErrorDialog("Failed to load user profile");
                    }
                  },
                  builder: (context, candidateData, rejectedData) => Container(
                    decoration: event.ended
                        ? null
                        : BoxDecoration(
                            color: AppColors.backgroundDark.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(120),
                            border: Border.all(
                              color: _isDroppingPerformer 
                                  ? AppColors.slottedOrange.withValues(alpha: 0.8)
                                  : _isDraggingPerformer
                                      ? AppColors.slottedOrange.withValues(alpha: 0.5)
                                      : AppColors.accent.withValues(alpha: 0.2),
                              width: _isDroppingPerformer || _isDraggingPerformer ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _isDroppingPerformer
                                    ? AppColors.slottedOrange.withValues(alpha: 0.4)
                                    : _isDraggingPerformer
                                        ? AppColors.slottedOrange.withValues(alpha: 0.2)
                                        : AppColors.accent.withValues(alpha: 0.1),
                                blurRadius: _isDroppingPerformer || _isDraggingPerformer ? 25 : 20,
                                spreadRadius: _isDroppingPerformer || _isDraggingPerformer ? 8 : 5,
                              ),
                              
                              // Highlight glow effect for active states
                              if (_isDroppingPerformer || _isDraggingPerformer)
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              if (_isDroppingPerformer)
                                BoxShadow(
                                  color: AppColors.highlight.withValues(alpha: 0.3),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                  offset: const Offset(0, -5),
                                                  ),
                                                ],
                                              ),
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                        if (event.performer != null) ...[
                          FutureBuilder(
                            future: FirebaseFirestore.instance.doc('users/${event.performer}').get(),
                            builder: (context, snapshot) {
                              final photoUrl = snapshot.data?.exists ?? false
                                  ? snapshot.data?.get('photoUrl') as String? ?? placeholderImage
                                  : placeholderImage;
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(120),
                                child: Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: _getCachedImageProvider(photoUrl),
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                        AppColors.backgroundDark.withValues(alpha: 0.5),
                                        BlendMode.darken,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ] else
                          Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.backgroundDark.withValues(alpha: 0.5),
                            ),
                          ),
                                      SizedBox(
                          width: 220,
                          height: 220,
                                        child: CircularProgressIndicator(
                                          value: event.performer == null ||
                                                  event.timeLimit == 0 ||
                                                  event.performerStart == null
                                ? 1.0
                                : progress,
                            strokeWidth: 4,
                                          strokeCap: StrokeCap.round,
                            backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation(
                              progress <= 0.25 
                                ? CupertinoColors.systemRed.withValues(alpha: 0.8)
                                : AppColors.accent.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        _buildTimerDisplay(event, duration, progress),
                        if (isHost && !event.ended)
                          Positioned.fill(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(120),
                                onTap: event.performerStart == null
                                    ? event.performer == null 
                                        ? _startEvent 
                                        : _startPerforming
                                    : _stopPerforming,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: event.performerStart == null
                                        ? AppColors.primary.withValues(alpha: 0.1)
                                        : AppColors.highlight.withValues(alpha: 0.1),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      event.performerStart == null
                                          ? CupertinoIcons.play_fill
                                          : CupertinoIcons.stop_fill,
                                      size: 48,
                                      color: event.performerStart == null
                                          ? AppColors.primary
                                          : AppColors.highlight,
                                    ),
                                  ),
                                ),
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
        ],
      ),
    );
  }

  Widget _buildTimerDisplay(Event event, Duration duration, double progress) {
    final bool isHost = event.host == FirebaseAuth.instance.currentUser?.uid;
    
    return GestureDetector(
      onTap: isHost && !event.ended ? () {
        _adjustTimeLimit(event, context, event.timeLimit.toString());
      } : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (event.ended)
                const Text(
                  'Event Ended',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 36,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 3.0,
                        color: Color.fromRGBO(0, 0, 0, 0.5),
                      ),
                    ],
                    color: CupertinoColors.systemGrey,
                  ),
                )
              else if (event.timeLimit == 0)
                const Text(
                  '∞',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 42,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 3.0,
                        color: Color.fromRGBO(0, 0, 0, 0.5),
                      ),
                    ],
                    color: AppColors.accent,
                  ),
                )
              else if (event.performerStart == null)
                Column(
                                    children: [
                                      Text(
                      "${event.timeLimit}:00",
                                        style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 42,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 2),
                            blurRadius: 3.0,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                        ],
                                          color: event.performer != null
                            ? AppColors.accent
                                              : CupertinoColors.systemGrey,
                                        ),
                                      ),
                  ],
                )
              else
                                        Text(
                  '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 42,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 2),
                        blurRadius: 3.0,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ],
                    color: progress <= 0.25
                        ? CupertinoColors.systemRed
                        : AppColors.accent,
                  ),
                ),
                
              // Show the performer name or status
              if (event.performer != null && !event.ended) ...[
                const SizedBox(height: 8),
                FutureBuilder(
                  future: FirebaseFirestore.instance.doc('users/${event.performer}').get(),
                  builder: (context, snapshot) {
                    final username = snapshot.hasError
                        ? ''
                        : snapshot.data?.exists ?? false
                            ? snapshot.data?.get('username') as String? ?? event.performer!
                            : event.performer!;
                    return Text(
                                          username,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.white,
                      ),
                    );
                  },
                ),
              ],
              if (event.performer == null && !event.ended)
                                        Text(
                                          'No Performer',
                                          style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                                            color: event.performerStart != null
                                                ? CupertinoColors.systemGreen
                                                : CupertinoColors.systemGrey,
                                          ),
                                        ),
              if (event.ended)
                const Text(
                  'Event Ended',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                              ],
                            ),
        ],
      ),
    );
  }

  Widget _buildEventControls(Event event) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
            onPressed: event.live ? _endEvent : _startEvent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: event.live 
                  ? CupertinoColors.destructiveRed.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: event.live 
                    ? CupertinoColors.destructiveRed.withValues(alpha: 0.3)
                    : AppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: event.live 
                      ? CupertinoColors.destructiveRed.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                              children: [
                  Icon(
                    event.live 
                      ? CupertinoIcons.stop_circle
                      : CupertinoIcons.play_circle,
                    color: event.live 
                      ? CupertinoColors.destructiveRed
                      : AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    event.live ? 'End Event' : 'Start Event',
                    style: TextStyle(
                      color: event.live 
                        ? CupertinoColors.destructiveRed
                        : AppColors.primary,
                      fontSize: 16,
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
  }

  Widget _buildRulesSection(Event event) {
    return GestureDetector(
      onTap: () => _navigateToEventDetails(event, context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.07),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          constraints: const BoxConstraints(maxHeight: 100),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.doc_text,
                    color: AppColors.slottedOrange,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                            const Text(
                              'Rules',
                              style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.w800,
                      color: AppColors.slottedOrange,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: CupertinoColors.white.withValues(alpha: 0.9),
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          CupertinoColors.white,
                          CupertinoColors.white,
                          CupertinoColors.white.withValues(alpha: 0.1),
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                              child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: event.rules.split('\n').map((rule) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                            rule,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.white,
                                  height: 1.3,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
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

  Widget _buildHostView(Event event, BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
                          Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.all(8),
                        onPressed: () => _showAddPerformerDialog(event, context),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.add_circled),
                            SizedBox(width: 8),
                            Text("Add Performer"),
                          ],
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.all(8),
                      onPressed: () => _navigateToEventChat(event, context),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                              color: AppColors.slottedOrange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                color: AppColors.slottedOrange.withValues(alpha: 0.3),
                                width: 1,
                                  ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                                children: [
                                Icon(
                                  CupertinoIcons.chat_bubble_2_fill,
                                  color: AppColors.slottedOrange,
                                  size: 20,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "Chat",
                                  style: TextStyle(
                                    color: AppColors.slottedOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_unreadMessagesCount > 0)
                            Positioned(
                              top: -6,
                              right: -6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: CupertinoColors.systemRed,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  _unreadMessagesCount > 99 ? '99+' : _unreadMessagesCount.toString(),
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Adding a SizedBox to create some space
        const SizedBox(height: 8),
        // Remove the "Scroll to Bottom" button
        // Give the performers list a fixed height to prevent layout shifts
        _buildPerformersList(event, context),
        // Adding a SizedBox at the bottom to ensure there's padding after the list
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildAttendeeView(Event event, BuildContext context) {
    final bool isUserAttending = widget.user != null && event.attendees.contains(widget.user?.uid);
    final bool isUserWaitlisted = event.waitlist.contains(widget.user?.uid);
    final bool hasExistingReservation = isUserAttending || isUserWaitlisted;
    final bool isHost = event.host == widget.user?.uid;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
                                    children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                                        CupertinoButton(
                                          padding: const EdgeInsets.all(8),
                onPressed: () => _navigateToEventChat(event, context),
                child: Stack(
                  clipBehavior: Clip.none,
                                                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.slottedOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.slottedOrange.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.chat_bubble_2_fill,
                            color: AppColors.slottedOrange,
                            size: 22,
                          ),
                          SizedBox(width: 8),
                                                    Text(
                            "Event Chat",
                            style: TextStyle(
                              color: AppColors.slottedOrange,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                                                    ),
                                                  ],
                                                ),
                    ),
                    if (_unreadMessagesCount > 0)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: CupertinoColors.systemRed,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            _unreadMessagesCount > 99 ? '99+' : _unreadMessagesCount.toString(),
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.user != null && !event.ended && !isHost)
                CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  onPressed: () => _handleReserveButtonPress(event),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: hasExistingReservation 
                          ? CupertinoColors.destructiveRed.withValues(alpha: 0.1)
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: hasExistingReservation 
                            ? CupertinoColors.destructiveRed.withValues(alpha: 0.3)
                            : AppColors.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasExistingReservation
                              ? CupertinoIcons.xmark_circle_fill
                              : CupertinoIcons.ticket_fill,
                          color: hasExistingReservation
                              ? CupertinoColors.destructiveRed
                              : AppColors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasExistingReservation ? "Unreserve" : "Reserve Spot",
                          style: TextStyle(
                            color: hasExistingReservation
                                ? CupertinoColors.destructiveRed
                                : AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        _buildPerformersList(event, context),
        
        // Add waitlist section if there are users on the waitlist
        if (event.waitlist.isNotEmpty)
          _buildWaitlistSection(event),
          
        // Add extra padding at the bottom to ensure last item is fully visible
        const SizedBox(height: 40),
      ],
    );
  }

  Future<void> _handleReserveButtonPress(Event event) async {
    if (widget.user == null) return;
    
    final bool isUserAttending = event.attendees.contains(widget.user?.uid);
    final bool isUserWaitlisted = event.waitlist.contains(widget.user?.uid);
    final bool hasExistingReservation = isUserAttending || isUserWaitlisted;
    
    try {
      // Show loading indicator
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CupertinoAlertDialog(
          title: Text(hasExistingReservation ? "Unreserving..." : "Reserving..."),
          content: const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: CupertinoActivityIndicator(),
          ),
        ),
      );
      
      // Get the SlottedUser with retry
      final userDoc = await _retryOperation(
        operation: () => FirebaseFirestore.instance.doc('users/${widget.user!.uid}').get(),
        operationName: 'getUserProfile',
      );

      if (!mounted) return;
      
      if (!userDoc.exists) {
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorDialog("User profile not found");
        return;
      }
      
      final slottedUser = SlottedUser.fromDocument(userDoc);
      
      // Call the reserve action with retry
      await _retryOperation(
        operation: () => widget.reserveAction(event, slottedUser),
        operationName: 'reserveAction',
      );
      
      // Wait a moment for Firestore to update
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Fetch the updated event data with retry
      final updatedEventDoc = await _retryOperation(
        operation: () => FirebaseFirestore.instance.doc('events/${event.id}').get(),
        operationName: 'getUpdatedEvent',
      );

      if (!mounted) return;
      
      if (updatedEventDoc.exists) {
        final updatedEvent = Event.fromDocument(updatedEventDoc);
        
        if (isUserAttending) {
          // Check if the user was actually removed from the attendees list
          final wasRemoved = !updatedEvent.attendees.contains(widget.user!.uid);
          
          // If not removed, manually remove the user from the attendees list
          if (!wasRemoved) {
            await _retryOperation(
              operation: () async {
                // Get the current attendees list and remove the user
                List<String> updatedAttendees = List<String>.from(updatedEvent.attendees);
                updatedAttendees.remove(widget.user!.uid);
                
                // Get the current reservation timestamps and remove the user
                Map<String, dynamic> updatedTimestamps = Map<String, dynamic>.from(updatedEventDoc.data()?['reservationTimestamps'] ?? {});
                updatedTimestamps.remove(widget.user!.uid);
                
                // Update the document
                await FirebaseFirestore.instance.doc('events/${event.id}').update({
                  'attendees': updatedAttendees,
                  'reservationTimestamps': updatedTimestamps,
                });
              },
              operationName: 'removeUserFromEvent',
            );
          }
        } else if (isUserWaitlisted) {
          // Check if the user was actually removed from the waitlist
          final wasRemoved = !updatedEvent.waitlist.contains(widget.user!.uid);
          
          // If not removed, manually remove the user from the waitlist
          if (!wasRemoved) {
            await _retryOperation(
              operation: () async {
                // Get the current waitlist and remove the user
                List<String> updatedWaitlist = List<String>.from(updatedEvent.waitlist);
                updatedWaitlist.remove(widget.user!.uid);
                
                // Update the document
                await FirebaseFirestore.instance.doc('events/${event.id}').update({
                  'waitlist': updatedWaitlist,
                });
              },
              operationName: 'removeUserFromWaitlist',
            );
          }
                                                        } else {
          // Check if the event is full
          final bool isEventFull = updatedEvent.attendees.length >= updatedEvent.slots;
          
          // Check if the user was added to either attendees or waitlist
          final bool wasAddedToAttendees = updatedEvent.attendees.contains(widget.user!.uid);
          final bool wasAddedToWaitlist = updatedEvent.waitlist.contains(widget.user!.uid);
          
          // If user wasn't added to either, manually add them to the appropriate list
          if (!wasAddedToAttendees && !wasAddedToWaitlist) {
            await _retryOperation(
              operation: () async {
                if (isEventFull) {
                  // Add to waitlist if event is full
                  List<String> updatedWaitlist = List<String>.from(updatedEvent.waitlist);
                  updatedWaitlist.add(widget.user!.uid);
                  
                  await FirebaseFirestore.instance.doc('events/${event.id}').update({
                    'waitlist': updatedWaitlist,
                  });
                                                      } else {
                  // Add to attendees if event has space
                  List<String> updatedAttendees = List<String>.from(updatedEvent.attendees);
                  updatedAttendees.add(widget.user!.uid);
                  
                  // Get the current reservation timestamps and add the user
                  Map<String, dynamic> updatedTimestamps = Map<String, dynamic>.from(updatedEventDoc.data()?['reservationTimestamps'] ?? {});
                  updatedTimestamps[widget.user!.uid] = Timestamp.now();
                  
                  // Update the document
                  await FirebaseFirestore.instance.doc('events/${event.id}').update({
                    'attendees': updatedAttendees,
                    'reservationTimestamps': updatedTimestamps,
                  });
                }
              },
              operationName: 'addUserToEvent',
            );
          }
        }
      }
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      if (!mounted) return;
      
      // Show success message
                                                        showCupertinoDialog(
                                                          context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text("Success"),
          content: Text(hasExistingReservation 
              ? "You have successfully unreserved from this event."
              : "You have successfully reserved a spot!"),
                                                            actions: [
                                                              CupertinoDialogAction(
              child: const Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
                                                              ),
                                                            ],
                                                          ),
                                                        );
      
      // Refresh the page
      setState(() {});
      
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      if (!mounted) return;
      
      Logger.e('Failed to handle reserve button press: $e', tag: 'Live');
      _showErrorDialog(
        'Failed to update reservation. Please check your connection and try again.',
        retryAction: () => _handleReserveButtonPress(event),
      );
    }
  }
  
  void _showErrorDialog(String message, {VoidCallback? retryAction}) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          if (retryAction != null)
            CupertinoDialogAction(
              child: const Text("Retry"),
              onPressed: () {
                Navigator.of(context).pop();
                retryAction();
                                                    },
                                                  ),
                                                  CupertinoDialogAction(
            child: const Text("OK"),
            onPressed: () => Navigator.of(context).pop(),
                                                  ),
                                                ],
                                              ),
                                            );
  }

  Widget _buildPerformersList(Event event, BuildContext context) {
    if (event.attendees.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
              Icon(
                CupertinoIcons.person_add,
                size: 48,
                color: CupertinoColors.systemGrey,
              ),
              SizedBox(height: 16),
              Text(
                'No performers yet\nTap "Add Performer" to get started',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.systemGrey,
                ),
                                      ),
                                    ],
                                  ),
        ),
      );
    }

    // Exclude upNext from the main performer list
    final List<String> allPerformers = [
      event.host,
      ...event.attendees.where((id) => id != event.host && id != event.upNext)
    ];

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allPerformers.length,
                                            onReorder: (oldIndex, newIndex) {
        if (oldIndex < newIndex) {
                                                newIndex -= 1;
                                              }
        final List<String> newOrder = List<String>.from(allPerformers);
        final String item = newOrder.removeAt(oldIndex);
        newOrder.insert(newIndex, item);
        // Update Firestore
        _retryOperation(
          operation: () => FirebaseFirestore.instance
              .doc('events/${event.id}')
              .update({'attendees': newOrder.where((id) => id != event.host).toList()}),
          operationName: 'reorderPerformers',
        ).then((_) {
          if (!mounted) return;
                                              setState(() {
            event.attendees = newOrder.where((id) => id != event.host).toList();
          });
          HapticFeedback.selectionClick();
        }).catchError((e) {
          if (!mounted) return;
          Logger.e('Failed to reorder performers: $e', tag: 'Live');
          _showErrorDialog(
            'Failed to update performer order. Please try again.',
            retryAction: () {
              final List<String> retryOrder = List<String>.from(allPerformers);
              final String retryItem = retryOrder.removeAt(oldIndex);
              retryOrder.insert(newIndex, retryItem);
                                              FirebaseFirestore.instance
                                                  .doc('events/${event.id}')
                  .update({'attendees': retryOrder.where((id) => id != event.host).toList()});
            },
          );
                                              });
                                            },
                                            itemBuilder: (context, index) {
        final performerId = allPerformers[index];
        return KeyedSubtree(
                                                key: ValueKey(performerId),
          child: _buildPerformerListItem(performerId, event, context),
        );
      },
    );
  }

  Widget _buildPerformerListItem(String performerId, Event event, BuildContext context) {
    final bool isHost = event.host == widget.user?.uid;
    final bool canDrag = isHost && !event.ended && event.live;
    final bool isChecked = event.checkedPerformers.contains(performerId);
    final bool isEventHost = performerId == event.host;
    
    // Create the base list tile
    Widget listTile = GestureDetector(
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => ProfilePage(userId: performerId),
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        color: isEventHost 
          ? AppColors.slottedOrange.withValues(alpha: 0.05)
          : CupertinoColors.secondaryLabel.withValues(alpha: 0.05),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isEventHost 
              ? AppColors.slottedOrange.withValues(alpha: 0.3)
              : CupertinoColors.secondaryLabel.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Reorder Handle for host
            if (isHost && !event.ended && !isEventHost)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: ReorderableDragStartListener(
                  index: event.attendees.indexOf(performerId),
                  child: Icon(
                    CupertinoIcons.bars,
                    color: CupertinoColors.systemGrey.withValues(alpha: 0.8),
                    size: 20,
                                                                      ),
                                                                    ),
                                                                  ),
            // Main content
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: (isHost && !event.ended && !isEventHost) ? 8 : 16,
                  right: 16,
                  top: 8,
                  bottom: 8,
                ),
                child: Row(
                  children: [
                    // Avatar
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: Stack(
                        children: [
                          _buildPerformerAvatar(performerId),
                          if (isEventHost)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.slottedOrange,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: CupertinoColors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  CupertinoIcons.star_fill,
                                  color: CupertinoColors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name and Status
                    Expanded(
                      child: Row(
                                                        children: [
                          // Name
                          Expanded(
                            child: _buildPerformerName(performerId),
                          ),
                          // Status and Check
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(child: _buildPerformerStatus(performerId, event)),
                              if (isHost && !isEventHost) ...[
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () => _togglePerformerCheck(performerId, event),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isChecked ? AppColors.slottedOrange : Colors.transparent,
                                      border: Border.all(
                                        color: isChecked ? AppColors.slottedOrange : Colors.grey.withValues(alpha: 0.5),
                                        width: 2,
                                      ),
                                    ),
                                    child: isChecked
                                      ? const Icon(
                                          CupertinoIcons.checkmark,
                                          color: CupertinoColors.white,
                                          size: 16,
                                        )
                                      : null,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Enhanced drag-to-perform functionality with auto-scroll
    if (canDrag && !isEventHost) {
      return LongPressDraggable<String>(
        data: performerId,
        hapticFeedbackOnStart: true,
        maxSimultaneousDrags: 1,
        dragAnchorStrategy: (draggable, context, position) {
          return const Offset(20, 20);
        },
        onDragStarted: () {
          _handleDragStarted(performerId);
        },
        onDragUpdate: (details) => _handleDragUpdate(details, context),
        onDragEnd: (_) => _handleDragEnd(DragEndDetails(velocity: Velocity.zero)),
        onDraggableCanceled: (_, __) {
          _stopAutoScroll();
          setState(() {
            _isDraggingPerformer = false;
            _draggingPerformerId = null;
            _activeDropZone = null;
            // _dragPosition = null;
          });
        },
        feedback: AnimatedBuilder(
          animation: _dragAnimationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _dragScaleAnimation.value,
              child: Transform.rotate(
                angle: _dragRotationAnimation.value,
                child: Material(
                  color: Colors.transparent,
                  elevation: 12,
                  shape: const CircleBorder(),
                  child: Container(
                    width: dragFeedbackSize,
                    height: dragFeedbackSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.slottedOrange.withValues(alpha: 0.9),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.slottedOrange.withValues(alpha: 0.6),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                                                                        ),
                                                                      ],
                                                                    ),
                    child: Stack(
                      children: [
                        _buildPerformerAvatar(performerId),
                        // Animated pulse effect
                        Positioned.fill(
                          child: AnimatedOpacity(
                            opacity: _isDraggingPerformer ? 0.3 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.slottedOrange.withValues(alpha: 0.8),
                                    AppColors.slottedOrange.withValues(alpha: 0.0),
                                  ],
                                ),
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
          },
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: _isDraggingPerformer && _draggingPerformerId == performerId
              ? (Matrix4.identity()..scale(0.95))
              : Matrix4.identity(),
          child: listTile,
        ),
      );
    }
    return listTile;
  }

  Widget _buildPerformerStatus(String performerId, Event event) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: Row(
        mainAxisSize: MainAxisSize.min,
                                                        children: [
          if (event.host == performerId) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.slottedOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.slottedOrange,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.slottedOrange.withValues(alpha: 0.15),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                "HOST",
                style: GoogleFonts.inter(
                  color: AppColors.slottedOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (event.performer == performerId) ...[
            const Flexible(
              child: Text(
                                                              "Performing",
                                                              style: TextStyle(
                  color: AppColors.slottedOrange,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (event.upNext == performerId) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: CupertinoColors.systemPurple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: CupertinoColors.systemPurple,
                  width: 1,
                ),
              ),
              child: Text(
                "NEXT",
                style: GoogleFonts.inter(
                  color: CupertinoColors.systemPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (event.reservationTimestamps[performerId] != null)
            Flexible(
              child: Text(
                _formatTimeSince(event.reservationTimestamps[performerId]!),
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                                                                fontSize: 14,
                                                              ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _togglePerformerCheck(String performerId, Event event) async {
    try {
      // Get current checked performers
      Set<String> checkedPerformers = Set<String>.from(event.checkedPerformers);
      
      // Toggle the performer's checked status
      if (checkedPerformers.contains(performerId)) {
        checkedPerformers.remove(performerId);
      } else {
        checkedPerformers.add(performerId);
      }
      
      // Update Firestore
      await _retryOperation(
        operation: () => FirebaseFirestore.instance
            .doc('events/${event.id}')
            .update({'checkedPerformers': checkedPerformers.toList()}),
        operationName: 'togglePerformerCheck',
      );

      // Update local state
      if (!mounted) return;
      setState(() {
        event.checkedPerformers = checkedPerformers;
      });
      
      // Add haptic feedback
      HapticFeedback.selectionClick();
      
    } catch (e) {
      if (!mounted) return;
      Logger.e('Failed to toggle performer check: $e', tag: 'Live');
      _showErrorDialog(
        'Failed to update performer status. Please try again.',
        retryAction: () => _togglePerformerCheck(performerId, event),
      );
    }
  }

  Widget _buildPerformerAvatar(String performerId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.doc('users/$performerId').snapshots(),
      builder: (context, snapshot) {
        final photoUrl = snapshot.data?.exists ?? false
            ? snapshot.data?.get('photoUrl') as String? ?? placeholderImage
            : placeholderImage;
        return CircleAvatar(
          backgroundColor: photoUrl.isEmpty ? AppColors.primary.withValues(alpha: 0.1) : null,
          backgroundImage: photoUrl.isNotEmpty ? _getCachedImageProvider(photoUrl) : null,
          child: photoUrl.isEmpty
              ? Icon(
                  CupertinoIcons.person,
                  size: 20,
                  color: AppColors.primary.withValues(alpha: 0.5),
                )
              : null,
        );
      },
    );
  }

  Widget _buildPerformerName(String performerId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.doc('users/$performerId').snapshots(),
      builder: (context, snapshot) {
        final username = snapshot.hasError
            ? performerId
            : snapshot.data?.exists ?? false
                ? snapshot.data?.get('username') as String? ?? performerId
                : performerId;
        return Text(
          username,
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            color: CupertinoColors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        );
      },
    );
  }



  void _showAddPerformerDialog(Event event, BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Add Performer"),
        content: Column(
          children: [
            Text("\n${event.slots - event.attendees.length <= 0 ? 'Current available slots = 0, adding a performer will increase available slots +1' : 'Enter performer\'s name'}"),
            const SizedBox(height: 8),
            CupertinoTextField(
              autofocus: true,
              controller: controller,
              placeholder: "Name",
                                  ),
                                ],
                              ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Add"),
            onPressed: () async {
              Navigator.of(context).pop();
              final newName = controller.text.trim();
              if (newName.isNotEmpty && !widget.event.attendees.contains(newName)) {
                setState(() {
                  widget.event.attendees.add(newName);
                  widget.event.reservationTimestamps[newName] = DateTime.now();
                });
                
                try {
                  if (event.slots - event.attendees.length <= 0) {
                    await FirebaseFirestore.instance
                        .doc('events/${event.id}')
                        .update({
                      'slots': event.slots + 1,
                      'attendees': widget.event.attendees,
                      'reservationTimestamps': widget.event.reservationTimestamps,
                    });
                  } else {
                    await FirebaseFirestore.instance
                        .doc('events/${event.id}')
                        .update({
                      'attendees': widget.event.attendees,
                      'reservationTimestamps': widget.event.reservationTimestamps,
                    });
                  }
                } catch (e) {
                  Logger.e('Failed to add performer: $e', tag: 'Live');
                  if (mounted) {
                    _showErrorDialog('Failed to add performer. Please try again.');
                  }
                }
                
                // Improved scroll to bottom with better implementation
                if (mounted) {
                  // Update the state first
                  setState(() {});
                  
                  // Use the smooth scroll helper
                  _scrollToBottomSmoothly();
                }
                
                // Check if widget is still mounted after async operations
                if (!mounted) return;
                
              } else {
                // Store context in a local variable to avoid using context after async gap
                final currentContext = context;
                
                // Check if widget is still mounted before showing dialog
                if (!mounted) return;
                
                showCupertinoDialog(
                  context: currentContext,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text("Error"),
                    content: const Text("This performer is already added or the name is empty."),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text("OK"),
                        onPressed: () => Navigator.of(context).pop(),
                                  ),
                                ],
                              ),
                );
              }
            },
          ),
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
    
    // Check if widget is still mounted after the dialog is closed
    if (!mounted) return;
  }

  void _navigateToEventDetails(Event event, BuildContext context) {
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

  void _navigateToEventChat(Event event, BuildContext context) async {
    // Update last chat open time
    await _updateLastChatOpenTime();
    
    // Navigate to chat
    if (!mounted) return;
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => EventChatPage(
          event: event,
          user: widget.user,
        ),
      ),
    );
  }

  // Add this method for retrying Firestore operations
  Future<T> _retryOperation<T>({
    required Future<T> Function() operation,
    String? operationName,
  }) async {
    int attempts = 0;
    Exception? lastError;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        lastError = e as Exception;
        attempts++;
        
        if (attempts < maxRetries) {
          Logger.d('Retrying $operationName (attempt $attempts/$maxRetries)', tag: 'Live');
          await Future.delayed(retryDelay * attempts); // Exponential backoff
        }
      }
    }

    throw lastError ?? Exception('Operation failed after $maxRetries attempts');
  }



  // Define the scroll to bottom method
  void _scrollToBottomSmoothly() {
    if (!mounted || !_scrollController.hasClients) return;
    
    try {
      // Get the maximum scroll extent
      final maxScroll = _scrollController.position.maxScrollExtent;
      
      // Use a more conservative target that doesn't try to go right to the edge
      // This prevents potential issues with overscrolling
      _scrollController.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } catch (e) {
      Logger.e('Error scrolling to bottom: $e', tag: 'Live');
    }
  }



  // Add method to get cached image provider
  CachedNetworkImageProvider _getCachedImageProvider(String photoUrl) {
    if (!_imageCache.containsKey(photoUrl)) {
      _imageCache[photoUrl] = CachedNetworkImageProvider(
        photoUrl,
        errorListener: (url) {
          Logger.e('Failed to load image: $url', tag: 'Live');
        },
      );
    }
    return _imageCache[photoUrl]!;
  }

  Future<void> _fetchEventData() async {
    try {
      final eventDoc = await _retryOperation(
        operation: () => FirebaseFirestore.instance
            .doc('events/${widget.event.id}')
            .get(),
        operationName: 'fetchEventData',
      );
      
      if (!mounted) return;
      
      if (eventDoc.exists) {
        final event = Event.fromDocument(eventDoc);
        
        setState(() {
          widget.event.live = event.live;
          widget.event.ended = event.ended;
          widget.event.performer = event.performer;
          widget.event.performerStart = event.performerStart;
          widget.event.timeLimit = event.timeLimit;
          widget.event.name = event.name;
          widget.event.attendees = event.attendees;
          widget.event.reservationTimestamps = event.reservationTimestamps;
          widget.event.checkedPerformers = event.checkedPerformers;
          
          // Remove pagination-related state updates
        });
      } else {
        Logger.e('Event document does not exist: ${widget.event.id}', tag: 'Live');
        if (mounted) {
          _showErrorDialog(
            'Event not found. Please check if the event still exists.',
            retryAction: _fetchEventData,
          );
        }
      }
    } catch (e) {
      Logger.e('Failed to fetch event data: $e', tag: 'Live');
      if (mounted) {
        _showErrorDialog(
          'Failed to load event data. Please check your connection and try again.',
          retryAction: _fetchEventData,
        );
      }
    }
  }

  // Add method to subscribe to messages and count unread ones
  void _subscribeToMessages() {
    if (widget.event.id.isNotEmpty) {
      // Get the last time the user opened the chat
      _getLastChatOpenTime().then((lastChatOpenTime) {
        // Subscribe to messages collection to get unread count
        _messagesSubscription = FirebaseFirestore.instance
            .collection('events')
            .doc(widget.event.id)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .snapshots()
            .listen((snapshot) {
          if (!mounted) return;
          
          // Count messages newer than last chat open time
          int unreadCount = 0;
          for (var doc in snapshot.docs) {
            final timestamp = doc['timestamp'] as Timestamp?;
            if (timestamp != null) {
              final messageTime = timestamp.toDate();
              if (lastChatOpenTime == null || messageTime.isAfter(lastChatOpenTime)) {
                unreadCount++;
              }
            }
          }
          
          setState(() {
            _unreadMessagesCount = unreadCount;
          });
        });
      });
    }
  }
  
  // Get the last time user opened the chat
  Future<DateTime?> _getLastChatOpenTime() async {
    if (widget.user == null) return null;
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user!.uid)
          .collection('chatLastOpened')
          .doc(widget.event.id)
          .get();
          
      if (doc.exists && doc.data() != null && doc.data()!['timestamp'] != null) {
        return (doc.data()!['timestamp'] as Timestamp).toDate();
      }
    } catch (e) {
      Logger.e('Error getting last chat open time: $e', tag: 'Live');
    }
    
    return null;
  }
  
  // Update the last time user opened the chat
  Future<void> _updateLastChatOpenTime() async {
    if (widget.user == null) return;
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user!.uid)
          .collection('chatLastOpened')
          .doc(widget.event.id)
          .set({
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Reset unread count locally
      setState(() {
        _unreadMessagesCount = 0;
      });
    } catch (e) {
      Logger.e('Error updating last chat open time: $e', tag: 'Live');
    }
  }

  // Add this new widget to show the Up Next performer
  Widget _buildUpNextSection(Event event, bool isHost) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemPurple.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
                              child: Row(
                                children: [
          const Icon(
            CupertinoIcons.arrow_up_circle_fill,
            color: CupertinoColors.systemPurple,
            size: 16,
          ),
          const SizedBox(width: 6),
          const Text(
            "UP NEXT:",
            style: TextStyle(
              color: CupertinoColors.systemPurple,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
                                    Expanded(
            child: FutureBuilder(
              future: FirebaseFirestore.instance.doc('users/${event.upNext}').get(),
              builder: (context, snapshot) {
                final upNextName = snapshot.data?.exists ?? false
                    ? snapshot.data?.get('username') as String? ?? event.upNext
                    : event.upNext;
                return Row(
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: _buildPerformerAvatar(event.upNext!),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        upNextName ?? "Unknown",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (isHost)
            CupertinoButton(
                                      padding: EdgeInsets.zero,
              onPressed: _clearUpNext,
              child: const Icon(
                CupertinoIcons.xmark_circle_fill,
                color: CupertinoColors.systemPurple,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  // Add method to handle scroll position changes
  void _handleScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    
    // Ensure we avoid updates during overscroll
    if (_scrollController.position.pixels < _scrollController.position.maxScrollExtent + 50 && 
        _scrollController.position.pixels > _scrollController.position.maxScrollExtent - 150) {
      if (!_isAtBottom || !_showScrollButton) {
        setState(() {
          _showScrollButton = true;
          _isAtBottom = true;
        });
      }
    } else if (_scrollController.position.pixels < _scrollController.position.maxScrollExtent - 150) {
      if (_isAtBottom) {
                                                      setState(() {
          _isAtBottom = false;
        });
      }
      
      if (!_showScrollButton) {
        setState(() {
          _showScrollButton = true;
        });
      }
    }
  }

  // Enhanced method to handle auto-scrolling and drop zone detection
  void _handleDragUpdate(DragUpdateDetails details, BuildContext context) {
    setState(() {
      // _dragPosition = details.globalPosition;
    });
    
    _autoScrollTimer?.cancel();
    
    // Get the drag position relative to the screen
    final dragY = details.globalPosition.dy;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Define scroll zones (even larger to increase responsiveness)
    final topThreshold = screenHeight * 0.5; // Increased from 0.4 to 0.5
    final bottomThreshold = screenHeight * 0.5; // Decreased from 0.6 to 0.5
    
    // Fling to the top when user gets very close to the top 20% of the screen
    if (dragY < screenHeight * 0.2 && !_hasPerformedFling && _scrollController.hasClients && _scrollController.offset > 0) {
      // Perform a fling to the top
      _hasPerformedFling = true;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
      );
      return;
    }
    
    // Reset fling flag if user is no longer at the top
    if (dragY > screenHeight * 0.25) {
      _hasPerformedFling = false;
    }
    
    if (dragY < topThreshold || dragY > bottomThreshold) {
      _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 8), (timer) {
        if (!mounted || !_scrollController.hasClients) {
          timer.cancel();
          return;
        }

        // Calculate scroll amount based on position with significantly increased speed
        double scrollAmount = 0;
        if (dragY < topThreshold) {
          // Scroll up when near top with increased speed and smoother acceleration
          final factor = 1 - (dragY / topThreshold);
          scrollAmount = -40.0 * math.pow(factor, 1.3);
        } else if (dragY > bottomThreshold) {
          // Scroll down when near bottom with increased speed and smoother acceleration
          final factor = (dragY - bottomThreshold) / (screenHeight - bottomThreshold);
          scrollAmount = 40.0 * math.pow(factor, 1.3);
        }

        // Ensure we don't scroll beyond bounds and apply smooth scrolling
        final newOffset = (_scrollController.offset + scrollAmount)
            .clamp(0.0, _scrollController.position.maxScrollExtent);
            
        if (_scrollController.offset != newOffset) {
          // Use jumpTo for immediate response
          _scrollController.jumpTo(newOffset);
        }
      });
    }
    
    // Update active drop zone
    _updateActiveDropZone(details.globalPosition);
  }

  // Add this method to stop auto-scrolling
  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _hasPerformedFling = false;
  }

  // Updated drag indicator with animated content
  Widget _buildDragIndicator() {
    if (!_isDraggingPerformer) return const SizedBox.shrink();
    
    return SafeArea(
      child: AnimatedOpacity(
        opacity: _isDraggingPerformer ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: AppColors.slottedOrange.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated arrow that moves up slightly
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 4),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                builder: (context, double value, child) {
                  return Transform.translate(
                    offset: Offset(0, -value),
                    child: const Icon(
                      CupertinoIcons.arrow_up,
                      color: CupertinoColors.white,
                      size: 18,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              const Text(
                "Drop in circle to add performer",
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
      ),
    );
  }

  // Find the _buildWaitlistTile method or add it near the _buildPerformerListItem method
  Widget _buildWaitlistTile(String userId, Event event) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
            child: Row(
              children: [
                CupertinoActivityIndicator(),
                SizedBox(width: 12),
                Text('Loading...', style: TextStyle(color: CupertinoColors.label)),
              ],
            ),
          );
        }
        
        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final username = userData?['username'] ?? 'Unknown User';
        final photoUrl = userData?['photoUrl'] ?? '';
        
        // Check if this is the last item in the waitlist
        final isLastItem = event.waitlist.last == userId;
        
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          decoration: BoxDecoration(
            border: isLastItem 
                ? null 
                : Border(
                    bottom: BorderSide(
                      color: CupertinoColors.systemGrey6.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: photoUrl.isNotEmpty 
                    ? NetworkImage(photoUrl) 
                    : const NetworkImage('https://upload.wikimedia.org/wikipedia/commons/c/cd/Portrait_Placeholder_Square.png'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Waitlist position: ${event.getWaitlistPosition(userId)}',
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
              if (_isEventHost(event))
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  minSize: 30,
                  child: const Text(
                    'Force Add',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onPressed: () => _forceAddUserToEvent(userId, event),
                ),
            ],
          ),
        );
      },
    );
  }

  // Add this method to check if current user is the event host
  bool _isEventHost(Event event) {
    return widget.user?.uid == event.host;
  }

  // Add this method to handle force adding a user
  Future<void> _forceAddUserToEvent(String userId, Event event) async {
    try {
      // Show loading dialog
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const CupertinoAlertDialog(
          title: Text("Adding user..."),
          content: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: CupertinoActivityIndicator(),
          ),
        ),
      );
      
      // Get the updated event data
      final eventDoc = await FirebaseFirestore.instance.doc('events/${event.id}').get();
      final updatedEvent = Event.fromDocument(eventDoc);
      
      // Update variables for the firestore update
      List<String> updatedAttendees = List<String>.from(updatedEvent.attendees);
      List<String> updatedWaitlist = List<String>.from(updatedEvent.waitlist);
      Map<String, dynamic> updatedReservationData = Map<String, dynamic>.from(
          eventDoc.data()?['reservationTimestamps'] ?? {});
      
      // Check if user is in waitlist
      if (updatedWaitlist.contains(userId)) {
        // Remove from waitlist
        updatedWaitlist.remove(userId);
        
        // Add to attendees if not already there
        if (!updatedAttendees.contains(userId)) {
          updatedAttendees.add(userId);
          updatedReservationData[userId] = Timestamp.now();
        }
        
        // Update firestore
        await FirebaseFirestore.instance.doc('events/${event.id}').update({
          'attendees': updatedAttendees,
          'waitlist': updatedWaitlist,
          'reservationTimestamps': updatedReservationData,
        });
        
        // Close loading dialog
        if (mounted) Navigator.of(context).pop();
        
        // Show success dialog
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text("Success"),
              content: const Text("User has been moved from waitlist to attendees list"),
              actions: [
                CupertinoDialogAction(
                  child: const Text("OK"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
        
        // Update state - we need to convert the timestamps to DateTime for the local state
        Map<String, DateTime> localReservationTimestamps = {};
        updatedReservationData.forEach((key, value) {
          if (value is Timestamp) {
            localReservationTimestamps[key] = value.toDate();
          }
        });
        
        setState(() {
          event.attendees = updatedAttendees;
          event.waitlist = updatedWaitlist;
          event.reservationTimestamps = localReservationTimestamps;
        });
      } else {
        // Close loading dialog
        if (mounted) Navigator.of(context).pop();
        
        // Show error message if user isn't in waitlist
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text("Error"),
              content: const Text("User is no longer in the waitlist"),
              actions: [
                CupertinoDialogAction(
                  child: const Text("OK"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      // Show error dialog
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text("Error"),
            content: Text("Failed to add user: ${e.toString()}"),
            actions: [
              CupertinoDialogAction(
                child: const Text("OK"),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
      
      Logger.e('Error in _forceAddUserToEvent: $e', tag: 'Live');
    }
  }

  // Make sure to add the import at the top of the file
  // import 'package:cloud_functions/cloud_functions.dart';

  // Find the section where you build the waitlist and modify it to use the _buildWaitlistTile method
  Widget _buildWaitlistSection(Event event) {
    if (event.waitlist.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Clickable header for waitlist
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            setState(() {
              _isWaitlistExpanded = !_isWaitlistExpanded;
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.slottedOrange.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.time,
                  color: AppColors.slottedOrange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Waitlist (${event.waitlist.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slottedOrange,
                  ),
                ),
                const Spacer(),
                Icon(
                  _isWaitlistExpanded 
                    ? CupertinoIcons.chevron_up 
                    : CupertinoIcons.chevron_down,
                  color: AppColors.slottedOrange,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        
        // Show waitlist items only if expanded
        if (_isWaitlistExpanded)
          Column(
            children: event.waitlist.map((userId) {
              return _buildWaitlistTile(userId, event);
            }).toList(),
          ),
      ],
    );
  }
}


