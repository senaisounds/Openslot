import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:slotted/common/colors.dart';

class MyEventsPage extends StatefulWidget {
  const MyEventsPage({super.key, required this.user});

  final User? user;

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> {
  @override
  Widget build(BuildContext context) {
    final bool loggedIn = widget.user != null;
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: Center(
        child: Text(loggedIn ? 'Events Page' : 'Not Logged In', style: const TextStyle(
          color: slottedOrange,
          fontWeight: FontWeight.bold,
          fontSize: 18.0,
        ),),
      ),
    );
  }
}
