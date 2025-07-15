// ignore_for_file: use_build_context_synchronously, body_might_complete_normally_nullable
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:slotted/api/firebase_options.dart';
import 'package:slotted/api/stripe_config.dart';
import 'package:slotted/common/error_boundary.dart';
import 'package:slotted/utils/error_handler.dart';
import 'package:slotted/pages/main_nav.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:slotted/providers/theme_provider.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:slotted/utils/location_service.dart';
import 'package:slotted/utils/logger.dart';
import 'dart:io';
// Import JS conditionally only for web
// import 'dart:js' as js;
import 'dart:math' as math;
import 'dart:async';
import 'package:slotted/api/notification_service.dart';
import 'package:slotted/utils/connectivity_service.dart';
import 'package:slotted/utils/event_cache_service.dart';
import 'package:slotted/providers/platform_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:slotted/utils/web_utils.dart' if (dart.library.html) 'package:slotted/utils/web_utils_web.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:slotted/utils/performance_optimizer.dart';
import 'package:slotted/utils/performance_monitor.dart';
import 'package:slotted/widgets/simple_splash_screen.dart';

import 'package:slotted/common/colors.dart';

// We can't directly override print, but we can use Logger consistently
const bool _debug = false;

// Main Theme Colors
const Color primaryColor = AppColors.primary; // Vibrant Orange - Stage Lights
const Color secondaryColor = AppColors.secondary; // Soft Orange - Energy
const Color accentColor = AppColors.accent; // Electric Orange - Microphone Glow
const Color highlightColor = AppColors.highlight; // Warm Yellow - Spotlight
const Color backgroundDarkColor = AppColors.backgroundDark; // Pure Black
const Color backgroundLightColor = AppColors.backgroundLight; // Light Mode
const Color openSlotOrange = AppColors.openSlotOrange; // Open Slot Orange

// Custom cache manager to fix the read-only database issue
class CustomCacheManager {
  static const key = 'slottedCacheKey';
  static late CacheManager instance;
  
  static Future<void> init(String? basePath) async {
    try {
      // Skip custom directory setup for web
      if (kIsWeb || basePath == null) {
        instance = CacheManager(
          Config(
            key,
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 100,
          ),
        );
        return;
      }
      
      // Create cache directories (mobile only)
      final cacheDir = Directory('$basePath/cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      
      instance = CacheManager(
        Config(
          key,
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 100,
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(),
        ),
      );
    } catch (e) {
      Logger.e('Failed to initialize cache manager: $e', error: e);
      // Fallback to default behavior if custom cache fails
      instance = CacheManager(
        Config(
          key,
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 100,
        ),
      );
    }
  }
}

// Setup for web platform
void _setupWebPlatform() {
  if (!kIsWeb) return;
  
  // Initialize WebUtils
  WebUtils.init();
  
  try {
    // Register service worker for offline capabilities
    Logger.d('Web platform setup - handled by WebUtils', tag: 'WebInit');
    
    // Listen for network changes
    ConnectivityService.instance.startWebNetworkListeners();
    
    // Add listener for authentication state changes (for handling social logins)
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // User signed in - handle any post-sign-in actions for web
        WebUtils.handleWebAuthSuccess(user);
      }
    });
  } catch (e) {
    Logger.e('Error in web platform setup: $e', tag: 'WebInit', error: e);
  }
}

// Initialize Firebase Crashlytics for improved error reporting
// Only for non-web platforms
Future<void> _initializeCrashlytics() async {
  if (kIsWeb) {
    Logger.i('Crashlytics not initialized - not supported on web platform', tag: 'Initialization');
    return;
  }
  
  try {
    // Pass all Flutter errors to Crashlytics
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!_debug);
    
    // Log app initialization 
    Logger.i('Firebase Crashlytics initialized successfully', tag: 'Initialization');
  } catch (e) {
    Logger.e('Failed to initialize Firebase Crashlytics: $e', tag: 'Initialization', error: e);
    // Continue despite Crashlytics initialization errors
  }
}

