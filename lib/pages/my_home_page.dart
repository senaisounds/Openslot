import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:slotted/api/stripe.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/common/date_components.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:slotted/pages/event_details.dart';
import 'package:http/http.dart' as http;
import 'package:slotted/pages/countdown_timer.dart';
import 'package:slotted/pages/live.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage(
      {super.key,
      this.debug = false,
      required this.user,
      required this.authAction,
      required this.reserveAction});

  final bool debug;
  final User? user;
  final Future<void> Function(BuildContext, bool, Function()) authAction;
  final Future<void> Function(Event event, SlottedUser slottedUser)
      reserveAction;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FocusNode searchFocus = FocusNode();
  String query = '';
  bool actionPending = false;

  KeyboardActionsConfig _buildConfig(BuildContext context) {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      keyboardBarColor: CupertinoColors.secondaryLabel.withOpacity(1),
      nextFocus: false,
      actions: [
        KeyboardActionsItem(focusNode: searchFocus, toolbarButtons: [
          (node) {
            return CupertinoButton(
              padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
              onPressed: () {
                node.unfocus();
                setState(() {});
              },
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

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchFocus.hasFocus || query.isNotEmpty;
    return KeyboardActions(
      config: _buildConfig(context),
      disableScroll: true,
      child: CupertinoPageScaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: CupertinoColors.systemBackground,
        child: StreamBuilder<DocumentSnapshot>(
          stream: widget.user == null
              ? null
              : FirebaseFirestore.instance
                  .doc('users/${widget.user!.uid}')
                  .snapshots(),
          builder: (context, snapshot) {
            final SlottedUser? slottedUser =
                snapshot.data == null || widget.user == null
                    ? null
                    : SlottedUser.fromDocument(snapshot.data!);
            return StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('events').snapshots(),
              builder: (context, snapshot) {
                final events = snapshot.hasData
                    ? (_convertQuerySnapshotToEvents(snapshot.data!)
                          ..sort((event_0, event_1) {
                            if (event_0.ended != event_1.ended) {
                              return event_1.ended ? -1 : 1;
                            } else if (event_0.date == event_1.date) {
                              return event_1.name.compareTo(event_0.name);
                            }
                            return event_1.date.compareTo(event_0.date);
                          }))
                        .where((event) =>
                            event.name
                                .toLowerCase()
                                .contains(query.toLowerCase()) ||
                            event.address
                                .toLowerCase()
                                .contains(query.toLowerCase()) ||
                            event.hostName
                                .toLowerCase()
                                .contains(query.toLowerCase()))
                        .toList()
                    : [];
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: CupertinoTextField(
                        onTap: () {
                          setState(() {});
                        },
                        onChanged: (query) {
                          setState(() {
                            this.query = query;
                          });
                        },
                        onEditingComplete: () {
                          setState(() {});
                        },
                        onTapOutside: (event) {
                          setState(() {});
                        },
                        clearButtonMode: OverlayVisibilityMode.editing,
                        focusNode: searchFocus,
                        placeholder: 'Search',
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(
                            CupertinoIcons.search,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSearching
                                ? slottedOrange
                                : CupertinoColors.systemGrey,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 222),
                        child: snapshot.hasError
                            ? Center(
                                child: Text('Error: ${snapshot.error}'),
                              )
                            : !snapshot.hasData
                                ? const Center(
                                    child: CupertinoActivityIndicator(
                                    color: slottedOrange,
                                    radius: 16,
                                  ))
                                : events.isEmpty
                                    ? const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            'No events found',
                                            style: TextStyle(
                                              color: slottedOrange,
                                              fontSize: 21,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      )
                                    : ListView.builder(
                                        itemCount: events.length,
                                        itemBuilder: (context, index) =>
                                            _buildListItem(context,
                                                events[index], slottedUser),
                                      ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
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
            builder: (context) => event.live
                ? LivePage(
                    event: event,
                    debug: widget.debug,
                    user: widget.user,
                    authAction: widget.authAction,
                    reserveAction: widget.reserveAction,
                  )
                : EventDetailsPage(
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
                        onPressed: event.live
                            ? () => Navigator.of(context).push(
                                  CupertinoPageRoute(
                                    builder: (context) => LivePage(
                                      event: event,
                                      debug: widget.debug,
                                      user: widget.user,
                                      authAction: widget.authAction,
                                      reserveAction: widget.reserveAction,
                                    ),
                                  ),
                                )
                            : slottedUser == null
                                ? () => widget.authAction(context, false, () {})
                                : () =>
                                    widget.reserveAction(event, slottedUser),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: event.live
                                ? CupertinoColors.systemGreen
                                : slottedUser == null
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
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: event.live
                                    ? CupertinoColors.systemGreen
                                    : slottedUser == null
                                        ? CupertinoColors.label
                                        : event.attendees
                                                .contains(slottedUser.id)
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
                          child: event.live
                              ? const Text('Live',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20,
                                      height: 1.2),
                                  textAlign: TextAlign.center)
                              : slottedUser == null
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
                                                  : event.waitlist.contains(
                                                          slottedUser.id)
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
                                          : event.waitlist
                                                  .contains(slottedUser.id)
                                              ? 'Waitlisted'
                                              : event.attendees.length <
                                                      event.slots
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
