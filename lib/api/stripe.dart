import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:slotted/common/event_class.dart';

class StripeApi {
  static String stripeKey =
      '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';
  // static String stripeKey =
  // 'sk_test_51NN216JiJ5SaqolZXlaFyh9KcnpEfJe88w8wJ51qpmk8TGZu3JiZrx1ZmSiWpBboo22bYZgcKEl6WSZkCVq8KAyU00f3XKNSLO';

  static Future<String> createCustomer([String? cid]) async {
    if (cid != null) return cid;

    var response = await http.post(
      Uri.parse('https://api.stripe.com/v1/customers'),
      headers: {
        'Authorization': 'Bearer $stripeKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );
    return json.decode(response.body)['id'];
  }

  static Future<String> getEphemeralKey(String customerId) async {
    var response = await http.post(
      Uri.parse(
          'https://us-central1-open-mic-5cc8e.cloudfunctions.net/getEphemeralKey'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'cusID': customerId,
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
    Stripe.merchantIdentifier = 'merchant.slotted';
    // Stripe.publishableKey =
    //     'pk_test_51NN216JiJ5SaqolZZSpfh1JgsVWZdWgJ5vzAwiqqPyXLNE5XdTHjrcyWFtX0ueyzBFWmIe6IBcRKtRXFmAyvVd1i00RXcYBy6R';
    Stripe.publishableKey =
        'pk_live_51NN216JiJ5SaqolZOcy7QUss4OoGRjpe4vwh2hhnId6dQSEl0QT16cOPUW2pMgcu316JtgU2Ia91pZbfHjGutGro00srzU7thB';
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: paymentIntent['client_secret'],
        style: ThemeMode.dark,
        merchantDisplayName: 'Slotted LLC',
        customerId: customer,
        customerEphemeralKeySecret: ephemeralKey,
        applePay: PaymentSheetApplePay(
          merchantCountryCode: 'US',
          cartItems: [
            ApplePayCartSummaryItem.immediate(
              label: 'Slotted - ${event.name}',
              amount: (event.price * 100).toInt().toString(),
            ),
          ],
          buttonType: PlatformButtonType.pay,
        ),
        googlePay: PaymentSheetGooglePay(
          merchantCountryCode: 'US',
          label: 'Slotted - ${event.name}',
          amount: (event.price * 100).toInt().toString(),
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
      String? returnUrl}) async {
    try {
      if (customerId == null) {
        customerId = await createCustomer();
        FirebaseFirestore.instance.doc('users/$userId').set({
          'customerID': customerId,
        }, SetOptions(merge: true));
      }

      //Request body
      Map<String, dynamic> body = {
        'amount': (amount * 100).toInt().toString(),
        'currency': currency,
        'customer': customerId,
        'setup_future_usage': 'on_session',
        'payment_method_types[]': 'card',
        'capture_method': 'manual',
      };

      //Make post request to Stripe
      // Stripe.instance.retrievePaymentIntent(clientSecret)
      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $stripeKey',
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
