// Firebase production configuration
class FirebaseProductionConfig {
  static const String projectId = 'open-mic-5cc8e';
  static const String apiKey = 'AIzaSyAUoCM_8WP-Z7o0w9F-dRZsUYbyFg7YuO0';
  static const String appId = '1:482276707475:web:2f422d12c97df492d41166';
  static const String messagingSenderId = '482276707475';
  static const String authDomain = 'open-mic-5cc8e.firebaseapp.com';
  static const String storageBucket = 'open-mic-5cc8e.appspot.com';
  static const String functionsRegion = 'us-central1';
  static const bool enableSecurityRules = true;
  static const bool enableCrashlytics = true;
  static const bool enableAnalytics = true;
  static const int maxCacheSize = 100;
  static const Duration cacheExpiration = Duration(days: 7);
  static const int maxConcurrentRequests = 10;
  static const bool enableErrorReporting = true;
  static const bool enablePerformanceMonitoring = true;
  static const Duration errorTimeout = Duration(seconds: 30);
}
