// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
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

// Create class MainNav that manages a tab controller screen with 5 routes. The middle route must point to MyHomePage.
class MainNav extends StatefulWidget {
  const MainNav({super.key, required this.user, this.debug = false});

  final User? user;
  final bool debug;

  @override
  State<MainNav> createState() => MainNavState();
}

class MainNavState extends State<MainNav> with SingleTickerProviderStateMixin {
  late final CupertinoTabController _tabController;
  late final SlottedUser? slottedUser;

  String? phoneNumber;

  bool isLoading = false;

  final double iconSize = 30;

  String titleString = 'Slotted';

  late final List<Widget> tabViews;

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

  Future<void> resAuth(Event event, SlottedUser slottedUser) async {
    setState(() {
      isLoading = true;
    });

    dynamic paymentIntent = '';

    final isReserved = event.attendees.contains(slottedUser.id);
    final isWaitlisted = event.waitlist.contains(slottedUser.id);

    if (isReserved || isWaitlisted) {
      // ignore: use_build_context_synchronously
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

                    print(e);

                    // ignore: use_build_context_synchronously
                    showCupertinoDialog(
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
        // ignore: use_build_context_synchronously
        showCupertinoDialog(
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
            debug: widget.debug),
      ),
      StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) => MyHomePage(
          debug: widget.debug,
          user: snapshot.data,
          authAction: (context, isLoggedIn, completion) =>
              _authAction(context, isLoggedIn, completion: completion),
          reserveAction: (event, slottedUser) => resAuth(event, slottedUser)
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool loggedIn = widget.user != null;
    return Stack(
      children: [
        CupertinoPageScaffold(
          resizeToAvoidBottomInset: false,
          navigationBar: CupertinoNavigationBar(
            border: null,
            backgroundColor: CupertinoColors.systemBackground,
            middle: _buildNavigationTitle(),
            leading: loggedIn
                ? CupertinoButton(
                    onPressed: isLoading ? null : () {},
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
          child: CupertinoTabScaffold(
            resizeToAvoidBottomInset: false,
            tabBar: CupertinoTabBar(
              height: 64,
              backgroundColor: CupertinoColors.secondarySystemBackground,
              activeColor: slottedOrange,
              currentIndex: _tabController.index,
              onTap: (index) {
                _tabController.index = index;
                setState(() {
                  switch (_tabController.index) {
                    case 0:
                      titleString = 'My Events';
                    case 1:
                      titleString = 'Slotted';
                    case 2:
                      titleString = 'Profile';
                    default:
                      titleString = 'Slotted';
                  }
                });
              },
              iconSize: iconSize,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.list_bullet),
                  // label: 'My Events',
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
                  // label: 'Profile',
                ),
              ],
            ),
            tabBuilder: (context, index) {
              return tabViews[index];
            },
          ),
        ),
        if (isLoading)
          const Opacity(
            opacity: 0.5,
            child: ModalBarrier(
              color: CupertinoColors.black,
              dismissible: false,
            ),
          ),
        if (isLoading)
          const Center(
            child: CupertinoActivityIndicator(
              radius: 20,
              color: CupertinoColors.black,
            ),
          ),
      ],
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
        await showCupertinoModalPopup(
          context: context,
          builder: (builder) {
            return CupertinoAlertDialog(
              title: const Text(
                'Sign In',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              content: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                child: CupertinoTextField(
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  placeholder: 'Phone Number',
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      phoneNumber = value;
                    });
                  },
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
                    if (phoneNumber == null || phoneNumber!.isEmpty) {
                      return;
                    }
                    final formattedNumber =
                        '+1${phoneNumber!.replaceAll(RegExp(r'[^0-9]'), '')}';
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
                    Navigator.of(context).pop(phoneNumber);
                  },
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            );
          },
        );

        if (phoneNumber == null) {
          setState(() {
            isLoading = false;
          });
          completion?.call();
        }
      }
    } catch (e) {
      print(e);
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
