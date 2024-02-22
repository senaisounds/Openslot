import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/common/date_components.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:slotted/pages/event_details.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.user,
  });

  final User? user;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FocusNode searchFocus = FocusNode();
  String query = '';

  KeyboardActionsConfig _buildConfig(BuildContext context) {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      keyboardBarColor: CupertinoColors.secondarySystemBackground,
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
                  fontSize: 17,
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
        backgroundColor: CupertinoColors.systemBackground,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('events').snapshots(),
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
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }
            if (!snapshot.hasData) {
              return const Center(
                  child: CupertinoActivityIndicator(
                color: slottedOrange,
                radius: 16,
              ));
            }
            if (events.isEmpty) {
              return const Text(
                'No events found',
                style: TextStyle(
                  color: slottedOrange,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              );
            }
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
                  child: ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) =>
                        _buildListItem(context, events[index]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, Event event) {
    final dateComponents = _convertDateTimeToStringComponents(event.date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: CupertinoButton(
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.all(0),
        onPressed: () => Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) =>
                EventDetailsPage(user: widget.user, event: event),
          ),
        ),
        // color: CupertinoColors.secondaryLabel,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: slottedOrange,
            boxShadow: const [
              BoxShadow(
                color: CupertinoColors.systemGrey3,
                spreadRadius: 3,
                blurRadius: 3,
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
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            color: CupertinoColors.label),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.hostName, // Display hostname
                        style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: CupertinoColors.label),
                      ),
                    ],
                  ),
                  Column(
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
                            fontSize: 15,
                            color: CupertinoColors.label),
                      ),
                      Text(
                        dateComponents.time, // Display date and time
                        style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: CupertinoColors.label),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 36),
              Text(
                event.address, // Display address
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: CupertinoColors.label),
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
