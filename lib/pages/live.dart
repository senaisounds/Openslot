import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:slotted/pages/event_details.dart';

const placeholderImage =
    'https://upload.wikimedia.org/wikipedia/commons/c/cd/Portrait_Placeholder_Square.png';

class LivePage extends StatefulWidget {
  const LivePage({
    super.key,
    required this.event,
    this.debug = false,
    required this.user,
    required this.authAction,
    required this.reserveAction,
  });

  final bool debug;
  final User? user;
  final Future<void> Function(BuildContext, bool, Function()) authAction;
  final Future<void> Function(Event event, SlottedUser slottedUser)
      reserveAction;

  final Event event;

  @override
  LivePageState createState() => LivePageState();
}

class LivePageState extends State<LivePage> {
  Duration duration = const Duration(seconds: 60); // Set duration of the timer
  Timer? timer;

  @override
  void initState() {
    super.initState();
  }

  void startTimer() {
    timer =
        Timer.periodic(const Duration(microseconds: 1), (_) => setCountdown());
  }

  void setCountdown() {
    const reduceMicroSecondsBy = 10;
    setState(() {
      final seconds = duration.inMicroseconds - reduceMicroSecondsBy;
      if (seconds < 0) {
        timer?.cancel();
      } else {
        duration = Duration(microseconds: seconds);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text(
              "${widget.event.timeLimit == 0 ? '∞' : "${widget.event.timeLimit}m"} Time Limit"),
          onPressed: () {},
        ),
      ),
      child: SafeArea(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .doc('events/${widget.event.id}')
              .snapshots(),
          builder: (context, snapshot) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: CircularProgressIndicator(
                        value: (60000 - duration.inMilliseconds) / 60000,
                        strokeWidth: 6,
                        backgroundColor: Colors.grey,
                        valueColor: const AlwaysStoppedAnimation(Colors.orange),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            // "0:00",
                            '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 24),
                          ),
                          const Text(
                            'Performing Now',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 24),
                          ),
                        ],
                      ),
                    ),
                    // Text(
                    //   '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                    //   style: const TextStyle(
                    //     fontWeight: FontWeight.bold,
                    //     fontSize: 20,
                    //   ),
                    // ),
                  ],
                ),
              ),
              // Padding(
              //   padding: EdgeInsets.symmetric(horizontal: 16.0),
              //   child: Text("Performing Now"),
              // ),
              // if (event.rules.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(
                widget.event.name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info),
                    SizedBox(width: 8),
                    Text("Details"),
                  ],
                ),
                onPressed: () => Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => EventDetailsPage(
                      initialEvent: widget.event,
                      debug: widget.debug,
                      authAction: widget.authAction,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (widget.event.rules.isNotEmpty) ...[
                const Text(
                  'Rules',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  height: 96,
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: widget.event.rules
                          .split('\n')
                          .map((rule) => Text(
                                rule,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w600),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
              const SizedBox(
                height: 4,
              ),
              // ],
              // if (event.rules.isEmpty)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  clipBehavior: Clip.hardEdge,
                  // padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: CupertinoColors.secondaryLabel,
                      ),
                      color: CupertinoColors.secondaryLabel),
                  child: ListView.builder(
                    itemCount: widget.event.attendees
                        .length, // replace with your dynamic size
                    itemBuilder: (context, index) {
                      return FutureBuilder(
                        future: FirebaseFirestore.instance
                            .doc('users/${widget.event.attendees[index]}')
                            .get(),
                        builder: (context, snapshot) {
                          return CupertinoListTile(
                            onTap: () => {},
                            leading: CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(
                                snapshot.data != null
                                    ? snapshot.data!['photoUrl'] as String? ??
                                        placeholderImage
                                    : placeholderImage,
                              ),
                            ),
                            title: Text(
                              snapshot.data != null
                                  ? snapshot.data!['username'] as String? ??
                                      'Anonymous'
                                  : 'Anonymous',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            // subtitle: Text("W W W W"),
                            // trailing: ElevatedButton(
                            //   onPressed: () {
                            //     // Handle start
                            //   },
                            //   child: Text("Start"),
                            // ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 84,
                padding: const EdgeInsets.fromLTRB(8, 24, 8, 0),
                child: CupertinoButton(
                  borderRadius: BorderRadius.circular(20),
                  onPressed: () {
                    // Handle start event
                  },
                  color: slottedOrange,
                  child: const Text(
                    "Start Event",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 21,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
