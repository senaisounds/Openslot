import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/pages/live.dart';

class NotificationsPage extends StatefulWidget {
  final User? user;

  const NotificationsPage({Key? key, required this.user}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user == null) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('Notifications'),
        ),
        child: Center(
          child: Text('Please sign in to view notifications.'),
        ),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Notifications'),
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users/${widget.user!.uid}/notifications')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            // if (snapshot.connectionState == ConnectionState.waiting) {
            //   return const Center(child: CupertinoActivityIndicator());
            // }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No notifications.'));
            }

            final notifications = snapshot.data!.docs;

            return SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: CupertinoSearchTextField(
                      controller: _searchController,
                      backgroundColor: CupertinoColors.systemGrey5,
                      placeholder: 'Search notifications',
                      prefixIcon: const Icon(CupertinoIcons.search,
                          color: CupertinoColors.systemGrey),
                      style: const TextStyle(color: CupertinoColors.white),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final title = notification['title'] as String;
                        final body = notification['body'] as String;
                        final timestamp =
                            (notification['timestamp'] as Timestamp).toDate();
                        final data = notification['data'] as dynamic;

                        // Filter notifications based on search query
                        if (searchQuery.isNotEmpty) {
                          if (!title
                                  .toLowerCase()
                                  .contains(searchQuery.toLowerCase()) &&
                              !body
                                  .toLowerCase()
                                  .contains(searchQuery.toLowerCase())) {
                            return const SizedBox.shrink();
                          }
                        }

                        return GestureDetector(
                          onTap: () {
                            if (data != null && data['eventId'] != null) {
                              FirebaseFirestore.instance
                                  .collection('events')
                                  .doc(data['eventId'])
                                  .get()
                                  .then((doc) {
                                if (doc.exists) {
                                  final event = Event.fromDocument(doc);
                                  Navigator.of(context).push(
                                    CupertinoPageRoute(
                                      builder: (context) => LivePage(
                                        event: event,
                                        debug: false,
                                        user: widget.user,
                                        authAction:
                                            (context, isLoggedIn, completion) =>
                                                Future(() => null),
                                        reserveAction: (event, slottedUser) =>
                                            Future(() => null),
                                      ),
                                    ),
                                  );
                                }
                              });
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(
                                vertical: 4.0, horizontal: 8.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  CupertinoColors.systemGrey5.darkColor,
                                  CupertinoColors.systemGrey3.darkColor,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: [
                                BoxShadow(
                                  color: CupertinoColors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 4.0, horizontal: 8.0),
                              decoration: BoxDecoration(
                                // color: CupertinoColors.systemGrey6.darkColor,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: CupertinoListTile(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 12.0),
                                title: Text(title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: CupertinoColors.white,
                                        fontSize: 16)),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(body,
                                      style: TextStyle(
                                          color: CupertinoColors.white
                                              .withOpacity(0.8),
                                          fontSize: 14)),
                                ),
                                trailing: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        color: CupertinoColors.white
                                            .withOpacity(0.6),
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (timestamp.day != DateTime.now().day ||
                                        timestamp.month != DateTime.now().month ||
                                        timestamp.year != DateTime.now().year)
                                      Text(
                                        '${timestamp.month}/${timestamp.day}/${timestamp.year.toString().substring(2)}',
                                        style: TextStyle(
                                          color: CupertinoColors.white
                                              .withOpacity(0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
