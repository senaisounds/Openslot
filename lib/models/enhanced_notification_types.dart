/// Enhanced notification types and categories for OpenSlot
enum NotificationCategory {
  eventUpdates,
  socialInteractions,
  locationBased,
  personalized,
  urgent,
  promotional,
  system,
}

enum NotificationType {
  // Event-related
  eventReminder,
  eventCancelled,
  eventUpdated,
  eventStartingSoon,
  eventCapacityWarning,
  
  // Waitlist & Reservations
  waitlistPromoted,
  reservationConfirmed,
  reservationExpiring,
  spotAvailable,
  
  // Social interactions
  hostMessage,
  attendeeJoined,
  friendRSVP,
  reviewRequest,
  
  // Location-based
  nearbyEvent,
  arrivalReminder,
  checkInAvailable,
  
  // Personalized suggestions
  recommendedEvent,
  similarEvent,
  categoryMatch,
  
  // Urgent notifications
  emergencyUpdate,
  weatherAlert,
  securityAlert,
  
  // Promotional
  newFeature,
  specialOffer,
  hostIncentive,
  
  // System
  appUpdate,
  maintenanceNotice,
  accountUpdate,
}

/// Enhanced notification data model
class EnhancedNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final NotificationCategory category;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic> data;
  final NotificationPriority priority;
  final List<NotificationAction> actions;
  final String? imageUrl;
  final Duration? expiresIn;

  const EnhancedNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.data = const {},
    this.priority = NotificationPriority.normal,
    this.actions = const [],
    this.imageUrl,
    this.expiresIn,
  });

  /// Get notification icon based on type
  String get icon {
    switch (type) {
      case NotificationType.eventReminder:
        return '⏰';
      case NotificationType.eventCancelled:
        return '❌';
      case NotificationType.waitlistPromoted:
        return '🎉';
      case NotificationType.nearbyEvent:
        return '🌟';
      case NotificationType.hostMessage:
        return '💬';
      case NotificationType.recommendedEvent:
        return '💡';
      case NotificationType.emergencyUpdate:
        return '🚨';
      case NotificationType.weatherAlert:
        return '⛈️';
      default:
        return '📱';
    }
  }

  /// Get notification color based on priority
  String get color {
    switch (priority) {
      case NotificationPriority.urgent:
        return '#FF3B30'; // Red
      case NotificationPriority.high:
        return '#FF9500'; // Orange
      case NotificationPriority.normal:
        return '#007AFF'; // Blue
      case NotificationPriority.low:
        return '#8E8E93'; // Gray
    }
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'category': category.name,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'data': data,
      'priority': priority.name,
      'actions': actions.map((a) => a.toMap()).toList(),
      'imageUrl': imageUrl,
      'expiresIn': expiresIn?.inMilliseconds,
    };
  }

  /// Create from map
  factory EnhancedNotification.fromMap(Map<String, dynamic> map) {
    return EnhancedNotification(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.eventReminder,
      ),
      category: NotificationCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => NotificationCategory.eventUpdates,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      isRead: map['isRead'] ?? false,
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      actions: (map['actions'] as List<dynamic>?)
          ?.map((a) => NotificationAction.fromMap(a))
          .toList() ?? [],
      imageUrl: map['imageUrl'],
      expiresIn: map['expiresIn'] != null 
          ? Duration(milliseconds: map['expiresIn'])
          : null,
    );
  }

  /// Create a copy with updated fields
  EnhancedNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    NotificationCategory? category,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
    NotificationPriority? priority,
    List<NotificationAction>? actions,
    String? imageUrl,
    Duration? expiresIn,
  }) {
    return EnhancedNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      priority: priority ?? this.priority,
      actions: actions ?? this.actions,
      imageUrl: imageUrl ?? this.imageUrl,
      expiresIn: expiresIn ?? this.expiresIn,
    );
  }
}

/// Notification priority levels
enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

/// Action buttons for notifications
class NotificationAction {
  final String id;
  final String title;
  final String? icon;
  final bool destructive;

  const NotificationAction({
    required this.id,
    required this.title,
    this.icon,
    this.destructive = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'icon': icon,
      'destructive': destructive,
    };
  }

