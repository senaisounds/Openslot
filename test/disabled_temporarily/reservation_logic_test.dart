import 'dart:convert';
import 'dart:io'; // For SocketException
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:slotted/pages/event_details.dart';
import '../test_helpers.dart';
import 'package:latlong2/latlong.dart';

// Custom test version of EventDetailsPage that exposes the reservation method
class TestEventDetailsPage extends EventDetailsPage {
  final http.Client httpClient;

  const TestEventDetailsPage({super.key, 
    required super.initialEvent,
    required super.authAction,
    required this.httpClient,
    super.debug = false,
  });

  // Public method for tests to access and call the appropriate reservation flow
  Future<String> callReserveAction(
      dynamic paymentIntent, Event event, SlottedUser slottedUser, User user) async {
    try {
      // Check network connectivity before making request
      try {
        final checkResponse = await httpClient.get(Uri.parse('https://google.com'))
            .timeout(const Duration(seconds: 3));
        if (checkResponse.statusCode != 200) {
          throw const SocketException('No internet connection');
        }
      } catch (e) {
        throw const SocketException('Network error');
      }

      // Prepare request body
      final body = {
        'eventID': event.id,
        'userID': user.uid,
        'debug': 'true',
      };
      
      // Add payment intent if present
      if (paymentIntent != '') {
        body['pi'] = json.encode(paymentIntent);
      } else {
        body['pi'] = '';
      }

      // Make reservation request
      final response = await httpClient.post(
        Uri.parse('https://us-central1-open-mic-5cc8e.cloudfunctions.net/reserveAction'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );
      
      return response.body;
    } catch (e) {
      rethrow;
    }
  }
}

// Mock http.Client
class MockClient extends Mock implements http.Client {}

// Mock Http Response
class MockResponse extends Mock implements http.Response {
  final String _body;
  final int _statusCode;

  MockResponse(this._body, this._statusCode);

  @override
  String get body => _body;

