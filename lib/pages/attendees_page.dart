import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:slotted/pages/live.dart';
import 'profile.dart'; // Ensure this import is correct based on your project structure

class AttendeesPage extends StatefulWidget {
  final String eventName;
  final List<String> attendees;
  final bool debug;
  final String eventId;
  final String? scrollToUser;
  final User? user;
  final Future<void> Function(BuildContext, bool, Function()) authAction;

  const AttendeesPage({
    Key? key,
    required this.eventName,
    required this.attendees,
    required this.eventId,
    this.scrollToUser,
    required this.debug,
    required this.user,
    required this.authAction,
  }) : super(key: key);

  @override
  _AttendeesPageState createState() => _AttendeesPageState();
}

class _AttendeesPageState extends State<AttendeesPage> {
  String searchQuery = '';
  late ScrollController _scrollController;
  ValueNotifier<String?> highlightedUser = ValueNotifier<String?>(null);
  Map<String, Map<String, String>> userData = {}; // Store user data locally

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fetchUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToUser());
  }

  Future<void> _fetchUserData() async {
    for (String performerId in widget.attendees) {
      final doc =
          await FirebaseFirestore.instance.doc('users/$performerId').get();
      if (doc.exists) {
        final username = doc.get('username') as String? ?? performerId;
        final photoUrl = doc.get('photoUrl') as String? ?? placeholderImage;
        setState(() {
          userData[performerId] = {
            'username': username,
            'photoUrl': photoUrl,
          };
        });
      } else {
        setState(() {
          userData[performerId] = {
            'username': performerId,
            'photoUrl': placeholderImage,
          };
        });
      }
    }
  }

  void _scrollToUser() {
    if (widget.scrollToUser != null) {
      final index = widget.attendees.indexOf(widget.scrollToUser!);
      if (index != -1) {
        final position = index * 72.0;
        final maxScrollExtent = _scrollController.position.maxScrollExtent;
        final minScrollExtent = _scrollController.position.minScrollExtent;
        final currentOffset = _scrollController.offset;

        if (position < currentOffset ||
            position > currentOffset + MediaQuery.of(context).size.height) {
          _scrollController
              .jumpTo(position.clamp(minScrollExtent, maxScrollExtent));
        }

        highlightedUser.value = widget.scrollToUser;
        Timer(const Duration(seconds: 1), () {
          highlightedUser.value = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredAttendees = userData.entries
        .where((entry) => entry.value['username']!
            .toLowerCase()
            .contains(searchQuery.toLowerCase()))
        .map((entry) => entry.key)
        .toList();
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.eventName,
            overflow: TextOverflow.ellipsis, maxLines: 1),
        previousPageTitle: 'Back',
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              CupertinoColors.systemBlue.withOpacity(0.1),
              CupertinoColors.systemPurple.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: CupertinoSearchTextField(
                  padding: const EdgeInsets.all(8),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  backgroundColor: CupertinoColors.systemGrey5,
                  placeholder: 'Search attendees',
                  prefixIcon: const Icon(CupertinoIcons.search,
                      color: CupertinoColors.systemGrey),
                  style: const TextStyle(color: CupertinoColors.white),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: filteredAttendees.length,
                  itemBuilder: (context, index) {
                    final performerId = filteredAttendees[index];
                    final username =
                        userData[performerId]?['username'] ?? performerId;
                    final photoUrl =
                        userData[performerId]?['photoUrl'] ?? placeholderImage;

                    return ValueListenableBuilder<String?>(
                      valueListenable: highlightedUser,
                      builder: (context, highlighted, child) {
                        return Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 8.0),
                          decoration: BoxDecoration(
                            color: highlighted == performerId
                                ? CupertinoColors.activeOrange.withOpacity(0.15)
                                : CupertinoColors.darkBackgroundGray,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: CupertinoListTile(
                            onTap: () async {
                              if (await FirebaseFirestore.instance
                                  .doc('users/$performerId')
                                  .get()
                                  .then((doc) => doc.exists)) {
                                Navigator.of(context).push(
                                  CupertinoPageRoute(
                                    builder: (context) => CupertinoPageScaffold(
                                      resizeToAvoidBottomInset: false,
                                      backgroundColor:
                                          CupertinoColors.systemBackground,
                                      navigationBar:
                                          const CupertinoNavigationBar(
                                        middle: Text("Performer's Profile"),
                                        backgroundColor: CupertinoColors
                                            .secondarySystemBackground,
                                      ),
                                      child: ProfilePage(
                                          debug: widget.debug,
                                          user: widget.user,
                                          authAction: (loggedIn) =>
                                              widget.authAction(
                                                  context, loggedIn, () {}),
                                          viewUser:
                                              performerId != widget.user?.uid
                                                  ? performerId
                                                  : null),
                                    ),
                                  ),
                                );
                              } else {
                                showCupertinoDialog(
                                  context: context,
                                  builder: (context) => CupertinoAlertDialog(
                                    title: const Text('🧍'),
                                    content: Text(
                                        '$performerId does not have an account'),
                                    actions: [
                                      CupertinoDialogAction(
                                        child: const Text('Dismiss'),
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            padding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundImage:
                                  CachedNetworkImageProvider(photoUrl),
                            ),
                            title: Text(
                              username,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
