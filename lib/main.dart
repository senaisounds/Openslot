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

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _signInPhoneController = TextEditingController();

  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _fadeOutAnimation;
  bool _showSplash = true;

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

  bool isProfileIncomplete(Map<String, dynamic> profileData) {
    // Check for non-optional fields
    return profileData['name'] == null ||
        profileData['name'].isEmpty ||
        profileData['email'] == null ||
        profileData['email'].isEmpty;
  }

  void showProfileCompletionDialog(BuildContext context) {
    _phoneController.addListener(() {
      final text = _phoneController.text;
      _phoneController.value = _phoneController.value.copyWith(
        text: _formatPhoneNumber(text),
        selection:
            TextSelection.collapsed(offset: _formatPhoneNumber(text).length),
      );
    });

    showCupertinoDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Complete Your Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const CupertinoTextField(
                placeholder: 'Name',
                // Add controller and logic to update name
              ),
              const SizedBox(height: 8),
              const CupertinoTextField(
                placeholder: 'Email',
                // Add controller and logic to update email
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _phoneController,
                placeholder: 'Phone Number',
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('Submit'),
              onPressed: () {
                // Validate and update profile data
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showSignInDialog(BuildContext context) {
    _signInPhoneController.addListener(() {
      final text = _signInPhoneController.text;
      _signInPhoneController.value = _signInPhoneController.value.copyWith(
        text: _formatPhoneNumber(text),
        selection: TextSelection.collapsed(offset: _formatPhoneNumber(text).length),
      );
    });

    showCupertinoDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Sign In'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const CupertinoTextField(
                placeholder: 'Email',
                // Add controller and logic to update email
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _signInPhoneController,
                placeholder: 'Phone Number',
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('Sign In'),
              onPressed: () {
                // Validate and handle sign-in logic
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _formatPhoneNumber(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) buffer.write('-');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  void onUserSignIn(BuildContext context, Map<String, dynamic> profileData) {
    if (isProfileIncomplete(profileData)) {
      showProfileCompletionDialog(context);
    }
    // Continue with the rest of the sign-in logic
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
      ),
    );

    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.85, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showSplash = false;
        });
      }
    });

    _controller.forward();

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      home: Stack(
        children: [
          MainNav(debug: widget.debug), // Load main app in background
          if (_showSplash)
            AnimatedSplashScreen(
              fadeInAnimation: _fadeInAnimation,
              fadeOutAnimation: _fadeOutAnimation,
            ),
        ],
      ),
    );
  }
}

class AnimatedSplashScreen extends StatelessWidget {
  final Animation<double> fadeInAnimation;
  final Animation<double> fadeOutAnimation;

  const AnimatedSplashScreen({
    required this.fadeInAnimation,
    required this.fadeOutAnimation,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E3F), // Solid base color to ensure full coverage
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E1E3F),
              Color(0xFF2D2B55),
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: fadeInAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: fadeOutAnimation.value,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < "SLOTTED".length; i++)
                      Opacity(
                        opacity: fadeInAnimation.value * (1 - (i * 0.12)),
                        child: Text(
                          "SLOTTED"[i],
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
