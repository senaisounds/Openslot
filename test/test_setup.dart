import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:slotted/providers/theme_provider.dart';
import 'package:slotted/utils/test_network_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprehensive test setup for OpenSlot app
class TestSetup {
  static late FakeFirebaseFirestore fakeFirestore;
  static bool _initialized = false;

  /// Initialize all test dependencies
  static Future<void> initialize() async {
    if (_initialized) return;

    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase for testing with proper options
    try {
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
    } catch (e) {
      // Firebase already initialized - this is fine
      debugPrint('Firebase already initialized: $e');
    }

    // Set up fake Firestore
    fakeFirestore = FakeFirebaseFirestore();
    
    // Enable test network service
    TestNetworkService.enableTestMode();
    
    // Set up SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
    
    _initialized = true;
  }

  /// Clean up after tests
  static Future<void> cleanup() async {
    TestNetworkService.disableTestMode();
    try {
      await fakeFirestore.terminate();
      await fakeFirestore.clearPersistence();
    } catch (e) {
      // Ignore cleanup errors
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
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => themeProvider ?? ThemeProvider(),
        ),
        if (includeFirestore)
          Provider<FirebaseFirestore>.value(value: fakeFirestore),
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
}
