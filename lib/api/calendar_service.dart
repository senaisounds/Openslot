import 'package:add_2_calendar/add_2_calendar.dart' as add2calendar;
import 'package:slotted/common/event_class.dart';
import 'package:slotted/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart' as device_calendar;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  static CalendarService get instance => _instance;
  
  final device_calendar.DeviceCalendarPlugin _deviceCalendarPlugin = device_calendar.DeviceCalendarPlugin();
  
  // Settings
  bool _enableCalendarSync = true;
  bool _askBeforeAdding = true;
  String? _defaultCalendarId;
  
  // Cached calendars
  List<device_calendar.Calendar>? _availableCalendars;
  bool _timezonesInitialized = false;
  
  CalendarService._internal() {
    _initializeTimezones();
  }
  
  void _initializeTimezones() {
    if (!_timezonesInitialized) {
      try {
        tz_data.initializeTimeZones();
        _timezonesInitialized = true;
      } catch (e) {
        Logger.d('Failed to initialize timezones: $e', tag: 'CalendarService');
      }
    }
  }
  
  /// Initialize the calendar service
  Future<void> initialize() async {
    await _loadPreferences();
    await _requestPermissions();
  }
  
  /// Load user preferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _enableCalendarSync = prefs.getBool('enable_calendar_sync') ?? true;
    _askBeforeAdding = prefs.getBool('ask_before_adding_to_calendar') ?? true;
    _defaultCalendarId = prefs.getString('default_calendar_id');
  }
  
  /// Request calendar permissions
  Future<bool> _requestPermissions() async {
    var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
    if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
      permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
      return permissionsGranted.isSuccess && permissionsGranted.data!;
    }
    return permissionsGranted.isSuccess && permissionsGranted.data!;
  }
  
  /// Check if calendar permissions are granted
  Future<bool> hasCalendarPermissions() async {
    var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
    return permissionsGranted.isSuccess && permissionsGranted.data!;
  }
  
  /// Get available calendars on device
  Future<List<device_calendar.Calendar>> getAvailableCalendars() async {
    if (_availableCalendars != null) {
      return _availableCalendars!;
    }
    
    final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    if (calendarsResult.isSuccess && calendarsResult.data != null) {
      _availableCalendars = calendarsResult.data!;
      return _availableCalendars!;
    }
    
    return [];
  }
  
  /// Set default calendar for adding events
  Future<void> setDefaultCalendar(String calendarId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_calendar_id', calendarId);
    _defaultCalendarId = calendarId;
  }
  
  /// Set whether to ask before adding events
  Future<void> setAskBeforeAdding(bool askBeforeAdding) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ask_before_adding_to_calendar', askBeforeAdding);
    _askBeforeAdding = askBeforeAdding;
  }
  
  /// Set whether calendar sync is enabled
  Future<void> setCalendarSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_calendar_sync', enabled);
    _enableCalendarSync = enabled;
  }
  
  /// Get current calendar settings
  Map<String, dynamic> getCalendarSettings() {
    return {
      'enableCalendarSync': _enableCalendarSync,
      'askBeforeAdding': _askBeforeAdding,
      'defaultCalendarId': _defaultCalendarId,
    };
  }
  
  /// Add a Slotted event to the device calendar
  Future<bool> addEventToCalendar(Event event, {BuildContext? context}) async {
    if (!_enableCalendarSync) {
      return false;
    }
    
    // Check permissions first
    if (!await hasCalendarPermissions()) {
      Logger.d('Calendar permissions not granted', tag: 'CalendarService');
      return false;
    }
    
    try {
      // Store context in a local variable to avoid async gap issues
      final currentContext = context;
      
      // If we should ask before adding and context is provided
      if (_askBeforeAdding && currentContext != null) {
        // Check if context is still mounted before proceeding
        if (!currentContext.mounted) {
          Logger.d('Context no longer mounted, skipping calendar confirmation', tag: 'CalendarService');
          return false;
        }
        
        final confirmed = await _showAddToCalendarConfirmation(currentContext, event);
        if (!confirmed) {
          return false;
        }
      }
      
      // Convert Slotted event to calendar event
      final calendarEvent = _convertToCalendarEvent(event);
      
      // Add to calendar
      if (_defaultCalendarId != null) {
        // Use device_calendar for more control when default calendar is set
        return await _addToDeviceCalendar(event, _defaultCalendarId!);
      } else {
        // Use add_2_calendar for system UI when no default is set
        add2calendar.Add2Calendar.addEvent2Cal(calendarEvent);
        return true;
      }
    } catch (e) {
      Logger.d('Error adding event to calendar: $e', tag: 'CalendarService');
      return false;
    }
  }
  
  /// Calculate event end time (default to 1.5 hours after start)
  DateTime _calculateEndTime(Event event) {
    // Events in Slotted app don't have end times, so we default to 1.5 hours
    return event.date.add(const Duration(hours: 1, minutes: 30));
  }
  
  /// Convert our Event to an add2calendar Event format
  add2calendar.Event _convertToCalendarEvent(Event event) {
    // Calculate end time (default to 1.5 hours after start)
    final endDate = _calculateEndTime(event);
    
    return add2calendar.Event(
      title: event.name,
      description: _buildEventDescription(event),
      location: event.address,
      startDate: event.date,
      endDate: endDate,
      allDay: false,
      iosParams: const add2calendar.IOSParams(
        reminder: Duration(minutes: 30),
      ),
      androidParams: const add2calendar.AndroidParams(
        emailInvites: [],
      ),
    );
  }
  
  /// Build a comprehensive event description
  String _buildEventDescription(Event event) {
    final buffer = StringBuffer();
    
    // Add event description
    buffer.writeln(event.description);
    buffer.writeln();
    
    // Add host info
    buffer.writeln('Hosted by: ${event.hostName}');
    
    // Add rules if available
    if (event.rules.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('EVENT RULES:');
      buffer.writeln(event.rules);
    }
    
    // Add Slotted info
    buffer.writeln();
    buffer.writeln('Added from Slotted App');
    
    return buffer.toString();
  }
  
  /// Add an event directly to device calendar with specific calendar ID
  Future<bool> _addToDeviceCalendar(Event event, String calendarId) async {
    try {
      // Calculate end time (default to 1.5 hours after start)
      final endDate = _calculateEndTime(event);
      
      // Convert DateTime to TZDateTime for device_calendar
      final tz.Location location = tz.local;
      final tz.TZDateTime startTZ = tz.TZDateTime.from(event.date, location);
      final tz.TZDateTime endTZ = tz.TZDateTime.from(endDate, location);
      
      final newEvent = device_calendar.Event(
        calendarId,
        title: event.name,
        description: _buildEventDescription(event),
        start: startTZ,
        end: endTZ,
        location: event.address,
      );
      
      // Add alerts - 30 minutes before event
      newEvent.reminders = [
        device_calendar.Reminder(minutes: 30)
      ];
      
      final createResult = await _deviceCalendarPlugin.createOrUpdateEvent(newEvent);
      return createResult?.isSuccess ?? false;
    } catch (e) {
      Logger.d('Error adding to device calendar: $e', tag: 'CalendarService');
      return false;
    }
  }
  
  /// Show confirmation dialog before adding to calendar
  Future<bool> _showAddToCalendarConfirmation(BuildContext context, Event event) async {
    // Check if context is still valid before showing dialog
    if (!context.mounted) {
      return false;
    }
    
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add to Calendar'),
          content: Text('Would you like to add "${event.name}" to your calendar?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;
  }
  
  /// Show calendar selection dialog
  Future<String?> showCalendarSelectionDialog(BuildContext context) async {
    final calendars = await getAvailableCalendars();
    
    if (calendars.isEmpty) {
      return null;
    }
    
    // Check if context is still valid before showing dialog
    if (!context.mounted) {
      return null;
    }
    
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Calendar'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: calendars.length,
              itemBuilder: (context, index) {
                final calendar = calendars[index];
                return ListTile(
                  title: Text(calendar.name ?? 'Unnamed Calendar'),
                  onTap: () => Navigator.of(context).pop(calendar.id),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(null),
            ),
          ],
        );
      },
    );
  }
}

// Extension for Event to work with Calendar
extension EventCalendarExtension on Event {
  /// Add this event to the user's calendar
  Future<bool> addToCalendar({BuildContext? context}) {
    return CalendarService.instance.addEventToCalendar(this, context: context);
  }
} 