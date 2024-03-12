import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/common/date_components.dart';
import 'package:slotted/common/event_class.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:slotted/pages/event_details.dart';

class MyEventsPage extends StatefulWidget {
  const MyEventsPage(
      {super.key,
      required this.user,
      required this.authAction,
      required this.reserveAction,
      this.debug = false});

  final User? user;
  final bool debug;

  final Future<void> Function(BuildContext, bool, Function()) authAction;
  final Future<void> Function(Event event, SlottedUser slottedUser)
      reserveAction;

  @override
  MyEventsPageState createState() => MyEventsPageState();
}

class MyEventsPageState extends State<MyEventsPage> {
  int eventMode = 0;

  @override
  Widget build(BuildContext context) {
    final bool loggedIn = widget.user != null;
    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: CupertinoColors.systemBackground,
      child: StreamBuilder<DocumentSnapshot>(
        stream: widget.user == null
            ? null
            : FirebaseFirestore.instance
                .doc('users/${widget.user!.uid}')
                .snapshots(),
        builder: (context, snapshot) {
          final SlottedUser? slottedUser = snapshot.data != null
              ? SlottedUser.fromDocument(snapshot.data!)
              : null;
          return Center(
            child: snapshot.connectionState == ConnectionState.waiting
                ? Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      // color: CupertinoColors.black.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const CircularProgressIndicator(
                      strokeCap: StrokeCap.round,
                      backgroundColor: CupertinoColors.systemOrange,
                      strokeAlign: -8,
                      strokeWidth: 5,
                      color: slottedOrange,
                    ),
                  )
                : widget.user == null
                    ? CupertinoButton(
                        child: const Text('Sign In'),
                        onPressed: () =>
                            widget.authAction(context, loggedIn, () {}),
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (slottedUser!.isHost) ...[
                              CupertinoSegmentedControl(
                                children: {
                                  0: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(
                                      'Attending',
                                      style: TextStyle(
                                          color:
                                              CupertinoColors.systemBackground,
                                          fontWeight: eventMode == 0
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          fontSize: eventMode == 0 ? 18 : 17),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  1: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(
                                      'Hosting',
                                      style: TextStyle(
                                          color:
                                              CupertinoColors.systemBackground,
                                          fontWeight: eventMode == 1
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          fontSize: eventMode == 1 ? 18 : 17),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                },
                                onValueChanged: (value) {
                                  setState(() {
                                    eventMode = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 12)
                            ],
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream: eventMode == 0
                                    ? FirebaseFirestore.instance
                                        .collection('events')
                                        .where('attendees',
                                            arrayContains: widget.user!.uid)
                                        .snapshots()
                                    : FirebaseFirestore.instance
                                        .collection('events')
                                        .where('host',
                                            isEqualTo: widget.user!.uid)
                                        .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    final events =
                                        _convertQuerySnapshotToEvents(
                                            snapshot.data!)
                                          ..sort((event_0, event_1) {
                                            if (event_0.ended !=
                                                event_1.ended) {
                                              return event_1.ended ? -1 : 1;
                                            } else if (event_0.date ==
                                                event_1.date) {
                                              return event_1.name
                                                  .compareTo(event_0.name);
                                            }
                                            return event_1.date
                                                .compareTo(event_0.date);
                                          });
                                    if (events.isEmpty) {
                                      return const Text('No events found');
                                    }
                                    return ListView.builder(
                                      padding: const EdgeInsets.only(top: 4),
                                      itemCount: events.length,
                                      itemBuilder: (context, index) =>
                                          _buildListItem(context, events[index],
                                              slottedUser),
                                    );
                                  } else if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  } else {
                                    return const CupertinoActivityIndicator(
                                      radius: 20,
                                      color: slottedOrange,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
          );
        },
      ),
    );
  }

  Widget _buildListItem(
      BuildContext context, Event event, SlottedUser? slottedUser) {
    final dateComponents = _convertDateTimeToStringComponents(event.date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: CupertinoButton(
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.all(0),
        onPressed: () => Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => EventDetailsPage(
              initialEvent: event,
              debug: widget.debug,
              authAction: widget.authAction,
            ),
          ),
        ),
        color: CupertinoColors.systemBackground,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: CupertinoColors.systemBackground,
            boxShadow: const [
              BoxShadow(
                color: slottedOrange,
                spreadRadius: 3,
                blurRadius: 9,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name, // Display title
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 21,
                            color: CupertinoColors.label),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.hostName, // Display hostname
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: CupertinoColors.label),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 18, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${dateComponents.monthShort} ${dateComponents.dayNum}', // Display date and time
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: CupertinoColors.label),
                        ),
                        Text(
                          dateComponents.dayFull, // Display date and time
                          style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: CupertinoColors.label),
                        ),
                        Text(
                          dateComponents.time, // Display date and time
                          style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: CupertinoColors.label),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (event.attendees.isNotEmpty) ...[
                const Text(
                  'Attendees',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 6),
                  height: 54,
                  // width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      // color: CupertinoColors.systemGrey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    // Build a row of slightly overlapping profile images for the attendees that are going
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: event.attendees
                          .sublist(0, min(10, event.attendees.length))
                          .asMap()
                          .map(
                            (index, attendee) => MapEntry(
                              index,
                              FutureBuilder<String>(
                                future: FirebaseStorage.instance
                                    .ref('profileImgs')
                                    .child('$attendee.png')
                                    .getDownloadURL(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                          ConnectionState.done &&
                                      snapshot.hasData) {
                                    return Transform.translate(
                                      offset: Offset(index * -20.0,
                                          0), // Adjust the overlap by changing this value
                                      child: CupertinoButton(
                                        onPressed: () => {},
                                        padding: EdgeInsets.zero,
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          clipBehavior: Clip.hardEdge,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(32),
                                            border: Border.all(
                                                color: Colors.black,
                                                width: 3,
                                                strokeAlign: BorderSide
                                                    .strokeAlignOutside),
                                          ),
                                          child: CachedNetworkImage(
                                            fit: BoxFit.fill,
                                            imageUrl: snapshot.data.toString(),
                                          ),
                                        ),
                                      ),
                                    );
                                  } else {
                                    return const SizedBox(width: 0);
                                  }
                                },
                              ),
                            ),
                          )
                          .values
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                    child: SizedBox(
                      width: 222,
                      child: Text(
                        event.address, // Display address
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: CupertinoColors.label,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: slottedUser == null
                            ? () => widget.authAction(context, false, () {})
                            : () => widget.reserveAction(event, slottedUser),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: slottedUser == null
                                ? CupertinoColors.label
                                : event.attendees.contains(slottedUser.id)
                                    ? CupertinoColors.label
                                    : event.waitlist.contains(slottedUser.id)
                                        ? CupertinoColors.label
                                        : event.attendees.length < event.slots
                                            ? slottedOrange
                                            : slottedOrange,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: slottedUser == null
                                    ? CupertinoColors.label
                                    : event.attendees.contains(slottedUser.id)
                                        ? CupertinoColors.label
                                        : event.waitlist
                                                .contains(slottedUser.id)
                                            ? CupertinoColors.label
                                            : event.attendees.length <
                                                    event.slots
                                                ? slottedOrange
                                                : slottedOrange,
                                spreadRadius: 1,
                                blurRadius: 1,
                              ),
                            ],
                          ),
                          width: 100,
                          height: 44,
                          child: slottedUser == null
                              ? Text(
                                  'Reserve\n${event.price > 0 ? '\$${event.price.toStringAsFixed(2)}' : 'Free'}',
                                  style: TextStyle(
                                      color: slottedOrange,
                                      fontWeight: FontWeight.w700,
                                      fontSize: slottedUser == null
                                          ? 14.5
                                          : event.attendees
                                                  .contains(slottedUser.id)
                                              ? 14.5
                                              : event.waitlist
                                                      .contains(slottedUser.id)
                                                  ? 14.5
                                                  : event.attendees.length <
                                                          event.slots
                                                      ? 18
                                                      : 18,
                                      height: 1.2),
                                  textAlign: TextAlign.center,
                                )
                              : Text(
                                  event.attendees.contains(slottedUser.id)
                                      ? 'Reserved'
                                      : event.waitlist.contains(slottedUser.id)
                                          ? 'Waitlisted'
                                          : event.attendees.length < event.slots
                                              ? 'Reserve\n${event.price > 0 ? '\$${event.price.toStringAsFixed(2)}' : 'Free'}'
                                              : 'Waitlist\n\$${event.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      color: event.attendees
                                              .contains(slottedUser.id)
                                          ? slottedOrange
                                          : event.waitlist
                                                  .contains(slottedUser.id)
                                              ? slottedOrange
                                              : event.attendees.length <
                                                      event.slots
                                                  ? CupertinoColors.label
                                                  : CupertinoColors.label,
                                      fontWeight: FontWeight.w700,
                                      fontSize: event.attendees
                                              .contains(slottedUser.id)
                                          ? 16
                                          : event.waitlist
                                                  .contains(slottedUser.id)
                                              ? 16
                                              : event.attendees.length <
                                                      event.slots
                                                  ? 14.5
                                                  : 14.5,
                                      height: 1.2),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                      if (!event.attendees.contains(slottedUser?.id) &&
                          !event.waitlist.contains(slottedUser?.id)) ...[
                        const SizedBox(height: 12),
                        Text(
                          '${event.slots - event.attendees.length} of ${event.slots} slots',
                          style: const TextStyle(
                            color: CupertinoColors.label,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editEvent(Event event) {
    print(event.name);
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

  List<Event> _convertQuerySnapshotToEvents(QuerySnapshot snapshot) {
    // Convert to a list of Event objects
    final snapshotDocuments =
        snapshot.docs.map((document) => document).toList();

    final events = snapshotDocuments.map((document) {
      return Event.fromDocument(document);
    }).toList()
      ..removeWhere((event) => event.id == '');

    return events;
  }
}
