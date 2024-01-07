import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: CupertinoColors.systemBackground,
        title: const Text('My Events'),
      ),
      body: Center(
        child:
            loggedIn ? const Text('Events Page') : const Text('Not Logged In'),
      ),
    );
  }
}
