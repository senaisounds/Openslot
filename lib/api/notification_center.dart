import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:slotted/api/notification_service.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notification center to manage and display notifications to users
class NotificationCenter {
  static final NotificationCenter _instance = NotificationCenter._internal();
  static NotificationCenter get instance => _instance;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService.instance;
  
  // Notification stream controller
  final StreamController<List<UserNotification>> _notificationsController = 
      StreamController<List<UserNotification>>.broadcast();
  
  // Stream for UI to listen to
  Stream<List<UserNotification>> get notificationsStream => _notificationsController.stream;
  
  // Cached notifications
  List<UserNotification> _cachedNotifications = [];
  StreamSubscription? _notificationsSubscription;
  
  // Notification preferences
  bool _notificationsEnabled = true;
  
  NotificationCenter._internal();
  
  /// Initialize the notification center
  Future<void> initialize() async {
    // Ensure the notification service is initialized
    await _notificationService.initialize();
    
    // Start listening for notifications if user is logged in
    _setupUserListener();
  }
  
  /// Setup listener for user authentication changes
  void _setupUserListener() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _startListeningForNotifications(user.uid);
      } else {
        _stopListeningForNotifications();
        _clearNotifications();
      }
    });
  }
  
  /// Start listening for user notifications
  void _startListeningForNotifications(String userId) {
    // Cancel any existing subscription
    _stopListeningForNotifications();
    
    // Query notifications for the current user
    final query = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50);
    
    _notificationsSubscription = query.snapshots().listen((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => UserNotification.fromDocument(doc))
          .toList();
      
      _cachedNotifications = notifications;
      _notificationsController.add(notifications);
    }, onError: (error) {
      Logger.d('Error listening to notifications: $error', tag: 'NotificationCenter');
    });
  }
  
  /// Stop listening for notifications
  void _stopListeningForNotifications() {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = null;
  }
  
  /// Clear cached notifications
  void _clearNotifications() {
    _cachedNotifications = [];
    _notificationsController.add([]);
  }
  
  /// Get all notifications for the current user
  List<UserNotification> getNotifications() {
    return _cachedNotifications;
  }
  
  /// Get unread notification count
  int getUnreadCount() {
    return _cachedNotifications.where((n) => !n.read).length;
  }
  
  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      Logger.d('Error marking notification as read: $e', tag: 'NotificationCenter');
    }
  }
  
  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final batch = _firestore.batch();
    final unreadNotifications = _cachedNotifications.where((n) => !n.read);
    
    for (final notification in unreadNotifications) {
      final docRef = _firestore.collection('notifications').doc(notification.id);
      batch.update(docRef, {'read': true});
    }
    
    try {
      await batch.commit();
    } catch (e) {
      Logger.d('Error marking all notifications as read: $e', tag: 'NotificationCenter');
    }
  }
  
  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      Logger.d('Error deleting notification: $e', tag: 'NotificationCenter');
    }
  }
  
  /// Create a new event notification
  Future<void> createEventNotification({
    required String userId,
    required String eventId,
    required String eventName,
    required NotificationType type,
    String? message,
  }) async {
    try {
      final notification = UserNotification(
        id: '', // Will be set by Firestore
        userId: userId,
        type: type,
        title: _getTitleForType(type, eventName),
        message: message ?? _getMessageForType(type, eventName),
        timestamp: DateTime.now(),
        read: false,
        data: {
          'eventId': eventId,
          'eventName': eventName,
        },
      );
      
      // Save to Firestore
      await _firestore
          .collection('notifications')
          .add(notification.toMap());
      
      // Send local notification if enabled
      if (_notificationsEnabled) {
        _sendLocalNotification(notification);
      }
    } catch (e) {
      Logger.d('Error creating notification: $e', tag: 'NotificationCenter');
    }
  }
  
  /// Get notification title based on type
  String _getTitleForType(NotificationType type, String eventName) {
    switch (type) {
      case NotificationType.eventReminder:
        return 'Event Reminder';
      case NotificationType.waitlistPromoted:
        return 'Waitlist Update';
      case NotificationType.eventCancelled:
        return 'Event Cancelled';
      case NotificationType.eventUpdated:
        return 'Event Updated';
      case NotificationType.reservationConfirmed:
        return 'Reservation Confirmed';
      default:
        return 'Notification';
    }
  }
  
  /// Get notification message based on type
  String _getMessageForType(NotificationType type, String eventName) {
    switch (type) {
      case NotificationType.eventReminder:
        return 'Your event "$eventName" is starting soon.';
      case NotificationType.waitlistPromoted:
        return 'You have been moved from the waitlist to attendees for "$eventName".';
      case NotificationType.eventCancelled:
        return 'The event "$eventName" has been cancelled.';
      case NotificationType.eventUpdated:
        return 'Details for "$eventName" have been updated.';
      case NotificationType.reservationConfirmed:
        return 'Your reservation for "$eventName" has been confirmed.';
      default:
        return 'You have a new notification for "$eventName".';
    }
  }
  
  /// Send a local notification
  void _sendLocalNotification(UserNotification notification) {
    switch (notification.type) {
      case NotificationType.eventReminder:
        _notificationService.sendTestEventReminder(
          notification.data['eventId'] ?? '',
          notification.data['eventName'] ?? '',
          DateTime.now(),
        );
        break;
      case NotificationType.waitlistPromoted:
        _notificationService.sendTestWaitlistNotification(
          notification.data['eventId'] ?? '',
        );
        break;
      default:
        // Use general notification for other types
        _notificationService.sendTestEventReminder(
          notification.data['eventId'] ?? '',
          notification.title,
          DateTime.now(),
        );
    }
  }
  
  /// Set whether notifications are enabled
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    
    // Also update the underlying service
    await _notificationService.setGeneralNotificationsEnabled(enabled);
    
    if (enabled) {
      // Re-enable other notification types
      await _notificationService.setWaitlistNotificationsEnabled(enabled);
      await _notificationService.setEventRemindersEnabled(enabled);
    }
  }
  
  /// Schedule event reminders for a user
  Future<void> scheduleEventReminders(Event event, String userId) async {
    return _notificationService.scheduleEventReminders(event, userId);
  }
  
  /// Cancel event reminders
  void cancelEventReminders(String eventId) {
    _notificationService.cancelEventReminders(eventId);
  }
  
  /// Dispose resources
  void dispose() {
    _stopListeningForNotifications();
    _notificationsController.close();
  }
}

