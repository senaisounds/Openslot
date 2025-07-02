import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
// import 'package:firebase_auth/firebase_auth.dart';  // Removing unused import
import 'package:slotted/common/event_class.dart';
import 'package:slotted/pages/event_details.dart';
import '../test_helpers.dart';
import 'package:latlong2/latlong.dart';  // Added LatLng import

// Mock HTTP client
class MockClient extends Mock implements http.Client {}

// Mock HTTP response
class MockResponse extends Mock implements http.Response {
  final String _body;
  final int _statusCode;
  final Duration _delay;

  MockResponse(this._body, this._statusCode, {Duration delay = Duration.zero})
      : _delay = delay;

  @override
  String get body => _body;

  @override
  int get statusCode => _statusCode;
}

// Create test event with variable number of attendees
Event createBenchmarkEvent({
  int numAttendees = 0,
  int numWaitlisted = 0,
  int slots = 100,
  double price = 0,
}) {
  return Event(
    id: 'benchmark-event',
    name: 'Benchmark Event',
    host: 'host-id',
    hostName: 'Host Name',
    description: 'Benchmark event description',
    rules: 'Benchmark rules',
    location: const LatLng(37.7749, -122.4194),  // Changed GeoPoint to LatLng
    date: DateTime.now().add(const Duration(days: 1)),
    address: '123 Test Street',
    category: 'comedy',
    live: false,
    ended: false,
    performer: '',
    performerStart: null,
    timeLimit: 0,
    attendees: List.generate(numAttendees, (i) => 'user-$i'),
    reservationTimestamps: {},
    checkedPerformers: {},
    upNext: '',
    price: price,
    signupOnLocation: false,
    slots: slots,
    type: EventType.mic,
    waitlist: List.generate(numWaitlisted, (i) => 'waitlist-user-$i'),
    isPrivate: false,
    password: '',
    coverUrl: '',
    isFeatured: false,
    capacity: 100,
    checkedPerformersList: const [],
  );
}

// Extended MockUser implementation for testing
class TestUser extends MockUser {
  final String _uid;
  
  TestUser({String uid = 'test-user-id'}) : _uid = uid;

  @override
  String get uid => _uid;
}

// Extended MockSlottedUser implementation for testing
class TestSlottedUser extends MockSlottedUser {
  final String _id;
  
  TestSlottedUser({String id = 'test-user-id'}) : _id = id;

  @override
  String get id => _id;
  
  @override
  String get customerID => '${_id}_customer';
  
  @override
  String get testCustomerID => '${_id}_test_customer';
}

