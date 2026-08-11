import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:slotted/api/functions_http_client.dart';
import 'package:slotted/utils/logger.dart';

/// Service for tracking usage events in Stripe Billing
class StripeUsageTracker {
  /// Report a booking completion to Stripe Billing.
  ///
  /// Server resolves the Stripe customer from the authenticated user —
  /// [customerId] is validated client-side only.
  static Future<bool> reportBookingCompleted({
    required String customerId,
    required String eventId,
    required String bookingId,
    required double amount,
    bool debug = true,
  }) async {
    try {
      Logger.i('Reporting booking to Stripe meter: $bookingId', tag: 'StripeUsage');

      if (customerId.isEmpty || !customerId.startsWith('cus_')) {
        Logger.e('Invalid customer ID: $customerId', tag: 'StripeUsage');
        return false;
      }

      if (amount <= 0) {
        Logger.e('Invalid amount: $amount', tag: 'StripeUsage');
        return false;
      }

      final headers = await FunctionsHttpClient.authHeaders();
      final response = await http.post(
        Uri.parse('${FunctionsHttpClient.baseUrl}/reportStripeUsage'),
        headers: headers,
        body: jsonEncode({
          'eventName': 'booking_completed',
          'quantity': 1,
          'timestamp': DateTime.now().toIso8601String(),
          'metadata': {
            'event_id': eventId,
            'booking_id': bookingId,
            'amount': amount,
            'currency': 'USD',
          },
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Logger.i('Usage reported successfully: ${data['id']}', tag: 'StripeUsage');
        return true;
      } else {
        Logger.e('Failed to report usage: ${response.body}', tag: 'StripeUsage');
        return false;
      }
    } on http.ClientException catch (e) {
      Logger.e('Network error reporting usage: ${e.message}', tag: 'StripeUsage');
      return false;
    } catch (e) {
      Logger.e('Error reporting usage to Stripe: $e', tag: 'StripeUsage');
      return false;
    }
  }

  static Future<int> reportBatchBookings({
    required String customerId,
    required List<Map<String, dynamic>> bookings,
    bool debug = true,
  }) async {
    int successCount = 0;

    for (var booking in bookings) {
      final success = await reportBookingCompleted(
        customerId: customerId,
        eventId: booking['eventId'] ?? '',
        bookingId: booking['bookingId'] ?? '',
        amount: booking['amount'] ?? 0.0,
        debug: debug,
      );

      if (success) successCount++;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    Logger.i('Batch usage report: $successCount/${bookings.length} successful', tag: 'StripeUsage');
    return successCount;
  }

  static Future<bool> testUsageReporting({
    required String customerId,
    bool debug = true,
  }) async {
    Logger.i('Testing usage reporting...', tag: 'StripeUsage');

    return await reportBookingCompleted(
      customerId: customerId,
      eventId: 'test_event_${DateTime.now().millisecondsSinceEpoch}',
      bookingId: 'test_booking_${DateTime.now().millisecondsSinceEpoch}',
      amount: 0.99,
      debug: debug,
    );
  }
}