  factory NotificationAction.fromMap(Map<String, dynamic> map) {
    return NotificationAction(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      icon: map['icon'],
      destructive: map['destructive'] ?? false,
    );
  }
}

/// Predefined notification actions
class NotificationActions {
  static const view = NotificationAction(
    id: 'view',
    title: 'View',
    icon: '👁️',
  );

  static const rsvp = NotificationAction(
    id: 'rsvp',
    title: 'RSVP',
    icon: '✅',
  );

  static const decline = NotificationAction(
    id: 'decline',
    title: 'Decline',
    icon: '❌',
    destructive: true,
  );

  static const reply = NotificationAction(
    id: 'reply',
    title: 'Reply',
    icon: '💬',
  );

  static const directions = NotificationAction(
    id: 'directions',
    title: 'Directions',
    icon: '🗺️',
  );

  static const share = NotificationAction(
    id: 'share',
    title: 'Share',
    icon: '📤',
  );

  static const dismiss = NotificationAction(
    id: 'dismiss',
    title: 'Dismiss',
    icon: '🚫',
  );
}

/// Notification templates for easy creation
class NotificationTemplates {
  static EnhancedNotification eventReminder({
    required String eventId,
    required String eventName,
    required DateTime eventTime,
    required String userId,
  }) {
    return EnhancedNotification(
      id: '',
      userId: userId,
      type: NotificationType.eventReminder,
      category: NotificationCategory.eventUpdates,
      title: '⏰ Event Reminder',
      message: '$eventName starts in 1 hour',
      timestamp: DateTime.now(),
      priority: NotificationPriority.high,
      data: {'eventId': eventId, 'eventName': eventName},
      actions: [
        NotificationActions.view,
        NotificationActions.directions,
      ],
    );
  }

  static EnhancedNotification nearbyEvent({
    required String eventId,
    required String eventName,
    required String distance,
    required String userId,
  }) {
    return EnhancedNotification(
      id: '',
      userId: userId,
      type: NotificationType.nearbyEvent,
      category: NotificationCategory.locationBased,
      title: '🌟 Event Near You!',
      message: '$eventName is $distance away',
      timestamp: DateTime.now(),
      priority: NotificationPriority.normal,
      data: {'eventId': eventId, 'eventName': eventName},
      actions: [
        NotificationActions.view,
        NotificationActions.rsvp,
        NotificationActions.dismiss,
      ],
    );
  }

  static EnhancedNotification hostMessage({
    required String eventId,
    required String eventName,
    required String hostName,
    required String message,
    required String userId,
  }) {
    return EnhancedNotification(
      id: '',
      userId: userId,
      type: NotificationType.hostMessage,
      category: NotificationCategory.socialInteractions,
      title: '💬 Message from $hostName',
      message: message,
      timestamp: DateTime.now(),
      priority: NotificationPriority.normal,
      data: {
        'eventId': eventId,
        'eventName': eventName,
        'hostName': hostName,
      },
      actions: [
        NotificationActions.view,
        NotificationActions.reply,
      ],
    );
  }

  static EnhancedNotification waitlistPromoted({
    required String eventId,
    required String eventName,
    required String userId,
  }) {
    return EnhancedNotification(
      id: '',
      userId: userId,
      type: NotificationType.waitlistPromoted,
      category: NotificationCategory.eventUpdates,
      title: '🎉 You\'re In!',
      message: 'You\'ve been promoted from waitlist to attendee for $eventName',
      timestamp: DateTime.now(),
      priority: NotificationPriority.high,
      data: {'eventId': eventId, 'eventName': eventName},
      actions: [
        NotificationActions.view,
        NotificationActions.share,
      ],
    );
  }

  static EnhancedNotification emergencyUpdate({
    required String eventId,
    required String eventName,
    required String message,
    required String userId,
  }) {
    return EnhancedNotification(
      id: '',
      userId: userId,
      type: NotificationType.emergencyUpdate,
      category: NotificationCategory.urgent,
      title: '🚨 Emergency Update',
      message: message,
      timestamp: DateTime.now(),
      priority: NotificationPriority.urgent,
      data: {'eventId': eventId, 'eventName': eventName},
      actions: [
        NotificationActions.view,
      ],
    );
  }
}
