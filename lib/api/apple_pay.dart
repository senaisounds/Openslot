import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/utils/logger.dart';

class ModernPaymentService {
  /// Check if platform pay (Apple Pay/Google Pay) is supported
  static Future<bool> isPlatformPaySupported() async {
    try {
      return await Stripe.instance.isPlatformPaySupported();
    } catch (e) {
      Logger.e('Error checking platform pay support: $e', tag: 'ModernPayment');
      return false;
    }
  }

  /// Get platform pay button label
  static String getPlatformPayLabel() {
    if (Platform.isIOS) {
      return 'Apple Pay';
    } else if (Platform.isAndroid) {
      return 'Google Pay';
    }
    return 'Digital Wallet';
  }

  /// Process payment with platform pay (Apple Pay/Google Pay)
  static Future<PaymentProcessResult> processPlatformPayment({
    required Event event,
    required String clientSecret,
    String? merchantName,
    bool debug = false,
  }) async {
    try {
      // Validate event details
      if (event.price <= 0) {
        Logger.w('Invalid event price for platform pay: ${event.price}', tag: 'ModernPayment');
        return PaymentFailure('Invalid payment amount');
      }

      if (clientSecret.isEmpty) {
        throw Exception('Client secret is required');
      }
      
      // Present platform pay
      final PaymentIntent result = await Stripe.instance.confirmPlatformPayPaymentIntent(
        clientSecret: clientSecret,
        confirmParams: Platform.isIOS 
          ? PlatformPayConfirmParams.applePay(
              applePay: ApplePayParams(
                merchantCountryCode: 'US',
                currencyCode: 'USD',
                cartItems: [
                  ApplePayCartSummaryItem.immediate(
                    label: event.name,
                    amount: event.price.toStringAsFixed(2),
                  ),
                ],
              ),
            )
          : PlatformPayConfirmParams.googlePay(
              googlePay: GooglePayParams(
                testEnv: debug,
                merchantName: merchantName ?? 'OpenSlot',
                merchantCountryCode: 'US',
                currencyCode: 'USD',
              ),
            ),
      );

      // Check payment status
      if (result.status == PaymentIntentsStatus.Succeeded) {
        Logger.i('Platform pay payment successful: ${result.id}', tag: 'ModernPayment');
        return PaymentSuccess(result.id);
      } else if (result.status == PaymentIntentsStatus.Canceled) {
        Logger.w('Platform pay payment canceled', tag: 'ModernPayment');
        return PaymentCancelled();
      } else {
        Logger.e('Platform pay payment failed: ${result.status}', tag: 'ModernPayment');
        return PaymentFailure('Payment failed: ${result.status}');
      }

    } on StripeException catch (e) {
      Logger.e('Stripe error in platform pay: ${e.error.message}', tag: 'ModernPayment');
      if (e.error.code == FailureCode.Canceled) {
        return PaymentCancelled();
      }
      return PaymentFailure(e.error.message ?? 'Payment failed');
    } on PlatformException catch (e) {
      Logger.e('Platform error in platform pay: ${e.message}', tag: 'ModernPayment');
      return PaymentFailure(e.message ?? 'Platform error');
    } catch (e) {
      Logger.e('Unexpected error in platform pay: $e', tag: 'ModernPayment');
      return PaymentFailure('Unexpected error occurred');
    }
  }

  /// Process traditional card payment
  static Future<PaymentProcessResult> processCardPayment({
    required Event event,
    required String clientSecret,
    String? merchantName,
    bool debug = false,
  }) async {
    try {
      // Validate event details
      if (event.price <= 0) {
        Logger.w('Invalid event price for card payment: ${event.price}', tag: 'ModernPayment');
        return PaymentFailure('Invalid payment amount');
      }

      if (clientSecret.isEmpty) {
        throw Exception('Client secret is required');
      }
      
      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: merchantName ?? 'OpenSlot',
          style: ThemeMode.dark,
          appearance: const PaymentSheetAppearance(
            primaryButton: PaymentSheetPrimaryButtonAppearance(
              colors: PaymentSheetPrimaryButtonTheme(
                light: PaymentSheetPrimaryButtonThemeColors(
                  background: Color(0xFFFF6B35), // OpenSlot orange
                  text: Color(0xFFFFFFFF),
                ),
                dark: PaymentSheetPrimaryButtonThemeColors(
                  background: Color(0xFFFF6B35), // OpenSlot orange  
                  text: Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),
        ),
      );
      
      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();
      
      Logger.i('Card payment successful', tag: 'ModernPayment');
      return PaymentSuccess(clientSecret);

    } on StripeException catch (e) {
      Logger.e('Stripe error in card payment: ${e.error.message}', tag: 'ModernPayment');
      if (e.error.code == FailureCode.Canceled) {
        return PaymentCancelled();
      }
      return PaymentFailure(e.error.message ?? 'Payment failed');
    } on PlatformException catch (e) {
      Logger.e('Platform error in card payment: ${e.message}', tag: 'ModernPayment');
      return PaymentFailure(e.message ?? 'Platform error');
    } catch (e) {
      Logger.e('Unexpected error in card payment: $e', tag: 'ModernPayment');
      return PaymentFailure('Unexpected error occurred');
    }
  }
}

/// Result of payment processing - sealed class for exhaustive pattern matching
sealed class PaymentProcessResult {}

/// Payment completed successfully
final class PaymentSuccess extends PaymentProcessResult {
  final String paymentId;
  
  PaymentSuccess(this.paymentId);
  
  @override
  String toString() => 'PaymentSuccess(paymentId: $paymentId)';
}

/// Payment failed with an error
final class PaymentFailure extends PaymentProcessResult {
  final String errorMessage;
  
  PaymentFailure(this.errorMessage);
  
  @override
  String toString() => 'PaymentFailure(errorMessage: $errorMessage)';
}

/// Payment was cancelled by the user
final class PaymentCancelled extends PaymentProcessResult {
  @override
  String toString() => 'PaymentCancelled()';
}

/// Extension methods for backward compatibility and convenience
extension PaymentProcessResultExtension on PaymentProcessResult {
  /// Factory method for success (backward compatibility)
  static PaymentSuccess success(String paymentId) => PaymentSuccess(paymentId);
  
  /// Factory method for failure (backward compatibility)
  static PaymentFailure failure(String errorMessage) => PaymentFailure(errorMessage);
  
  /// Factory method for cancelled (backward compatibility)
  static PaymentCancelled cancelled() => PaymentCancelled();
  
  /// Check if payment was successful
  bool get isSuccess => this is PaymentSuccess;
  
  /// Check if payment was cancelled
  bool get isCancelled => this is PaymentCancelled;
  
  /// Get payment ID if successful, null otherwise
  String? get paymentId => switch (this) {
    PaymentSuccess(paymentId: final id) => id,
    _ => null,
  };
  
  /// Get error message if failed, null otherwise
  String? get errorMessage => switch (this) {
    PaymentFailure(errorMessage: final msg) => msg,
    _ => null,
  };
}