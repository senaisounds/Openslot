// ignore_for_file: use_build_context_synchronously

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
  Timer? timer;

  @override
  initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 1), (timer) {
      setState(() {});
    });
  }

  @override
  dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _adjustTimeLimit(
      Event event, BuildContext context, String currentTime) async {
    final TextEditingController controller = TextEditingController();
    controller.text = currentTime;

    await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Time Limit"),
        content: Column(
          children: [
            const Text(
                "Set the time limit for your participants.\n For unlimited time set 0"),
            const SizedBox(height: 8),
            CupertinoTextField(
              autofocus: true,
              controller: controller,
              keyboardType: TextInputType.number,
              placeholder: "Minutes",
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: const Text("Set"),
            onPressed: () async {
              final int timeLimit = int.tryParse(controller.text) ?? 0;
              await FirebaseFirestore.instance
                  .doc('events/${widget.event.id}')
                  .update({
                'timeLimit': timeLimit,
                'performerStart':
                    event.performerStart != null ? DateTime.now() : null,
              });
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _stopPerforming() async {
    await FirebaseFirestore.instance.doc('events/${widget.event.id}').update({
      'performerStart': null,
    });
  }

  Future<void> _startPerforming() async {
    await FirebaseFirestore.instance.doc('events/${widget.event.id}').update({
      'performerStart': DateTime.now(),
    });
  }

  Future<void> _lineupPerformer(Event event, String? currentPerformer,
      String performer, String username) async {
    bool isCurrentPerformer = currentPerformer == performer;
    final confirmation = await showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title:
                Text(isCurrentPerformer ? "Edit Performer?" : "Next Performer"),
            content: Column(
              children: [
                const SizedBox(height: 8),
                Text(isCurrentPerformer
                    ? "$username is currently performing what would you like to do?"
                    : "Is $username performing now?"),
              ],
            ),
            actions: [
              if ((event.performerStart != null && event.timeLimit != 0) ||
                  !isCurrentPerformer)
                CupertinoDialogAction(
                  child: Text(isCurrentPerformer ? "Restart" : "No"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              if (isCurrentPerformer && event.performerStart == null) ...[
                CupertinoDialogAction(
                  child: Text(isCurrentPerformer ? "Cancel" : "Yes"),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                CupertinoDialogAction(
                  child: const Text("Remove"),
                  onPressed: () => Navigator.of(context).pop(false),
                )
              ],
              if (isCurrentPerformer && event.performerStart != null) ...[
                CupertinoDialogAction(
                  child: const Text("Remove"),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                CupertinoDialogAction(
                  child: Text(isCurrentPerformer ? "Cancel" : "Yes"),
                  onPressed: () => Navigator.of(context).pop(true),
                )
              ],
              if (!isCurrentPerformer) ...[
                CupertinoDialogAction(
                  child: Text(isCurrentPerformer ? "Cancel" : "Yes"),
                  onPressed: () => Navigator.of(context).pop(true),
                )
              ],
            ],
          );
        });
    switch (confirmation) {
      case true:
        if (!isCurrentPerformer) {
          await FirebaseFirestore.instance
              .doc('events/${widget.event.id}')
              .update({
            'performer': performer,
            'performerStart': null,
          });
        }
        break;
      case null:
        if (isCurrentPerformer) {
          await FirebaseFirestore.instance
              .doc('events/${widget.event.id}')
              .update({
            'performerStart':
                event.performerStart != null ? DateTime.now() : null,
          });
        }
      case false:
        await FirebaseFirestore.instance
            .doc('events/${widget.event.id}')
            .update({
          'performer': null,
          'performerStart': null,
        });
        break;
      default:
        break;
    }
  }

  Future<void> _endEvent() async {
    final confirmation = await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("End Event"),
        content: const Column(
          children: [
            SizedBox(height: 8),
            Text("Are you sure you want to end this event?"),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: const Text("End"),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmation != true) {
      return;
    }

    await FirebaseFirestore.instance.doc('events/${widget.event.id}').update({
      'live': false,
      'ended': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      initialData: widget.event,
      stream: FirebaseFirestore.instance
          .doc('events/${widget.event.id}')
          .snapshots(),
      builder: (context, snapshot) {
        final event = snapshot.data != null
            ? snapshot.data! is DocumentSnapshot
                ? Event.fromDocument(snapshot.data! as DocumentSnapshot)
                : snapshot.data! as Event
            : widget.event;
        final bool isHost = event.host == widget.user?.uid;
        final duration = event.performerStart != null
            ? event.performerStart!
                .add(Duration(minutes: event.timeLimit))
                .difference(DateTime.now())
            : Duration.zero;
        return CupertinoPageScaffold(
          resizeToAvoidBottomInset: false,
          navigationBar: CupertinoNavigationBar(
            backgroundColor: Colors.transparent,
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: event.ended
                  ? null
                  : isHost
                      ? () => _adjustTimeLimit(
                          event, context, event.timeLimit.toString())
                      : null,
              child: Text(
                "${event.timeLimit == 0 ? '∞' : "${event.timeLimit}m"} Time Limit",
                style: const TextStyle(color: slottedOrange),
              ),
            ),
          ),
          child: SafeArea(
            child: FutureBuilder(
              future: event.performer == null
                  ? null
                  : FirebaseFirestore.instance
                      .doc('users/${event.performer}')
                      .get(),
              builder: (context, snapshot) {
                final username = event.performer != null &&
                        snapshot.data != null
                    ? snapshot.data!['username'] as String? ?? event.performer!
                    : 'No Performer';
                final photoUrl = event.performer != null &&
                        snapshot.data != null
                    ? snapshot.data!['photoUrl'] as String? ?? placeholderImage
                    : '';

                final progress = event.performerStart != null
                    ? 1 -
                        (DateTime.now()
                                .difference(event.performerStart!)
                                .inMilliseconds /
                            (event.timeLimit * 60000))
                    : 1.0;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: photoUrl != ''
                                ? BoxDecoration(
                                    image: DecorationImage(
                                      colorFilter: const ColorFilter.mode(
                                        CupertinoColors.secondaryLabel,
                                        // slottedOrange,
                                        BlendMode.darken,
                                      ),
                                      opacity: 0.5,
                                      image: CachedNetworkImageProvider(
                                        photoUrl,
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                    // color: CupertinoColors.black,
                                    borderRadius: BorderRadius.circular(120),
                                  )
                                : null,
                            width: 240,
                            height: 240,
                            child: CircularProgressIndicator(
                              value: event.performer == null ||
                                      event.timeLimit == 0 ||
                                      event.performerStart == null
                                  ? 1
                                  : progress,
                              strokeWidth: 6,
                              strokeCap: StrokeCap.round,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation(
                                  event.performer != null
                                      ? slottedOrange
                                      : CupertinoColors.secondaryLabel),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  event.performerStart == null
                                      ? event.timeLimit == 0
                                          ? '∞'
                                          : "${event.timeLimit}:00"
                                      : progress > 0
                                          ? '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}'
                                          : event.timeLimit == 0
                                              ? '∞'
                                              : '0:00',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28,
                                    color: event.performer != null
                                        ? CupertinoColors.white
                                        : CupertinoColors.systemGrey,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (event.performer != null)
                                  Text(
                                    username,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                if (event.performer == null)
                                  Text(
                                    'No Performer',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                      color: event.performerStart != null
                                          ? CupertinoColors.systemGreen
                                          : CupertinoColors.systemGrey,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      event.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    // const SizedBox(height: ),
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
                            initialEvent: event,
                            debug: widget.debug,
                            authAction: widget.authAction,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (event.rules.isNotEmpty) ...[
                      const Text(
                        'Rules',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color:
                              CupertinoColors.systemBackground.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        height: 72,
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: event.rules
                                .split('\n')
                                .map((rule) => Text(
                                      rule,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600),
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
                          itemCount: event.attendees
                              .length, // replace with your dynamic size
                          itemBuilder: (context, index) {
                            return Column(children: [
                              FutureBuilder(
                                future: FirebaseFirestore.instance
                                    .doc('users/${event.attendees[index]}')
                                    .get(),
                                builder: (context, snapshot) {
                                  final username = snapshot.data != null
                                      ? snapshot.data!['username'] as String? ??
                                          event.attendees[index]
                                      : 'Anonymous';
                                  final photoUrl = snapshot.data != null
                                      ? snapshot.data!['photoUrl'] as String? ??
                                          placeholderImage
                                      : placeholderImage;
                                  return CupertinoListTile(
                                    onTap: event.host != widget.user?.uid ||
                                            event.ended ||
                                            !event.live
                                        ? null
                                        : () {
                                            _lineupPerformer(
                                                event,
                                                event.performer,
                                                event.attendees[index],
                                                username);
                                          },
                                    padding: const EdgeInsets.all(16),
                                    leading: CircleAvatar(
                                      backgroundImage:
                                          CachedNetworkImageProvider(
                                        photoUrl,
                                      ),
                                    ),
                                    title: Text(
                                      username,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    // subtitle: Text("W W W W"),
                                    trailing: event.performer ==
                                            event.attendees[index]
                                        ? const Text(
                                            "Performing",
                                            style: TextStyle(
                                              color: slottedOrange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  );
                                },
                              ),
                              if (index < event.attendees.length - 1)
                                const Divider(
                                  height: 0,
                                  thickness: 0,
                                  color: CupertinoColors.systemGrey,
                                  // indent: 12,
                                  // endIndent: 12,
                                ),
                            ]);
                          },
                        ),
                      ),
                    ),
                    if (isHost)
                      Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: 84,
                        padding: const EdgeInsets.fromLTRB(8, 24, 8, 0),
                        child: Row(
                          children: [
                            if (event.live) ...[
                              Expanded(
                                // flex: 2,
                                child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  minSize: 58,
                                  borderRadius: BorderRadius.circular(20),
                                  onPressed: () => _endEvent(),
                                  color: CupertinoColors.systemRed,
                                  child: const Icon(
                                    CupertinoIcons.stop_circle_fill,
                                    size: 32,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24)
                            ],
                            Expanded(
                              flex: 4,
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                minSize: 58,
                                borderRadius: BorderRadius.circular(20),
                                onPressed: event.live
                                    ? (event.performer != null
                                        ? event.performerStart != null
                                            ? _stopPerforming
                                            : _startPerforming
                                        : null)
                                    : !event.ended
                                        ? event.date.isBefore(DateTime.now())
                                            ? () async {
                                                await FirebaseFirestore.instance
                                                    .doc('events/${event.id}')
                                                    .update({
                                                  'live': true,
                                                });
                                              }
                                            : null
                                        : null,
                                color: slottedOrange,
                                child: Text(
                                  event.live
                                      ? event.performer != null
                                          ? event.performerStart != null
                                              ? "Stop Performing"
                                              : "Start Performing"
                                          : "No Performer"
                                      : !event.ended
                                          ? event.date.isBefore(DateTime.now())
                                              ? "Start Event"
                                              : "Upcoming"
                                          : "Event Ended",
                                  style: TextStyle(
                                    color: event.live
                                        ? event.performer != null
                                            ? Colors.black
                                            : CupertinoColors.systemGrey
                                        : !event.ended
                                            ? event.date
                                                    .isBefore(DateTime.now())
                                                ? Colors.black
                                                : CupertinoColors.systemGrey
                                            : CupertinoColors.systemGrey,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