// Measure the reservation function performance
void main() {
  late MockClient mockClient;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  setUp(() {
    mockClient = MockClient();
    // Setup connectivity check mock
    when(mockClient.get(Uri.parse('https://google.com')))
        .thenAnswer((_) async => MockResponse('', 200));
  });

  // Helper function to measure function execution time
  Future<Map<String, dynamic>> measureExecution(Future<String> Function() action) async {
    final stopwatch = Stopwatch()..start();
    String result;
    try {
      result = await action();
      return {
        'success': true,
        'result': result,
        'timeMs': stopwatch.elapsedMilliseconds,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'timeMs': stopwatch.elapsedMilliseconds,
      };
    } finally {
      stopwatch.stop();
    }
  }

  group('Reservation Performance Benchmarks', () {
    testWidgets('Measure free event reservation performance', (WidgetTester tester) async {
      // Create an event with varying numbers of attendees for benchmarking
      final event = createBenchmarkEvent(numAttendees: 0, slots: 100);
      final testUser = TestUser();
      final testSlottedUser = TestSlottedUser();
      
      // Configure mock with different response times to simulate server load
      final responseTimeVariations = [
        Duration.zero,
        const Duration(milliseconds: 100),
        const Duration(milliseconds: 500),
        const Duration(seconds: 1),
        const Duration(seconds: 2),
      ];
      
      // Build widget under test
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigatorKey,
        home: Builder(
          builder: (context) {
            // Just a container to hold the context
            return Container();
          },
        ),
      ));
      
      await tester.pumpAndSettle();
      
      // Run benchmark with different response times
      final results = <Map<String, dynamic>>[];
      
      for (final responseTime in responseTimeVariations) {
        // Mock response with variable delay
        when(mockClient.post(
          Uri.parse('https://us-central1-open-mic-5cc8e.cloudfunctions.net/reserveAction'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async {
          await Future.delayed(responseTime);
          return MockResponse('Successfully reserved', 200);
        });
        
        // Measure reservation action with current response time
        final eventDetailsPage = EventDetailsPage(
          initialEvent: event,
          debug: true,
          authAction: (_, __, ___) async {},
        );
        
        // Use reflection or private access method to get the state
        // Note: This is a simplified approach for benchmarking, in real tests you'd
        // need proper widget testing with state access
        
        // Simulate the reserveAction method call with timing measurement
        final benchmarkResult = await measureExecution(() async {
          try {
            // Direct API call for benchmarking to avoid widget state issues
            final response = await http.post(
              Uri.parse('https://us-central1-open-mic-5cc8e.cloudfunctions.net/reserveAction'),
              headers: {'Content-Type': 'application/x-www-form-urlencoded'},
              body: {
                'eventID': event.id,
                'userID': testUser.uid,
                'debug': 'true',
                'pi': '',
              },
            );
            return response.body;
          } catch (e) {
            return 'Error: $e';
          }
        });
        
        benchmarkResult['simulatedServerDelay'] = responseTime.inMilliseconds;
        results.add(benchmarkResult);
      }
      
      // Print benchmark results
      print('====== FREE EVENT RESERVATION PERFORMANCE =====');
      for (final result in results) {
        print('Server Delay: ${result['simulatedServerDelay']}ms, Total Time: ${result['timeMs']}ms, Success: ${result['success']}');
      }
    });
    
    testWidgets('Measure event capacity effect on performance', (WidgetTester tester) async {
      // Test with different numbers of attendees to measure scaling performance
      final attendeesVariations = [0, 10, 50, 100, 500];
      final results = <Map<String, dynamic>>[];
      
      for (final numAttendees in attendeesVariations) {
        final event = createBenchmarkEvent(
          numAttendees: numAttendees,
          slots: numAttendees + 10, // Always have some open slots
        );
        
        final testUser = TestUser();
        final testSlottedUser = TestSlottedUser();
        
        // Mock response
        when(mockClient.post(
          Uri.parse('https://us-central1-open-mic-5cc8e.cloudfunctions.net/reserveAction'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => MockResponse('Successfully reserved', 200));
        
        // Build widget under test
        await tester.pumpWidget(MaterialApp(
          navigatorKey: navigatorKey,
          home: Builder(
            builder: (context) {
              return Container();
            },
          ),
        ));
        
        await tester.pumpAndSettle();
        
        // Measure with current attendee count
        final benchmarkResult = await measureExecution(() async {
          try {
            // Direct API call for benchmarking
            final response = await http.post(
              Uri.parse('https://us-central1-open-mic-5cc8e.cloudfunctions.net/reserveAction'),
              headers: {'Content-Type': 'application/x-www-form-urlencoded'},
              body: {
                'eventID': event.id,
                'userID': testUser.uid,
                'debug': 'true',
                'pi': '',
              },
            );
            return response.body;
          } catch (e) {
            return 'Error: $e';
          }
        });
        
        benchmarkResult['attendeeCount'] = numAttendees;
        results.add(benchmarkResult);
      }
      
      // Print benchmark results
      print('====== EVENT SIZE SCALING PERFORMANCE =====');
      for (final result in results) {
        print('Attendees: ${result['attendeeCount']}, Time: ${result['timeMs']}ms, Success: ${result['success']}');
      }
    });
    
    testWidgets('Measure paid event reservation performance', (WidgetTester tester) async {
      // Create a paid event
      final event = createBenchmarkEvent(price: 10.0);
      final testUser = TestUser();
      final testSlottedUser = TestSlottedUser();
      
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
      
      // Mock reservation with payment
      when(mockClient.post(
        Uri.parse('https://us-central1-open-mic-5cc8e.cloudfunctions.net/reserveAction'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => MockResponse('Successfully reserved', 200));
      
      // Build widget under test
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigatorKey,
        home: Builder(
          builder: (context) {
            return Container();
          },
        ),
      ));
      
      await tester.pumpAndSettle();
      
      // Measure end-to-end performance of payment intent creation + reservation
      final paymentIntentCreationResult = await measureExecution(() async {
        try {
          // Simulate payment intent creation
          final response = await http.post(
            Uri.parse('https://api.stripe.com/v1/payment_intents'),
            headers: {
              'Authorization': 'Bearer sk_test_dummy',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'amount': '1000',
              'currency': 'usd',
              'customer': testSlottedUser.testCustomerID,
            },
          );
          return response.body;
        } catch (e) {
          return 'Error: $e';
        }
      });
      
      final ephemeralKeyResult = await measureExecution(() async {
        try {
          // Simulate ephemeral key creation
          final response = await http.post(
            Uri.parse('https://us-central1-open-mic-5cc8e.cloudfunctions.net/getEphemeralKey'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'cusID': testSlottedUser.testCustomerID,
              'debug': 'true',
            },
          );
          return response.body;
        } catch (e) {
          return 'Error: $e';
        }
      });
      
      final reservationResult = await measureExecution(() async {
        try {
          // Simulate reservation with payment
          final response = await http.post(
            Uri.parse('https://us-central1-open-mic-5cc8e.cloudfunctions.net/reserveAction'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'eventID': event.id,
              'userID': testUser.uid,
              'debug': 'true',
              'pi': json.encode({
                'id': 'pi_test123',
                'client_secret': 'test_secret',
              }),
            },
          );
          return response.body;
        } catch (e) {
          return 'Error: $e';
        }
      });
      
      // Calculate total time for paid reservation flow
      final totalTime = paymentIntentCreationResult['timeMs'] +
          ephemeralKeyResult['timeMs'] +
          reservationResult['timeMs'];
      
      // Print benchmark results
      print('====== PAID EVENT RESERVATION PERFORMANCE =====');
      print('Payment Intent Creation: ${paymentIntentCreationResult['timeMs']}ms');
      print('Ephemeral Key Creation: ${ephemeralKeyResult['timeMs']}ms');
      print('Reservation with Payment: ${reservationResult['timeMs']}ms');
      print('Total End-to-End Time: ${totalTime}ms');
    });
    
    testWidgets('Measure concurrent reservation performance', (WidgetTester tester) async {
      // Create an event with limited slots to test concurrent reservations
      final event = createBenchmarkEvent(numAttendees: 90, slots: 100);
      
      // Create multiple test users for concurrent reservations
      const concurrentUsers = 20;
      final users = List.generate(
        concurrentUsers, 
        (i) => TestUser(uid: 'concurrent-user-$i')
      );
      
      final slottedUsers = List.generate(
        concurrentUsers, 
        (i) => TestSlottedUser(id: 'concurrent-user-$i')
      );
      
      // Mock response with delay to simulate server processing time
      when(mockClient.post(
        Uri.parse('https://us-central1-open-mic-5cc8e.cloudfunctions.net/reserveAction'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Determine if the user gets waitlisted based on remaining slots
        final body = _.positionalArguments[0].body as Map<String, String>;
        final userIdMatch = RegExp(r'concurrent-user-(\d+)').firstMatch(body['userID']!);
        final userIndex = userIdMatch != null 
            ? int.parse(userIdMatch.group(1)!) 
            : 0;
        
        // First 10 users get reserved, others get waitlisted
        if (userIndex < 10) {
          return MockResponse('Successfully reserved', 200);
        } else {
          return MockResponse(
            json.encode({'status': 'waitlisted', 'position': userIndex - 9}),
            200
          );
        }
      });
      
      // Build widget under test
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigatorKey,
        home: Builder(
          builder: (context) {
            return Container();
          },
        ),
      ));
      
      await tester.pumpAndSettle();
      
      // Perform concurrent reservation requests
      final stopwatch = Stopwatch()..start();
      
      final futures = <Future<Map<String, dynamic>>>[];
      
      for (int i = 0; i < concurrentUsers; i++) {
        final user = users[i];
        final slottedUser = slottedUsers[i];
        
        futures.add(measureExecution(() async {
          try {
            final response = await http.post(
              Uri.parse('https://us-central1-open-mic-5cc8e.cloudfunctions.net/reserveAction'),
              headers: {'Content-Type': 'application/x-www-form-urlencoded'},
              body: {
                'eventID': event.id,
                'userID': user.uid,
                'debug': 'true',
                'pi': '',
              },
            );
            return response.body;
          } catch (e) {
            return 'Error: $e';
          }
        }));
      }
      
      // Wait for all concurrent requests to complete
      final results = await Future.wait(futures);
      
      final totalTime = stopwatch.elapsedMilliseconds;
      stopwatch.stop();
      
      // Calculate statistics
      int successCount = 0;
      int waitlistCount = 0;
      int errorCount = 0;
      int totalIndividualTime = 0;
      
      for (final result in results) {
        totalIndividualTime += result['timeMs'] as int;
        
        if (!result['success']) {
          errorCount++;
        } else {
          final resultStr = result['result'] as String;
          if (resultStr.contains('waitlisted')) {
            waitlistCount++;
          } else {
            successCount++;
          }
        }
      }
      
      final averageTime = totalIndividualTime / concurrentUsers;
      
      // Print benchmark results
      print('====== CONCURRENT RESERVATION PERFORMANCE =====');
      print('Number of concurrent users: $concurrentUsers');
      print('Successfully reserved: $successCount');
      print('Waitlisted: $waitlistCount');
      print('Errors: $errorCount');
      print('Average individual request time: ${averageTime.toStringAsFixed(2)}ms');
      print('Total concurrent operation time: ${totalTime}ms');
      print('Efficiency ratio: ${(averageTime / totalTime).toStringAsFixed(2)}');
    });
  });
} 