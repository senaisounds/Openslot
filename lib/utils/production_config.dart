import 'package:flutter/foundation.dart';

/// Production configuration management
class ProductionConfig {
  static const bool _isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
  static const bool _isDebug = kDebugMode;
  
  /// Check if running in production mode
  static bool get isProduction => _isProduction || !_isDebug;
  
  /// Check if running in debug mode
  static bool get isDebug => _isDebug;
  
  /// Get Firebase project ID based on environment
  static String get firebaseProjectId {
    if (isProduction) {
      return 'open-mic-5cc8e'; // Production project
    } else {
      return 'open-mic-5cc8e'; // Same project for now, can be different
    }
  }
  
  /// Get Stripe publishable key based on environment
  static String get stripePublishableKey {
    if (isProduction) {
      return 'pk_live_...'; // Replace with your live key
    } else {
      return 'pk_test_...'; // Replace with your test key
    }
  }
  
  /// Get API base URL based on environment
  static String get apiBaseUrl {
    if (isProduction) {
      return 'https://us-central1-open-mic-5cc8e.cloudfunctions.net';
    } else {
      return 'http://localhost:5001/open-mic-5cc8e/us-central1';
    }
  }
  
  /// Check if Firebase Functions should use emulator
  static bool get useFirebaseEmulator => !isProduction;
  
  /// Get Firebase Functions emulator host
  static String get firebaseEmulatorHost => 'localhost';
  
  /// Get Firebase Functions emulator port
  static int get firebaseEmulatorPort => 5001;
  
  /// Get app version for production builds
  static String get appVersion => '1.0.95';
  
  /// Get build number for production builds
  static int get buildNumber => 129;
  
  /// Check if crashlytics should be enabled
  static bool get enableCrashlytics => isProduction;
  
  /// Check if analytics should be enabled
  static bool get enableAnalytics => isProduction;
  
  /// Get maximum cache size for production
  static int get maxCacheSize => isProduction ? 100 : 50;
  
  /// Get cache expiration time for production
  static Duration get cacheExpiration => isProduction 
    ? const Duration(days: 7) 
    : const Duration(hours: 1);
} 