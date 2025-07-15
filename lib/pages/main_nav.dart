// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
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
      dynamic paymentIntent, Event event, SlottedUser slottedUser) async {
    try {
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
      var response = await http.post(
        Uri.parse(
            'https://us-central1-open-mic-5cc8e.cloudfunctions.net/reserveAction'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'eventID': event.id,
          'userID': slottedUser.id,
          'pi': paymentIntent == '' ? paymentIntent : json.encode(paymentIntent),
          'debug': widget.debug ? 'true' : 'false',
        },
      ).timeout(const Duration(seconds: 30));
      
      Logger.d('Reservation response status: ${response.statusCode}', tag: 'Main_nav');
      Logger.d('Reservation response body: ${response.body}', tag: 'Main_nav');
      
      if (response.statusCode != 200) {
        try {
          final errorData = json.decode(response.body);
          throw Exception(errorData['error'] ?? 'Failed to reserve: ${response.body}');
        } catch (jsonError) {
          throw Exception('Failed to reserve: ${response.body}');
        }
      }
      
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
      var response = await http.post(
        Uri.parse(
            'https://us-central1-open-mic-5cc8e.cloudfunctions.net/deleteEvent'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'eventID': eventId,
          'debug': widget.debug ? 'true' : 'false',
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

    dynamic paymentIntent = '';

    final isReserved = event.attendees.contains(slottedUser.id);
    final isWaitlisted = event.waitlist.contains(slottedUser.id);

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

        // Verify password with backend
        try {
          Logger.d('Verifying password for event: ${event.id}', tag: 'Main_nav');
          final verifyResponse = await http.post(
            Uri.parse(
                'https://us-central1-open-mic-5cc8e.cloudfunctions.net/verifyEventPassword'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
            },
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
        final clientSecret = await createPaymentIntentOnBackend(
          amount: (event.price * 100).toInt(),
          currency: 'usd',
          customerId: widget.debug ? slottedUser.testCustomerID : slottedUser.customerID,
          debug: widget.debug,
        );
        if (clientSecret == null) throw Exception('No client secret returned');
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'OpenSlot',
          ),
        );
        await Stripe.instance.presentPaymentSheet();
      }

      await reserveAction('', event, slottedUser);
      
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
      
      String errorMessage =
          'There was an error processing your payment. Please try again.\n$e';
      bool cancelled = false;
      if (e is PlatformException) {
        errorMessage = e.message ?? errorMessage;
      } else if (e is StripeException) {
        errorMessage = e.error.message ?? errorMessage;
        cancelled = e.error.code == FailureCode.Canceled;
      } else if (e is StripeError) {
        errorMessage = e.message;
      }

      Logger.d(e.toString(), tag: 'Main_nav');

      setState(() {
        isLoading = false;
      });

      if (!cancelled) {
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
  bool debug = true,
}) async {
  final url = '${EnvironmentConfig.apiBaseUrl}/createPaymentIntent';
  final response = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'amount': amount.toString(),
      'currency': currency,
      'customerId': customerId,
      'debug': debug,
    }),
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['clientSecret'];
  } else {
    throw Exception('Failed to create PaymentIntent: \\${response.body}');
  }
}
