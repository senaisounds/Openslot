import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'profile_page.dart'; // Updated to use the working profile page implementation
import 'package:slotted/common/constants.dart';

class AttendeesPage extends StatefulWidget {
  final String eventName;
  final List<String> attendees;
  final bool debug;
  final String eventId;
  final String? scrollToUser;
  final User? user;
  final Future<void> Function(BuildContext, bool, Function()) authAction;

  const AttendeesPage({
    super.key,
    required this.eventName,
    required this.attendees,
    required this.eventId,
    this.scrollToUser,
    required this.debug,
    required this.user,
    required this.authAction,
  });

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
      final doc = await FirebaseFirestore.instance.doc('users/$performerId').get();
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

  // Helper method to get consistent avatar colors
  Color _getAvatarColor(String userId) {
    final colors = [
      const Color(0xFFE53E3E), // Red
      const Color(0xFF9F7AEA), // Purple  
      const Color(0xFF38A169), // Green
      const Color(0xFF3182CE), // Blue
      const Color(0xFFD69E2E), // Orange/Yellow
      const Color(0xFF805AD5), // Purple variant
      const Color(0xFF319795), // Teal
      const Color(0xFFDD6B20), // Orange
      const Color(0xFF2B6CB0), // Blue variant
      const Color(0xFFD53F8C), // Pink
      const Color(0xFF38B2AC), // Teal variant
      const Color(0xFFED8936), // Orange variant
    ];
    
    final colorIndex = userId.hashCode.abs() % colors.length;
    return colors[colorIndex];
  }

  // Helper method to get user initials
  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    } else {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
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
              CupertinoColors.systemBlue.withValues(alpha: 0.1),
              CupertinoColors.systemPurple.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CupertinoColors.activeBlue.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: CupertinoSearchTextField(
                    padding: const EdgeInsets.all(12),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    backgroundColor: CupertinoColors.systemGrey6.withValues(alpha: 0.1),
                    placeholder: 'Search attendees',
                    placeholderStyle: TextStyle(
                      color: CupertinoColors.systemGrey.withValues(alpha: 0.8),
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(
                      CupertinoIcons.search,
                      color: CupertinoColors.systemGrey.withValues(alpha: 0.8),
                      size: 20,
                    ),
                    suffixIcon: Icon(
                      CupertinoIcons.xmark_circle_fill,
                      color: CupertinoColors.systemGrey.withValues(alpha: 0.8),
                      size: 20,
                    ),
                    style: const TextStyle(
                      color: CupertinoColors.black,
                      fontSize: 16,
                    ),
                  ),
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
                                ? CupertinoColors.activeOrange.withValues(alpha: 0.15)
                                : CupertinoColors.darkBackgroundGray,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: CupertinoListTile(
                            onTap: () async {
                              if (await FirebaseFirestore.instance
                                  .doc('users/$performerId')
                                  .get()
                                  .then((doc) => doc.exists)) {
                                if (!mounted) return;
                                // Store context reference to avoid async gap issues
                                final currentContext = context;
                                if (!currentContext.mounted) return;
                                Navigator.of(currentContext).push(
                                  CupertinoPageRoute(
                                    builder: (context) => ProfilePage(userId: performerId),
                                  ),
                                );
                              } else {
                                if (!mounted) return;
                                // Store context reference to avoid async gap issues
                                final currentContext = context;
                                if (!currentContext.mounted) return;
                                showCupertinoDialog(
                                  context: currentContext,
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
                              backgroundImage: photoUrl.isNotEmpty && photoUrl != placeholderImage
                                  ? CachedNetworkImageProvider(photoUrl)
                                  : null,
                              backgroundColor: photoUrl.isEmpty || photoUrl == placeholderImage
                                  ? _getAvatarColor(performerId)
                                  : null,
                              child: photoUrl.isEmpty || photoUrl == placeholderImage
                                  ? Text(
                                      _getInitials(username),
                                      style: const TextStyle(
                                        color: CupertinoColors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
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
