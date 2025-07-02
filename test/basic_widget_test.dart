import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_setup.dart';

void main() {
  // Initialize test setup before all tests
  setUpAll(() async {
    await TestSetup.initialize();
  });

  // Clean up after all tests
  tearDownAll(() async {
    await TestSetup.cleanup();
  });

  group('Basic Widget Tests', () {
    testWidgets('Simple widgets render correctly', (WidgetTester tester) async {
      // Test simple widgets without Firebase dependencies
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: const Scaffold(
            body: Center(
              child: Text('Hello World'),
            ),
          ),
        ),
      );

      // Verify basic UI elements
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Hello World'), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('Material components work', (WidgetTester tester) async {
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Test App'),
            ),
            body: const Center(
              child: Text('App Content'),
            ),
          ),
        ),
      );

      // Look for AppBar and content
      expect(find.text('Test App'), findsOneWidget);
      expect(find.text('App Content'), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('Buttons respond to interaction', (WidgetTester tester) async {
      int counter = 0;

      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Counter: $counter'),
                  ElevatedButton(
                    onPressed: () {
                      counter++;
                    },
                    child: const Text('Increment'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Find and tap the increment button
      final button = find.text('Increment');
      expect(button, findsOneWidget);

      await TestSetup.safeTap(tester, button);

      // Verify the counter was incremented
      expect(counter, equals(1));
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('Text input works correctly', (WidgetTester tester) async {
      final controller = TextEditingController();

      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            body: Center(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Enter text',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
        ),
      );

      // Find the text field and enter text
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await TestSetup.safeEnterText(tester, textField, 'Test input');

      // Verify text was entered
      expect(controller.text, 'Test input');
    }, timeout: const Timeout(Duration(seconds: 10)));
  });

  group('Layout Tests', () {
    testWidgets('Column layout works', (WidgetTester tester) async {
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: const Scaffold(
            body: Column(
              children: [
                Text('Item 1'),
                Text('Item 2'),
                Text('Item 3'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('Row layout works', (WidgetTester tester) async {
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: const Scaffold(
            body: Row(
              children: [
                Text('Left'),
                Text('Center'),
                Text('Right'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Left'), findsOneWidget);
      expect(find.text('Center'), findsOneWidget);
      expect(find.text('Right'), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 10)));
  });

  group('Error Handling Tests', () {
    testWidgets('Widgets handle null values gracefully', (WidgetTester tester) async {
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            body: Column(
              children: [
                Text('${null ?? 'Default'}'),
                const Text('Static Text'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Default'), findsOneWidget);
      expect(find.text('Static Text'), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('Empty containers render without errors', (WidgetTester tester) async {
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            body: Column(
              children: [
                SizedBox(height: 50),
                Container(),
                Text('After empty container'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('After empty container'), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    }, timeout: const Timeout(Duration(seconds: 10)));
  });
}
