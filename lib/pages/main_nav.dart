// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:slotted/api/stripe_usage_tracker.dart';
import 'package:slotted/api/stripe_customer_service.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:slotted/common/constants.dart' as constants;
import 'package:slotted/pages/my_home_page.dart';
import 'package:slotted/api/firebase_auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:slotted/pages/login_page.dart';
import 'package:slotted/utils/logger.dart';
import 'package:slotted/common/private_event_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:slotted/config/environment_config.dart';
import 'package:slotted/widgets/modern_payment_widget.dart';
import 'package:slotted/api/apple_pay.dart';
import 'package:slotted/api/functions_http_client.dart';

// Animation constants from constants.dart
const kAnimationDurationLong = constants.kAnimationDurationLong;
const kAnimationDurationMedium = constants.kAnimationDurationMedium;
const kAnimationCurveEnergetic = constants.kAnimationCurveEnergetic;
const kAnimationCurveBouncy = constants.kAnimationCurveBouncy;

// Create class MainNav that manages a tab controller screen with 5 routes. The middle route must point to MyHomePage.
class MainNav extends StatefulWidget {
  const MainNav({super.key, this.debug = false, this.event});

  final bool debug;
  final Event? event;

  @override
  State<MainNav> createState() => MainNavState();
}

class MainNavState extends State<MainNav> with SingleTickerProviderStateMixin {
  late final SlottedUser? slottedUser;
final FocusNode authFocusNode = FocusNode();
  final Color complementaryColor = CupertinoColors.systemTeal;

  String? phoneNumber;

  bool isLoading = false;

  final double iconSize = 30;

  String titleString = 'Open Slot';

  late final List<Widget> tabViews;

  final TextEditingController phoneController = TextEditingController();

