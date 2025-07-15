// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:slotted/common/event_class.dart' as EventClass;
import 'package:slotted/common/slotted_user.dart';
import 'package:slotted/pages/edit_event.dart';
import 'package:slotted/pages/live.dart';
import 'package:slotted/widgets/enhanced_event_card.dart';
// import 'package:slotted/common/design_system.dart'; // Will be used for other improvements
import 'package:slotted/widgets/ds_button.dart';
import 'package:slotted/widgets/ds_section_header.dart';

class MyEventsPage extends StatefulWidget {
  const MyEventsPage(
      {super.key,
      required this.user,
      required this.authAction,
      required this.reserveAction,
      required this.deleteEvent,
      this.debug = false});

  final User? user;
  final bool debug;

  final Future<void> Function(BuildContext, bool, Function()) authAction;
  final Future<void> Function(EventClass.Event event, SlottedUser slottedUser)
      reserveAction;
  final Future<void> Function(String eventId) deleteEvent;

  @override
  MyEventsPageState createState() => MyEventsPageState();
}

class MyEventsPageState extends State<MyEventsPage> {
  int eventMode = 0;
  String headerTitle = 'UPCOMING';
  final ScrollController eventsScrollController = ScrollController();

  final Color complementaryColor = CupertinoColors.systemTeal;



