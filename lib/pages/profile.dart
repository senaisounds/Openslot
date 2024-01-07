import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.user});

  final User? user;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final bool loggedIn = widget.user != null;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: CupertinoColors.systemBackground,
        title: const Text('My Profile'),
      ),
      body: Center(
        child: loggedIn
        ? const Text('Profile Page')
        : const Text('Not Logged In'),
      ),
    );
  }
}