  Future<String> reserveAction(
      dynamic paymentIntent, Event event, SlottedUser slottedUser, {String? password}) async {
    try {
      Logger.d('Starting reserveAction for event: ${event.id}, user: ${slottedUser.id}', tag: 'Main_nav');
      
      // Check network connectivity before making request
      try {
        final connectivityCheck = await http.get(Uri.parse('https://google.com'))
            .timeout(const Duration(seconds: 5));
        if (connectivityCheck.statusCode != 200) {
          Logger.d('Network connectivity check failed with status: ${connectivityCheck.statusCode}', tag: 'Main_nav');
          throw Exception('No internet connection');
        }
      } catch (e) {
        Logger.d('Network connectivity check failed: $e', tag: 'Main_nav');
        throw Exception('Please check your internet connection');
      }

      Logger.d('Making reservation request for event: ${event.id}, user: ${slottedUser.id}', tag: 'Main_nav');
      
      // Identity comes from Firebase ID token on the server — do not send userID
      final requestBody = <String, String>{
        'eventID': event.id,
        'pi': paymentIntent == '' ? paymentIntent.toString() : json.encode(paymentIntent),
        if (password != null && password.isNotEmpty)
          'password': Uri.encodeComponent(password),
      };
      
      Logger.d('Request body keys: ${requestBody.keys.toList()}', tag: 'Main_nav');
      
      final headers = await FunctionsHttpClient.authHeaders(
        contentType: 'application/x-www-form-urlencoded',
      );
      var response = await http.post(
        Uri.parse(
            'https://us-central1-open-mic-5cc8e.cloudfunctions.net/reserveAction'),
        headers: headers,
        body: requestBody,
      ).timeout(const Duration(seconds: 30));
      
      Logger.d('Reservation response status: ${response.statusCode}', tag: 'Main_nav');
      Logger.d('Reservation response body: ${response.body}', tag: 'Main_nav');
      
      if (response.statusCode == 403) {
        try {
          final errorData = json.decode(response.body);
          if (errorData['error'] == 'Password verification required for private event') {
            throw Exception('Password verification required for private event');
          }
        } catch (jsonError) {
          throw Exception('Password verification required for private event');
        }
      }
      
      if (response.statusCode != 200) {
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['error'] ?? 'Failed to reserve: ${response.body}';
          Logger.d('Reservation failed with error: $errorMessage', tag: 'Main_nav');
          throw Exception(errorMessage);
        } catch (jsonError) {
          final errorMessage = 'Failed to reserve: ${response.body}';
          Logger.d('Reservation failed with error: $errorMessage', tag: 'Main_nav');
          throw Exception(errorMessage);
        }
      }
      
      Logger.d('Reservation successful', tag: 'Main_nav');
      return response.body;
    } catch (e) {
      Logger.d('Error in reserveAction: $e', tag: 'Main_nav');
      if (e.toString().contains('timeout')) {
        throw Exception('Request timed out. Please try again');
      }
      throw Exception('Failed to complete reservation: ${e.toString()}');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    setState(() {
      isLoading = true;
    });

    try {
      final headers = await FunctionsHttpClient.authHeaders(
        contentType: 'application/x-www-form-urlencoded',
      );
      var response = await http.post(
        Uri.parse(
            'https://us-central1-open-mic-5cc8e.cloudfunctions.net/deleteEvent'),
        headers: headers,
        body: {
          'eventID': eventId,
        },
      );
      final body = response.body;

      if (response.statusCode == 200) {
        await showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: const Text('Success'),
              content: const Text('Event deleted successfully.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      } else {
        await showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text(
                  'There was an error deleting the event. Please try again.\n$body'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      String errorMessage =
          'There was an error deleting the event. Please try again.\n$e';
      if (e is FirebaseException) {
        errorMessage = e.message ?? errorMessage;
      }

      await showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(errorMessage),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> resAuth(Event event, SlottedUser slottedUser) async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
    });

    final isReserved = event.attendees.contains(slottedUser.id);
    final isWaitlisted = event.waitlist.contains(slottedUser.id);
    String? privateEventPassword;

    try {
      // Check if event is private and requires password verification
      if (event.isPrivate && !(isReserved || isWaitlisted)) {
        final password = await showCupertinoDialog<String>(
          context: context,
          barrierDismissible: true,
          builder: (context) => PrivateEventDialog(
            eventName: event.name,
            onSubmit: (password) => Navigator.of(context).pop(password),
            onCancel: () => Navigator.of(context).pop(null),
          ),
        );

        // If user cancels password entry
        if (password == null) {
          if (!mounted) return;
          setState(() {
            isLoading = false;
          });
          return;
        }

        privateEventPassword = password;

        // Verify password with backend (UI gate; reserveAction re-verifies server-side)
        try {
          Logger.d('Verifying password for event: ${event.id}', tag: 'Main_nav');
          final verifyHeaders = await FunctionsHttpClient.authHeaders(
            contentType: 'application/x-www-form-urlencoded',
          );
          final verifyResponse = await http.post(
            Uri.parse(
                'https://us-central1-open-mic-5cc8e.cloudfunctions.net/verifyEventPassword'),
            headers: verifyHeaders,
            body: {
              'eventID': event.id,
              'password': Uri.encodeComponent(password),
            },
          ).timeout(const Duration(seconds: 10));

          Logger.d('Password verification response status: ${verifyResponse.statusCode}', tag: 'Main_nav');
          Logger.d('Password verification response body: ${verifyResponse.body}', tag: 'Main_nav');

          if (verifyResponse.statusCode != 200) {
            final errorData = json.decode(verifyResponse.body);
            final errorMessage = errorData['error'] ?? 'Invalid password';
            Logger.d('Password verification failed: $errorMessage', tag: 'Main_nav');
            throw Exception(errorMessage);
          }

          // Parse response to check success field
          final responseData = json.decode(verifyResponse.body);
          if (!responseData['success']) {
            Logger.d('Password verification response indicated failure', tag: 'Main_nav');
            throw Exception('Password verification failed');
          }
          
          Logger.d('Password verification successful', tag: 'Main_nav');
          
          // After successful password verification, proceed with reservation
          // The backend should now allow the reservation to proceed
        } catch (e) {
          Logger.d('Error verifying password: $e', tag: 'Main_nav');
          if (!mounted) return;
          
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text(e.toString().contains('Invalid password') 
                ? 'Invalid password. Please try again.' 
                : 'Failed to verify password. Please try again.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
          
          setState(() {
            isLoading = false;
          });
          return;
        }
      }

      // Continue with payment and reservation if password verification passed
      if (event.price > 0 && !(isReserved || isWaitlisted)) {
        try {
          // Create or get Stripe customer first
          String? customerId;
          try {
            customerId = await StripeCustomerService.createOrGetCustomer(
              userId: slottedUser.id,
              email: slottedUser.email,
              name: slottedUser.username,
              debug: widget.debug,
            );
            Logger.d('Got customer ID for payment: $customerId', tag: 'Main_nav');
          } catch (e) {
            Logger.w('Failed to create customer, proceeding with guest checkout: $e', tag: 'Main_nav');
          }

          // Create payment intent with customer ID (if available)
          final clientSecret = await createPaymentIntentOnBackend(
            amount: (event.price * 100).toInt(),
            currency: 'usd',
            customerId: customerId,
            eventID: event.id,
            debug: widget.debug,
          );
          if (clientSecret == null) throw Exception('No client secret returned');
          
          // Show modern payment widget with Apple Pay support
          PaymentProcessResult? paymentResult;
          
          await showCupertinoModalPopup<void>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.7,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ModernPaymentWidget(
                  event: event,
                  clientSecret: clientSecret,
                  debug: widget.debug,
                  onPaymentResult: (result) {
                    paymentResult = result;
                    Navigator.of(context).pop();
                  },
                  onCancel: () {
                    paymentResult = PaymentCancelled();
                    Navigator.of(context).pop();
                  },
                ),
              );
            },
          );
          
          // Handle payment result
          if (paymentResult == null || paymentResult is PaymentCancelled) {
            setState(() {
              isLoading = false;
            });
            return;
          }
          
          if (paymentResult is PaymentFailure) {
            throw Exception((paymentResult as PaymentFailure).errorMessage);
          }
          
          // Payment successful, continue with reservation
          Logger.d('Payment successful: ${(paymentResult as PaymentSuccess).paymentId}', tag: 'Main_nav');
          
          // CRITICAL: Report usage to Stripe for billing
          try {
            final customerId = widget.debug ? slottedUser.testCustomerID : slottedUser.customerID;
            if (customerId != null && customerId.isNotEmpty) {
              final usageReported = await StripeUsageTracker.reportBookingCompleted(
                customerId: customerId,
                eventId: event.id,
                bookingId: (paymentResult as PaymentSuccess).paymentId,
                amount: event.price,
                debug: widget.debug,
              );
              
              if (!usageReported) {
                Logger.w('Failed to report usage to Stripe - billing may be affected', tag: 'Main_nav');
              }
            } else {
              Logger.w('No customer ID available - usage tracking skipped', tag: 'Main_nav');
            }
          } catch (e) {
            Logger.e('Error reporting usage to Stripe: $e', tag: 'Main_nav');
            // Don't fail the booking if usage tracking fails
          }
          
        } catch (e) {
          Logger.d('Payment error: $e', tag: 'Main_nav');
          if (!mounted) return;
          
          setState(() {
            isLoading = false;
          });
          
          // Show payment error dialog
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Payment Failed'),
              content: Text('Could not process payment: ${e.toString()}'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
          return;
        }
      }

      // Make the reservation request (password re-checked server-side for private events)
      final result = await reserveAction(
        '',
        event,
        slottedUser,
        password: privateEventPassword,
      );
      Logger.d('Reservation result: $result', tag: 'Main_nav');
      
      // Show success message
      if (!mounted) return;
      
      setState(() {
        isLoading = false;
      });
      
      try {
        // Check if the event is now full and if the user is on the waitlist
        final updatedEvent = await FirebaseFirestore.instance.collection('events').doc(event.id).get();
        final isNowWaitlisted = updatedEvent.exists && 
                               (updatedEvent.data()?['waitlist'] as List<dynamic>?)?.contains(slottedUser.id) == true;
        
        await showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: const Text('Success'),
              content: Text(isNowWaitlisted 
                ? 'You have been added to the waitlist for ${event.name}. We\'ll notify you if a spot becomes available.'
                : 'You have successfully reserved a spot for ${event.name}.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      } catch (dialogError) {
        Logger.d('Error showing success dialog: $dialogError', tag: 'Main_nav');
        // Dialog failed but reservation succeeded
      }
      
      // Force UI refresh after successful reservation
      if (!mounted) return;
      setState(() {
        // Trigger rebuild to update UI
      });
      
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = 'There was an error processing your reservation. Please try again.\n$e';
      bool cancelled = false;
      
      if (e is PlatformException) {
        errorMessage = e.message ?? errorMessage;
      } else if (e is StripeException) {
        errorMessage = e.error.message ?? errorMessage;
        cancelled = e.error.code == FailureCode.Canceled;
      } else if (e is StripeError) {
        errorMessage = e.message;
      }

      Logger.d('Reservation error: $e', tag: 'Main_nav');

      setState(() {
        isLoading = false;
      });

      if (!cancelled) {
        await showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: const Text('Reservation Failed'),
              content: Text(errorMessage),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoDialogAction(
                  child: const Text('Retry'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    resAuth(event, slottedUser); // Retry the reservation
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeFirebaseMessaging();
  }

  Future<void> _initializeFirebaseMessaging() async {
    // ... existing _initializeFirebaseMessaging code ...
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  bool isDialogShowing = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        return CupertinoPageScaffold(
          resizeToAvoidBottomInset: false,
          child: MyHomePage(
            user: snapshot.data,
            debug: widget.debug,
            authAction: (context, loggedIn, completion) async {
              await _authAction(context, loggedIn, completion: completion);
            },
            reserveAction: (event, slottedUser) async {
              return resAuth(event, slottedUser);
            },
            deleteEvent: (String eventId) async {
              await deleteEvent(eventId);
            },
          ),
        );
      },
    );
  }



  Future<void> _authAction(BuildContext context, bool loggedIn,
      {Function()? completion}) async {
    setState(() {
      isLoading = true;
    });
    try {
      if (loggedIn) {
        await FirebaseAuthService().signOut();
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          completion?.call();
          Navigator.of(context).pushAndRemoveUntil(
            CupertinoPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      } else {
        // Use the new LoginPage instead of the modal dialog
        await Navigator.of(context).push(
          CupertinoPageRoute(
            fullscreenDialog: true,
            builder: (context) => const LoginPage(),
          ),
        );

        // Check if user is logged in after returning from login page
        if (FirebaseAuth.instance.currentUser != null) {
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            isLoading = false;
          });
          completion?.call();
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      completion?.call();
      rethrow;
    }
  }






}

Future<String?> createPaymentIntentOnBackend({
  required int amount, // in cents
  required String currency,
  String? customerId,
  String? eventID,
  bool debug = true,
}) async {
  final headers = await FunctionsHttpClient.authHeaders();
  final response = await http.post(
    Uri.parse('${EnvironmentConfig.apiBaseUrl}/createPaymentIntent'),
    headers: headers,
    body: jsonEncode({
      'amount': amount.toString(),
      'currency': currency,
      // customerId ignored server-side; kept for backward compatibility
      'customerId': customerId,
      if (eventID != null) 'eventID': eventID,
    }),
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['clientSecret'];
  } else {
    throw Exception('Failed to create PaymentIntent: ${response.body}');
  }
}