/// User notification model
class UserNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool read;
  final Map<String, dynamic> data;
  
  UserNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.read,
    required this.data,
  });
  
  factory UserNotification.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserNotification(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      type: NotificationType.values[data['type'] as int? ?? 0],
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] as bool? ?? false,
      data: data['data'] as Map<String, dynamic>? ?? {},
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.index,
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'read': read,
      'data': data,
    };
  }
}

/// Types of notifications
enum NotificationType {
  eventReminder,
  waitlistPromoted,
  reservationConfirmed,
  eventCancelled,
  eventUpdated,
  other,
}

/// Extension methods for NotificationService
extension NotificationServiceExtension on NotificationService {
  /// Set whether general notifications are enabled
  Future<void> setGeneralNotificationsEnabled(bool enabled) async {
    // Call directly without extension to avoid recursion
    await SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('enable_general_notifications', enabled);
    });
  }
  
  /// Set whether waitlist notifications are enabled
  Future<void> setWaitlistNotificationsEnabled(bool enabled) async {
    // Call directly without extension to avoid recursion
    await SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('enable_waitlist_notifications', enabled);
    });
  }
  
  /// Set whether event reminders are enabled
  Future<bool> setEventRemindersEnabled(bool enabled) async {
    // Call directly without extension to avoid recursion
    await SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('enable_event_reminders', enabled);
    });
    return true;
  }
} 