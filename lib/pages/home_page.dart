import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:slotted/common/event_class.dart' as event_class;
import 'package:slotted/common/slotted_user.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/pages/my_home_page.dart';
import 'package:slotted/utils/logger.dart';

/// A standalone implementation of the home page that can be used 
/// independently from the main navigation, with proper dependency injection.
/// This is useful for testing or for specific entry points into the app.
class HomePage extends StatefulWidget {
  final bool debug;
  
  /// Optional authentication action handler. If not provided, a default implementation is used.
  final Future<void> Function(BuildContext, bool, VoidCallback)? authActionHandler;
  
  /// Optional reservation action handler. If not provided, a default implementation is used.
  final Future<void> Function(event_class.Event, SlottedUser)? reserveActionHandler;
  
  /// Optional delete event handler. If not provided, a default implementation is used.
  final Future<void> Function(String)? deleteEventHandler;

  const HomePage({
    super.key, 
    this.debug = false,
    this.authActionHandler,
    this.reserveActionHandler,
    this.deleteEventHandler,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Default authentication action if none provided
  Future<void> _defaultAuthAction(BuildContext context, bool isSignUp, VoidCallback onComplete) async {
    // Default implementation just completes the callback
    onComplete();
  }
  
  /// Default reservation action if none provided
  Future<void> _defaultReserveAction(event_class.Event event, SlottedUser slottedUser) async {
    // Default empty implementation
    Logger.d('Default reserve action called for event: ${event.id}', tag: 'Home_page');
  }
  
  /// Default delete event action if none provided
  Future<void> _defaultDeleteEvent(String eventId) async {
    // Default empty implementation
    Logger.d('Default delete action called for event: $eventId', tag: 'Home_page');
  }
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            statusBarBrightness: Brightness.dark,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: CupertinoPageScaffold(
            backgroundColor: AppColors.backgroundDark,
            resizeToAvoidBottomInset: false,
            child: MyHomePage(
              user: snapshot.data,
              debug: widget.debug,
              authAction: widget.authActionHandler ?? _defaultAuthAction,
              reserveAction: widget.reserveActionHandler ?? _defaultReserveAction,
              deleteEvent: widget.deleteEventHandler ?? _defaultDeleteEvent,
            ),
          ),
        );
      },
    );
  }
} 