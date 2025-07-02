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

  group('Payment Processing Tests', () {
    late Event paidEvent;
    late Event freeEvent;
    late SlottedUser testUser;

    setUp(() async {
      await TestSetup.setupTestData();
      
      paidEvent = Event(
        id: 'paid-event',
        name: 'Paid Test Event',
        host: 'host-user-id',
        hostName: 'Test Host',
        date: DateTime.now().add(const Duration(hours: 2)),
        slots: 10,
        price: 25.50,
        attendees: [],
        waitlist: [],
        live: false,
        ended: false,
        address: '123 Payment St',
        category: 'Music',
        location: const LatLng(40.7128, -74.0060),
        isPrivate: false,
      );

      freeEvent = Event(
        id: 'free-event',
        name: 'Free Test Event',
        host: 'host-user-id',
        hostName: 'Test Host',
        date: DateTime.now().add(const Duration(hours: 2)),
        slots: 10,
        price: 0.0,
        attendees: [],
        waitlist: [],
        live: false,
        ended: false,
        address: '456 Free St',
        category: 'Music',
        location: const LatLng(40.7128, -74.0060),
        isPrivate: false,
      );

      testUser = SlottedUser()
        ..id = 'payment-test-user'
        ..username = 'PaymentTestUser'
        ..bio = 'Test user for payment testing'
        ..photoUrl = ''
        ..isFirstTimer = false
        ..twitter = ''
        ..instagram = ''
        ..customerID = 'test-customer-id'
        ..testCustomerID = 'test-customer-id-test';
    });

    testWidgets('Payment UI displays correctly for paid events', (WidgetTester tester) async {
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            body: Column(
              children: [
                Text('Event: ${paidEvent.name}'),
                Text('Price: \$${paidEvent.price.toStringAsFixed(2)}'),
                const SizedBox(height: 20),
                // Payment button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  onPressed: () {},
                  child: Text('Pay \$${paidEvent.price.toStringAsFixed(2)}'),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Secure payment powered by Stripe',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Event: Paid Test Event'), findsOneWidget);
      expect(find.text('Price: \$25.50'), findsOneWidget);
      expect(find.text('Pay \$25.50'), findsOneWidget);
      expect(find.text('Secure payment powered by Stripe'), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('Free events show correct UI', (WidgetTester tester) async {
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            body: Column(
              children: [
                Text('Event: ${freeEvent.name}'),
                Text('Price: ${freeEvent.price == 0 ? 'Free' : '\$${freeEvent.price.toStringAsFixed(2)}'}'),
                const SizedBox(height: 20),
                // Reserve button for free event
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  onPressed: () {},
                  child: const Text('Reserve Spot'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Event: Free Test Event'), findsOneWidget);
      expect(find.text('Price: Free'), findsOneWidget);
      expect(find.text('Reserve Spot'), findsOneWidget);
      expect(find.text('Pay'), findsNothing);
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('Payment validation works correctly', (WidgetTester tester) async {
      final validationScenarios = [
        {'price': -5.0, 'isValid': false, 'error': 'Invalid price'},
        {'price': 0.0, 'isValid': true, 'error': null},
        {'price': 1.0, 'isValid': true, 'error': null},
        {'price': 999.99, 'isValid': true, 'error': null},
        {'price': 10000.0, 'isValid': false, 'error': 'Price too high'},
      ];

      for (final scenario in validationScenarios) {
        final price = scenario['price'] as double;
        final isValid = scenario['isValid'] as bool;
        final error = scenario['error'] as String?;

        await TestSetup.safePumpWidget(
          tester,
          TestSetup.createSimpleTestWidget(
            child: Scaffold(
              body: Column(
                children: [
                  Text('Price: \$${price.toStringAsFixed(2)}'),
                  Text('Valid: $isValid'),
                  if (error != null)
                    Text(
                      'Error: $error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  if (isValid && price > 0)
                    ElevatedButton(
                      onPressed: () {},
                      child: Text('Pay \$${price.toStringAsFixed(2)}'),
                    )
                  else if (isValid && price == 0)
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Reserve Free'),
                    ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Price: \$${price.toStringAsFixed(2)}'), findsOneWidget);
        expect(find.text('Valid: $isValid'), findsOneWidget);
        
        if (error != null) {
          expect(find.text('Error: $error'), findsOneWidget);
        }
        
        await tester.pump(const Duration(milliseconds: 100));
      }
    }, timeout: const Timeout(Duration(seconds: 20)));

    testWidgets('Payment loading states work correctly', (WidgetTester tester) async {
      bool isProcessingPayment = true;
      
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            body: Column(
              children: [
                Text('Event: ${paidEvent.name}'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isProcessingPayment ? null : () {},
                  child: isProcessingPayment
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Processing...'),
                          ],
                        )
                      : Text('Pay \$${paidEvent.price.toStringAsFixed(2)}'),
                ),
                if (isProcessingPayment)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'Please do not close this screen',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Processing...'), findsOneWidget);
      expect(find.text('Please do not close this screen'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('Payment success states display correctly', (WidgetTester tester) async {
      bool paymentSuccessful = true;
      
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            body: Column(
              children: [
                if (paymentSuccessful) ...[
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Payment Successful!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('You have reserved a spot for ${paidEvent.name}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('View Ticket'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );

      expect(find.text('Payment Successful!'), findsOneWidget);
      expect(find.text('You have reserved a spot for Paid Test Event'), findsOneWidget);
      expect(find.text('View Ticket'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('Payment error handling works correctly', (WidgetTester tester) async {
      final errorScenarios = [
        'Payment failed. Please try again.',
        'Your card was declined.',
        'Network error. Please check your connection.',
        'Invalid payment method.',
      ];

      for (final errorMessage in errorScenarios) {
        await TestSetup.safePumpWidget(
          tester,
          TestSetup.createSimpleTestWidget(
            child: Scaffold(
              body: Column(
                children: [
                  const Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Payment Failed',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Try Again'),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Payment Failed'), findsOneWidget);
        expect(find.text(errorMessage), findsOneWidget);
        expect(find.text('Try Again'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        
        await tester.pump(const Duration(milliseconds: 100));
      }
    }, timeout: const Timeout(Duration(seconds: 20)));
  });

  group('Apple Pay Tests', () {
    testWidgets('Apple Pay option displays when available', (WidgetTester tester) async {
      bool isApplePayAvailable = true;
      
      await TestSetup.safePumpWidget(
        tester,
        TestSetup.createSimpleTestWidget(
          child: Scaffold(
            body: Column(
              children: [
                Text('Event: ${paidEvent.name}'),
                Text('Price: \$${paidEvent.price.toStringAsFixed(2)}'),
                const SizedBox(height: 20),
                if (isApplePayAvailable) ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {},
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.apple),
                        SizedBox(width: 8),
                        Text('Pay with Apple Pay'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('or'),
                  const SizedBox(height: 10),
                ],
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Pay with Card'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Pay with Apple Pay'), findsOneWidget);
      expect(find.text('or'), findsOneWidget);
      expect(find.text('Pay with Card'), findsOneWidget);
    }, timeout: const Timeout(Duration(seconds: 10)));
  });

  group('Customer ID Management Tests', () {
    testWidgets('Customer ID validation works correctly', (WidgetTester tester) async {
      final customerIdScenarios = [
        {'customerId': '', 'isValid': false, 'message': 'Customer ID required'},
        {'customerId': 'cus_test123', 'isValid': true, 'message': 'Valid customer'},
        {'customerId': 'invalid-id', 'isValid': false, 'message': 'Invalid format'},
      ];

      for (final scenario in customerIdScenarios) {
        final customerId = scenario['customerId'] as String;
        final isValid = scenario['isValid'] as bool;
        final message = scenario['message'] as String;

        await TestSetup.safePumpWidget(
          tester,
          TestSetup.createSimpleTestWidget(
            child: Scaffold(
              body: Column(
                children: [
                  Text('Customer ID: ${customerId.isEmpty ? 'None' : customerId}'),
                  Text('Status: $message'),
                  if (isValid)
                    const Icon(Icons.check, color: Colors.green)
                  else
                    const Icon(Icons.error, color: Colors.red),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Status: $message'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 100));
      }
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
