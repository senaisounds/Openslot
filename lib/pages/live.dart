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
import 'package:slotted/pages/profile.dart';
import 'package:torch_light/torch_light.dart';

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
  bool _isFlashlightOn = false;

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
            title: Text(
                isCurrentPerformer ? "Change Performer?" : "Next Performer"),
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
              if (performer != username) ...[
                CupertinoDialogAction(
                  child: const Text("View Profile"),
                  onPressed: () => Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => CupertinoPageScaffold(
                        resizeToAvoidBottomInset: false,
                        backgroundColor: CupertinoColors.systemBackground,
                        navigationBar: const CupertinoNavigationBar(
                          middle: Text("Performer's Profile"),
                          backgroundColor:
                              CupertinoColors.secondarySystemBackground,
                        ),
                        child: ProfilePage(
                          debug: widget.debug,
                          user: widget.user,
                          authAction: (loggedIn) =>
                              widget.authAction(context, loggedIn, () {}),
                          viewUser: performer,
                        ),
                      ),
                    ),
                  ),
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

  Future<void> _removePerformer(String performerId) async {
    final confirmation = await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Remove Performer"),
        content: const Text("Are you sure you want to remove this performer?"),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            child: const Text("Remove"),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmation == true) {
      widget.event.attendees.remove(performerId);
      widget.event.reservationTimestamps.remove(performerId);
      await FirebaseFirestore.instance.doc('events/${widget.event.id}').update({
        'attendees': widget.event.attendees,
        'reservationTimestamps': widget.event.reservationTimestamps,
      });
      setState(() {});
    }
  }

  Future<void> _toggleFlashlight() async {
    try {
      if (_isFlashlightOn) {
        await TorchLight.disableTorch();
      } else {
        await TorchLight.enableTorch();
      }
      setState(() {
        _isFlashlightOn = !_isFlashlightOn;
      });
    } catch (e) {
      // Handle errors, e.g., device doesn't have a flashlight
      print('Error toggling flashlight: $e');
    }
  }

  String _formatTimeSince(DateTime timestamp) {
    final duration = DateTime.now().difference(timestamp);
    if (duration.inSeconds < 60) {
      return duration.inSeconds == 0 ? 'Now' : '${duration.inSeconds}s ago';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ago';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}h ago';
    } else if (duration.inDays < 7) {
      return '${duration.inDays}d ago';
    } else if (duration.inDays < 365) {
      return '${(duration.inDays / 7).floor()}w ago';
    } else {
      return '${(duration.inDays / 365).floor()}y ago';
    }
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
            child: Stack(
              children: [
                FutureBuilder(
                  future: event.performer == null
                      ? null
                      : FirebaseFirestore.instance
                          .doc('users/${event.performer}')
                          .get(),
                  builder: (context, snapshot) {
                    final username = snapshot.hasError
                        ? ''
                        : event.performer != null
                            ? snapshot.data?.exists ?? false
                                ? snapshot.data?.get('username') as String? ??
                                    event.performer!
                                : event.performer!
                            : 'No Performer';
                    final photoUrl = snapshot.hasError
                        ? ''
                        : event.performer != null
                            ? snapshot.data?.exists ?? false
                                ? snapshot.data?.get('photoUrl') as String? ??
                                    placeholderImage
                                : placeholderImage
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
                                        borderRadius:
                                            BorderRadius.circular(120),
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
                        const SizedBox(height: 12),
                        const Text("EXAMPLE"),
                        const SizedBox(height: 12),
                        Text(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                              color: CupertinoColors.systemBackground
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            height: 72,
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
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
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: CupertinoColors.secondaryLabel,
                                ),
                                color: CupertinoColors.secondaryLabel),
                            child: Column(
                              children: [
                                if (event.host == widget.user?.uid)
                                  CupertinoButton(
                                    padding: const EdgeInsets.all(8),
                                    onPressed: () async {
                                      final TextEditingController controller =
                                          TextEditingController();

                                      await showCupertinoDialog(
                                        context: context,
                                        builder: (context) =>
                                            CupertinoAlertDialog(
                                          title: const Text("Add Performer"),
                                          content: Column(
                                            children: [
                                              Text(
                                                  "\n${event.slots - event.attendees.length <= 0 ? 'Current available slots = 0, adding a performer will increase available slots +1' : 'Enter performer\'s name'}"),
                                              const SizedBox(height: 8),
                                              CupertinoTextField(
                                                autofocus: true,
                                                controller: controller,
                                                placeholder: "Name",
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            CupertinoDialogAction(
                                              child: const Text("Cancel"),
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                            ),
                                            CupertinoDialogAction(
                                              child: const Text("Add"),
                                              onPressed: () async {
                                                final newName =
                                                    controller.text.trim();
                                                if (newName.isNotEmpty &&
                                                    !widget.event.attendees
                                                        .contains(newName)) {
                                                  setState(() {
                                                    widget.event.attendees
                                                        .add(newName);
                                                    widget.event
                                                            .reservationTimestamps[
                                                        newName] = DateTime.now();
                                                  });
                                                  if (event.slots -
                                                          event.attendees
                                                              .length <=
                                                      0) {
                                                    await FirebaseFirestore
                                                        .instance
                                                        .doc(
                                                            'events/${widget.event.id}')
                                                        .update({
                                                      'slots': event.slots + 1,
                                                      'attendees': widget
                                                          .event.attendees,
                                                      'reservationTimestamps':
                                                          widget.event
                                                              .reservationTimestamps,
                                                    });
                                                  } else {
                                                    await FirebaseFirestore
                                                        .instance
                                                        .doc(
                                                            'events/${widget.event.id}')
                                                        .update({
                                                      'attendees': widget
                                                          .event.attendees,
                                                      'reservationTimestamps':
                                                          widget.event
                                                              .reservationTimestamps,
                                                    });
                                                  }

                                                  Navigator.of(context).pop();
                                                } else {
                                                  // Show an error message if the name is empty or already exists
                                                  showCupertinoDialog(
                                                    context: context,
                                                    builder: (context) =>
                                                        CupertinoAlertDialog(
                                                      title:
                                                          const Text("Error"),
                                                      content: const Text(
                                                          "This performer is already added or the name is empty."),
                                                      actions: [
                                                        CupertinoDialogAction(
                                                          child:
                                                              const Text("OK"),
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(CupertinoIcons.add_circled),
                                        SizedBox(width: 8),
                                        Text("Add Performer"),
                                      ],
                                    ),
                                  ),
                                Expanded(
                                  child: widget.user?.uid == event.host
                                      ? ReorderableListView.builder(
                                          onReorder: (oldIndex, newIndex) {
                                            if (newIndex > oldIndex) {
                                              newIndex -= 1;
                                            }
                                            setState(() {
                                              final List<String>
                                                  updatedAttendees = List.from(
                                                      widget.event.attendees);
                                              final String movedPerformer =
                                                  updatedAttendees
                                                      .removeAt(oldIndex);
                                              updatedAttendees.insert(
                                                  newIndex, movedPerformer);
                                              widget.event.attendees =
                                                  updatedAttendees;
                                            });
                                            // Perform async update after setState
                                            FirebaseFirestore.instance
                                                .doc(
                                                    'events/${widget.event.id}')
                                                .update({
                                              'attendees':
                                                  widget.event.attendees,
                                            });
                                          },
                                          itemCount:
                                              widget.event.attendees.length,
                                          itemBuilder: (context, index) {
                                            final performerId =
                                                widget.event.attendees[index];
                                            return Dismissible(
                                              key: ValueKey(performerId),
                                              direction:
                                                  DismissDirection.startToEnd,
                                              onDismissed: (direction) {
                                                _removePerformer(performerId);
                                              },
                                              background: Container(
                                                color:
                                                    CupertinoColors.systemRed,
                                                alignment: Alignment.centerLeft,
                                                padding: const EdgeInsets.only(
                                                    left: 20),
                                                child: const Icon(
                                                    CupertinoIcons.delete,
                                                    color:
                                                        CupertinoColors.white),
                                              ),
                                              child: FutureBuilder(
                                                future: FirebaseFirestore
                                                    .instance
                                                    .doc('users/$performerId')
                                                    .get(),
                                                builder: (context, snapshot) {
                                                  final username = snapshot
                                                          .hasError
                                                      ? ''
                                                      : snapshot.data?.exists ??
                                                              false
                                                          ? snapshot.data?.get(
                                                                      'username')
                                                                  as String? ??
                                                              performerId
                                                          : performerId;
                                                  final photoUrl = snapshot
                                                              .data?.exists ??
                                                          false
                                                      ? snapshot.data?.get(
                                                                  'photoUrl')
                                                              as String? ??
                                                          placeholderImage
                                                      : placeholderImage;
                                                  return CupertinoListTile(
                                                    onTap: isHost &&
                                                            !widget
                                                                .event.ended &&
                                                            widget.event.live
                                                        ? () {
                                                            _lineupPerformer(
                                                                widget.event,
                                                                widget.event
                                                                    .performer,
                                                                performerId,
                                                                username);
                                                          }
                                                        : (snapshot.data?.exists ??
                                                                    false) !=
                                                                true
                                                            ? () =>
                                                                showCupertinoDialog(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (context) =>
                                                                          CupertinoAlertDialog(
                                                                    title:
                                                                        const Text(
                                                                            '🧍'),
                                                                    content: Text(
                                                                        '$performerId does not have an account'),
                                                                    actions: [
                                                                      CupertinoDialogAction(
                                                                        child: const Text(
                                                                            'Dismiss'),
                                                                        onPressed:
                                                                            () =>
                                                                                Navigator.of(context).pop(),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                )
                                                            : () =>
                                                                Navigator.of(
                                                                        context)
                                                                    .push(
                                                                  CupertinoPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            CupertinoPageScaffold(
                                                                      resizeToAvoidBottomInset:
                                                                          false,
                                                                      backgroundColor:
                                                                          CupertinoColors
                                                                              .systemBackground,
                                                                      navigationBar:
                                                                          const CupertinoNavigationBar(
                                                                        middle:
                                                                            Text("Performer's Profile"),
                                                                        backgroundColor:
                                                                            CupertinoColors.secondarySystemBackground,
                                                                      ),
                                                                      child:
                                                                          ProfilePage(
                                                                        debug: widget
                                                                            .debug,
                                                                        user: widget
                                                                            .user,
                                                                        authAction: (loggedIn) => widget.authAction(
                                                                            context,
                                                                            loggedIn,
                                                                            () {}),
                                                                        viewUser: snapshot.data ==
                                                                                null
                                                                            ? null
                                                                            : performerId,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    leading: CircleAvatar(
                                                      backgroundImage:
                                                          CachedNetworkImageProvider(
                                                              photoUrl),
                                                    ),
                                                    title: Text(
                                                      username,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    trailing: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        if (widget.event
                                                                    .reservationTimestamps[
                                                                performerId] !=
                                                            null)
                                                          Text(
                                                            _formatTimeSince(widget
                                                                    .event
                                                                    .reservationTimestamps[
                                                                performerId]!),
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  CupertinoColors
                                                                      .systemGrey,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        const SizedBox(
                                                            width: 8),
                                                        if (isHost)
                                                          const Icon(
                                                              CupertinoIcons
                                                                  .bars),
                                                        if (widget.event
                                                                .performer ==
                                                            performerId)
                                                          const Text(
                                                            "Performing",
                                                            style: TextStyle(
                                                              color:
                                                                  slottedOrange,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                        )
                                      : ListView.builder(
                                          itemCount:
                                              widget.event.attendees.length,
                                          itemBuilder: (context, index) {
                                            final performerId =
                                                widget.event.attendees[index];
                                            return Dismissible(
                                              key: ValueKey(performerId),
                                              direction:
                                                  DismissDirection.startToEnd,
                                              onDismissed: (direction) {
                                                _removePerformer(performerId);
                                              },
                                              background: Container(
                                                color:
                                                    CupertinoColors.systemRed,
                                                alignment: Alignment.centerLeft,
                                                padding: const EdgeInsets.only(
                                                    left: 20),
                                                child: const Icon(
                                                    CupertinoIcons.delete,
                                                    color:
                                                        CupertinoColors.white),
                                              ),
                                              child: FutureBuilder(
                                                future: FirebaseFirestore
                                                    .instance
                                                    .doc('users/$performerId')
                                                    .get(),
                                                builder: (context, snapshot) {
                                                  final username = snapshot
                                                          .hasError
                                                      ? ''
                                                      : snapshot.data?.exists ??
                                                              false
                                                          ? snapshot.data?.get(
                                                                      'username')
                                                                  as String? ??
                                                              performerId
                                                          : performerId;
                                                  final photoUrl = snapshot
                                                              .data?.exists ??
                                                          false
                                                      ? snapshot.data?.get(
                                                                  'photoUrl')
                                                              as String? ??
                                                          placeholderImage
                                                      : placeholderImage;
                                                  return CupertinoListTile(
                                                    onTap: isHost &&
                                                            !widget
                                                                .event.ended &&
                                                            widget.event.live
                                                        ? () {
                                                            _lineupPerformer(
                                                                widget.event,
                                                                widget.event
                                                                    .performer,
                                                                performerId,
                                                                username);
                                                          }
                                                        : (snapshot.data?.exists ??
                                                                    false) !=
                                                                true
                                                            ? () =>
                                                                showCupertinoDialog(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (context) =>
                                                                          CupertinoAlertDialog(
                                                                    title:
                                                                        const Text(
                                                                            '🧍'),
                                                                    content: Text(
                                                                        '$performerId does not have an account'),
                                                                    actions: [
                                                                      CupertinoDialogAction(
                                                                        child: const Text(
                                                                            'Dismiss'),
                                                                        onPressed:
                                                                            () =>
                                                                                Navigator.of(context).pop(),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                )
                                                            : () =>
                                                                Navigator.of(
                                                                        context)
                                                                    .push(
                                                                  CupertinoPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            CupertinoPageScaffold(
                                                                      resizeToAvoidBottomInset:
                                                                          false,
                                                                      backgroundColor:
                                                                          CupertinoColors
                                                                              .systemBackground,
                                                                      navigationBar:
                                                                          const CupertinoNavigationBar(
                                                                        middle:
                                                                            Text("Performer's Profile"),
                                                                        backgroundColor:
                                                                            CupertinoColors.secondarySystemBackground,
                                                                      ),
                                                                      child:
                                                                          ProfilePage(
                                                                        debug: widget
                                                                            .debug,
                                                                        user: widget
                                                                            .user,
                                                                        authAction: (loggedIn) => widget.authAction(
                                                                            context,
                                                                            loggedIn,
                                                                            () {}),
                                                                        viewUser: snapshot.data ==
                                                                                null
                                                                            ? null
                                                                            : performerId,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    leading: CircleAvatar(
                                                      backgroundImage:
                                                          CachedNetworkImageProvider(
                                                              photoUrl),
                                                    ),
                                                    title: Text(
                                                      username,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    trailing: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        if (widget.event
                                                                    .reservationTimestamps[
                                                                performerId] !=
                                                            null)
                                                          Text(
                                                            _formatTimeSince(widget
                                                                    .event
                                                                    .reservationTimestamps[
                                                                performerId]!),
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  CupertinoColors
                                                                      .systemGrey,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        const SizedBox(
                                                            width: 8),
                                                        if (isHost)
                                                          const Icon(
                                                              CupertinoIcons
                                                                  .bars),
                                                        if (widget.event
                                                                .performer ==
                                                            performerId)
                                                          const Text(
                                                            "Performing",
                                                            style: TextStyle(
                                                              color:
                                                                  slottedOrange,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
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
                                            ? event.date.isBefore(
                                                        DateTime.now()) &&
                                                    event.attendees.isNotEmpty
                                                ? () async {
                                                    await FirebaseFirestore
                                                        .instance
                                                        .doc(
                                                            'events/${event.id}')
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
                                              ? event.date
                                                      .isBefore(DateTime.now())
                                                  ? "Start Event"
                                                  : "Upcoming"
                                              : "Event Ended",
                                      style: TextStyle(
                                        color: event.live
                                            ? event.performer != null
                                                ? Colors.black
                                                : CupertinoColors.systemGrey
                                            : !event.ended
                                                ? event.date.isBefore(
                                                        DateTime.now())
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
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _toggleFlashlight,
                      child: Icon(
                        _isFlashlightOn
                            ? CupertinoIcons.lightbulb_fill
                            : CupertinoIcons.lightbulb_slash,
                        color: slottedOrange,
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
}
