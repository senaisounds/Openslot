import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slotted/utils/logger.dart';

class ConnectivityService extends ChangeNotifier {
  // Singleton pattern
  static final ConnectivityService _instance = ConnectivityService._internal();
  static ConnectivityService get instance => _instance;
  
  // Private constructor
  ConnectivityService._internal() {
    _initConnectivity();
  }
  
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<dynamic>? _subscription;
  
  bool _isOnline = true;
  bool _wasOffline = false;
  
  // Getters
  bool get isOnline => _isOnline;
  bool get wasOffline => _wasOffline;
  
  // Initialize connectivity monitoring
  void _initConnectivity() {
    _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    // Check initial connection state
    _checkConnectivity();
  }
  
  // Check current connectivity
  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      Logger.e('Failed to check connectivity: $e', tag: 'ConnectivityService');
      _isOnline = false;
      notifyListeners();
    }
  }
  
  // Handle connection status changes
  void _updateConnectionStatus(dynamic connectivityResult) {
    final previousStatus = _isOnline;
    
    if (connectivityResult is List<ConnectivityResult>) {
      // For platforms that return a list
      _isOnline = connectivityResult.isNotEmpty && 
                  connectivityResult.any((result) => result != ConnectivityResult.none);
    } else if (connectivityResult is ConnectivityResult) {
      // For platforms that return a single result
      _isOnline = connectivityResult != ConnectivityResult.none;
    } else {
      // Fallback for unknown types
      Logger.w('Unknown connectivity result type: ${connectivityResult.runtimeType}', 
               tag: 'ConnectivityService');
      _isOnline = false;
    }
    
    // If we went from offline to online, set wasOffline flag
    if (!previousStatus && _isOnline) {
      _wasOffline = true;
      // Auto-reset the flag after sync
      Future.delayed(const Duration(seconds: 5), () {
        _wasOffline = false;
        notifyListeners();
      });
    }
    
    // Only notify if status actually changed
    if (previousStatus != _isOnline) {
      Logger.d('Connection status changed: $_isOnline', tag: 'ConnectivityService');
      notifyListeners();
      _saveLastConnectionState();
    }
  }
  
  // Save the last known connection state
  Future<void> _saveLastConnectionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('last_connection_state', _isOnline);
      await prefs.setString('last_connection_time', DateTime.now().toIso8601String());
    } catch (e) {
      Logger.e('Failed to save connection state: $e', tag: 'ConnectivityService');
    }
  }
  
  // Get the last known connection state and time
  Future<Map<String, dynamic>> getLastConnectionInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastState = prefs.getBool('last_connection_state') ?? true;
      final lastTimeStr = prefs.getString('last_connection_time');
      final lastTime = lastTimeStr != null ? DateTime.parse(lastTimeStr) : DateTime.now();
      
      return {
        'state': lastState,
        'time': lastTime,
      };
    } catch (e) {
      Logger.e('Failed to get last connection info: $e', tag: 'ConnectivityService');
      return {
        'state': true,
        'time': DateTime.now(),
      };
    }
  }
  
  // Manual connectivity check (can be called when app resumes)
  Future<bool> checkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      return _isOnline;
    } catch (e) {
      Logger.e('Error checking connection: $e', tag: 'ConnectivityService');
      return false;
    }
  }
  
  // Add setOnline method to support web platform
  void setOnline(bool isOnline) {
    _isOnline = isOnline;
    notifyListeners();
  }
  
  // Add web network listeners method
  void startWebNetworkListeners() {
    // This method is only implemented in web-specific code
    // The actual implementation is in web_utils_web.dart
    try {
      Logger.d('Setting up web network listeners', tag: 'ConnectivityService');
      // The actual listeners are set up in WebUtils 
      // but this method ensures the API exists on all platforms
    } catch (e) {
      Logger.e('Error setting up web network listeners: $e', tag: 'ConnectivityService');
    }
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
} 