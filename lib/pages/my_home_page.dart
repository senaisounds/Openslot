import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.user});

  final User? user;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final bool loggedIn = widget.user != null;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: CupertinoColors.systemBackground,
        title: const Text('Home'),
      ),
      body: Center(
        child: Text(
          loggedIn ? 'Welcome: ${widget.user!.phoneNumber}' : 'Not Logged In',
        ),
      ),
    );
  }
}
