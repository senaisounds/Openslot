// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mockito/mockito.dart';
import 'package:slotted/main.dart';
import 'package:slotted/providers/theme_provider.dart';
import '../test_helpers.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late MockFlutterLocalNotificationsPlugin mockNotifications;


  setUpAll(() async {
    // Setup Firebase for testing
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockAuth = MockFirebaseAuth();
    mockNotifications = MockFlutterLocalNotificationsPlugin();

    
    // Mock the auth state changes
    when(mockAuth.authStateChanges())
        .thenAnswer((_) => Stream.value(null));
    
    // Mock the notifications initialization with proper settings
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    when(mockNotifications.initialize(
      initializationSettings,
    )).thenAnswer((_) async => true);
  });

  testWidgets('App initializes with theme provider', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<FirebaseAuth>.value(value: mockAuth),
          Provider<FlutterLocalNotificationsPlugin>.value(value: mockNotifications),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Wait for initial frame
    await tester.pump();

    // Verify the app initializes without errors
    expect(find.byType(CupertinoApp), findsOneWidget);
  });
}
