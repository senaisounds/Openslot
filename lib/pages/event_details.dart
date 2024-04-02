import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:latlong2/latlong.dart';
import 'package:slotted/api/stripe.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/common/date_components.dart';
import 'package:slotted/common/event_class.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:http/http.dart' as http;

class EventDetailsPage extends StatefulWidget {
  const EventDetailsPage({
    super.key,
    required this.authAction,
    required this.initialEvent,
    this.debug = false,
  });

  final Event initialEvent;
  final bool debug;
  final Future<void> Function(BuildContext, bool, Function()) authAction;

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final MapController mapController = MapController();
  bool actionPending = false;

  Future<String> reserveAction(dynamic paymentIntent, Event event,
      SlottedUser slottedUser, User user) async {
    var response = await http.post(
      Uri.parse(
          'https://us-central1-open-mic-5cc8e.cloudfunctions.net/reserveAction'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'eventID': event.id,
        'userID': user.uid,
        'pi': paymentIntent == '' ? paymentIntent : json.encode(paymentIntent),
        'debug': widget.debug ? 'true' : 'false',
      },
    );
    return response.body;
  }

  Future<void> _reserveAction(
      Event event, SlottedUser slottedUser, User user) async {
    setState(() {
      actionPending = true;
    });

    dynamic paymentIntent = '';

    final isReserved = event.attendees.contains(user?.uid);
    final isWaitlisted = event.waitlist.contains(user?.uid);

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
                      actionPending = false;
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
                    await reserveAction(
                        paymentIntent, event, slottedUser, user);
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
                    actionPending = false;
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
          userId: user.uid,
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

      await reserveAction(paymentIntent, event, slottedUser, user);
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
      actionPending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !actionPending,
      child: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          final User? user = snapshot.data;
          return StreamBuilder<DocumentSnapshot>(
            stream: user == null
                ? null
                : FirebaseFirestore.instance
                    .doc('users/${user!.uid}')
                    .snapshots(),
            builder: (context, userSnap) {
              final slottedUser = userSnap.data == null
                  ? null
                  : SlottedUser.fromDocument(userSnap.data!);
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .doc(widget.initialEvent.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  Event event;
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    event = widget.initialEvent;
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Error loading event'),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: Text('Event not found'),
                    );
                  }
                  event = Event.fromDocument(snapshot.data!);
                  return CupertinoPageScaffold(
                    resizeToAvoidBottomInset: false,
                    navigationBar: CupertinoNavigationBar(
                      border: null,
                      backgroundColor: CupertinoColors.systemBackground,
                      leading: actionPending ? const SizedBox() : null,
                      middle: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                        child: Text(
                          event.name,
                          style: const TextStyle(
                            color: slottedOrange,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    child: SafeArea(
                      child: Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 20,
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  'Hosted by ${event.hostName}',
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${_convertDateTimeToStringComponents(event.date).dayFull}, ${_convertDateTimeToStringComponents(event.date).monthFull} ${_convertDateTimeToStringComponents(event.date).dayNum} at ${_convertDateTimeToStringComponents(event.date).time}',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  event.address,
                                  textAlign: TextAlign.center,
                                ),
                                if (event.rules.isNotEmpty) ...[
                                  const SizedBox(height: 28),
                                  const Text(
                                    'Rules',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.systemBackground
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    height: 96,
                                    width:
                                        MediaQuery.of(context).size.width * 0.8,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: event.rules
                                            .split('\n')
                                            .map((rule) => Text(
                                                  rule,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 16,
                                  ),
                                ],
                                if (event.rules.isEmpty)
                                  const SizedBox(
                                    height: 32,
                                  ),
                              ],
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.width * 0.78,
                              child: SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Container(
                                    clipBehavior: Clip.hardEdge,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Stack(
                                      children: [
                                        FlutterMap(
                                          mapController: mapController,
                                          options: MapOptions(
                                            initialCenter: event.location,
                                            initialZoom: 16,
                                            minZoom: 2,
                                            maxZoom: 19,
                                            cameraConstraint:
                                                CameraConstraint.contain(
                                              bounds: LatLngBounds(
                                                const LatLng(-90, -180),
                                                const LatLng(90, 180),
                                              ),
                                            ),
                                            interactionOptions:
                                                const InteractionOptions(
                                                    flags: InteractiveFlag.all &
                                                        ~InteractiveFlag.rotate,
                                                    enableMultiFingerGestureRace:
                                                        false),
                                          ),
                                          children: [
                                            TileLayer(
                                                retinaMode:
                                                    RetinaMode.isHighDensity(
                                                        context),
                                                userAgentPackageName:
                                                    'com.M3.Open-Mic',
                                                urlTemplate:
                                                    'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}.png?api_key={api_key}',
                                                additionalOptions: const {
                                                  'api_key':
                                                      'bca0bb22-6d70-4b47-83ab-f11382d719e3'
                                                }),
                                            MarkerLayer(
                                              markers: <Marker>[
                                                Marker(
                                                  width: 56.0,
                                                  height: 56.0,
                                                  point: event.location,
                                                  alignment: const Alignment(
                                                      0.0, -0.2),
                                                  child: GestureDetector(
                                                    onTap: () => mapController
                                                        .moveAndRotate(
                                                            event.location,
                                                            mapController.camera
                                                                    .zoom +
                                                                3,
                                                            0),
                                                    child: Image.asset(
                                                      'lib/assets/images/s_pin.png',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Positioned(
                                          top: 16,
                                          right: 16,
                                          child: CupertinoButton(
                                              color: CupertinoColors
                                                  .systemBackground,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              padding: const EdgeInsets.all(4),
                                              child: const SizedBox(
                                                height: 44,
                                                width: 44,
                                                child: Icon(
                                                  CupertinoIcons.location,
                                                  color: slottedOrange,
                                                  size: 30,
                                                ),
                                              ),
                                              onPressed: () => mapController
                                                  .move(event.location, 16)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Expanded(
                              child: SizedBox(),
                            ),
                            // if (!event.attendees.contains(user?.uid) &&
                            //     !event.waitlist.contains(user?.uid))
                            Text(
                              '${event.openSlots} of ${event.slots} slots',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 66,
                              width: double.infinity,
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(22, 0, 22, 0),
                                child: CupertinoButton(
                                  color: event.live
                                      ? CupertinoColors.activeGreen
                                      : event.host == slottedUser?.id
                                          ? slottedOrange
                                          : event.attendees.contains(user?.uid)
                                              ? CupertinoColors
                                                  .secondarySystemBackground
                                              : event.waitlist
                                                      .contains(user?.uid)
                                                  ? CupertinoColors
                                                      .secondarySystemBackground
                                                  : slottedOrange,
                                  padding: EdgeInsets.zero,
                                  onPressed: () => actionPending
                                      ? null
                                      : event.live
                                          ? Navigator.of(context).pop()
                                          : event.host == slottedUser?.id ||
                                                  event.date
                                                      .isBefore(DateTime.now())
                                              ? Navigator.of(context).pop()
                                              : (slottedUser == null
                                                  ? () async {
                                                      setState(() {
                                                        actionPending = true;
                                                      });
                                                      await widget.authAction(
                                                          context, false, () {
                                                        setState(() {
                                                          actionPending = false;
                                                        });
                                                      });
                                                    }()
                                                  : _reserveAction(event,
                                                      slottedUser, user!)),
                                  borderRadius: BorderRadius.circular(20),
                                  child: actionPending
                                      ? CupertinoActivityIndicator(
                                          radius: 14,
                                          color: event.attendees
                                                  .contains(user?.uid)
                                              ? slottedOrange
                                              : event.waitlist
                                                      .contains(user?.uid)
                                                  ? slottedOrange
                                                  : CupertinoColors
                                                      .secondarySystemBackground,
                                        )
                                      : event.live
                                          ? const Text('Live',
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 20,
                                                  height: 1.2),
                                              textAlign: TextAlign.center)
                                          : event.host == slottedUser?.id ||
                                                  event.date
                                                      .isBefore(DateTime.now())
                                              ? const Text('View',
                                                  style: TextStyle(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 20,
                                                      height: 1.2),
                                                  textAlign: TextAlign.center)
                                              : event.attendees
                                                      .contains(user?.uid)
                                                  ? const Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          'Reserved',
                                                          style: TextStyle(
                                                            color:
                                                                slottedOrange,
                                                            fontSize: 19,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                          ),
                                                        ),
                                                        SizedBox(width: 12),
                                                        Icon(
                                                          CupertinoIcons
                                                              .check_mark_circled_solid,
                                                          size: 20,
                                                          color: slottedOrange,
                                                          weight: 30,
                                                        )
                                                      ],
                                                    )
                                                  : event.waitlist
                                                          .contains(user?.uid)
                                                      ? const Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              'Waitlisted',
                                                              style: TextStyle(
                                                                color:
                                                                    slottedOrange,
                                                                fontSize: 19,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                              ),
                                                            ),
                                                            SizedBox(width: 12),
                                                            Icon(
                                                              CupertinoIcons
                                                                  .check_mark_circled_solid,
                                                              size: 20,
                                                              color:
                                                                  slottedOrange,
                                                              weight: 30,
                                                            )
                                                          ],
                                                        )
                                                      : slottedUser == null
                                                          ? const Text(
                                                              'Sign in to reserve',
                                                              style: TextStyle(
                                                                color:
                                                                    CupertinoColors
                                                                        .label,
                                                                fontSize: 19,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                              ),
                                                            )
                                                          : event.openSlots > 0
                                                              ? Text(
                                                                  'Reserve - ${event.price > 0 ? '\$${event.price.toStringAsFixed(2)}' : 'FREE'}',
                                                                  style:
                                                                      const TextStyle(
                                                                    color: CupertinoColors
                                                                        .label,
                                                                    fontSize:
                                                                        20,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w800,
                                                                  ),
                                                                )
                                                              : Text(
                                                                  'Waitlist - ${event.price > 0 ? '\$${event.price.toStringAsFixed(2)}' : 'FREE'}',
                                                                  style:
                                                                      const TextStyle(
                                                                    color: CupertinoColors
                                                                        .label,
                                                                    fontSize:
                                                                        20,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w800,
                                                                  ),
                                                                ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 32,
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  DateComponents _convertDateTimeToStringComponents(DateTime date) {
    final monthFull = DateFormat.LLLL().format(date).toString();
    final monthShort = DateFormat.LLL().format(date).toString();
    final dayFull = DateFormat.EEEE().format(date).toString();
    final dayShort = DateFormat.E().format(date).toString();
    final dayNum = DateFormat.d().format(date).toString();
    final time = DateFormat.jm().format(date).toString();

    return DateComponents(
      monthFull: monthFull,
      monthShort: monthShort,
      dayFull: dayFull,
      dayShort: dayShort,
      dayNum: dayNum,
      time: time,
    );
  }
}
