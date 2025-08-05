import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotted/widgets/enhanced_event_card.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/common/slotted_user.dart';

void main() {
  group('Reserve Button Tests', () {
    late Event testEvent;
    late SlottedUser testUser;

    setUp(() {
      testEvent = Event(
        id: 'test-event-1',
        name: 'Test Event',
        description: 'A test event',
        host: 'test-host',
        date: DateTime.now().add(const Duration(days: 1)),
        address: '123 Test St',
        category: 'Music',
        price: 0.0,
        slots: 10,
        attendees: [],
        waitlist: [],
        isPrivate: false,
        ended: false,
      );

      testUser = SlottedUser()
        ..id = 'test-user-1'
        ..username = 'testuser'
        ..email = 'test@example.com'
        ..phoneNumber = '+1234567890'
        ..customerID = 'cus_test'
        ..testCustomerID = 'cus_test_debug';
    });

    testWidgets('Reserve button shows correct text for available event', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedEventCard(
              event: testEvent,
              currentUser: testUser,
              onReserve: (event) async {
                // Mock reserve action
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Should show "Reserve" for available event
      expect(find.text('Reserve'), findsOneWidget);
    });

    testWidgets('Reserve button shows "Reserved" when user is already reserved', (WidgetTester tester) async {
      final reservedEvent = Event(
        id: 'test-event-2',
        name: 'Test Event',
        description: 'A test event',
        host: 'test-host',
        date: DateTime.now().add(const Duration(days: 1)),
        address: '123 Test St',
        category: 'Music',
        price: 0.0,
        slots: 10,
        attendees: ['test-user-1'], // User is already reserved
        waitlist: [],
        isPrivate: false,
        ended: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedEventCard(
              event: reservedEvent,
              currentUser: testUser,
              onReserve: (event) async {
                // Mock reserve action
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Should show "Reserved" when user is already reserved
      expect(find.text('Reserved'), findsOneWidget);
    });

    testWidgets('Reserve button shows "Waitlist" when event is full', (WidgetTester tester) async {
      final fullEvent = Event(
        id: 'test-event-3',
        name: 'Test Event',
        description: 'A test event',
        host: 'test-host',
        date: DateTime.now().add(const Duration(days: 1)),
        address: '123 Test St',
        category: 'Music',
        price: 0.0,
        slots: 2,
        attendees: ['user1', 'user2'], // Event is full
        waitlist: [],
        isPrivate: false,
        ended: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedEventCard(
              event: fullEvent,
              currentUser: testUser,
              onReserve: (event) async {
                // Mock reserve action
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Should show "Join Waitlist" when event is full
      expect(find.text('Join Waitlist'), findsOneWidget);
    });

    testWidgets('Reserve button is disabled when no user is logged in', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedEventCard(
              event: testEvent,
              currentUser: null, // No user logged in
              onReserve: (event) async {
                // Mock reserve action
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // When no user is logged in, the button should either be disabled or not rendered
      // Check if button exists and is disabled
      final buttonFinder = find.byType(CupertinoButton);
      if (buttonFinder.evaluate().isNotEmpty) {
        final button = tester.widget<CupertinoButton>(buttonFinder);
        expect(button.onPressed, isNull);
      } else {
        // Button might not be rendered at all when no user is logged in
        expect(find.text('Reserve'), findsNothing);
      }
    });

    testWidgets('Reserve button calls onReserve when tapped', (WidgetTester tester) async {
      bool reserveCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedEventCard(
              event: testEvent,
              currentUser: testUser,
              onReserve: (event) async {
                reserveCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Tap the reserve button
      await tester.tap(find.text('Reserve'));
      await tester.pump();

      // Verify that onReserve was called
      expect(reserveCalled, isTrue);
    });
  });
} 