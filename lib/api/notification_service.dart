import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:slotted/utils/logger.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:slotted/common/event_class.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  
  // Notification channels
  static const String waitlistChannel = 'waitlist_notifications';
  static const String remindersChannel = 'event_reminders';
  static const String generalChannel = 'general_notifications';
  
  // Notification IDs by type
  static const int waitlistBaseId = 10000;
  static const int reminderBaseId = 20000;
  static const int generalBaseId = 30000;
  
  // Notification preferences
  bool _enableWaitlistNotifications = true;
  bool _enableEventReminders = true;
  bool _enableGeneralNotifications = true;
  bool _initialized = false;
  
  // Scheduled reminder timers
  final Map<String, List<Timer>> _scheduledReminders = {};

  NotificationService._internal();
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Initialize preferences
      await _loadPreferences();
      
      // Request notification permissions
      await _requestPermissions();
      
      // Initialize notification plugin
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const InitializationSettings initSettings = InitializationSettings(
        iOS: iosSettings,
      );
      
      await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _handleNotificationTap(response.payload);
        },
      );
      
      // Listen for Firebase messages (with error handling)
      try {
        FirebaseMessaging.onMessage.listen(_handleFirebaseMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleFirebaseMessageOpened);
      } catch (e) {
        Logger.w('Warning: Could not set up Firebase message listeners: $e', tag: 'notification_service');
        // Continue without Firebase messaging
      }
      
      _initialized = true;
    } catch (e) {
      Logger.w('Warning: Notification service initialization had issues: $e', tag: 'notification_service');
      // Mark as initialized anyway to prevent repeated attempts
      _initialized = true;
    }
  }
  
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _enableWaitlistNotifications = prefs.getBool('enable_waitlist_notifications') ?? true;
    _enableEventReminders = prefs.getBool('enable_event_reminders') ?? true;
    _enableGeneralNotifications = prefs.getBool('enable_general_notifications') ?? true;
  }
  
  Future<void> _requestPermissions() async {
    try {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      // Gracefully handle permission errors (common in simulator)
      Logger.w('Warning: Could not request Firebase messaging permissions: $e', tag: 'notification_service');
      // Continue initialization without Firebase messaging permissions
    }
  }
  
  void _handleFirebaseMessage(RemoteMessage message) {
    final data = message.data;
    final notificationType = data['type'] as String? ?? '';
    
    if (notificationType == 'waitlist_promoted' && _enableWaitlistNotifications) {
      _showWaitlistNotification(
        message.notification?.title ?? 'Waitlist Update',
        message.notification?.body ?? 'You\'ve been moved from the waitlist to attendees!',
        data['eventId'] as String? ?? '',
      );
    } else if (notificationType == 'event_reminder' && _enableEventReminders) {
      _showEventReminderNotification(
        message.notification?.title ?? 'Event Reminder',
        message.notification?.body ?? 'Your event is coming up soon!',
        data['eventId'] as String? ?? '',
      );
    } else if (_enableGeneralNotifications) {
      _showGeneralNotification(
        message.notification?.title ?? 'New Notification',
        message.notification?.body ?? '',
        data['eventId'] as String? ?? '',
      );
    }
  }
  
  void _handleFirebaseMessageOpened(RemoteMessage message) {
    // Handle navigation based on the notification payload
    _handleNotificationTap(message.data['eventId'] as String?);
  }
  
  void _handleNotificationTap(String? eventId) {
    if (eventId != null && eventId.isNotEmpty) {
      // Navigation logic would be here
      // This would typically be handled by a Navigation service or provider
    }
  }
  
  // Waitlist Notifications
  Future<void> _showWaitlistNotification(String title, String body, String eventId) async {
    const NotificationDetails details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        categoryIdentifier: waitlistChannel,
      ),
    );
    
    final int id = waitlistBaseId + Random().nextInt(1000);
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: eventId,
    );
  }
  
  // Event Reminder Notifications
  Future<void> _showEventReminderNotification(String title, String body, String eventId) async {
    const NotificationDetails details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        categoryIdentifier: remindersChannel,
      ),
    );
    
    final int id = reminderBaseId + Random().nextInt(1000);
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: eventId,
    );
  }
  
  // General Notifications
  Future<void> _showGeneralNotification(String title, String body, String eventId) async {
    const NotificationDetails details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: generalChannel,
      ),
    );
    
    final int id = generalBaseId + Random().nextInt(1000);
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: eventId,
    );
  }
  
  // Schedule event reminders for a given event
  Future<void> scheduleEventReminders(Event event, String userId) async {
    if (!_enableEventReminders) return;
    
    // Cancel any existing reminders for this event
    cancelEventReminders(event.id);
    
    // Only schedule reminders for upcoming events
    final now = DateTime.now();
    if (event.date.isBefore(now) || !event.attendees.contains(userId)) return;
    
    final String eventId = event.id;
    final List<Timer> timers = [];
    
    // Calculate time until 24 hours before event
    final timeTo24HoursBefore = event.date.subtract(const Duration(hours: 24)).difference(now);
    if (timeTo24HoursBefore.inSeconds > 0) {
      timers.add(Timer(timeTo24HoursBefore, () {
        _showEventReminderNotification(
          'Event Tomorrow',
          '${event.name} is happening tomorrow at ${DateFormat.jm().format(event.date)}',
          eventId,
        );
      }));
    }
    
    // Calculate time until 1 hour before event
    final timeTo1HourBefore = event.date.subtract(const Duration(hours: 1)).difference(now);
    if (timeTo1HourBefore.inSeconds > 0) {
      timers.add(Timer(timeTo1HourBefore, () {
        _showEventReminderNotification(
          'Event Starting Soon',
          '${event.name} is starting in 1 hour at ${DateFormat.jm().format(event.date)}',
          eventId,
        );
      }));
    }
    
    // Store timers for later cancellation if needed
    _scheduledReminders[eventId] = timers;
  }
  
  // Cancel event reminders for a specific event
  void cancelEventReminders(String eventId) {
    final timers = _scheduledReminders[eventId];
    if (timers != null) {
      for (final timer in timers) {
        timer.cancel();
      }
      _scheduledReminders.remove(eventId);
    }
  }
  
  // Cancel all scheduled reminders
  void cancelAllReminders() {
    _scheduledReminders.forEach((_, timers) {
      for (final timer in timers) {
        timer.cancel();
      }
    });
    _scheduledReminders.clear();
  }
  
  // Settings for notifications
  Future<void> setWaitlistNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_waitlist_notifications', enabled);
    _enableWaitlistNotifications = enabled;
  }
  
  Future<void> setEventRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_event_reminders', enabled);
    _enableEventReminders = enabled;
    
    // If disabling reminders, cancel all scheduled reminders
    if (!enabled) {
      cancelAllReminders();
    }
  }
  
  Future<void> setGeneralNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_general_notifications', enabled);
    _enableGeneralNotifications = enabled;
  }
  
  // Getters for notification settings
  bool get areWaitlistNotificationsEnabled => _enableWaitlistNotifications;
  bool get areEventRemindersEnabled => _enableEventReminders;
  bool get areGeneralNotificationsEnabled => _enableGeneralNotifications;
  
  // For testing and debugging
  Future<void> sendTestWaitlistNotification(String eventId) async {
    await _showWaitlistNotification(
      'Waitlist Update',
      'You\'ve been moved from the waitlist to the attendee list!',
      eventId,
    );
  }
  
  Future<void> sendTestEventReminder(String eventId, String eventName, DateTime eventTime) async {
    await _showEventReminderNotification(
      'Event Reminder',
      '$eventName is happening today at ${DateFormat.jm().format(eventTime)}',
      eventId,
    );
  }
} 