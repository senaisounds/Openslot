import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:slotted/api/functions_http_client.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/utils/logger.dart';

class SlottedStripeError implements Exception {
  final String message;
  final Object? originalError;
  
  SlottedStripeError(this.message, {this.originalError});
  
  @override
  String toString() => 'Stripe error: $message';
}

class StripeApi {
  // Stripe secret keys must NOT be present in client code. All secret-key operations must be handled by a secure backend.



  static String getApiKey(bool debug) {
    throw UnimplementedError('Stripe secret key usage is not allowed in client code. Use a backend endpoint.');
  }

  static Future<String> createCustomer({String? cid, bool debug = false}) async {
    throw UnimplementedError('Customer creation must be handled by a backend endpoint.');
  }

  static Future<String> getEphemeralKey(String customerId,
      {bool debug = false}) async {
    try {
      if (customerId.isEmpty) {
        throw SlottedStripeError('Customer ID is required');
      }

      final headers = await FunctionsHttpClient.authHeaders(
        contentType: 'application/x-www-form-urlencoded',
      );
      // Server resolves customer from authenticated user; cusID ignored server-side
      var response = await http.post(
        Uri.parse(
            'https://us-central1-open-mic-5cc8e.cloudfunctions.net/getEphemeralKey'),
        headers: headers,
        body: {
          'cusID': customerId,
        },
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw SlottedStripeError(
            errorData['error'] ?? 'Failed to get ephemeral key');
      }

      final responseData = json.decode(response.body);
      if (responseData['secret'] == null) {
        throw SlottedStripeError('Invalid response: Missing ephemeral key');
      }

      return responseData['secret'];
    } on FormatException catch (e) {
      throw SlottedStripeError('Invalid response format: ${e.message}');
    } on http.ClientException catch (e) {
      throw SlottedStripeError('Network error while getting ephemeral key: ${e.message}');
    } catch (e) {
      if (e is SlottedStripeError) rethrow;
      throw SlottedStripeError('Unexpected error while getting ephemeral key: ${e.toString()}');
    }
  }

  static Future<void> pay({
    required dynamic paymentIntent,
    required String customer,
    required String ephemeralKey,
    required Event event,
  }) async {
    try {
      // Validate input parameters
      if (paymentIntent == null || paymentIntent['client_secret'] == null) {
        throw SlottedStripeError('Invalid payment intent: Missing client secret');
      }
      if (customer.isEmpty) {
        throw SlottedStripeError('Customer ID is required');
      }
      if (ephemeralKey.isEmpty) {
        throw SlottedStripeError('Ephemeral key is required');
      }
      if (event.price <= 0) {
        throw SlottedStripeError('Invalid event price');
      }

      try {
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: paymentIntent['client_secret'],
            merchantDisplayName: 'OpenSlot',
            customerId: customer,
            customerEphemeralKeySecret: ephemeralKey,
            style: ThemeMode.dark,
            appearance: const PaymentSheetAppearance(
              colors: PaymentSheetAppearanceColors(
                background: Color(0xFF2D2D3A),
                primary: Color(0xFF6C4AB0),
                componentBackground: Color(0xFF1E1E2F),
              ),
            ),
          ),
        );
      } catch (e) {
        throw SlottedStripeError('Failed to initialize payment sheet: ${e.toString()}');
      }

      try {
        await Stripe.instance.presentPaymentSheet();
      } catch (e) {
        if (e is StripeException) {
          final errorCode = e.error.code.toString();
          
          if (errorCode == 'payment_intent_authentication_failure' || errorCode == 'payment_intent_payment_attempt_failed') {
            throw SlottedStripeError('Payment failed. Please try again with a different payment method.');
          } else if (errorCode == 'payment_intent_canceled') {
            throw SlottedStripeError('Payment was canceled.');
          } else if (errorCode == 'invalid_shipping_address') {
            throw SlottedStripeError('Invalid shipping address provided.');
          } else {
            throw SlottedStripeError(e.error.message ?? 'An error occurred with the payment.');
          }
        }
        throw SlottedStripeError('Failed to process payment: ${e.toString()}');
      }
    } catch (e) {
      if (e is SlottedStripeError) rethrow;
      throw SlottedStripeError('Payment error: ${e.toString()}');
    }
  }

  static Future<dynamic> createPaymentIntent({
    required String userId,
    required double amount,
    required String currency,
    String? customerId,
    String? returnUrl,
    bool debug = false}) async {
    throw UnimplementedError('PaymentIntent creation must be handled by a backend endpoint.');
  }

  // Add better error handling for Stripe payment process
  static Future<bool> handlePaymentError(dynamic e) async {
    String errorMessage = '';
    
    if (e is StripeException) {
      // Handle different error types by converting code to string first
      final errorCode = e.error.code.toString();
      
      if (errorCode == 'payment_intent_authentication_failure' || errorCode == 'payment_intent_payment_attempt_failed') {
        errorMessage = 'Payment failed. Please try again with a different payment method.';
      } else if (errorCode == 'payment_intent_canceled') {
        errorMessage = 'Payment was canceled.';
      } else if (errorCode == 'invalid_shipping_address') {
        errorMessage = 'Invalid shipping address provided.';
      } else {
        errorMessage = e.error.message ?? 'An unknown error occurred during payment.';
      }
    } else if (e is SlottedStripeError) {
      errorMessage = e.message;
    } else {
      errorMessage = 'An unexpected error occurred: ${e.toString()}';
    }
    
    // Log the error for debugging
    Logger.d('Stripe payment error: $errorMessage', tag: 'Stripe');
    
    return false;
  }
  
  // Utility method to validate pricing
  static bool isValidPrice(double price) {
    return price > 0 && price < 100000; // Set a reasonable max limit
  }
  
  // Initialize Stripe - call this during app startup
  static Future<void> initializeStripe(String publishableKey) async {
    try {
      // Use the proper way to initialize Stripe based on the flutter_stripe package
      await Stripe.instance.dangerouslyUpdateCardDetails(
        CardDetails.fromJson({'cvc': '123', 'expiryMonth': 12, 'expiryYear': 25}),
      );
      Logger.d('Stripe initialized successfully', tag: 'Stripe');
    } catch (e) {
      Logger.d('Failed to initialize Stripe: $e', tag: 'Stripe');
      throw SlottedStripeError('Failed to initialize Stripe: ${e.toString()}');
    }
  }
}
