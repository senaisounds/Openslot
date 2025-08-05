import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotted/pages/edit_event.dart';
import 'package:slotted/common/event_class.dart';
import 'package:provider/provider.dart';
import 'package:slotted/providers/theme_provider.dart';
import '../test_helpers.dart';

void main() {
  late MockSlottedUser mockUser;
  late Event mockEvent;

  setUp(() {
    setupTestMocks();
    mockUser = MockSlottedUser(
      id: 'test-host-id',
      username: 'Test Host',
    );
    mockEvent = Event(id: 'test-event-id');
    
    // Initialize event properties
    mockEvent.name = 'Test Event';
    mockEvent.host = 'test-host-id';
    mockEvent.hostName = 'Test Host';
    mockEvent.date = DateTime.now();
    mockEvent.address = '123 Test St';
    mockEvent.slots = 10;
    mockEvent.price = 15.0;
    mockEvent.rules = 'Test Rules';
    mockEvent.attendees = [];
    mockEvent.waitlist = [];
    mockEvent.live = false;
    mockEvent.ended = false;
  });

  testWidgets('EditEventPage shows event details when editing', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: CupertinoApp(
          home: EditEventPage(
            user: mockUser,
            event: mockEvent,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Verify event details are displayed
    expect(find.text('Edit Event'), findsOneWidget);
    expect(find.text('Test Event'), findsOneWidget);
    expect(find.text('123 Test St'), findsOneWidget);
    expect(find.text('Test Rules'), findsOneWidget);
  });

  testWidgets('EditEventPage shows category bubbles', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: CupertinoApp(
          home: EditEventPage(
            user: mockUser,
            event: mockEvent,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Verify category bubbles are displayed
    expect(find.text('Comedy 🎭'), findsOneWidget);
    expect(find.text('DJ 🎧'), findsOneWidget);
    expect(find.text('Poetry ✍️'), findsOneWidget);
    expect(find.text('Other 🎨'), findsOneWidget);
  });

  testWidgets('EditEventPage allows editing event name', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: CupertinoApp(
          home: EditEventPage(
            user: mockUser,
            event: mockEvent,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Find and enter text in the event name field
    final nameField = find.widgetWithText(CupertinoTextField, 'Event Name');
    expect(nameField, findsOneWidget);

    await tester.enterText(nameField, 'Updated Event Name');
    await tester.pump();

    // Verify text was entered
    expect(find.text('UPDATED EVENT NAME'), findsOneWidget);
  });

  testWidgets('EditEventPage allows editing event price', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: CupertinoApp(
          home: EditEventPage(
            user: mockUser,
            event: mockEvent,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Find and enter text in the price field
    final priceField = find.widgetWithText(CupertinoTextField, 'Price');
    expect(priceField, findsOneWidget);

    await tester.enterText(priceField, '25.00');
    await tester.pump();

    // Verify text was entered
    expect(find.text('25.00'), findsOneWidget);
  });

  testWidgets('EditEventPage allows editing event slots', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: CupertinoApp(
          home: EditEventPage(
            user: mockUser,
            event: mockEvent,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Find and enter text in the slots field
    final slotsField = find.widgetWithText(CupertinoTextField, 'Slots');
    expect(slotsField, findsOneWidget);

    await tester.enterText(slotsField, '20');
    await tester.pump();

    // Verify text was entered
    expect(find.text('20'), findsOneWidget);
  });
} 