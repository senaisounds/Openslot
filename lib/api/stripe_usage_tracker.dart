import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:slotted/utils/logger.dart';

/// Service for tracking usage events in Stripe Billing
/// 
/// This is CRITICAL for usage-based billing to work.
/// Every booking must be reported to Stripe's meter.
class StripeUsageTracker {
  /// Report a booking completion to Stripe Billing
  /// 
  /// This sends a 'booking_completed' event to your Stripe meter.
  /// Stripe will use this to calculate the $0.99 per booking fee.
  /// 
  /// Parameters:
  /// - [customerId]: Stripe customer ID (e.g., 'cus_...')
  /// - [eventId]: Your internal event ID for tracking
  /// - [bookingId]: The booking/reservation ID
  /// - [amount]: Amount of the booking (in dollars)
  /// - [debug]: Whether to use test or live Stripe key
  static Future<bool> reportBookingCompleted({
    required String customerId,
    required String eventId,
    required String bookingId,
    required double amount,
    bool debug = true,
  }) async {
    try {
      Logger.i('Reporting booking to Stripe meter: $bookingId', tag: 'StripeUsage');
      
      // Validate inputs
      if (customerId.isEmpty || !customerId.startsWith('cus_')) {
        Logger.e('Invalid customer ID: $customerId', tag: 'StripeUsage');
        return false;
      }
      
      if (amount <= 0) {
        Logger.e('Invalid amount: $amount', tag: 'StripeUsage');
        return false;
      }
      
      // Call Firebase Function to report usage
      final response = await http.post(
        Uri.parse('https://us-central1-open-mic-5cc8e.cloudfunctions.net/reportStripeUsage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customerId': customerId,
          'eventName': 'booking_completed', // Must match Stripe meter event name
          'quantity': 1, // Count as 1 booking
          'timestamp': DateTime.now().toIso8601String(),
          'metadata': {
            'event_id': eventId,
            'booking_id': bookingId,
            'amount': amount,
            'currency': 'USD',
          },
          'debug': debug,
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
        final errorData = jsonDecode(response.body);
        Logger.e('Failed to report usage: ${errorData['error']}', tag: 'StripeUsage');
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
  
  /// Report multiple bookings at once (batch operation)
  /// 
  /// Useful for syncing historical bookings or bulk operations
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
      
      // Small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    Logger.i('Batch usage report: $successCount/${bookings.length} successful', tag: 'StripeUsage');
    return successCount;
  }
  
  /// Verify usage reporting is working
  /// 
  /// Use this for testing - sends a test event to Stripe
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

