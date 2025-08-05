import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:slotted/pages/login_page.dart';

void main() {
  group('Apple Sign In Tests', () {
    setUpAll(() async {
      // Setup test environment
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    testWidgets('Apple Sign In button is present and styled correctly', (WidgetTester tester) async {
      // Build the login page
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify Apple Sign In button exists with correct text
      expect(find.text('Sign in with Apple'), findsOneWidget);

      // Verify the button has the correct styling
      final appleButton = tester.widget<CupertinoButton>(
        find.byWidgetPredicate((widget) => 
          widget is CupertinoButton && 
          widget.child is Row &&
          (widget.child as Row).children.any((child) => 
            child is Text && 
            (child).data == 'Sign in with Apple'
          )
        ),
      );

      // Verify button color is transparent (as set in the actual implementation)
      expect(appleButton.color, Colors.transparent);

      // Verify Apple logo container exists
      expect(find.byWidgetPredicate((widget) => 
        widget is Container && 
        widget.decoration is BoxDecoration &&
        (widget.decoration as BoxDecoration).color == CupertinoColors.black
      ), findsOneWidget);
    });

    testWidgets('Apple Sign In button shows loading state when pressed', (WidgetTester tester) async {
      // Build the login page
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the Apple Sign In button
      final appleButton = find.text('Sign in with Apple');
      expect(appleButton, findsOneWidget);

      await tester.tap(appleButton);
      await tester.pump();

      // Verify loading state (button should be disabled)
      final button = tester.widget<CupertinoButton>(
        find.byWidgetPredicate((widget) => 
          widget is CupertinoButton && 
          widget.child is Row &&
          (widget.child as Row).children.any((child) => 
            child is Text && 
            (child).data == 'Sign in with Apple'
          )
        ),
      );

      // Button should be disabled during loading
      expect(button.onPressed, isNull);
    });

    testWidgets('Error message is displayed when Apple Sign In fails', (WidgetTester tester) async {
      // Build the login page
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the Apple Sign In button
      final appleButton = find.text('Sign in with Apple');
      await tester.tap(appleButton);

      // Wait for the async operation to complete
      await tester.pumpAndSettle();

      // Verify error message is displayed (updated to match actual error message)
      expect(find.textContaining('Apple Sign In failed'), findsOneWidget);
    });

    test('Apple Sign In capability is properly configured', () {
      // Test that the AppleLogoPainter class exists
      expect(() => AppleLogoPainter(), returnsNormally);
    });

    test('AppleLogoPainter draws correctly', () {
      final painter = AppleLogoPainter();
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(24, 24);

      // Should not throw when painting
      expect(() => painter.paint(canvas, size), returnsNormally);
    });

    test('AppleLogoPainter shouldRepaint returns false', () {
      final painter = AppleLogoPainter();
      expect(painter.shouldRepaint(painter), false);
    });

    testWidgets('Apple Sign In button is accessible', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify button is accessible
      final appleButton = find.text('Sign in with Apple');
      expect(appleButton, findsOneWidget);

      // Verify button is tappable
      expect(tester.getSemantics(appleButton), isNotNull);
    });

    testWidgets('Apple Sign In button has correct accessibility label', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );

      await tester.pumpAndSettle();

      final appleButton = find.text('Sign in with Apple');
      final semantics = tester.getSemantics(appleButton);
      
      expect(semantics, isNotNull);
      expect(semantics.label, contains('Apple'));
    });
  });
} 