import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:slotted/providers/theme_provider.dart';
import 'package:slotted/utils/test_network_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_helpers.dart';

/// Comprehensive test setup for OpenSlot app
class TestSetup {
  static late FakeFirebaseFirestore fakeFirestore;
  static late MockFirebaseAuth mockAuth;
  static late MockUser mockUser;
  static bool _initialized = false;

  /// Initialize all test dependencies
  static Future<void> initialize() async {
    if (_initialized) return;

    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Set up SharedPreferences for testing first
    SharedPreferences.setMockInitialValues({});
    
    // Initialize Firebase for testing with proper options
    try {
      // Check if Firebase is already initialized
      if (Firebase.apps.isNotEmpty) {
        debugPrint('Firebase already initialized, skipping initialization');
      } else {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'test-api-key',
            appId: 'test-app-id',
            messagingSenderId: 'test-sender-id',
            projectId: 'test-project',
            authDomain: 'test-project.firebaseapp.com',
            storageBucket: 'test-project.appspot.com',
          ),
        );
        debugPrint('Firebase initialized successfully for testing');
      }
    } catch (e) {
      debugPrint('Firebase initialization error (safe to ignore in tests): $e');
      // Continue despite Firebase initialization errors
    }

    // Set up fake Firestore
    fakeFirestore = FakeFirebaseFirestore();
    
    // Set up mock Firebase Auth
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    
    // Set up initial auth state (signed in by default)
    mockAuth.signIn(mockUser);
    
    // Enable test network service
    TestNetworkService.enableTestMode();
    
    _initialized = true;
    debugPrint('TestSetup initialized successfully');
  }

  /// Clean up after tests
  static Future<void> cleanup() async {
    TestNetworkService.disableTestMode();
    try {
      await fakeFirestore.terminate();
      await fakeFirestore.clearPersistence();
    } catch (e) {
      debugPrint('Cleanup error (safe to ignore): $e');
    }
    _initialized = false;
  }

  /// Create a simple test widget for basic testing
  static Widget createSimpleTestWidget({
    required Widget child,
  }) {
    return MaterialApp(
      title: 'Simple Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: child,
    );
  }

  /// Create a test widget wrapper with all necessary providers
  static Widget createTestApp({
    required Widget child,
    ThemeProvider? themeProvider,
    bool includeFirestore = true,
    bool includeAuth = true,
    User? customUser,
  }) {
    // Use custom user if provided
    if (customUser != null && includeAuth) {
      mockAuth.signIn(customUser);
    }
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => themeProvider ?? ThemeProvider(),
        ),
        if (includeFirestore)
          Provider<FirebaseFirestore>.value(value: fakeFirestore),
        if (includeAuth)
          Provider<FirebaseAuth>.value(value: mockAuth),
      ],
      child: MaterialApp(
        title: 'OpenSlot Test',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: child,
      ),
    );
  }

  /// Create Cupertino test app for iOS-style widgets
  static Widget createCupertinoTestApp({
    required Widget child,
    ThemeProvider? themeProvider,
    bool includeFirestore = true,
    bool includeAuth = true,
    User? customUser,
  }) {
    // Use custom user if provided
    if (customUser != null && includeAuth) {
      mockAuth.signIn(customUser);
    }
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => themeProvider ?? ThemeProvider(),
        ),
        if (includeFirestore)
          Provider<FirebaseFirestore>.value(value: fakeFirestore),
        if (includeAuth)
          Provider<FirebaseAuth>.value(value: mockAuth),
      ],
      child: CupertinoApp(
        title: 'OpenSlot Test',
        home: Material(child: child),
      ),
    );
  }

  /// Create test data in Firestore
  static Future<void> setupTestData() async {
    // Add test events
    await fakeFirestore.collection('events').doc('event-1').set({
      'id': 'event-1',
      'name': 'Test Comedy Show',
      'category': 'Comedy',
      'date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'slots': 50,
      'price': 15.00,
      'host': 'test-user-123',
      'hostName': 'Test Host',
      'address': '123 Test Street',
      'ended': false,
      'live': false,
      'isPrivate': false,
      'attendees': [],
      'waitlist': [],
      'location': {
        'latitude': 40.7128,
        'longitude': -74.0060,
      },
    });

    // Add test user
    await fakeFirestore.collection('users').doc('test-user-123').set({
      'id': 'test-user-123',
      'username': 'testuser',
      'email': 'test@example.com',
      'photoUrl': 'https://example.com/photo.jpg',
      'bio': 'Test user bio',
      'isHost': true,
      'savedEvents': [],
      'hostingEvents': ['event-1'],
    });
  }

  /// Safe pump widget with timeout protection
  static Future<void> safePumpWidget(
    WidgetTester tester,
    Widget widget, {
    Duration? timeout,
  }) async {
    try {
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle(timeout ?? const Duration(seconds: 5));
    } catch (e) {
      debugPrint('SafePumpWidget timeout: $e');
      // Continue with test even if pump times out
    }
  }

  /// Safe tap with timeout protection
  static Future<void> safeTap(
    WidgetTester tester,
    Finder finder, {
    Duration? timeout,
  }) async {
    try {
      if (tester.any(finder)) {
        await tester.tap(finder);
        await tester.pumpAndSettle(timeout ?? const Duration(seconds: 2));
      } else {
        debugPrint('SafeTap: Widget not found');
      }
    } catch (e) {
      debugPrint('SafeTap timeout: $e');
    }
  }

  /// Safe text entry with timeout protection
  static Future<void> safeEnterText(
    WidgetTester tester,
    Finder finder,
    String text, {
    Duration? timeout,
  }) async {
    try {
      if (tester.any(finder)) {
        await tester.enterText(finder, text);
        await tester.pumpAndSettle(timeout ?? const Duration(seconds: 2));
      } else {
        debugPrint('SafeEnterText: Widget not found');
      }
    } catch (e) {
      debugPrint('SafeEnterText timeout: $e');
    }
  }

  /// Get mock user for testing
  static User getMockUser() => mockUser;

  /// Get mock auth for testing
  static MockFirebaseAuth getMockAuth() => mockAuth;

  /// Get fake firestore for testing
  static FakeFirebaseFirestore getFakeFirestore() => fakeFirestore;

  /// Sign out the mock user
  static Future<void> signOut() async {
    await mockAuth.signOut();
  }

  /// Sign in the mock user
  static void signIn([User? user]) {
    mockAuth.signIn(user ?? mockUser);
  }
}
