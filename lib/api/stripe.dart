import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:slotted/common/colors.dart';
import 'package:slotted/common/event_class.dart';

class StripeApi {
  static String stripeKey =
      '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';
  static String stripeDebugKey =
      'sk_test_51NN216JiJ5SaqolZXlaFyh9KcnpEfJe88w8wJ51qpmk8TGZu3JiZrx1ZmSiWpBboo22bYZgcKEl6WSZkCVq8KAyU00f3XKNSLO';

  static Future<String> createCustomer(
      {String? cid, bool debug = false}) async {
    if (cid != null) return cid;

    var response = await http.post(
      Uri.parse('https://api.stripe.com/v1/customers'),
      headers: {
        'Authorization': 'Bearer ${debug ? stripeDebugKey : stripeKey}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );
    return json.decode(response.body)['id'];
  }

  static Future<String> getEphemeralKey(String customerId,
      {bool debug = false}) async {
    var response = await http.post(
      Uri.parse(
          'https://us-central1-open-mic-5cc8e.cloudfunctions.net/getEphemeralKey'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'cusID': customerId,
        'debug': debug ? 'true' : 'false',
      },
    );
    return json.decode(response.body)['secret'];
  }

  static Future<void> pay({
    required dynamic paymentIntent,
    required String customer,
    required String ephemeralKey,
    required Event event,
  }) async {
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: paymentIntent['client_secret'],
        allowsDelayedPaymentMethods: true,
        appearance: PaymentSheetAppearance(
          colors: PaymentSheetAppearanceColors(
            error: Colors.red,
            icon: slottedOrange,
            background: CupertinoColors.darkBackgroundGray.withOpacity(1.0),
            primary: slottedOrange,
            placeholderText: CupertinoColors.lightBackgroundGray,
          ),
          shapes: const PaymentSheetShape(
            borderRadius: 14,
            borderWidth: 1.5,
          ),
        ),
        primaryButtonLabel: event.attendees.length < event.slots
            ? 'Reserve - \$${event.price.toStringAsFixed(2)}'
            : 'Waitlist - \$${event.price.toStringAsFixed(2)}',
        style: ThemeMode.dark,
        merchantDisplayName: 'Slotted LLC',
        customerId: customer,
        customerEphemeralKeySecret: ephemeralKey,
        applePay: PaymentSheetApplePay(
          merchantCountryCode: 'US',
          cartItems: [
            ApplePayCartSummaryItem.immediate(
              label: '${event.name} - Slotted',
              amount: event.price.toString(),
            ),
          ],
          buttonType: PlatformButtonType.pay,
        ),
        googlePay: PaymentSheetGooglePay(
          merchantCountryCode: 'US',
          label: '${event.name} - Slotted',
          amount: event.price.toString(),
        ),
      ),
    );
    await Stripe.instance.presentPaymentSheet();
  }

  static Future<dynamic> createPaymentIntent(
      {required String userId,
      required double amount,
      required String currency,
      String? customerId,
      String? returnUrl,
      bool debug = false}) async {
    try {
      if (customerId == null) {
        customerId = await createCustomer(cid: customerId, debug: debug);
        FirebaseFirestore.instance.doc('users/$userId').set({
          '${debug ? 'test-' : ''}customerID': customerId,
        }, SetOptions(merge: true));
      }

      Map<String, dynamic> body = {
        'amount': (amount * 100).toInt().toString(),
        'currency': currency,
        'customer': customerId,
        'setup_future_usage': 'on_session',
        'payment_method_types[]': 'card',
        'capture_method': 'manual',
      };

      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer ${debug ? stripeDebugKey : stripeKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );
      return json.decode(response.body);
    } catch (err) {
      throw Exception(err.toString());
    }
  }
}
