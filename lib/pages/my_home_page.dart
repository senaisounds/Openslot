import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/common/date_components.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';

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
  @override
  Widget build(BuildContext context) {
    // final bool loggedIn = widget.user != null;
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('default').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final events = _convertQuerySnapshotToEvents(snapshot.data!)
              ..sort((event_0, event_1) {
                if (event_0.ended != event_1.ended) {
                  return event_1.ended ? -1 : 1;
                } else if (event_0.dateTime == event_1.dateTime) {
                  return event_1.venueName.compareTo(event_0.venueName);
                }
                return event_1.dateTime.compareTo(event_0.dateTime);
              });
            return ListView.builder(
              padding: const EdgeInsets.only(top: 4),
              itemCount: events.length,
              itemBuilder: (context, index) =>
                  _buildListItem(context, events[index]),
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }

  Widget _buildListItem(BuildContext context, Event event) {
    final dateComponents = _convertDateTimeToStringComponents(event.dateTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: CupertinoButton(
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.all(0),
        onPressed: () => _tappedEvent(event),
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
                blurRadius: 12,
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
                          event.venueName, // Display title
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

  void _tappedEvent(Event event) {
    print(event.venueName);
  }

  DateComponents _convertDateTimeToStringComponents(double dateTime) {
    final date = DateTime.fromMillisecondsSinceEpoch((dateTime * 1000).toInt());
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
