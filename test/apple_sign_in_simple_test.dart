import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

void main() {
  group('Apple Sign In Tests', () {
    testWidgets('Apple Sign In button should be present', (WidgetTester tester) async {
      // Build a simple widget with Apple Sign In button
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SignInWithAppleButton(
                onPressed: () async {
                  // This would normally handle the sign in
                  print('Apple Sign In pressed');
                },
              ),
            ),
          ),
        ),
      );

      // Verify the button is present
      expect(find.byType(SignInWithAppleButton), findsOneWidget);
    });

    test('Apple Sign In availability check', () async {
      // Check if Apple Sign In is available on the device
      final isAvailable = await SignInWithApple.isAvailable();
      print('Apple Sign In available: $isAvailable');
      
      // This test will pass if the package is properly configured
      expect(isAvailable, isA<bool>());
    });
  });
} 