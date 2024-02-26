import 'dart:collection';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
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
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class EventDetailsPage extends StatefulWidget {
  const EventDetailsPage(
      {super.key, required this.user, required this.initialEvent});
  final User? user;
  final Event initialEvent;

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final MapController mapController = MapController();
  bool actionPending = false;

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
        'userID': widget.user!.uid,
        'pi': json.encode(paymentIntent),
      },
    );
    print(response.body);
    return response.body;
  }

  Future<void> _reserveAction(Event event, SlottedUser slottedUser) async {
    if (widget.user != null) {
      setState(() {
        actionPending = true;
      });

      dynamic paymentIntent = '';

      final isReserved = event.attendees.contains(widget.user!.uid) ||
          event.waitlist.contains(widget.user!.uid);

      try {
        if (event.price > 0 && !isReserved) {
          paymentIntent = await StripeApi.createPaymentIntent(
            userId: widget.user!.uid,
            amount: event.price,
            currency: 'USD',
            customerId: slottedUser.customerID,
          );
          final stripeCustomerId = paymentIntent['customer'];
          final ephemeralKey =
              await StripeApi.getEphemeralKey(stripeCustomerId);

          await StripeApi.pay(
              paymentIntent: paymentIntent,
              customer: stripeCustomerId,
              ephemeralKey: ephemeralKey,
              event: event);
        }

        await reserveAction(paymentIntent, event, slottedUser);
      } catch (e) {
        showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text((e as StripeException).error.message ??
                  (e as StripeError)?.message ??
                  'There was an error processing your payment. Please try again.'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .doc('users/${widget.user!.uid}')
          .snapshots(),
      builder: (context, userSnap) {
        final slottedUser = widget.user == null || userSnap.data == null
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
                      const SizedBox(height: 16),
                      Text('Hosted by ${event.hostName}'),
                      if (event.rules.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          event.rules,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '${_convertDateTimeToStringComponents(event.date).dayFull}, ${_convertDateTimeToStringComponents(event.date).monthFull} ${_convertDateTimeToStringComponents(event.date).dayNum} at ${_convertDateTimeToStringComponents(event.date).time}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.address,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Insert map showing location
                      Expanded(
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
                                              flags:
                                                  InteractiveFlag
                                                          .all &
                                                      ~InteractiveFlag.rotate,
                                              enableMultiFingerGestureRace:
                                                  false),
                                    ),
                                    children: [
                                      TileLayer(
                                          retinaMode:
                                              RetinaMode.isHighDensity(context),
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
                                            alignment:
                                                const Alignment(0.0, -0.2),
                                            child: GestureDetector(
                                              onTap: () =>
                                                  mapController.moveAndRotate(
                                                      event.location,
                                                      mapController
                                                              .camera.zoom +
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
                                        color: CupertinoColors.systemBackground,
                                        borderRadius: BorderRadius.circular(16),
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
                                        onPressed: () => mapController.move(
                                            event.location, 16)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 66,
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
                          child: CupertinoButton(
                            color: event.attendees.contains(widget.user!.uid)
                                ? CupertinoColors.secondarySystemBackground
                                : event.waitlist.contains(widget.user!.uid)
                                    ? CupertinoColors.secondarySystemBackground
                                    : slottedOrange,
                            padding: EdgeInsets.zero,
                            onPressed: () => widget.user == null
                                ? null
                                : _reserveAction(event, slottedUser!),
                            borderRadius: BorderRadius.circular(20),
                            child: actionPending
                                ? CupertinoActivityIndicator(
                                    radius: 14,
                                    color: event.attendees
                                            .contains(widget.user!.uid)
                                        ? slottedOrange
                                        : event.waitlist
                                                .contains(widget.user!.uid)
                                            ? slottedOrange
                                            : CupertinoColors
                                                .secondarySystemBackground,
                                  )
                                : event.attendees.contains(widget.user!.uid)
                                    ? const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Reserved',
                                            style: TextStyle(
                                              color: slottedOrange,
                                              fontSize: 19,
                                              fontWeight: FontWeight.w800,
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
                                    : event.waitlist.contains(widget.user!.uid)
                                        ? const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Waitlisted',
                                                style: TextStyle(
                                                  color: slottedOrange,
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.w800,
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
                                        : event.openSpots > 0
                                            ? const Text(
                                                'Reserve',
                                                style: TextStyle(
                                                  color: CupertinoColors
                                                      .systemBackground,
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              )
                                            : const Text(
                                                'Waitlist',
                                                style: TextStyle(
                                                  color: CupertinoColors
                                                      .systemBackground,
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.w800,
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