void main() async {
  // Run the app in a guarded zone to catch async errors
  runZonedGuarded<Future<void>>(() async {
    // Ensure Flutter is initialized within the same zone
    WidgetsFlutterBinding.ensureInitialized();
    
    await _initializeApp();
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => PlatformProvider()),
        ],
        child: const MyApp(debug: _debug),
      ),
    );
  }, (error, stack) {
    // Handle async errors, especially cache database issues
    final errorString = error.toString();
    if (errorString.contains('attempt to write a readonly database') ||
        errorString.contains('DatabaseException') && errorString.contains('cacheObject') ||
        errorString.contains('DELETE FROM cacheObject')) {
      // Log cache database errors as debug (safe to ignore in simulator)
      Logger.d('Async cache database warning (safe to ignore in simulator): $error', 
              tag: 'CacheManager');
      return;
    }
    
    // For other async errors, log them properly
    Logger.e('Unhandled async error: $error', 
            tag: 'ZoneError', 
            error: error, 
            stackTrace: stack);
  });
}

Future<void> _initializeApp() async {
  try {
    // Initialize performance optimization settings
    PerformanceOptimizer.initialize();
    
    // Initialize optimized image cache
    PaintingBinding.instance.imageCache.maximumSize = 50;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50MB
    
    // Enable performance monitoring in debug mode
    PerformanceMonitor.setEnabled(kDebugMode);
    
    // Disable verbose logging by default
    Logger.setQuietMode();

    // Initialize logger with improved error handling
    try {
      await Logger.initialize();
    } catch (e) {
      // Fallback logging if initialization fails - don't let this crash the app
      // Logger initialization failed - continuing without debug output
    }

    // Set up global error handlers using our new utility
    ErrorHandler.initGlobalErrorHandling();
    
    // Add additional stability measures
    WidgetsFlutterBinding.ensureInitialized();
    
    // Set preferred orientations with error handling
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } catch (e) {
      Logger.w('Failed to set orientation: $e', tag: 'main');
    }
    
    // Set system UI overlay style with error handling
    try {
              SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: AppColors.backgroundDark,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
        );
    } catch (e) {
      Logger.w('Failed to set system UI style: $e', tag: 'main');
    }
    
    String? appDocPath;
    
    // Skip path_provider for web platform
    if (!kIsWeb) {
      // Initialize path provider for proper database access on mobile
      try {
        final appDocDir = await path_provider.getApplicationDocumentsDirectory();
        appDocPath = appDocDir.path;
      } catch (error) {
        Logger.e('Failed to get application documents directory: $error', tag: 'Initialization', error: error);
        // Continue despite path provider errors
      }
    } else {
      // Setup web-specific functionality
      _setupWebPlatform();
    }
    
    // Initialize our custom cache manager (will use web-compatible approach if on web)
    await CustomCacheManager.init(appDocPath).catchError((error) {
      Logger.e('Failed to initialize custom cache manager: $error', tag: 'Initialization', error: error);
      // Continue despite cache initialization errors
    });
    
    // Initialize default cache manager
    try {
      DefaultCacheManager();
    } catch (e) {
      Logger.e('Failed to initialize default cache manager: $e', tag: 'Initialization', error: e);
      // Continue despite cache initialization errors
    }

    // Initialize Location Service (skip for web or handle appropriately)
    if (!kIsWeb) {
      await LocationService.initialize().catchError((error) {
        Logger.e('Failed to initialize location service: $error', tag: 'Initialization', error: error);
        // Continue despite location service initialization errors
      });
    }

    // Initialize Firebase with platform-specific options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).catchError((error) {
      Logger.e('Failed to initialize Firebase: $error', tag: 'Initialization', error: error);
      throw Exception('Could not initialize Firebase');
    });

    // Set up global error handling for cache database issues
    FlutterError.onError = (FlutterErrorDetails details) {
      // Check if this is a cache database error that we can safely ignore
      final errorString = details.exception.toString();
      if (errorString.contains('attempt to write a readonly database') ||
          errorString.contains('DatabaseException') && errorString.contains('cacheObject') ||
          errorString.contains('DELETE FROM cacheObject') ||
          errorString.contains('setState() called after dispose()')) {
        // Log as debug instead of error for these common simulator issues
        Logger.d('Global error handler - Safe to ignore: ${details.exception}', 
                tag: 'ErrorHandler');
        return;
      }
      
      // For other errors, use the default error handling
      FlutterError.presentError(details);
      Logger.e('Flutter Error: ${details.exception}', 
              tag: 'FlutterError', 
              error: details.exception, 
              stackTrace: details.stack);
    };

    // Initialize Firebase Crashlytics for improved error reporting (platform-dependent)
    await _initializeCrashlytics();

    // Configure Firebase Functions to use local emulator in debug mode
    if (_debug) {
      try {
        FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
        Logger.d('Firebase Functions emulator configured', tag: 'Initialization');
      } catch (e) {
        Logger.e('Failed to configure Firebase Functions emulator: $e', tag: 'Initialization', error: e);
      }
    }

    // Initialize Stripe with merchant identifier and publishable key
    try {
      Stripe.merchantIdentifier = StripeConfig.merchantIdentifier;
      Stripe.publishableKey = StripeConfig.getPublishableKey(_debug);
    } catch (e) {
      Logger.e('Failed to initialize Stripe: $e', tag: 'Initialization', error: e);
      // Continue despite Stripe initialization errors
    }
    
    // Initialize connectivity service
    ConnectivityService.instance;
    
    // Initialize event cache service
    EventCacheService.instance;
    
    // Log initialization of services
    Logger.d('Initialized connectivity and cache services', tag: 'Initialization');
  } catch (e, stackTrace) {
    Logger.e('Unhandled error during app initialization: $e', tag: 'Initialization', error: e, stackTrace: stackTrace);
    rethrow;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.debug = false});

  final bool debug;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _signInPhoneController = TextEditingController();

  late AnimationController _controller;
  late AnimationController _pulseController;
  late AnimationController _bounceController;

  bool _showSplash = true;
  int idCount = 0;

  Future<void> showNotification(int id, String? title, String? body) async {
    try {
      Logger.d('Showing notification: $id, $title, $body', tag: 'Notifications');
      var iOSPlatformChannelSpecifics = const DarwinNotificationDetails(
        presentBanner: true,
      );
      var platformChannelSpecifics =
          NotificationDetails(iOS: iOSPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.show(
        id, // Notification ID
        title, // Notification title
        body, // Notification body
        platformChannelSpecifics,
      );
    } catch (e, stackTrace) {
      Logger.e('Failed to show notification: $e', 
               tag: 'Notifications', 
               error: e, 
               stackTrace: stackTrace);
      // Continue execution - notification failure shouldn't affect app function
    }
  }

  bool isProfileIncomplete(Map<String, dynamic> profileData) {
    // Check for non-optional fields
    return profileData['name'] == null ||
        profileData['name'].isEmpty ||
        profileData['email'] == null ||
        profileData['email'].isEmpty;
  }

  void showProfileCompletionDialog(BuildContext context) {
    _phoneController.addListener(() {
      final text = _phoneController.text;
      _phoneController.value = _phoneController.value.copyWith(
        text: _formatPhoneNumber(text),
        selection:
            TextSelection.collapsed(offset: _formatPhoneNumber(text).length),
      );
    });

    showCupertinoDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Complete Your Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const CupertinoTextField(
                placeholder: 'Name',
                // Add controller and logic to update name
              ),
              const SizedBox(height: 8),
              const CupertinoTextField(
                placeholder: 'Email',
                // Add controller and logic to update email
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _phoneController,
                placeholder: 'Phone Number',
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('Submit'),
              onPressed: () {
                // Validate and update profile data
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showSignInDialog(BuildContext context) {
    _signInPhoneController.addListener(() {
      final text = _signInPhoneController.text;
      _signInPhoneController.value = _signInPhoneController.value.copyWith(
        text: _formatPhoneNumber(text),
        selection: TextSelection.collapsed(offset: _formatPhoneNumber(text).length),
      );
    });

    showCupertinoDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Sign In'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const CupertinoTextField(
                placeholder: 'Email',
                // Add controller and logic to update email
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _signInPhoneController,
                placeholder: 'Phone Number',
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('Sign In'),
              onPressed: () {
                // Validate and handle sign-in logic
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _formatPhoneNumber(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) buffer.write('-');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  void onUserSignIn(BuildContext context, Map<String, dynamic> profileData) {
    if (isProfileIncomplete(profileData)) {
      showProfileCompletionDialog(context);
    }
    // Continue with the rest of the sign-in logic
  }

  @override
  void initState() {
    super.initState();

    try {
      // Initialize animation controllers and setup animations
      _setupAnimations();
      
      // Initialize notification services
      _initializeNotifications();
      
      // Set up Firebase message handlers
      _setupFirebaseMessaging();
    } catch (e, stackTrace) {
      Logger.e('Error during initialization: $e', 
              tag: 'AppInit', 
              error: e, 
              stackTrace: stackTrace);
      // If critical initialization fails, skip splash screen
      if (_showSplash) {
        setState(() {
          _showSplash = false;
        });
      }
    }
  }
  
  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    
    // Add a fun bounce effect to the logo
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Initialize pulse controller
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showSplash = false;
        });
      }
    });

    _controller.forward();
    _bounceController.forward();
  }
  
  Future<void> _initializeNotifications() async {
    try {
      // Initialize notification service using the unified service
      await NotificationService.instance.initialize().catchError((error, stackTrace) {
        Logger.e('Failed to initialize notification service: $error', 
                tag: 'Notifications', 
                error: error, 
                stackTrace: stackTrace);
      });
    } catch (e) {
      // Silently handle initialization errors in simulator
      Logger.d('Notification service initialization skipped: $e', tag: 'Notifications');
    }
    
    try {
      // Legacy initialization for backward compatibility
      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        defaultPresentAlert: false,
        onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
      );
      
      final InitializationSettings initializationSettings =
          InitializationSettings(
        iOS: initializationSettingsIOS,
      );
      
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    } catch (e) {
      Logger.d('Legacy notification initialization skipped: $e', tag: 'Notifications');
    }
  }
  
  Future<void> _onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    try {
      showNotification(id, title, body);
    } catch (e) {
      Logger.e('Error in onDidReceiveLocalNotification: $e', 
              tag: 'Notifications', 
              error: e);
    }
  }
  
  void _setupFirebaseMessaging() {
    // Set up Firebase message handler for foreground messages
    FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
      onError: _handleFirebaseError,
    );

    // Set up Firebase message handler for when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(
      _handleAppOpenedFromNotification,
      onError: _handleFirebaseError,
    );
  }
  
  void _handleForegroundMessage(RemoteMessage message) {
    try {
      Logger.d('Received foreground message: ${message.messageId}', tag: 'Firebase');
      if (message.notification?.body != null &&
          message.notification?.title != null) {
        idCount++;
        showNotification(
          (DateTime.now().millisecondsSinceEpoch ~/ 1000.0) + idCount,
          message.notification!.title,
          message.notification!.body,
        );
      }
    } catch (e, stackTrace) {
      Logger.e('Error processing foreground message: $e', 
              tag: 'Firebase', 
              error: e, 
              stackTrace: stackTrace);
    }
  }
  
  void _handleAppOpenedFromNotification(RemoteMessage message) {
    try {
      Logger.i("App opened from notification: ${message.messageId}", tag: 'Firebase');
      // Handle the message when the app is opened from a notification
    } catch (e, stackTrace) {
      Logger.e('Error handling notification open: $e', 
              tag: 'Firebase', 
              error: e, 
              stackTrace: stackTrace);
    }
  }
  
  void _handleFirebaseError(Object error, StackTrace stackTrace) {
    Logger.e('Error in Firebase message stream: $error', 
            tag: 'Firebase', 
            error: error, 
            stackTrace: stackTrace);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Don't use Google Fonts for web - use system fonts instead
    // Preload Noto fonts to fix font warning - already handled in main for web
    // if (!kIsWeb) {
    //   GoogleFonts.notoSans();
    //   GoogleFonts.notoEmoji();
    // }
    
    return AnimatedTheme(
      data: ThemeData(
        brightness: themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: themeProvider.backgroundColor,
        fontFamily: 'Roboto, Arial, sans-serif',
        colorScheme: ColorScheme(
          brightness: themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
          primary: AppColors.primary,
          onPrimary: AppColors.textPrimary,
          secondary: AppColors.secondary,
          onSecondary: AppColors.textPrimary,
          error: AppColors.error,
          onError: AppColors.textPrimary,
          surface: themeProvider.isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
          onSurface: themeProvider.isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryLight,
          tertiary: AppColors.openSlotOrange,
          onTertiary: AppColors.textPrimary,
        ),
      ),
      duration: themeProvider.themeSwitchDuration,
      child: CupertinoApp(
        title: 'Open Slot',
        theme: const CupertinoThemeData(
          brightness: Brightness.dark, // Always use dark mode
          primaryColor: AppColors.primary,
          primaryContrastingColor: AppColors.openSlotOrange,
          scaffoldBackgroundColor: AppColors.backgroundDark, // Always use dark background
          barBackgroundColor: AppColors.backgroundDark, // Always use dark background
        ),
        builder: (context, child) {
          // Apply web-specific styling adjustments
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              // Don't scale text on web to maintain consistent appearance
              textScaler: kIsWeb 
                ? const TextScaler.linear(1.0)
                : MediaQuery.of(context).textScaler,
              // Apply padding for web to ensure content is visible
              padding: kIsWeb 
                ? MediaQuery.of(context).padding.copyWith(
                    top: math.max(MediaQuery.of(context).padding.top, 20),
                    bottom: math.max(MediaQuery.of(context).padding.bottom, 20),
                  )
                : MediaQuery.of(context).padding,
            ),
            // Apply web-specific layout changes
            child: kIsWeb
              ? _buildWebSpecificWrapper(context, child!)
              : child!,
          );
        },
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
        ],
        home: _showSplash
            ? SimpleSplashScreen(
                onFinished: () {
                  setState(() {
                    _showSplash = false;
                  });
                },
              )
            : ErrorBoundary(
                onRetry: () {
                  Logger.i('Retrying main navigation after error', tag: 'ErrorBoundary');
                },
                child: MainNav(
                  debug: widget.debug,
                ),
              ),
      ),
    );
  }

  // Add a new method for web-specific wrapper
  Widget _buildWebSpecificWrapper(BuildContext context, Widget child) {
    // Get screen size
    final screenSize = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width > 1200;
    final isMediumScreen = screenSize.width > 800 && screenSize.width <= 1200;
    
    // Apply specific font configurations for web
    if (kIsWeb) {
      // Simply add a default text style wrapper
      child = DefaultTextStyle(
        style: const TextStyle(
          fontFamily: 'Roboto, Arial, sans-serif',
          fontSize: 14,
          color: Colors.white,
        ),
        child: child,
      );
    }
    
    // For large screens, constrain the width for better readability
    if (isLargeScreen || isMediumScreen) {
      // Calculate appropriate width based on screen size
      final containerWidth = isLargeScreen 
          ? math.min(screenSize.width * 0.7, 1200.0)
          : math.min(screenSize.width * 0.9, 900.0);
          
      return Center(
        child: Container(
          width: containerWidth,
          decoration: BoxDecoration(
            color: backgroundDarkColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: child,
          ),
        ),
      );
    }
    
    // For smaller screens, just adjust padding
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: child,
    );
  }
}

