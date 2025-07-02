import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:slotted/api/stripe.dart';
import 'package:slotted/common/event_class.dart';

class ApplePayService {
  /// Check if Apple Pay is supported on the device
  static Future<bool> isApplePaySupported() async {
    try {
      return await Stripe.instance.isPlatformPaySupported();
    } catch (e) {
      log('Error checking Apple Pay support: $e');
      return false;
    }
  }

  /// Process payment with Apple Pay
  static Future<bool> processApplePayment({
    required Event event,
    required String userId,
    required String? customerId,
    bool debug = false,
  }) async {
    try {
      // Validate event details
      if (event.price <= 0) {
        log('Invalid event price for Apple Pay: ${event.price}');
        return false;
      }

      // Safely handle customerId
      final String custId = customerId ?? '';
      if (custId.isEmpty) {
        log('No customer ID provided for Apple Pay payment');
      }

      // Create payment intent
      final paymentIntent = await StripeApi.createPaymentIntent(
        userId: userId,
        amount: event.price,
        currency: 'USD',
        customerId: custId.isEmpty ? null : custId,
        debug: debug,
      );

      if (paymentIntent == null) {
        throw Exception('Failed to create payment intent');
      }

      final String clientSecret = paymentIntent['client_secret'];
      
      // Enhanced Apple Pay presentation
      final PaymentIntent result = await Stripe.instance.confirmPlatformPayPaymentIntent(
        clientSecret: clientSecret,
        confirmParams: PlatformPayConfirmParams.applePay(
          applePay: ApplePayParams(
            merchantCountryCode: 'US',
            currencyCode: 'USD',
            cartItems: [
              ApplePayCartSummaryItem.immediate(
                label: event.name,
                amount: event.price.toString(),
              ),
              // Add total as final item (same as price since we don't have convenience fee)
              ApplePayCartSummaryItem.immediate(
                label: 'Total',
                amount: event.price.toString(),
              ),
            ],
          ),
        ),
      );

      // Enhanced status checking
      if (result.status == PaymentIntentsStatus.Succeeded) {
        log('Apple Pay payment successful: ${result.id}');
        return true;
      } else if (result.status == PaymentIntentsStatus.RequiresPaymentMethod) {
        log('Apple Pay payment requires another payment method: ${result.status}');
        return false;
      } else if (result.status == PaymentIntentsStatus.RequiresConfirmation) {
        log('Apple Pay payment requires additional confirmation: ${result.status}');
        return false;
      } else {
        log('Apple Pay payment failed with status: ${result.status}');
        return false;
      }
    } on PlatformException catch (e) {
      log('Platform exception during Apple Pay: ${e.message}');
      return false;
    } on SlottedStripeError catch (e) {
      log('Stripe error during Apple Pay: ${e.message}');
      return false;
    } catch (e) {
      log('Error during Apple Pay: $e');
      return false;
    }
  }
  
  /// Get a display-friendly error message for Apple Pay errors
  static String getApplePayErrorMessage(dynamic error) {
    if (error is PlatformException) {
      if (error.code == 'cancelled') {
        return 'Payment was cancelled';
      } else if (error.code == 'notSupported') {
        return 'Apple Pay is not supported on this device';
      } else {
        return 'Apple Pay error: ${error.message}';
      }
    } else if (error is SlottedStripeError) {
      return 'Payment processing error: ${error.message}';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }
} 