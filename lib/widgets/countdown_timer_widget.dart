import 'dart:async';
import 'package:flutter/material.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/utils/logger.dart';

/// Real-time countdown timer widget for events
class CountdownTimerWidget extends StatefulWidget {
  final Event event;
  final TextStyle? textStyle;
  final bool showLabels;
  final bool compact;
  final VoidCallback? onExpired;
  final VoidCallback? onAlmostExpired; // Called when < 5 minutes remaining

  const CountdownTimerWidget({
    super.key,
    required this.event,
    this.textStyle,
    this.showLabels = true,
    this.compact = false,
    this.onExpired,
    this.onAlmostExpired,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget>
    with TickerProviderStateMixin {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _hasExpired = false;
  bool _almostExpiredTriggered = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupPulseAnimation();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _setupPulseAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _startTimer() {
    _updateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingTime();
    });
  }

  void _updateRemainingTime() {
    final now = DateTime.now();
    final difference = widget.event.date.difference(now);

    setState(() {
      _remainingTime = difference.isNegative ? Duration.zero : difference;
      
      // Check if expired
      if (_remainingTime.inSeconds <= 0 && !_hasExpired) {
        _hasExpired = true;
        _timer?.cancel();
        widget.onExpired?.call();
        Logger.d('Event ${widget.event.id} countdown expired', tag: 'CountdownTimer');
      }
      
      // Check if almost expired (5 minutes remaining)
      else if (_remainingTime.inMinutes <= 5 && 
               _remainingTime.inMinutes > 0 && 
               !_almostExpiredTriggered) {
        _almostExpiredTriggered = true;
        _pulseController.repeat(reverse: true);
        widget.onAlmostExpired?.call();
        Logger.d('Event ${widget.event.id} countdown almost expired', tag: 'CountdownTimer');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasExpired) {
      return _buildExpiredWidget();
    }

    if (widget.compact) {
      return _buildCompactTimer();
    }

    return _buildFullTimer();
  }

  Widget _buildExpiredWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            color: Colors.red,
            size: widget.compact ? 16 : 20,
          ),
          const SizedBox(width: 6),
          Text(
            'Event Started',
            style: (widget.textStyle ?? const TextStyle()).copyWith(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTimer() {
    final timeText = _formatCompactTime(_remainingTime);
    final isUrgent = _remainingTime.inMinutes <= 5;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isUrgent ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getTimerColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _getTimerColor().withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  color: _getTimerColor(),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  timeText,
                  style: (widget.textStyle ?? const TextStyle()).copyWith(
                    color: _getTimerColor(),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullTimer() {
    final timeComponents = _getTimeComponents(_remainingTime);
    final isUrgent = _remainingTime.inMinutes <= 5;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isUrgent ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getTimerColor().withValues(alpha: 0.1),
                  _getTimerColor().withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getTimerColor().withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.schedule,
                      color: _getTimerColor(),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getTimerTitle(),
                      style: (widget.textStyle ?? const TextStyle()).copyWith(
                        color: _getTimerColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (timeComponents['days']! > 0)
                      _buildTimeUnit(timeComponents['days']!, 'Days'),
                    if (timeComponents['hours']! > 0 || timeComponents['days']! > 0)
                      _buildTimeUnit(timeComponents['hours']!, 'Hours'),
                    _buildTimeUnit(timeComponents['minutes']!, 'Minutes'),
                    if (timeComponents['days']! == 0) // Only show seconds if less than a day
                      _buildTimeUnit(timeComponents['seconds']!, 'Seconds'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeUnit(int value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _getTimerColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: (widget.textStyle ?? const TextStyle()).copyWith(
              color: _getTimerColor(),
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
        if (widget.showLabels) ...[
          const SizedBox(height: 4),
          Text(
            label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          ),
        ],
      ],
    );
  }

  String _getTimerTitle() {
    final days = _remainingTime.inDays;
    final hours = _remainingTime.inHours;
    final minutes = _remainingTime.inMinutes;

    if (days > 0) {
      return 'Event in $days day${days == 1 ? '' : 's'}';
    } else if (hours > 0) {
      return 'Event in $hours hour${hours == 1 ? '' : 's'}';
    } else if (minutes > 30) {
      return 'Event starting soon';
    } else if (minutes > 5) {
      return 'Event starting very soon!';
    } else {
      return 'Event starting now!';
    }
  }

  Color _getTimerColor() {
    final minutes = _remainingTime.inMinutes;
    
    if (minutes <= 5) {
      return Colors.red; // Urgent
    } else if (minutes <= 30) {
      return Colors.orange; // Warning
    } else if (_remainingTime.inHours <= 2) {
      return Colors.amber; // Notice
    } else {
      return AppColors.primary; // Normal
    }
  }

  String _formatCompactTime(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (days > 0) {
      return '${days}d ${hours}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  Map<String, int> _getTimeComponents(Duration duration) {
    return {
      'days': duration.inDays,
      'hours': duration.inHours % 24,
      'minutes': duration.inMinutes % 60,
      'seconds': duration.inSeconds % 60,
    };
  }
}

/// Countdown timer service for managing multiple timers
class CountdownTimerService {
  static final CountdownTimerService _instance = CountdownTimerService._internal();
  static CountdownTimerService get instance => _instance;

  final Map<String, Timer> _activeTimers = {};
  final Map<String, VoidCallback> _expirationCallbacks = {};

  CountdownTimerService._internal();

  /// Start a countdown timer for an event
  void startEventTimer({
    required String eventId,
    required DateTime eventDate,
    VoidCallback? onExpired,
    VoidCallback? onAlmostExpired,
  }) {
    // Cancel existing timer if any
    stopEventTimer(eventId);

    final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final remaining = eventDate.difference(now);

      if (remaining.inSeconds <= 0) {
        // Event has started/expired
        timer.cancel();
        _activeTimers.remove(eventId);
        onExpired?.call();
        Logger.d('Event $eventId timer expired', tag: 'CountdownTimerService');
      } else if (remaining.inMinutes <= 5 && remaining.inMinutes > 4) {
        // Almost expired (trigger only once when crossing 5-minute mark)
        onAlmostExpired?.call();
        Logger.d('Event $eventId timer almost expired', tag: 'CountdownTimerService');
      }
    });

    _activeTimers[eventId] = timer;
    if (onExpired != null) {
      _expirationCallbacks[eventId] = onExpired;
    }
  }

  /// Stop a countdown timer for an event
  void stopEventTimer(String eventId) {
    _activeTimers[eventId]?.cancel();
    _activeTimers.remove(eventId);
    _expirationCallbacks.remove(eventId);
  }

  /// Check if an event has an active timer
  bool hasActiveTimer(String eventId) {
    return _activeTimers.containsKey(eventId);
  }

  /// Get time remaining for an event
  Duration getTimeRemaining(DateTime eventDate) {
    final now = DateTime.now();
    final difference = eventDate.difference(now);
    return difference.isNegative ? Duration.zero : difference;
  }

  /// Stop all active timers
  void stopAllTimers() {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
    _expirationCallbacks.clear();
  }

  /// Get count of active timers
  int get activeTimerCount => _activeTimers.length;

  /// Dispose the service
  void dispose() {
    stopAllTimers();
  }
}
