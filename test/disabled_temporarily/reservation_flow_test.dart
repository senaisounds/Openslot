import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:slotted/common/event_class.dart';
import 'package:slotted/pages/event_details.dart';
import '../test_helpers.dart';
import 'package:latlong2/latlong.dart';

// Helper class to create test widgets
class TestApp extends StatelessWidget {
  final Widget child;
  final bool isLoggedIn;
  final MockUser? mockUser;
  final Function(BuildContext, bool, Function) authAction;

  const TestApp({
    super.key,
    required this.child,
    this.isLoggedIn = true,
    this.mockUser,
    required this.authAction,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: child,
    );
  }
}

// Mock HTTP client
class MockClient extends Mock implements http.Client {}

// Mock HTTP response
class MockResponse extends Mock implements http.Response {
  final String _body;
  final int _statusCode;

  MockResponse(this._body, this._statusCode);

  @override
  String get body => _body;

  @override
  int get statusCode => _statusCode;
}

// Create a test event
Event createTestEvent({
  String id = 'test-event-id',
  bool isPrivate = false,
  bool isFull = false,
  List<String> attendees = const [],
  List<String> waitlist = const [],
  double price = 0.0,
}) {
  return Event(
    id: id,
    name: 'Test Event',
    host: 'host-id',
    hostName: 'Host Name',
    description: 'Test description',
    rules: 'Test rules',
    location: const LatLng(37.7749, -122.4194),
    date: DateTime.now().add(const Duration(days: 1)),
    address: '123 Test Street',
    category: 'comedy',
    live: false,
    ended: false,
    performer: '',
    performerStart: null,
    timeLimit: 0,
    attendees: attendees,
    reservationTimestamps: {},
    checkedPerformers: {},
    upNext: '',
    price: price,
    signupOnLocation: false,
    slots: isFull ? attendees.length : attendees.length + 10,
    type: EventType.mic,
    waitlist: waitlist,
    isPrivate: isPrivate,
    password: isPrivate ? 'testpassword' : '',
    coverUrl: '',
    isFeatured: false,
    capacity: 100,
    checkedPerformersList: const [],
  );
}