  @override
  Widget build(BuildContext context) {
    final bool loggedIn = widget.user != null;
    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: CupertinoColors.black,
          ),
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
                          // color: CupertinoColors.black.withValues(opacity: 0.9),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: CircularProgressIndicator(
                          strokeCap: StrokeCap.round,
                          backgroundColor: CupertinoColors.systemOrange,
                          strokeAlign: -8,
                          strokeWidth: 5,
                          color: complementaryColor,
                        ),
                      )
                    : widget.user == null
                        ? CupertinoButton(
                            child: const Text('Sign In'),
                            onPressed: () =>
                                widget.authAction(context, loggedIn, () {}),
                          )
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(4, 24, 4, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [

                                if (slottedUser!.isHost) ...[
                                  // Tab Bar Section
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.black,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: complementaryColor.withValues(alpha: 0.3),
                                            spreadRadius: 2,
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                      child: CupertinoSegmentedControl(
                                        selectedColor: Colors.transparent,
                                        borderColor: Colors.transparent,
                                        pressedColor: Colors.transparent,
                                        unselectedColor: Colors.transparent,
                                        children: {
                                          0: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 12),
                                            child: Text(
                                              'Attending',
                                              style: TextStyle(
                                                  color: eventMode == 1 &&
                                                          slottedUser.isHost
                                                      ? CupertinoColors
                                                          .systemBackground
                                                      : complementaryColor,
                                                  fontWeight: eventMode == 1 &&
                                                          slottedUser.isHost
                                                      ? FontWeight.w500
                                                      : FontWeight.w700,
                                                  fontSize: 16),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          1: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 12),
                                            child: Text(
                                              'Hosting',
                                              style: TextStyle(
                                                  color: eventMode == 1 &&
                                                          slottedUser.isHost
                                                      ? complementaryColor
                                                      : CupertinoColors
                                                          .systemBackground,
                                                  fontWeight: eventMode == 1 &&
                                                          slottedUser.isHost
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                  fontSize: 16),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        },
                                        onValueChanged: (value) {
                                          if (value == eventMode) return;
                                          setState(() {
                                            eventMode = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  
                                  // Create Event Button Section
                                  if (slottedUser.isHost) ...[
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                                      child: DSPrimaryButton(
                                        text: 'Create Event',
                                        icon: CupertinoIcons.add_circled,
                                        onPressed: () => Navigator.of(context).push(
                                          CupertinoPageRoute(
                                            builder: (context) => EditEventPage(
                                              user: slottedUser,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                                Expanded(
                                  child: StreamBuilder<QuerySnapshot>(
                                    stream: eventMode == 1 && slottedUser.isHost
                                        ? FirebaseFirestore.instance
                                            .collection('events')
                                            .where('host',
                                                isEqualTo: widget.user!.uid)
                                            .snapshots()
                                        : FirebaseFirestore.instance
                                            .collection('events')
                                            .where('attendees',
                                                arrayContains: widget.user!.uid)
                                            .snapshots(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return Center(
                                          child: CupertinoActivityIndicator(
                                            color: complementaryColor,
                                            radius: 16,
                                          ),
                                        );
                                      }
                                      if (snapshot.hasData) {
                                        final events =
                                            _convertQuerySnapshotToEvents(
                                                snapshot.data!)
                                          ..sort((event_0, event_1) {
                                            return event_0.date
                                                .compareTo(event_1.date);
                                          });
                                        final now = DateTime.now();
                                        final todayEvents = events.where((event) {
                                          return (event.date.day == now.day &&
                                                  event.date.month == now.month &&
                                                  event.date.year == now.year &&
                                                  !event.ended) ||
                                              event.live;
                                        }).toList();

                                        final tomorrow =
                                            now.add(const Duration(days: 1));
                                        final tomorrowEvents =
                                            events.where((event) {
                                          return event.date.day == tomorrow.day &&
                                              event.date.month ==
                                                  tomorrow.month &&
                                              event.date.year == tomorrow.year &&
                                              !event.ended;
                                        }).toList();

                                        final upcomingEvents =
                                            events.where((event) {
                                          return !todayEvents.contains(event) &&
                                              !tomorrowEvents.contains(event) &&
                                              !event.ended;
                                        }).toList();

                                        final endedEvents = events
                                            .where((event) => event.ended)
                                            .toList();

                                        if (events.isEmpty) {
                                          return Padding(
                                            padding: const EdgeInsets.all(32),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  eventMode == 1 
                                                    ? CupertinoIcons.calendar_badge_plus
                                                    : CupertinoIcons.tickets,
                                                  size: 64,
                                                  color: CupertinoColors.systemGrey,
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  eventMode == 1 
                                                    ? 'No events hosted yet'
                                                    : 'No events attended yet',
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w600,
                                                    color: CupertinoColors.systemGrey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  eventMode == 1 
                                                    ? 'Start creating amazing events!'
                                                    : 'Discover events to attend!',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: CupertinoColors.systemGrey2,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                        return ListView(
                                          controller: eventsScrollController,
                                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                          children: [
                                            if (todayEvents.isNotEmpty) ...[
                                              _buildHeader('Today'),
                                              const SizedBox(height: 8),
                                              ...todayEvents.map((event) =>
                                                  _buildListItem(context, event,
                                                      slottedUser)),
                                              const SizedBox(height: 16),
                                            ],
                                            if (tomorrowEvents.isNotEmpty) ...[
                                              _buildHeader('Tomorrow'),
                                              const SizedBox(height: 8),
                                              ...tomorrowEvents.map((event) =>
                                                  _buildListItem(context, event,
                                                      slottedUser)),
                                              const SizedBox(height: 16),
                                            ],
                                            if (upcomingEvents.isNotEmpty) ...[
                                              _buildHeader('Upcoming'),
                                              const SizedBox(height: 8),
                                              ...upcomingEvents.map((event) =>
                                                  _buildListItem(context, event,
                                                      slottedUser)),
                                              const SizedBox(height: 16),
                                            ],
                                            if (endedEvents.isNotEmpty) ...[
                                              _buildHeader('Ended'),
                                              const SizedBox(height: 8),
                                              ...endedEvents.map((event) =>
                                                  _buildListItem(context, event,
                                                      slottedUser)),
                                            ],
                                          ],
                                        );
                                      } else if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      } else {
                                        return CupertinoActivityIndicator(
                                          radius: 20,
                                          color: complementaryColor,
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
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    IconData headerIcon;
    switch (title.toLowerCase()) {
      case 'today':
        headerIcon = CupertinoIcons.clock;
        break;
      case 'tomorrow':
        headerIcon = CupertinoIcons.calendar_today;
        break;
      case 'upcoming':
        headerIcon = CupertinoIcons.calendar;
        break;
      case 'ended':
        headerIcon = CupertinoIcons.checkmark_circle;
        break;
      default:
        headerIcon = CupertinoIcons.calendar;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
      child: DSSectionHeader(
        title: title,
        icon: headerIcon,
        showBorder: true,
      ),
    );
  }

  Widget _buildListItem(
      BuildContext context, EventClass.Event event, SlottedUser? slottedUser) {
    // Create the enhanced event card that matches the home page design
    final eventCard = EnhancedEventCard(
      event: event,
      currentUser: slottedUser,
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => LivePage(
            event: event,
            debug: widget.debug,
            user: widget.user,
            authAction: widget.authAction,
            reserveAction: widget.reserveAction,
          ),
        ),
      ),
      onReserve: (EventClass.Event eventToReserve) async {
        if (slottedUser != null) {
          await widget.reserveAction(eventToReserve, slottedUser);
        }
      },
      customMargin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
    );

    // Add dismissible functionality for hosts only
    return slottedUser?.id == event.host
          ? Dismissible(
              key: Key(event.id),
              direction: DismissDirection.endToStart,
              background: Container(
                padding: const EdgeInsets.fromLTRB(0, 0, 30, 0),
                alignment: Alignment.centerRight,
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
            child: eventCard,
          )
        : eventCard;
  }



  List<EventClass.Event> _convertQuerySnapshotToEvents(QuerySnapshot snapshot) {
    // Convert to a list of Event objects
    final snapshotDocuments =
        snapshot.docs.map((document) => document).toList();

    final events = snapshotDocuments.map((document) {
      return EventClass.Event.fromDocument(document);
    }).toList()
      ..removeWhere((event) => event.id == '');

    return events;
  }


}
