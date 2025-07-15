import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotted/pages/event_chat.dart';
import 'package:slotted/common/event_class.dart';
import '../test_setup.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockUser extends Mock implements User {}

void main() {
  setUpAll(() async {
    await TestSetup.initialize();
  });

  tearDownAll(() async {
    await TestSetup.cleanup();
  });

  group('EventChatPage Widget Tests', () {
    late Event testEvent;
    late User testUser;

    setUp(() async {
      await TestSetup.setupTestData();
      testEvent = Event(
        id: 'test-event',
        name: 'Test Event',
        host: 'host-user-id',
        hostName: 'Test Host',
        date: DateTime.now(),
        slots: 3,
        price: 0.0,
        attendees: ['user1'],
        waitlist: [],
        live: true,
        ended: false,
        address: '123 Test St',
        category: 'Music',
        location: null,
        isPrivate: false,
      );
      testUser = MockUser();
      when(testUser.uid).thenReturn('user1');
    });

    testWidgets('User can send and see a message', (WidgetTester tester) async {
      await TestSetup.safePumpWidget(
        tester,
        CupertinoApp(
          home: EventChatPage(
            event: testEvent,
            user: testUser, // Pass the mock user
            debug: true,
          ),
        ),
      );

      // Enter a message
      final messageField = find.byType(CupertinoTextField);
      expect(messageField, findsOneWidget);
      await tester.enterText(messageField, 'Hello, this is a test message!');
      await tester.pumpAndSettle();

      // Tap send button
      final sendButton = find.byIcon(CupertinoIcons.arrow_up);
      expect(sendButton, findsOneWidget);
      await tester.tap(sendButton);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Check that the message appears in the chat list
      expect(find.text('Hello, this is a test message!'), findsWidgets);
    });
  });
} 