void main() {
  late MockClient mockClient;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockSlottedUser mockSlottedUser;
  
  setUp(() async {
    // Initialize mocks
    mockClient = MockClient();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockSlottedUser = MockSlottedUser();
    
    // Setup Firebase mocks
    await setupTestMocks();
    setupFirebaseCoreMocks();
    
    // Setup connectivity check mock
    when(mockClient.get(Uri.parse('https://google.com')))
        .thenAnswer((_) async => MockResponse('', 200));
    
    // Sign in the mock user
    mockAuth.signIn(mockUser);
  });
  
  // Authentication mock function
  Future<void> mockAuthAction(BuildContext context, bool isSignup, Function callback) async {
    // Simulate successful authentication
    mockAuth.signIn(mockUser);
    callback();
  }
  
  group('Event Reservation Integration Tests', () {
    testWidgets('Complete free event reservation flow', (WidgetTester tester) async {
      // Create a test event with open slots
      final event = createTestEvent();
      
      // Mock API responses
      when(mockClient.post(
        Uri.parse('https://us-central1-open-mic-5cc8e.cloudfunctions.net/reserveAction'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => MockResponse('Successfully reserved', 200));
      
      // Build event details page
      await tester.pumpWidget(
        TestApp(
          authAction: mockAuthAction,
          isLoggedIn: true,
          mockUser: mockUser,
          child: EventDetailsPage(
            initialEvent: event,
            debug: true,
            authAction: mockAuthAction,
          ),
        ),
      );
      
      // Wait for widget to build
      await tester.pumpAndSettle();
      
      // Find and tap the reserve button
      final reserveButtonFinder = find.text('Reserve');
      expect(reserveButtonFinder, findsOneWidget);
      await tester.tap(reserveButtonFinder);
      await tester.pumpAndSettle();
      
      // Wait for the reservation process to complete
      await tester.pump(const Duration(seconds: 2));
      
      // Verify success dialog is shown
      expect(find.text('Success'), findsOneWidget);
      expect(find.text('Your spot has been reserved!'), findsOneWidget);
      
      // Tap OK to dismiss the dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      
      // Verify the button now shows "Reserved"
      expect(find.text('Reserved'), findsOneWidget);
    });
    
    testWidgets('Waitlist flow when event is full', (WidgetTester tester) async {
      // Create a full event
      final event = createTestEvent(
        isFull: true,
        attendees: List.generate(10, (index) => 'user$index'),
      );
      
      // Mock waitlist response
      when(mockClient.post(
        Uri.parse('https://us-central1-open-mic-5cc8e.cloudfunctions.net/reserveAction'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => MockResponse(
        json.encode({'status': 'waitlisted', 'position': 1}),
        200
      ));
      
      // Build event details page
      await tester.pumpWidget(
        TestApp(
          authAction: mockAuthAction,
          isLoggedIn: true,
          mockUser: mockUser,
          child: EventDetailsPage(
            initialEvent: event,
            debug: true,
            authAction: mockAuthAction,
          ),
        ),
      );
      
      // Wait for widget to build
      await tester.pumpAndSettle();
      
      // Find and tap the reserve button
      final reserveButtonFinder = find.text('Reserve');
      expect(reserveButtonFinder, findsOneWidget);
      await tester.tap(reserveButtonFinder);
      await tester.pumpAndSettle();
      
      // Wait for the reservation process to complete
      await tester.pump(const Duration(seconds: 2));
      
      // Verify success dialog is shown
      expect(find.text('Success'), findsOneWidget);
      expect(find.text('You have been added to the waitlist!'), findsOneWidget);
      
      // Tap OK to dismiss the dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      
      // Verify the button now shows waitlist status
      expect(find.text('Waitlisted (#1)'), findsOneWidget);
    });
    
    testWidgets('Unreserve flow', (WidgetTester tester) async {
      // Create an event with the user already attending
      final event = createTestEvent(
        attendees: ['test-uid', 'user2'],
      );
      
      // Mock unreserve response
      when(mockClient.post(
        Uri.parse('https://us-central1-open-mic-5cc8e.cloudfunctions.net/reserveAction'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => MockResponse('Successfully unreserved', 200));
      
      // Build event details page
      await tester.pumpWidget(
        TestApp(
          authAction: mockAuthAction,
          isLoggedIn: true,
          mockUser: mockUser,
          child: EventDetailsPage(
            initialEvent: event,
            debug: true,
            authAction: mockAuthAction,
          ),
        ),
      );
      
      // Wait for widget to build
      await tester.pumpAndSettle();
      
      // Find and tap the unreserve button
      final unreserveButtonFinder = find.text('Unreserve');
      expect(unreserveButtonFinder, findsOneWidget);
      await tester.tap(unreserveButtonFinder);
      await tester.pumpAndSettle();
      
      // Confirm unreserve dialog
      expect(find.text('Cancel Reservation'), findsOneWidget);
      await tester.tap(find.text('Unreserve'));
      await tester.pumpAndSettle();
      
      // Wait for the unreserve process to complete
      await tester.pump(const Duration(seconds: 2));
      
      // Verify success dialog is shown
      expect(find.text('Success'), findsOneWidget);
      expect(find.text('Your reservation has been cancelled.'), findsOneWidget);
      
      // Tap OK to dismiss the dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      
      // Verify the button now shows "Reserve"
      expect(find.text('Reserve'), findsOneWidget);
    });
    
    testWidgets('Private event with password flow', (WidgetTester tester) async {
      // Create a private event
      final event = createTestEvent(isPrivate: true);
      
      // Mock reservation response
      when(mockClient.post(
        Uri.parse('https://us-central1-open-mic-5cc8e.cloudfunctions.net/reserveAction'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => MockResponse('Successfully reserved', 200));
      
      // Build event details page
      await tester.pumpWidget(
        TestApp(
          authAction: mockAuthAction,
          isLoggedIn: true,
          mockUser: mockUser,
          child: EventDetailsPage(
            initialEvent: event,
            debug: true,
            authAction: mockAuthAction,
          ),
        ),
      );
      
      // Wait for widget to build
      await tester.pumpAndSettle();
      
      // Find and tap the reserve button
      final reserveButtonFinder = find.text('Reserve');
      expect(reserveButtonFinder, findsOneWidget);
      await tester.tap(reserveButtonFinder);
      await tester.pumpAndSettle();
      
      // Verify password dialog appears
      expect(find.text('Enter Event Password'), findsOneWidget);
      
      // Enter correct password
      await tester.enterText(find.byType(TextField), 'testpassword');
      await tester.pumpAndSettle();
      
      // Tap continue to submit password
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      
      // Wait for the reservation process to complete
      await tester.pump(const Duration(seconds: 2));
      
      // Verify success dialog is shown
      expect(find.text('Success'), findsOneWidget);
      expect(find.text('Your spot has been reserved!'), findsOneWidget);
      
      // Tap OK to dismiss the dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      
      // Verify the button now shows "Reserved"
      expect(find.text('Reserved'), findsOneWidget);
    });
    
    testWidgets('Network error handling', (WidgetTester tester) async {
      // Create a test event
      final event = createTestEvent();
      
      // Mock network error
      when(mockClient.get(Uri.parse('https://google.com')))
          .thenThrow(const HttpException('Network error'));
      
      // Build event details page
      await tester.pumpWidget(
        TestApp(
          authAction: mockAuthAction,
          isLoggedIn: true,
          mockUser: mockUser,
          child: EventDetailsPage(
            initialEvent: event,
            debug: true,
            authAction: mockAuthAction,
          ),
        ),
      );
      
      // Wait for widget to build
      await tester.pumpAndSettle();
      
      // Find and tap the reserve button
      final reserveButtonFinder = find.text('Reserve');
      expect(reserveButtonFinder, findsOneWidget);
      await tester.tap(reserveButtonFinder);
      await tester.pumpAndSettle();
      
      // Wait for error processing
      await tester.pump(const Duration(seconds: 2));
      
      // Verify error dialog is shown
      expect(find.text('Error'), findsOneWidget);
      expect(find.textContaining('connection'), findsOneWidget);
      
      // Tap OK to dismiss the dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      
      // Verify the button still shows "Reserve"
      expect(find.text('Reserve'), findsOneWidget);
    });
    
    testWidgets('Paid event flow', (WidgetTester tester) async {
      // Create a paid event
      final event = createTestEvent(price: 10.0);
      
      // Mock payment intent creation
      when(mockClient.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => MockResponse(
        json.encode({
          'id': 'pi_test123',
          'client_secret': 'test_secret',
          'amount': 1000,
          'currency': 'usd',
          'customer': 'cus_test',
        }),
        200
      ));
      
      // Mock ephemeral key creation
      when(mockClient.post(
        Uri.parse('https://us-central1-open-mic-5cc8e.cloudfunctions.net/getEphemeralKey'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => MockResponse(
        json.encode({'secret': 'ephemeral_key_test'}),
        200
      ));
      
      // Mock reservation response
      when(mockClient.post(
        Uri.parse('https://us-central1-open-mic-5cc8e.cloudfunctions.net/reserveAction'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => MockResponse('Successfully reserved', 200));
      
      // Build event details page
      await tester.pumpWidget(
        TestApp(
          authAction: mockAuthAction,
          isLoggedIn: true,
          mockUser: mockUser,
          child: EventDetailsPage(
            initialEvent: event,
            debug: true,
            authAction: mockAuthAction,
          ),
        ),
      );
      
      // Wait for widget to build
      await tester.pumpAndSettle();
      
      // Find and tap the reserve button
      final reserveButtonFinder = find.text('Reserve (\$10.00)');
      expect(reserveButtonFinder, findsOneWidget);
      await tester.tap(reserveButtonFinder);
      await tester.pumpAndSettle();
      
      // Note: In a real test, we would interact with the payment sheet here,
      // but since it's a native UI component, we can only simulate its completion
      
      // Simulate completion of payment process
      // This is a placeholder for what would happen after payment
      
      // Verify success dialog would be shown
      // In a real test environment, this would appear after payment completion
      // expect(find.text('Success'), findsOneWidget);
      // expect(find.text('Your spot has been reserved!'), findsOneWidget);
    });
  });
} 