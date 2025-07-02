import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_setup.dart';

void main() {
  setUpAll(() async {
    await TestSetup.initialize();
  });

  tearDownAll(() async {
    await TestSetup.cleanup();
  });

  group('Basic Widget Interaction Tests', () {
    testWidgets('Button tap works correctly', (WidgetTester tester) async {
      int tapCount = 0;
      
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  tapCount++;
                },
                child: const Text('Test Button'),
              ),
            ),
          ),
        ),
      );

      // Find and tap the button
      final buttonFinder = find.text('Test Button');
      expect(buttonFinder, findsOneWidget);
      
      await TestSetup.safeTap(tester, buttonFinder);
      expect(tapCount, equals(1));
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('Text fields work correctly', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            body: Center(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Enter text'),
              ),
            ),
          ),
        ),
      );

      // Find and enter text
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      
      await TestSetup.safeEnterText(tester, textFieldFinder, 'Test input');
      expect(controller.text, equals('Test input'));
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('Basic layout renders correctly', (WidgetTester tester) async {
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            appBar: AppBar(title: const Text('Test App')),
            body: const Column(
              children: [
                Text('Header'),
                Expanded(child: Center(child: Text('Content'))),
                Text('Footer'),
              ],
            ),
          ),
        ),
      );

      // Verify all elements are present
      expect(find.text('Test App'), findsOneWidget);
      expect(find.text('Header'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
      expect(find.text('Footer'), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 10)));
  });

  group('Widget State Tests', () {
    testWidgets('StatefulWidget state changes work', (WidgetTester tester) async {
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: const Scaffold(
            body: Center(child: _CounterWidget()),
          ),
        ),
      );

      // Initial state
      expect(find.text('Count: 0'), findsOneWidget);
      
      // Tap increment button
      await TestSetup.safeTap(tester, find.text('Increment'));
      
      // Check updated state
      expect(find.text('Count: 1'), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('Multiple widgets interact correctly', (WidgetTester tester) async {
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            body: Column(
              children: [
                const Text('Multiple Widgets Test'),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Button 1'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Button 2'),
                ),
                const TextField(
                  decoration: InputDecoration(hintText: 'Input field'),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify all widgets are present
      expect(find.text('Multiple Widgets Test'), findsOneWidget);
      expect(find.text('Button 1'), findsOneWidget);
      expect(find.text('Button 2'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 10)));
  });
}

// Simple test widget for state testing
class _CounterWidget extends StatefulWidget {
  const _CounterWidget();

  @override
  State<_CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<_CounterWidget> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Count: $_count'),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _count++;
            });
          },
          child: const Text('Increment'),
        ),
      ],
    );
  }
}