class AnimatedSplashScreen extends StatelessWidget {
  final Animation<double> fadeInAnimation;
  final Animation<double> fadeOutAnimation;
  final Animation<double> pulseAnimation;

  const AnimatedSplashScreen({
    required this.fadeInAnimation,
    required this.fadeOutAnimation,
    required this.pulseAnimation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E3F), // Solid base color to ensure full coverage
      child: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E1E3F),
                  Color(0xFF2D2B55),
                ],
              ),
            ),
          ),
          
          // Animated orange circles
          ...List.generate(5, (index) {
            final double size = 100.0 + (index * 30);
            final double opacity = 0.07 + (index * 0.02);
            final double offsetX = -50.0 + (index * 40);
            final double offsetY = 100.0 - (index * 60);
            
            return Positioned(
              left: offsetX,
              top: offsetY,
              child: AnimatedBuilder(
                animation: fadeInAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: (0.5 + (fadeInAnimation.value * 0.5)) * pulseAnimation.value * (1 + (index * 0.05)),
                    child: Opacity(
                      opacity: fadeInAnimation.value * opacity,
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: openSlotOrange.withValues(alpha: 0.3),
                          boxShadow: [
                            BoxShadow(
                              color: openSlotOrange.withValues(alpha: 0.2),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          
          // Animated orange circles (bottom right)
          ...List.generate(3, (index) {
            final double size = 80.0 + (index * 40);
            final double opacity = 0.06 + (index * 0.02);
            final double offsetX = math.max(MediaQuery.of(context).size.width - size + (index * 30), 0);
            final double offsetY = math.max(MediaQuery.of(context).size.height - size - (index * 50), 0);
            
            return Positioned(
              left: offsetX,
              top: offsetY,
              child: AnimatedBuilder(
                animation: fadeInAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: (0.7 + (fadeInAnimation.value * 0.3)) * pulseAnimation.value * (1 - (index * 0.03)),
                    child: Opacity(
                      opacity: fadeInAnimation.value * opacity,
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: openSlotOrange.withValues(alpha: 0.2),
                          boxShadow: [
                            BoxShadow(
                              color: openSlotOrange.withValues(alpha: 0.15),
                              blurRadius: 25,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          
          // Add floating orange particles
          ...List.generate(12, (index) {
            final double size = 4.0 + (index % 4 * 3.0);
            final double opacity = 0.4 + (index % 3 * 0.15);
            // Distribute particles across the screen with some randomness
            final double offsetX = (MediaQuery.of(context).size.width / 12) * index;
            final double offsetY = 100 + (index * 50) % MediaQuery.of(context).size.height;
            
            return Positioned(
              left: offsetX,
              top: offsetY,
              child: AnimatedBuilder(
                animation: pulseAnimation,
                builder: (context, child) {
                  // Create different animation patterns for different particles
                  final double individualOffset = index / 12;
                  final double animValue = (pulseAnimation.value - 0.95) / 0.1; // normalize to 0-1
                  final double moveY = math.sin((animValue + individualOffset) * 3.14) * 10;
                  final double moveX = math.cos((animValue + individualOffset) * 3.14) * 6;
                  
                  return Opacity(
                    opacity: fadeInAnimation.value * opacity,
                    child: Transform.translate(
                      offset: Offset(moveX, moveY),
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: openSlotOrange,
                          boxShadow: [
                            BoxShadow(
                              color: openSlotOrange.withValues(alpha: 0.5),
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          
          // Main content
          AnimatedBuilder(
            animation: fadeInAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: fadeOutAnimation.value,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < "OPEN SLOT".length; i++)
                        Opacity(
                          opacity: fadeInAnimation.value * (1 - (i * 0.08)),
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                highlightColor,
                                openSlotOrange,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: Text(
                              "OPEN SLOT"[i],
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Helper function to build a loading widget with animations
Widget buildLoadingWidget(Animation<double> pulseAnimation, Animation<double> bounceAnimation) {
  // Fun loading messages
  final loadingMessages = [
    "Warming up the microphone...",
    "Tuning the guitars...",
    "Setting up the spotlight...",
    "Rolling out the red carpet...",
    "Gathering the audience...",
    "Preparing your standing ovation...",
    "Polishing the stage...",
    "Checking the sound system...",
    "Just one more minute of fame...",
    "The show is about to begin!"
  ];
  
  // Select a random message each time
  final random = math.Random();
  final message = loadingMessages[random.nextInt(loadingMessages.length)];
  
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Animated logo
      ScaleTransition(
        scale: pulseAnimation,
        child: RotationTransition(
          turns: Tween(begin: 0.0, end: 0.05).animate(
            CurvedAnimation(
              parent: bounceAnimation,
              curve: const Interval(0.3, 0.8),
            ),
          ),
          child: const Icon(
            Icons.mic, // Microphone icon
            size: 80,
            color: Colors.white,
          ),
        ),
      ),
      const SizedBox(height: 24),
      // Fun loading message
      Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      // Small bounce effect on the loading indicator
      ScaleTransition(
        scale: bounceAnimation,
        child: const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    ],
  );
}
// Test change to trigger automation
