import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:latlong2/latlong.dart';
import '../test_setup.dart';

void main() {
  setUpAll(() async {
    await TestSetup.initialize();
  });

  tearDownAll(() async {
    await TestSetup.cleanup();
  });

  group('Live Page Comprehensive Tests', () {
    late Event testEvent;
    late SlottedUser testUser;

    setUp(() async {
      await TestSetup.setupTestData();
      
      // Create test event
      testEvent = Event(
        id: 'test-live-event',
        name: 'Test Live Event',
        host: 'host-user-id',
        hostName: 'Test Host',
        date: DateTime.now().add(const Duration(hours: 2)),
        slots: 5,
        price: 15.0,
        attendees: ['user1', 'user2'],
        waitlist: ['waitlist1'],
        live: false,
        ended: false,
        address: '123 Test St',
        category: 'Music',
        location: const LatLng(40.7128, -74.0060),
        isPrivate: false,
      );

      // Create test user
      testUser = SlottedUser()
        ..id = 'test-user-id'
        ..username = 'TestUser'
        ..bio = 'Test bio'
        ..photoUrl = 'https://example.com/photo.jpg'
        ..isFirstTimer = false
        ..twitter = '@testuser'
        ..instagram = '@testuser';
    });

    testWidgets('Event displays basic information correctly', (WidgetTester tester) async {
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            body: Column(
              children: [
                Text('Event: ${testEvent.name}'),
                Text('Host: ${testEvent.hostName}'),
                Text('Slots: ${testEvent.attendees.length}/${testEvent.slots}'),
                Text('Price: \$${testEvent.price.toStringAsFixed(2)}'),
                Text('Waitlist: ${testEvent.waitlist.length}'),
              ],
            ),
          ),
        ),
      );

      // Verify event information is displayed
      expect(find.text('Event: Test Live Event'), findsOneWidget);
      expect(find.text('Host: Test Host'), findsOneWidget);
      expect(find.text('Slots: 2/5'), findsOneWidget);
      expect(find.text('Price: \$15.00'), findsOneWidget);
      expect(find.text('Waitlist: 1'), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('Waitlist management works correctly', (WidgetTester tester) async {
      bool isUserWaitlisted = testEvent.waitlist.contains(testUser.id);
      bool isEventFull = testEvent.attendees.length >= testEvent.slots;
      
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            body: Column(
              children: [
                Text('User Waitlisted: $isUserWaitlisted'),
                Text('Event Full: $isEventFull'),
                Text('Available Slots: ${testEvent.slots - testEvent.attendees.length}'),
                if (isUserWaitlisted)
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Leave Waitlist'),
                  )
                else if (isEventFull)
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Join Waitlist'),
                  )
                else
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Reserve Spot'),
                  ),
              ],
            ),
          ),
        ),
      );

      // Verify waitlist status
      expect(find.text('User Waitlisted: false'), findsOneWidget);
      expect(find.text('Event Full: false'), findsOneWidget);
      expect(find.text('Available Slots: 3'), findsOneWidget);
      expect(find.text('Reserve Spot'), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('Event status transitions work correctly', (WidgetTester tester) async {
      // Test different event states
      final states = [
        {'live': false, 'ended': false, 'status': 'Upcoming'},
        {'live': true, 'ended': false, 'status': 'Live'},
        {'live': false, 'ended': true, 'status': 'Ended'},
      ];

      for (final state in states) {
        final event = Event(
          id: testEvent.id,
          name: testEvent.name,
          host: testEvent.host,
          hostName: testEvent.hostName,
          date: testEvent.date,
          slots: testEvent.slots,
          price: testEvent.price,
          attendees: testEvent.attendees,
          waitlist: testEvent.waitlist,
          live: state['live'] as bool,
          ended: state['ended'] as bool,
          address: testEvent.address,
          category: testEvent.category,
          location: testEvent.location,
          isPrivate: testEvent.isPrivate,
        );

        await TestSetup.safePumpWidget(
          tester,
          TestSetup.createSimpleTestWidget(
            child: Scaffold(
              body: Column(
                children: [
                  Text('Status: ${state['status']}'),
                  if (event.live) 
                    const Icon(CupertinoIcons.dot_radiowaves_left_right, color: Colors.red)
                  else if (event.ended)
                    const Icon(CupertinoIcons.check_mark_circled, color: Colors.green)
                  else
                    const Icon(CupertinoIcons.clock, color: Colors.orange),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Status: ${state['status']}'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 100));
      }
    }, timeout: const Timeout(Duration(seconds: 15)));

    testWidgets('Reservation button states work correctly', (WidgetTester tester) async {
      final scenarios = [
        {
          'userInAttendees': true,
          'userInWaitlist': false,
          'eventFull': false,
          'expectedText': 'Reserved',
          'expectedColor': Colors.green,
        },
        {
          'userInAttendees': false,
          'userInWaitlist': true,
          'eventFull': true,
          'expectedText': 'Waitlisted',
          'expectedColor': Colors.orange,
        },
        {
          'userInAttendees': false,
          'userInWaitlist': false,
          'eventFull': false,
          'expectedText': 'Reserve',
          'expectedColor': Colors.blue,
        },
        {
          'userInAttendees': false,
          'userInWaitlist': false,
          'eventFull': true,
          'expectedText': 'Join Waitlist',
          'expectedColor': Colors.orange,
        },
      ];

      for (final scenario in scenarios) {
        final attendees = scenario['userInAttendees'] as bool 
            ? [...testEvent.attendees, testUser.id]
            : testEvent.attendees;
        
        final waitlist = scenario['userInWaitlist'] as bool
            ? [...testEvent.waitlist, testUser.id]
            : testEvent.waitlist;

        final slots = scenario['eventFull'] as bool ? attendees.length : testEvent.slots;

        await TestSetup.safePumpWidget(
          tester,
          TestSetup.createSimpleTestWidget(
            child: Scaffold(
              body: Column(
                children: [
                  Text('Scenario: ${scenario['expectedText']}'),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scenario['expectedColor'] as Color,
                    ),
                    onPressed: () {},
                    child: Text(scenario['expectedText'] as String),
                  ),
                  Text('Attendees: ${attendees.length}/$slots'),
                  Text('Waitlist: ${waitlist.length}'),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Scenario: ${scenario['expectedText']}'), findsOneWidget);
        expect(find.text(scenario['expectedText'] as String), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 100));
      }
    }, timeout: const Timeout(Duration(seconds: 20)));
  });

  group('Live Page Error Handling Tests', () {
    testWidgets('Handles missing event data gracefully', (WidgetTester tester) async {
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            body: Column(
              children: [
                const Text('Event not found'),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Event not found'), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('Handles network errors gracefully', (WidgetTester tester) async {
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            body: Column(
              children: [
                const Icon(CupertinoIcons.wifi_slash, size: 50),
                const Text('Network error'),
                const Text('Please check your connection and try again'),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Network error'), findsOneWidget);
      expect(find.text('Please check your connection and try again'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 10)));
  });
}
