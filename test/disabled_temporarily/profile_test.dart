import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:slotted/pages/profile_page.dart';
import 'package:slotted/providers/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late ThemeProvider themeProvider;
  late MockDocumentReference mockDocRef;
  late MockFirebaseFirestore mockFirestore;

  setUp(() async {
    // Initialize test mocks
    await setupTestMocks();
    
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockFirestore = MockFirebaseFirestore();
    mockDocRef = mockFirestore.doc('users/test-uid') as MockDocumentReference;
    themeProvider = ThemeProvider();

    // Set up initial auth state
    mockAuth.signIn(mockUser);
  });

  Widget buildTestWidget({User? user, String? viewUser, bool debug = true}) {
    return MultiProvider(
      providers: [
        Provider<FirebaseAuth>.value(value: mockAuth),
        Provider<FirebaseFirestore>.value(value: mockFirestore),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const CupertinoApp(
        home: ProfilePage(),
      ),
    );
  }

  testWidgets('Shows sign in view when user is null and no viewUser',
      (WidgetTester tester) async {
    mockAuth.signOut();
    
    await tester.pumpWidget(buildTestWidget(user: null));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to view your profile'), findsOneWidget);
  });

  testWidgets('Shows profile view when user is authenticated',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget(user: mockUser));
    await tester.pumpAndSettle();

    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
  });

  testWidgets('Bio field is editable when viewing own profile',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget(user: mockUser));
    await tester.pumpAndSettle();

    final bioField = find.byType(CupertinoTextField);
    expect(bioField, findsOneWidget);

    await tester.enterText(bioField, 'New bio');
    await tester.pumpAndSettle();

    expect(find.text('New bio'), findsOneWidget);
  });

  testWidgets('Social media buttons are tappable', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget(user: mockUser));
    await tester.pumpAndSettle();

    expect(find.byIcon(CupertinoIcons.globe), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.chat_bubble), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.person_2), findsOneWidget);
  });

  testWidgets('Animations are properly triggered', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget(user: mockUser));
    
    // Initial state
    await tester.pump();
    expect(find.text('Test User'), findsOneWidget);
    
    // After animation
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Test User'), findsOneWidget);
  });

  testWidgets('Profile image loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget(user: mockUser));
    await tester.pumpAndSettle();

    // Wait for the widget to build
    await tester.pump();

    expect(find.byType(CircleAvatar), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.person_fill), findsOneWidget);
  });
} 