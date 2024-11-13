import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/common/date_components.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:slotted/pages/edit_event.dart';
import 'package:slotted/pages/event_details.dart';
import 'package:slotted/pages/live.dart';
import 'package:slotted/pages/profile.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage(
      {super.key,
      this.debug = false,
      required this.user,
      required this.authAction,
      required this.reserveAction,
      required this.deleteEvent});

  final bool debug;
  final User? user;
  final Future<void> Function(BuildContext, bool, Function()) authAction;
  final Future<void> Function(Event event, SlottedUser slottedUser)
      reserveAction;
  final Future<void> Function(String) deleteEvent;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FocusNode searchFocus = FocusNode();
  String query = '';
  bool actionPending = false;
  String headerTitle = 'UPCOMING';
  final ScrollController eventsScrollController = ScrollController();

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

  // @override
  // void initState() {
  //   eventsScrollController.addListener(() {
  //     // set headerTitle based on the date of the first event in view
  //     if (eventsScrollController.position.atEdge) {
  //       if (eventsScrollController.position.pixels == 0) {
  //         // Top of the list
  //         setState(() {
  //         headerTitle = 'UPCOMING';
  //         });
  //       } else {
  //         // Bottom of the list
  //         setState(() {
  //         headerTitle = 'PAST';
  //         });
  //       }
  //     } else {
  //       // Scrolling in between
  //       final firstVisibleEventIndex = eventsScrollController
  //         .position.minScrollExtent.toInt() ~/ 100; // Assuming each event takes 100 pixels
  //       final firstVisibleEvent = [firstVisibleEventIndex];
  //       final dateComponents =
  //         _convertDateTimeToStringComponents(firstVisibleEvent.date);
  //       setState(() {
  //         headerTitle = dateComponents.dayFull;
  //       });
  //     }
  //   });
  //   super.initState();
  // }

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
                if (!snapshot.hasData) {
                  return const Center(
                    child: CupertinoActivityIndicator(
                      color: slottedOrange,
                      radius: 16,
                    ),
                  );
                }

                final events = _convertQuerySnapshotToEvents(snapshot.data!)
                  ..sort((event_0, event_1) {
                    return event_0.date.compareTo(event_1.date);
                  });

                final filteredEvents = events.where((event) {
                  final lowerQuery = query.toLowerCase();
                  return event.name.toLowerCase().contains(lowerQuery) ||
                      event.address.toLowerCase().contains(lowerQuery) ||
                      event.hostName.toLowerCase().contains(lowerQuery);
                }).toList();

                final now = DateTime.now();
                final todayEvents = filteredEvents.where((event) {
                  return (event.date.day == now.day &&
                          event.date.month == now.month &&
                          event.date.year == now.year &&
                          !event.ended) ||
                      event.live;
                }).toList();

                final tomorrow = now.add(const Duration(days: 1));
                final tomorrowEvents = filteredEvents.where((event) {
                  return event.date.day == tomorrow.day &&
                      event.date.month == tomorrow.month &&
                      event.date.year == tomorrow.year &&
                      !event.ended;
                }).toList();

                final upcomingEvents = filteredEvents.where((event) {
                  return !todayEvents.contains(event) &&
                      !tomorrowEvents.contains(event) &&
                      !event.ended;
                }).toList();

                final endedEvents =
                    filteredEvents.where((event) => event.ended).toList();

                return ListView(
                  controller: eventsScrollController,
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'lib/assets/images/default_featured.jpg', // Replace with your image path
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (todayEvents.isNotEmpty) ...[
                      _buildHeader('Today'),
                      ...todayEvents.map((event) =>
                          _buildListItem(context, event, slottedUser)),
                    ],
                    if (tomorrowEvents.isNotEmpty) ...[
                      _buildHeader('Tomorrow'),
                      ...tomorrowEvents.map((event) =>
                          _buildListItem(context, event, slottedUser)),
                    ],
                    if (upcomingEvents.isNotEmpty) ...[
                      _buildHeader('Upcoming'),
                      ...upcomingEvents.map((event) =>
                          _buildListItem(context, event, slottedUser)),
                    ],
                    if (endedEvents.isNotEmpty) ...[
                      _buildHeader('Ended'),
                      ...endedEvents.map((event) =>
                          _buildListItem(context, event, slottedUser)),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        title,
        style: const TextStyle(
          color: slottedOrange,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String? _getEventHeader(Event event) {
    final now = DateTime.now();
    if (event.ended) {
      return 'Ended';
    } else if (event.date.day == now.day &&
        event.date.month == now.month &&
        event.date.year == now.year) {
      return 'Today';
    } else if (event.date.day == now.add(const Duration(days: 1)).day &&
        event.date.month == now.add(const Duration(days: 1)).month &&
        event.date.year == now.add(const Duration(days: 1)).year) {
      return 'Tomorrow';
    } else if (event.date.isAfter(now)) {
      return 'Upcoming';
    }
    return null;
  }

  Widget _buildListItem(
      BuildContext context, Event event, SlottedUser? slottedUser) {
    final dateComponents = _convertDateTimeToStringComponents(event.date);

    final cellChild = CupertinoButton(
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(0),
      onPressed: () => Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => LivePage(
            event: event,
            debug: widget.debug,
            user: widget.user,
            authAction: widget.authAction,
            reserveAction: widget.reserveAction,
          ),
          // event.live || event.ended || event.host != slottedUser?.id
          //     ? LivePage(
          //         event: event,
          //         debug: widget.debug,
          //         user: widget.user,
          //         authAction: widget.authAction,
          //         reserveAction: widget.reserveAction,
          //       )
          //     : EventDetailsPage(
          //         initialEvent: event,
          //         debug: widget.debug,
          //         authAction: widget.authAction,
          //       ),
        ),
      ),
      // color: CupertinoColors.systemBackground,
      // color: slottedOrange,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // Shimmering slottedOrange and systemGrey gradient
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.4, 0.8, 1.0],
            colors: event.ended
                ? [
                    CupertinoColors.systemGrey
                        .withRed(CupertinoColors.systemGrey.red + 1)
                        .withGreen(CupertinoColors.systemGrey.green + 1)
                        .withBlue(CupertinoColors.systemGrey.blue + 1)
                        .withOpacity(0.9),
                    CupertinoColors.systemGrey.withOpacity(0.7),
                    CupertinoColors.systemGrey
                        .withRed(CupertinoColors.systemGrey.red + 1)
                        .withGreen(CupertinoColors.systemGrey.green + 1)
                        .withBlue(CupertinoColors.systemGrey.blue + 1)
                        .withOpacity(0.9),
                    CupertinoColors.systemGrey.withOpacity(0.8),
                  ]
                : [
                    slottedOrange
                        .withRed(slottedOrange.red + 1)
                        .withGreen(slottedOrange.green + 1)
                        .withBlue(slottedOrange.blue + 1)
                        .withOpacity(0.9),
                    slottedOrange.withOpacity(0.7),
                    slottedOrange
                        .withRed(slottedOrange.red + 1)
                        .withGreen(slottedOrange.green + 1)
                        .withBlue(slottedOrange.blue + 1)
                        .withOpacity(0.9),
                    slottedOrange.withOpacity(0.8),
                    // CupertinoColors.black.withOpacity(0.5),
                    // slottedOrange.withOpacity(0.4),
                    // CupertinoColors.white.withOpacity(0.8),
                    // slottedOrange.withOpacity(0.8),
                  ],
          ),
          borderRadius: BorderRadius.circular(12),
          // color: slottedOrange.withOpacity(1),
          boxShadow: [
            BoxShadow(
              color: event.ended
                  ? CupertinoColors.systemGrey.withOpacity(0.4)
                  : slottedOrange.withOpacity(0.4),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        event.name, // Display title
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 21,
                            color: CupertinoColors.label),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Host: ${event.hostName}', // Display hostname
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: CupertinoColors.label),
                      ),
                    ],
                  ),
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
                  color: CupertinoColors.label,
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
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .doc('users/$attendee')
                                  .get(),
                              initialData: null,
                              builder: (context, docSnapshot) {
                                return FutureBuilder<String>(
                                  future: FirebaseStorage.instance
                                      .ref('profileImgs')
                                      .child('$attendee.png')
                                      .getDownloadURL(),
                                  initialData: placeholderImage,
                                  builder: (context, snapshot) {
                                    return Transform.translate(
                                      offset: Offset(index * -20.0,
                                          0), // Adjust the overlap by changing this value
                                      child: CupertinoButton(
                                        onPressed: (docSnapshot.data?.exists ??
                                                    false) !=
                                                true
                                            ? () => showCupertinoDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      CupertinoAlertDialog(
                                                    title: const Text('🧍'),
                                                    content: Text(
                                                        '$attendee does not have an account'),
                                                    actions: [
                                                      CupertinoDialogAction(
                                                        child: const Text(
                                                            'Dismiss'),
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                            : () => Navigator.of(context).push(
                                                  CupertinoPageRoute(
                                                    builder: (context) =>
                                                        CupertinoPageScaffold(
                                                      resizeToAvoidBottomInset:
                                                          false,
                                                      backgroundColor:
                                                          CupertinoColors
                                                              .systemBackground,
                                                      navigationBar:
                                                          const CupertinoNavigationBar(
                                                        middle: Text(
                                                            "Performer's Profile"),
                                                        backgroundColor:
                                                            CupertinoColors
                                                                .secondarySystemBackground,
                                                      ),
                                                      child: ProfilePage(
                                                        debug: widget.debug,
                                                        user: widget.user,
                                                        authAction:
                                                            (loggedIn) => widget
                                                                .authAction(
                                                                    context,
                                                                    loggedIn,
                                                                    () {}),
                                                        viewUser:
                                                            docSnapshot.data ==
                                                                    null
                                                                ? null
                                                                : attendee,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                        padding: EdgeInsets.zero,
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          clipBehavior: Clip.hardEdge,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(32),
                                            border: Border.all(
                                                color:
                                                    snapshot.connectionState ==
                                                            ConnectionState.done
                                                        ? Colors.black
                                                        : Colors.transparent,
                                                width: 1.5,
                                                strokeAlign: BorderSide
                                                    .strokeAlignOutside),
                                          ),
                                          child: CachedNetworkImage(
                                            fit: BoxFit.fill,
                                            imageUrl: (snapshot
                                                            .connectionState ==
                                                        ConnectionState.done &&
                                                    snapshot.hasData)
                                                ? snapshot.data.toString()
                                                : placeholderImage,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        )
                        .values
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
                      maxLines: 3,
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
                      onPressed: event.live ||
                              event.ended ||
                              event.date.isBefore(DateTime.now())
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
                          : event.host == slottedUser?.id
                              ? () => Navigator.of(context).push(
                                    CupertinoPageRoute(
                                      builder: (context) => EditEventPage(
                                        user: slottedUser,
                                        event: event,
                                      ),
                                    ),
                                  )
                              : slottedUser == null
                                  ? () =>
                                      widget.authAction(context, false, () {})
                                  : () =>
                                      widget.reserveAction(event, slottedUser),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: event.live
                              ? CupertinoColors.systemGreen
                              : event.host == slottedUser?.id &&
                                      event.host.isNotEmpty &&
                                      (slottedUser?.id ?? '').isNotEmpty
                                  ? event.date.isBefore(DateTime.now())
                                      ? event.ended
                                          ? CupertinoColors.systemGrey
                                          : CupertinoColors.white
                                              .withOpacity(0.8)
                                      : CupertinoColors.systemBlue
                                          .withBlue(
                                              CupertinoColors.systemBlue.blue -
                                                  40)
                                          .withRed(
                                              CupertinoColors.systemBlue.red +
                                                  40)
                                          .withGreen(
                                              CupertinoColors.systemBlue.green -
                                                  40)
                                          .withOpacity(0.8)
                                  : event.ended
                                      ? CupertinoColors.systemGrey
                                      : CupertinoColors.label,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: event.ended
                                  ? CupertinoColors.black
                                  : event.live
                                      ? CupertinoColors.systemGreen
                                          .withBlue(CupertinoColors.systemGreen.blue -
                                              40)
                                          .withRed(CupertinoColors.systemGreen.red -
                                              40)
                                          .withGreen(CupertinoColors.systemGreen.green -
                                              40)
                                      : event.host == slottedUser?.id
                                          ? slottedOrange
                                              .withBlue(slottedOrange.blue - 40)
                                              .withRed(slottedOrange.red - 40)
                                              .withGreen(
                                                  slottedOrange.green - 40)
                                          : slottedUser == null
                                              ? CupertinoColors.label
                                              : event.attendees
                                                      .contains(slottedUser.id)
                                                  ? CupertinoColors.label
                                                  : event.waitlist.contains(
                                                          slottedUser.id)
                                                      ? CupertinoColors.label
                                                      : event.attendees.length <
                                                              event.slots
                                                          ? slottedOrange
                                                              .withBlue(slottedOrange.blue - 40)
                                                              .withRed(slottedOrange.red - 40)
                                                              .withGreen(slottedOrange.green - 40)
                                                          : slottedOrange,
                              spreadRadius: 1,
                              blurRadius: 1,
                            ),
                          ],
                        ),
                        width: 100,
                        height: 44,
                        child: event.live
                            ? const Text(
                                'Live',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              )
                            : event.date.isBefore(DateTime.now())
                                ? Text(
                                    event.host == slottedUser?.id &&
                                            !event.ended
                                        ? 'Start'
                                        : event.ended
                                            ? 'Ended'
                                            : 'View',
                                    style: TextStyle(
                                      color: event.host == slottedUser?.id &&
                                              !event.ended
                                          ? Colors.black
                                          : event.ended
                                              ? Colors.black
                                              : Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20,
                                      height: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                : event.host == slottedUser?.id
                                    ? Text(
                                        event.ended
                                            ? 'View'
                                            : event.date
                                                    .isBefore(DateTime.now())
                                                ? 'Start'
                                                : 'Edit',
                                        style: TextStyle(
                                            color: slottedUser?.id == event.host
                                                ? Colors.black
                                                : Colors.white,
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
                                                    : event.attendees.contains(
                                                            slottedUser.id)
                                                        ? 14.5
                                                        : event.waitlist
                                                                .contains(
                                                                    slottedUser
                                                                        .id)
                                                            ? 14.5
                                                            : event.attendees
                                                                        .length <
                                                                    event.slots
                                                                ? 18
                                                                : 18,
                                                height: 1.2),
                                            textAlign: TextAlign.center,
                                          )
                                        : Text(
                                            event.attendees
                                                    .contains(slottedUser.id)
                                                ? 'Reserved'
                                                : event.waitlist.contains(
                                                        slottedUser.id)
                                                    ? 'Waitlisted'
                                                    : event.attendees.length <
                                                            event.slots
                                                        ? 'Reserve\n${event.price > 0 ? '\$${event.price.toStringAsFixed(2)}' : 'Free'}'
                                                        : 'Waitlist\n\$${event.price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                                color: !event.date
                                                        .isAfter(DateTime.now())
                                                    ? Colors.white
                                                    : event.attendees.contains(
                                                            slottedUser.id)
                                                        ? slottedOrange
                                                        : event.waitlist
                                                                .contains(
                                                                    slottedUser
                                                                        .id)
                                                            ? slottedOrange
                                                            : event.attendees
                                                                        .length <
                                                                    event.slots
                                                                ? CupertinoColors
                                                                    .white
                                                                : CupertinoColors
                                                                    .white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: event.attendees
                                                        .contains(
                                                            slottedUser.id)
                                                    ? 16
                                                    : event.waitlist.contains(
                                                            slottedUser.id)
                                                        ? 16
                                                        : event.attendees
                                                                    .length <
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
    );

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: slottedUser?.id == event.host
            ? Dismissible(
                key: Key(event.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  padding: const EdgeInsets.fromLTRB(0, 0, 30, 0),
                  alignment: Alignment.centerRight,
                  // color: CupertinoColors.systemRed,
                  child: const Icon(
                    CupertinoIcons.trash,
                    color: CupertinoColors.systemRed,
                  ),
                ),
                confirmDismiss: (direction) {
                  return showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text('Delete Event'),
                      content: const Text(
                          'Are you sure you want to delete this event?'),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                        CupertinoDialogAction(
                          child: const Text('Delete'),
                          onPressed: () async {
                            widget.deleteEvent(event.id);
                            Navigator.of(context).pop(true);
                          },
                        ),
                      ],
                    ),
                  );
                },
                child: cellChild,
              )
            : cellChild);
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
