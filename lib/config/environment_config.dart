// Environment configuration for OpenSlot
class EnvironmentConfig {
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
  static const bool isDebug = bool.fromEnvironment('DEBUG', defaultValue: true);
  static const bool isTest = bool.fromEnvironment('TEST', defaultValue: false);
  static String get apiBaseUrl {
    // Always use the public URL unless running on an emulator or simulator
    return 'https://us-central1-open-mic-5cc8e.cloudfunctions.net';
  }
  static bool get useFirebaseEmulator => !isProduction;
  static String get firebaseEmulatorHost => 'localhost';
  static int get firebaseEmulatorPort => 5001;
  static bool get enableDebugLogs => !isProduction;
  static bool get enableCrashlytics => isProduction;
  static bool get enableAnalytics => isProduction;
  static int get maxCacheSize => isProduction ? 100 : 50;
  static Duration get cacheExpiration => isProduction ? const Duration(days: 7) : const Duration(hours: 1);
  static bool get enableSSL => isProduction;
  static bool get enableCertificatePinning => isProduction;
  static Duration get requestTimeout => isProduction ? const Duration(seconds: 30) : const Duration(seconds: 10);
  static bool get enableAdvancedFeatures => isProduction;
  static bool get enableBetaFeatures => !isProduction;
  static bool get enableDebugMenu => !isProduction;
}