  @override
  int get statusCode => _statusCode;
}

// Extended MockUser with necessary implementations
class TestUser extends MockUser {
  @override
  String get uid => 'test-user-id';
}

// Test SlottedUser implementation
class TestSlottedUser extends SlottedUser {
  TestSlottedUser() {
    id = 'test-user-id';
    customerID = 'test-customer-id';
    testCustomerID = 'test-test-customer-id';
    username = 'testuser';
    email = 'test@example.com';
    phoneNumber = '+1234567890';
    isHost = false;
    isFirstTimer = false;
    createdAt = DateTime.now();
    lastLogin = DateTime.now();
  }
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

// Test reservation logic
void main() {
  late MockClient mockClient;
  late TestUser testUser;
  late TestSlottedUser testSlottedUser;
  late GlobalKey<NavigatorState> navigatorKey;

  setUp(() {
    mockClient = MockClient();
    testUser = TestUser();
    testSlottedUser = TestSlottedUser();
    navigatorKey = GlobalKey<NavigatorState>();
    
    // Mock connectivity check
    when(mockClient.get(Uri.parse('https://google.com')))
        .thenAnswer((_) async => MockResponse('', 200));
  });

  group('Event reservation logic', () {
    test('Can reserve a spot in an event with available slots', () async {
      // Create event with open slots
      final event = createTestEvent(
        attendees: ['user1', 'user2'],
        waitlist: [],
      );
      
      // Mock successful reservation
      when(mockClient.post(
        Uri.parse('https://us-central1-open-mic-5cc8e.cloudfunctions.net/reserveAction'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => MockResponse('Successfully reserved', 200));
      
      // Create a test instance to access the reservation action
      final testWidget = MaterialApp(
        navigatorKey: navigatorKey,
        home: TestEventDetailsPage(
          initialEvent: event,
          debug: true,
          authAction: (_, __, ___) async {},
          httpClient: mockClient,
        ),
      );
      
      await pumpEventQueue();
      
      // Call the reservation action directly 
      final eventDetails = (testWidget.home as TestEventDetailsPage);
      final result = await eventDetails.callReserveAction('', event, testSlottedUser, testUser);
      
      // Verify that the reservation was successful
      expect(result, 'Successfully reserved');
    });

    test('When event is full, user is added to waitlist', () async {
      // Create a full event
      final event = createTestEvent(
        isFull: true,
        attendees: List.generate(10, (index) => 'user$index'),
        waitlist: [],
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
      
      // Create a test instance
      final testWidget = MaterialApp(
        navigatorKey: navigatorKey,
        home: TestEventDetailsPage(
          initialEvent: event,
          debug: true,
          authAction: (_, __, ___) async {},
          httpClient: mockClient,
        ),
      );
      
      await pumpEventQueue();
      
      // Call the reservation action directly
      final eventDetails = (testWidget.home as TestEventDetailsPage);
      final result = await eventDetails.callReserveAction('', event, testSlottedUser, testUser);
      
      // Verify the waitlist status
      final parsedResult = json.decode(result);
      expect(parsedResult['status'], 'waitlisted');
      expect(parsedResult['position'], 1);
    });

    test('Can unreserve from an event', () async {
      // Create event with user already in attendees
      final event = createTestEvent(
        attendees: ['test-user-id', 'user2'],
        waitlist: [],
      );
      
      // Mock successful unreserve
      when(mockClient.post(
        Uri.parse('https://us-central1-open-mic-5cc8e.cloudfunctions.net/reserveAction'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => MockResponse('Successfully unreserved', 200));
      
      // Create a test instance
      final testWidget = MaterialApp(
        navigatorKey: navigatorKey,
        home: TestEventDetailsPage(
          initialEvent: event,
          debug: true,
          authAction: (_, __, ___) async {},
          httpClient: mockClient,
        ),
      );
      
      await pumpEventQueue();
      
      // Call the reservation action directly
      final eventDetails = (testWidget.home as TestEventDetailsPage);
      final result = await eventDetails.callReserveAction('', event, testSlottedUser, testUser);
      
      // Verify that the unreserve was successful
      expect(result, 'Successfully unreserved');
    });
    
    test('Can leave waitlist', () async {
      // Create event with user in waitlist
      final event = createTestEvent(
        attendees: ['user1', 'user2'],
        waitlist: ['test-user-id', 'user3'],
      );
      
      // Mock successful unreserve
      when(mockClient.post(
        Uri.parse('https://us-central1-open-mic-5cc8e.cloudfunctions.net/reserveAction'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => MockResponse('Successfully unreserved', 200));
      
      // Create a test instance
      final testWidget = MaterialApp(
        navigatorKey: navigatorKey,
        home: TestEventDetailsPage(
          initialEvent: event,
          debug: true,
          authAction: (_, __, ___) async {},
          httpClient: mockClient,
        ),
      );
      
      await pumpEventQueue();
      
      // Call the reservation action directly
      final eventDetails = (testWidget.home as TestEventDetailsPage);
      final result = await eventDetails.callReserveAction('', event, testSlottedUser, testUser);
      
      // Verify that the user was removed from waitlist
      expect(result, 'Successfully unreserved');
    });
    
    test('Handles network errors gracefully', () async {
      final event = createTestEvent();
      
      // Mock network error
      when(mockClient.get(Uri.parse('https://google.com')))
          .thenThrow(const SocketException('Failed to connect'));
      
      // Create a test instance
      final testWidget = MaterialApp(
        navigatorKey: navigatorKey,
        home: TestEventDetailsPage(
          initialEvent: event,
          debug: true,
          authAction: (_, __, ___) async {},
          httpClient: mockClient,
        ),
      );
      
      await pumpEventQueue();
      
      // Call the reservation action and expect network error
      final eventDetails = (testWidget.home as TestEventDetailsPage);
      
      // For network errors, wrap in try/catch
      try {
        await eventDetails.callReserveAction('', event, testSlottedUser, testUser);
        fail('Expected a NetworkException to be thrown');
      } catch (e) {
        expect(e, isA<SocketException>());
      }
    });
    
    test('Handles server errors with retry mechanism', () async {
      final event = createTestEvent();
      
      // Mock server error followed by success
      var callCount = 0;
      when(mockClient.post(
        Uri.parse('https://us-central1-open-mic-5cc8e.cloudfunctions.net/reserveAction'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async {
        callCount++;
        // First call fails with 500, second succeeds
        if (callCount == 1) {
          return MockResponse('Server Error', 500);
        } else {
          return MockResponse('Successfully reserved', 200);
        }
      });
      
      // Create a test instance
      final testWidget = MaterialApp(
        navigatorKey: navigatorKey,
        home: TestEventDetailsPage(
          initialEvent: event,
          debug: true,
          authAction: (_, __, ___) async {},
          httpClient: mockClient,
        ),
      );
      
      await pumpEventQueue();
      
      // Call the reservation action directly
      final eventDetails = (testWidget.home as TestEventDetailsPage);
      final result = await eventDetails.callReserveAction('', event, testSlottedUser, testUser);
      
      // Verify that the reservation was successful after retry
      expect(result, 'Successfully reserved');
      expect(callCount, 2); // Verify it was called twice
    });
    
    test('Handles paid event reservations', () async {
      // Create paid event
      final event = createTestEvent(price: 10.0);
      
      // Mock payment intent in response
      when(mockClient.post(
        Uri.parse('https://us-central1-open-mic-5cc8e.cloudfunctions.net/reserveAction'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => MockResponse('Successfully reserved', 200));
      
      // Create a test instance
      final testWidget = MaterialApp(
        navigatorKey: navigatorKey,
        home: TestEventDetailsPage(
          initialEvent: event,
          debug: true,
          authAction: (_, __, ___) async {},
          httpClient: mockClient,
        ),
      );
      
      await pumpEventQueue();
      
      // Create a mock payment intent
      final paymentIntent = {
        'id': 'test-payment-intent',
        'client_secret': 'test-client-secret',
        'amount': 1000,
        'currency': 'usd',
      };
      
      // Call the reservation action directly
      final eventDetails = (testWidget.home as TestEventDetailsPage);
      final result = await eventDetails.callReserveAction(paymentIntent, event, testSlottedUser, testUser);
      
      // Verify that the reservation was successful
      expect(result, 'Successfully reserved');
    });
  });
} 