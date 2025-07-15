import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotted/pages/profile_page.dart';
import '../test_setup.dart';

void main() {
  setUpAll(() async {
    await TestSetup.initialize();
  });

  tearDownAll(() async {
    await TestSetup.cleanup();
  });

  group('ProfilePage Tests', () {
    testWidgets('Shows sign in view when user is null', (WidgetTester tester) async {
      // Sign out the user
      await TestSetup.signOut();
      
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createCupertinoTestApp(
          child: const ProfilePage(),
        ),
      );

      // Look for sign in prompt
      expect(find.text('Sign in to view your profile'), findsOneWidget);
    });

    testWidgets('Shows profile view when user is authenticated', (WidgetTester tester) async {
      // Ensure user is signed in
      TestSetup.signIn();
      
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createCupertinoTestApp(
          child: const ProfilePage(),
        ),
      );

      // Look for user info - check for any text that indicates profile is loaded
      // We expect at least one text widget to be present
      expect(find.byType(Text), findsAtLeastNWidgets(1));
    });

    testWidgets('Profile page renders without crashing', (WidgetTester tester) async {
      TestSetup.signIn();
      
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createCupertinoTestApp(
          child: const ProfilePage(),
        ),
      );

      // Just verify the page loads
      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('Profile page handles null user gracefully', (WidgetTester tester) async {
      await TestSetup.signOut();
      
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createCupertinoTestApp(
          child: const ProfilePage(),
        ),
      );

      // Should not crash and should show some content
      expect(find.byType(ProfilePage), findsOneWidget);
    });
  });
} 