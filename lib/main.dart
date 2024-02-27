// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:slotted/api/firebase_options.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/pages/main_nav.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

const bool _debug = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Stripe.merchantIdentifier = 'merchant.m3.slotted';
  Stripe.publishableKey = _debug
      ? 'pk_test_51NN216JiJ5SaqolZZSpfh1JgsVWZdWgJ5vzAwiqqPyXLNE5XdTHjrcyWFtX0ueyzBFWmIe6IBcRKtRXFmAyvVd1i00RXcYBy6R'
      : 'pk_live_51NN216JiJ5SaqolZOcy7QUss4OoGRjpe4vwh2hhnId6dQSEl0QT16cOPUW2pMgcu316JtgU2Ia91pZbfHjGutGro00srzU7thB';

  // Run the application
  runApp(const MyApp(debug: _debug));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.debug = false});

  final bool debug;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> showNotification(String title, String body) async {
    var iOSPlatformChannelSpecifics = const DarwinNotificationDetails();
    var platformChannelSpecifics =
        NotificationDetails(iOS: iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch, // Notification ID
      title, // Notification title
      body, // Notification body
      platformChannelSpecifics,
    );
  }

  @override
  void initState() {
    super.initState();

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
      onDidReceiveLocalNotification:
          (int id, String? title, String? body, String? payload) async {
        // Handle notification when app is in foreground on iOS
      },
    );
    final InitializationSettings initializationSettings =
        InitializationSettings(
      iOS: initializationSettingsIOS,
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("onMessage: $message");
      RemoteNotification? notification = message.notification;
      AppleNotification? iOS = message.notification?.apple;

      if (notification != null && iOS != null) {
        // Display the notification
        showNotification(notification.title!, notification.body!);
      }
      // Handle the message when the app is in the foreground
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("onMessageOpenedApp: $message");
      // Handle the message when the app is opened from a terminated state
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Slotted',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: slottedOrange,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.data?.uid != null) {
            Permission.notification.request().then((status) {
              if (status.isGranted) {
                // Permission is granted
                print('Notification permissions granted');
                _firebaseMessaging.getAPNSToken().then((apnsToken) {
                  return _firebaseMessaging.getToken();
                }).then((token) {
                  FirebaseFirestore.instance
                      .doc('users/${snapshot.data!.uid}')
                      .set(
                    {
                      'pushToken': token,
                    },
                    SetOptions(merge: true),
                  );
                });
              } else {
                // Permission is denied
                print('Notification permissions denied');
              }
            });
          }
          return MainNav(user: snapshot.data, debug: widget.debug);
        },
      ),
    );
  }
}
