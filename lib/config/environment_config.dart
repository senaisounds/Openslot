// Environment configuration for OpenSlot
// Production-safe defaults: emulator and debug menus are opt-in via dart-defines.
class EnvironmentConfig {
  /// Pass `--dart-define=PRODUCTION=true` for release/store builds.
  /// Defaults to true so misconfigured releases fail closed (no emulator).
  static const bool isProduction =
      bool.fromEnvironment('PRODUCTION', defaultValue: true);

  /// Pass `--dart-define=DEBUG=true` to force debug flags in non-debug tooling.
  static const bool isDebug =
      bool.fromEnvironment('DEBUG', defaultValue: false);

  static const bool isTest =
      bool.fromEnvironment('TEST', defaultValue: false);

  /// Explicit opt-in for local Functions emulator.
  static const bool useFirebaseEmulator =
      bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);

  static String get apiBaseUrl {
    return 'https://us-central1-open-mic-5cc8e.cloudfunctions.net';
  }

  static String get firebaseEmulatorHost => 'localhost';
  static int get firebaseEmulatorPort => 5001;
  static bool get enableDebugLogs => !isProduction || isDebug;
  static bool get enableCrashlytics => isProduction;
  static bool get enableAnalytics => isProduction;
  static int get maxCacheSize => isProduction ? 100 : 50;
  static Duration get cacheExpiration =>
      isProduction ? const Duration(days: 7) : const Duration(hours: 1);
  static bool get enableSSL => true;
  static bool get enableCertificatePinning => isProduction;
  static Duration get requestTimeout =>
      isProduction ? const Duration(seconds: 30) : const Duration(seconds: 10);
  static bool get enableAdvancedFeatures => isProduction;
  static bool get enableBetaFeatures => !isProduction;
  static bool get enableDebugMenu => !isProduction || isDebug;
}
