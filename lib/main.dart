// ignore_for_file: use_build_context_synchronously
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:slotted/api/firebase_options.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/pages/main_nav.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

const bool _debug = true;
int idCount = 0;

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
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> showNotification(int id, String? title, String? body) async {
    print(id);
    print(title);
    print(body);
    var iOSPlatformChannelSpecifics = const DarwinNotificationDetails(
      presentBanner: true,
    );
    var platformChannelSpecifics =
        NotificationDetails(iOS: iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      id, // Notification ID
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
      requestAlertPermission: false,
      defaultPresentAlert: false,
      onDidReceiveLocalNotification:
          (int id, String? title, String? body, String? payload) async {
        showNotification(id, title, body);
      },
    );
    final InitializationSettings initializationSettings =
        InitializationSettings(
      iOS: initializationSettingsIOS,
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification?.body != null &&
          message.notification?.title != null) {
        idCount++;
        showNotification(
          (DateTime.now().millisecondsSinceEpoch ~/ 1000.0) + idCount,
          message.notification!.title,
          message.notification!.body,
        );
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
      home: MainNav(debug: widget.debug),
    );
  }
}
