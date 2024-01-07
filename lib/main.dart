// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:slotted/api/firebase_auth_service.dart';
import 'package:slotted/api/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run the application
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slotted',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 255, 134, 20)),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) =>
            MyHomePage(title: 'Slotted Home Page', user: snapshot.data),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.user});

  final String title;
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Text(
          loggedIn ? 'Welcome: ${widget.user!.phoneNumber}' : 'Not Logged In',
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: loggedIn
            ? () async {
                await FirebaseAuthService().signOut();
                setState(() {});
              }
            : () async {
                await FirebaseAuthService().signIn('+1 914 582 2780', context);
                setState(() {});
              },
        tooltip: loggedIn ? 'Sign Out' : 'Sign In',
        child: loggedIn ? const Icon(Icons.logout) : const Icon(Icons.login),
      ),
    );
  }
}
