// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:slotted/api/stripe.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:slotted/pages/my_events.dart';
import 'package:slotted/pages/my_home_page.dart';
import 'package:slotted/pages/profile.dart';
import 'package:slotted/api/firebase_auth_service.dart';
import 'package:slotted/widgets/code_verification_page.dart';
import 'package:http/http.dart' as http;
import 'notifications_page.dart';

// Create class MainNav that manages a tab controller screen with 5 routes. The middle route must point to MyHomePage.
class MainNav extends StatefulWidget {
  const MainNav({super.key, this.debug = false});

  final bool debug;

  @override
  State<MainNav> createState() => MainNavState();
}

class MainNavState extends State<MainNav> with SingleTickerProviderStateMixin {
  late final CupertinoTabController _tabController;
  late final SlottedUser? slottedUser;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  final FocusNode authFocusNode = FocusNode();
  KeyboardActionsConfig _buildConfig(BuildContext context) {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      keyboardBarColor: CupertinoColors.secondaryLabel.withOpacity(1),
      nextFocus: false,
      actions: [
        KeyboardActionsItem(focusNode: authFocusNode, toolbarButtons: [
          (node) {
            return CupertinoButton(
              padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
              onPressed: () => node.unfocus(),
              child: const Text(
                'Done',
                style: TextStyle(
                  color: slottedOrange,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
        ]),
      ],
    );
  }

  String? phoneNumber;

  bool isLoading = false;

  final double iconSize = 30;

  String titleString = 'Slotted';

  late final List<Widget> tabViews;

  final TextEditingController phoneController = TextEditingController();

  bool _hasCheckedUser = false;

  Future<String> reserveAction(
      dynamic paymentIntent, Event event, SlottedUser slottedUser) async {
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
    );
    return response.body;
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
    setState(() {
      isLoading = true;
    });

    dynamic paymentIntent = '';

    final isReserved = event.attendees.contains(slottedUser.id);
    final isWaitlisted = event.waitlist.contains(slottedUser.id);

    if (isReserved || isWaitlisted) {
      await showCupertinoDialog(
        context: context,
        builder: (context) {
          final isPaid = event.price > 0;
          return CupertinoAlertDialog(
            title: Text('${isPaid ? 'Refund' : 'Cancel'} Reservation'),
            content: Text(
                'Are you sure you want to give up your slot for this event?${isPaid ? ' You will be refunded after your reservation is cancelled.' : ''}'),
            actions: [
              CupertinoDialogAction(
                  child: const Text(
                    'Back',
                    style: TextStyle(
                      color: slottedOrange,
                    ),
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    setState(() {
                      isLoading = false;
                    });
                  }),
              CupertinoDialogAction(
                child: const Text(
                  'Unreserve',
                  style: TextStyle(
                      color: CupertinoColors.systemRed,
                      fontWeight: FontWeight.w600),
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    await reserveAction(paymentIntent, event, slottedUser);
                  } catch (e) {
                    String errorMessage =
                        'There was an error processing your ${isPaid ? 'refund' : 'cancellation'}. Please try again.\n$e';
                    if (e is PlatformException) {
                      errorMessage = e.message ?? errorMessage;
                    } else if (e is StripeException) {
                      errorMessage = e.error.message ?? errorMessage;
                    } else if (e is StripeError) {
                      errorMessage = e.message;
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
                },
              ),
            ],
          );
        },
      );
      return;
    }

    try {
      if (event.price > 0 && !(isReserved || isWaitlisted)) {
        paymentIntent = await StripeApi.createPaymentIntent(
          userId: slottedUser.id,
          amount: event.price,
          currency: 'USD',
          customerId: widget.debug
              ? slottedUser.testCustomerID
              : slottedUser.customerID,
          debug: widget.debug,
        );
        final stripeCustomerId = paymentIntent['customer'];
        final ephemeralKey = await StripeApi.getEphemeralKey(stripeCustomerId,
            debug: widget.debug);

        await StripeApi.pay(
            paymentIntent: paymentIntent,
            customer: stripeCustomerId,
            ephemeralKey: ephemeralKey,
            event: event);
      }

      await reserveAction(paymentIntent, event, slottedUser);
    } catch (e) {
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

      print(e);

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

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = CupertinoTabController(
      initialIndex: 1,
    );
    tabViews = [
      StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) => MyEventsPage(
            user: snapshot.data,
            authAction: (context, isLoggedIn, completion) =>
                _authAction(context, isLoggedIn, completion: completion),
            reserveAction: (event, slottedUser) => resAuth(event, slottedUser),
            deleteEvent: (eventId) => deleteEvent(eventId),
            debug: widget.debug),
      ),
      StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) => MyHomePage(
          debug: widget.debug,
          user: snapshot.data,
          authAction: (context, isLoggedIn, completion) =>
              _authAction(context, isLoggedIn, completion: completion),
          reserveAction: (event, slottedUser) => resAuth(event, slottedUser),
          deleteEvent: (eventId) => deleteEvent(eventId),
        ),
      ),
      StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) => ProfilePage(
          user: snapshot.data,
          authAction: (isLoggedIn) => _authAction(context, isLoggedIn),
          debug: widget.debug,
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  bool isDialogShowing = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        bool loggedIn = snapshot.data != null;
        if (snapshot.data?.uid != null) {
          // Use a delayed future to run this code once after launch
          String? currentUid = snapshot.data?.uid; // Capture current UID
          Future.delayed(const Duration(seconds: 2), () {
            if (!mounted) return; // Check if widget is still mounted
            if (snapshot.data?.uid != currentUid)
              return; // Check if user changed

            // Track if we've already run this code
            if (!_hasCheckedUser) {
              _hasCheckedUser = true;

              FirebaseFirestore.instance
                  .doc('users/${snapshot.data!.uid}')
                  .get()
                  .then((value) {
                final slottedUser = SlottedUser.fromDocument(value);

                if (slottedUser.username.isEmpty) {
                  // Show username collection dialog
                  if (!isDialogShowing) {
                    isDialogShowing = true;
                    showCupertinoDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        final usernameController = TextEditingController();
                        return CupertinoAlertDialog(
                          title: const Text('Welcome to Slotted!'),
                          content: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                            child: Column(
                              children: [
                                const Text(
                                    'Please choose a username to get started.'),
                                const SizedBox(
                                  height: 8,
                                ),
                                CupertinoTextField(
                                  autofocus: true,
                                  controller: usernameController,
                                  placeholder: 'Username',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            CupertinoDialogAction(
                              onPressed: () {
                                if (usernameController.text.isNotEmpty) {
                                  FirebaseFirestore.instance
                                      .doc('users/${snapshot.data!.uid}')
                                      .set({
                                    'username': usernameController.text,
                                    'joined': Timestamp.now(),
                                    'isHost': true,
                                    'photoUrl': null,
                                  }, SetOptions(merge: true)).then((_) {
                                    isDialogShowing = false;
                                    Navigator.pop(context);
                                  });
                                }
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                }
              });

              Permission.notification.request().then((status) {
                if (status.isGranted) {
                  // Permission is granted
                  _firebaseMessaging.getAPNSToken().then((apnsToken) {
                    // print("APNS TOKEN: $apnsToken");
                    return _firebaseMessaging.getToken();
                  }).then((token) {
                    // print("MESSAGING TOKEN: $token");
                    FirebaseFirestore.instance
                        .doc('users/${snapshot.data!.uid}')
                        .set(
                      {
                        'pushToken': token,
                      },
                      SetOptions(merge: true),
                    );
                  });
                }
              });
            }
          });
        }
        return Stack(
          children: [
            CupertinoPageScaffold(
              resizeToAvoidBottomInset: false,
              navigationBar: CupertinoNavigationBar(
                border: null,
                backgroundColor: Colors.transparent,
                middle: _buildNavigationTitle(),
                leading: loggedIn
                    ? CupertinoButton(
                        onPressed: isLoading
                            ? null
                            : () => Navigator.of(context).push(
                                  CupertinoPageRoute(
                                    builder: (context) => NotificationsPage(
                                      user: snapshot.data,
                                    ),
                                  ),
                                ),
                        padding: EdgeInsets.zero,
                        child: const Icon(CupertinoIcons.bell, size: 30),
                      )
                    : null,
                trailing: CupertinoButton(
                  onPressed:
                      isLoading ? null : () => _openSettings(context, loggedIn),
                  padding: EdgeInsets.zero,
                  child: loggedIn
                      ? const Icon(
                          CupertinoIcons.gear,
                          size: 30,
                        )
                      : const Text(
                          'Sign In',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      CupertinoColors.systemBlue.withOpacity(0.1),
                      CupertinoColors.systemPurple.withOpacity(0.1),
                    ],
                  ),
                ),
                child: CupertinoTabScaffold(
                  resizeToAvoidBottomInset: false,
                  tabBar: CupertinoTabBar(
                    height: 64,
                    backgroundColor: CupertinoColors.systemGrey.withOpacity(0.2),
                    activeColor: slottedOrange,
                    inactiveColor: CupertinoColors.systemGrey,
                    currentIndex: _tabController.index,
                    onTap: (index) {
                      _tabController.index = index;
                      setState(() {
                        switch (_tabController.index) {
                          case 0:
                            titleString = 'My Events';
                            break;
                          case 1:
                            titleString = 'Slotted';
                            break;
                          case 2:
                            titleString = 'Profile';
                            break;
                          default:
                            titleString = 'Slotted';
                        }
                      });
                    },
                    iconSize: iconSize,
                    items: [
                      const BottomNavigationBarItem(
                        icon: Icon(CupertinoIcons.list_bullet),
                      ),
                      BottomNavigationBarItem(
                        icon: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: _tabController.index == 1
                                  ? slottedOrange.withOpacity(0.93)
                                  : CupertinoColors.systemGrey.withOpacity(0.7),
                              width: 3,
                            ),
                          ),
                          child: Image.asset(
                            'lib/assets/images/s_logo.png',
                            width: iconSize * 1.2,
                            height: iconSize * 1.2,
                            color: _tabController.index == 1
                                ? slottedOrange.withOpacity(0.93)
                                : CupertinoColors.systemGrey.withOpacity(0.7),
                          ),
                        ),
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(CupertinoIcons.person),
                      ),
                    ],
                  ),
                  tabBuilder: (context, index) {
                    return SafeArea(
                      child: tabViews[index],
                    );
                  },
                ),
              ),
            ),
            if (isLoading)
              const Opacity(
                opacity: 0.7,
                child: ModalBarrier(
                  color: CupertinoColors.black,
                  dismissible: false,
                ),
              ),
            if (isLoading)
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const CircularProgressIndicator(
                    strokeCap: StrokeCap.round,
                    backgroundColor: CupertinoColors.systemOrange,
                    strokeAlign: -8,
                    strokeWidth: 5,
                    color: slottedOrange,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _openSettings(BuildContext context, bool loggedIn) {
    if (!loggedIn) {
      _authAction(context, loggedIn);
      return;
    }
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: const Text('Settings'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => _authAction(context, loggedIn),
              child: Text(
                loggedIn ? 'Sign Out' : 'Sign In',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
        setState(() {
          isLoading = false;
        });
        completion?.call();
        Navigator.of(context).pop();
      } else {
        // Present sign in modal to collect phone number
        phoneController.clear();
        final result = await showCupertinoModalPopup(
          context: context,
          builder: (builder) {
            return
                // KeyboardActions(
                //   isDialog: true,
                //   disableScroll: true,
                //   autoScroll: false,
                //   config: _buildConfig(context),
                //   child:
                CupertinoAlertDialog(
              title: const Text(
                'Sign In',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              content: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                child: CupertinoTextField(
                  focusNode: authFocusNode,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  placeholder: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  onChanged: (value) {
                    // Format the display value
                    final digits = value.replaceAll(RegExp(r'\D'), '');
                    String formatted = '';
                    for (int i = 0; i < digits.length && i < 10; i++) {
                      if (i == 3 || i == 6) formatted += '-';
                      formatted += digits[i];
                    }

                    setState(() {
                      phoneNumber = value.replaceAll('-', '');
                      phoneController.text = formatted;
                    });
                  },
                  controller: phoneController,
                  maxLength: 12,
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () {
                    setState(() {
                      phoneNumber = null;
                      isLoading = false;
                    });
                    completion?.call();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                CupertinoDialogAction(
                  onPressed: () async {
                    // Format phone number, filter all characters except 0-9 and +
                    var formattedNumber = phoneNumber
                        ?.replaceAll(' ', '')
                        .replaceAll('-', '')
                        .trim();
                    // if formattedNumber doesn't start with +, add +1

                    if (formattedNumber == null || formattedNumber.isEmpty) {
                      return;
                    }

                    if (!formattedNumber.startsWith('+')) {
                      formattedNumber = '+1$formattedNumber';
                    }

                    await FirebaseAuthService().firebaseAuth.verifyPhoneNumber(
                          phoneNumber: formattedNumber,
                          verificationCompleted:
                              (PhoneAuthCredential credential) async {
                            // Auto-retrieval or instant verification completed
                            await FirebaseAuthService()
                                .firebaseAuth
                                .signInWithCredential(credential);
                            setState(() {
                              isLoading = false;
                            });
                            completion?.call();
                          },
                          verificationFailed: (FirebaseAuthException e) {
                            // Handle error
                            showCupertinoDialog(
                              context: context,
                              builder: (context) => CupertinoAlertDialog(
                                title: const Text('Error'),
                                content: Text(e.message ?? e.toString()),
                                actions: [
                                  CupertinoButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                            setState(() {
                              isLoading = false;
                            });
                            completion?.call();
                          },
                          codeSent: (String verificationId, int? resendToken) {
                            // Code sent for manual entry
                            Navigator.of(context)
                                .push(CupertinoPageRoute(
                              builder: (context) => CodeVerificationPage(
                                  verificationId: verificationId),
                            ))
                                .then((value) {
                              setState(() {
                                isLoading = false;
                              });
                              completion?.call();
                            });
                          },
                          codeAutoRetrievalTimeout: (String verificationId) {
                            // Auto retrieval timeout
                            showCupertinoDialog(
                              context: context,
                              builder: (context) => CupertinoAlertDialog(
                                title: const Text('Error'),
                                content: const Text('Verifcation timed out.'),
                                actions: [
                                  CupertinoButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                            setState(() {
                              isLoading = false;
                            });
                            completion?.call();
                          },
                        );
                    Navigator.of(context).pop(formattedNumber);
                  },
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              // ),
            );
          },
        );

        if (result == null) {
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

  Widget _buildNavigationTitle() {
    const style = TextStyle(
      color: slottedOrange,
      fontWeight: FontWeight.w700,
      fontSize: 30,
    );

    return Text(
      titleString,
      style: style,
    );
  }
}
