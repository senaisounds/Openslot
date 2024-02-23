import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/common/date_components.dart';
import 'package:slotted/common/event_class.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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

  void _reserveAction(Event event) {
    if (widget.user != null) {
      if (event.attendees.contains(widget.user!.uid)) {
        // Unreserve
        print('Unreserve');
      } else if (event.waitlist.contains(widget.user!.uid)) {
        // Unwaitlist
        print('Unwaitlist');
      } else if (event.openSpots > 0) {
        // Reserve
        print('Reserve');
      } else {
        // Waitlist
        print('Waitlist');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            trailing: widget.user != null
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
                    child: CupertinoButton(
                      color: event.attendees.contains(widget.user!.uid)
                          ? slottedOrange
                          : event.waitlist.contains(widget.user!.uid)
                              ? slottedOrange
                              : CupertinoColors.secondarySystemBackground,
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                      onPressed: () => _reserveAction(event),
                      borderRadius: BorderRadius.circular(50),
                      child: event.attendees.contains(widget.user!.uid)
                          ? const Text(
                              'Reserved',
                              style: TextStyle(
                                color: CupertinoColors.systemBackground,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          : event.waitlist.contains(widget.user!.uid)
                              ? const Text(
                                  'Waitlisted',
                                  style: TextStyle(
                                    color: CupertinoColors.systemBackground,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                )
                              : event.openSpots > 0
                                  ? const Text(
                                      'Reserve',
                                      style: TextStyle(
                                        color: slottedOrange,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    )
                                  : const Text(
                                      'Waitlist',
                                      style: TextStyle(
                                        color: slottedOrange,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                    ),
                  )
                : null,
          ),
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
                        child: FlutterMap(
                          mapController: mapController,
                          options: MapOptions(
                            initialCenter: event.location,
                            initialZoom: 15.6,
                            minZoom: 6,
                            maxZoom: 19,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.M3.Open-Mic',
                            ),
                            MarkerLayer(
                              markers: <Marker>[
                                Marker(
                                  width: 56.0,
                                  height: 56.0,
                                  point: event.location,
                                  alignment: const Alignment(0.0, -0.2),
                                  child: GestureDetector(
                                    onTap: () => mapController.moveAndRotate(
                                        event.location,
                                        mapController.camera.zoom + 3,
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
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
