// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:slotted/pages/my_events.dart';
import 'package:slotted/pages/my_home_page.dart';
import 'package:slotted/pages/profile.dart';
import 'package:slotted/api/firebase_auth_service.dart';

// Create class MainNav that manages a tab controller screen with 5 routes. The middle route must point to MyHomePage.
class MainNav extends StatefulWidget {
  const MainNav({super.key, required this.user});

  final User? user;

  @override
  State<MainNav> createState() => MainNavState();
}

class MainNavState extends State<MainNav> with SingleTickerProviderStateMixin {
  late final CupertinoTabController _tabController;
  late final SlottedUser? slottedUser;

  String? phoneNumber;

  @override
  void initState() {
    super.initState();
    _tabController = CupertinoTabController(
      initialIndex: 1,
    );
    _tabController.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    setState(() {});
  }

  final double iconSize = 30;

  @override
  Widget build(BuildContext context) {
    bool loggedIn = widget.user != null;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.secondarySystemBackground,
        middle: _buildNavigationTitle(),
        leading: loggedIn
            ? CupertinoButton(
                onPressed: () {},
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.bell, size: 30),
              )
            : null,
        trailing: CupertinoButton(
          onPressed: () => _openSettings(context, loggedIn),
          padding: EdgeInsets.zero,
          child: loggedIn
              ? const Icon(
                  CupertinoIcons.gear,
                  size: 30,
                )
              : const Text('Sign In'),
        ),
      ),
      child: CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          height: 56,
          backgroundColor: CupertinoColors.secondarySystemBackground,
          activeColor: slottedOrange,
          currentIndex: _tabController.index,
          onTap: (index) {
            _tabController.index = index;
            setState(() {});
          },
          iconSize: iconSize,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.list_bullet),
              // label: 'My Events',
            ),
            BottomNavigationBarItem(
              icon: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: _tabController.index == 1
                        ? slottedOrange.withOpacity(0.93)
                        : CupertinoColors.systemGrey.withOpacity(0.7),
                    width: 3,
                  ),
                ),
                child: Image.asset(
                  'lib/assets/images/s_logo.png',
                  width: iconSize * 1.2,
                  height: iconSize * 1.2,
                  color: _tabController.index == 1
                      ? slottedOrange.withOpacity(0.93)
                      : CupertinoColors.systemGrey.withOpacity(0.7),
                ),
              ),
            ),
            const BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person),
              // label: 'Profile',
            ),
          ],
        ),
        tabBuilder: (context, index) {
          late Widget tabView;
          switch (index) {
            case 0:
              tabView = MyEventsPage(
                user: widget.user,
                authAction: (isLoggedIn) => _authAction(context, isLoggedIn),
              );
              break;
            case 1:
              tabView = MyHomePage(user: widget.user);
              break;
            case 2:
              tabView = ProfilePage(
                user: widget.user,
                authAction: (isLoggedIn) => _authAction(context, isLoggedIn),
              );
              break;
            default:
              tabView = MyHomePage(user: widget.user);
          }
          // return CupertinoTabView(builder: (context) => tabView);
          return tabView;
        },
      ),
    );
  }

  void _openSettings(BuildContext context, bool loggedIn) {
    if (!loggedIn) {
      _authAction(context, loggedIn);
      return;
    }
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: const Text('Settings'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => _authAction(context, loggedIn),
              child: Text(loggedIn ? 'Sign Out' : 'Sign In'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  Future<void> _authAction(BuildContext context, bool loggedIn) async {
    if (loggedIn) {
      await FirebaseAuthService().signOut();
      Navigator.of(context).pop();
    } else {
      // Present sign in modal to collect phone number
      await showCupertinoModalPopup(
        context: context,
        builder: (builder) {
          return CupertinoAlertDialog(
            title: const Text('Sign In'),
            content: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
              child: CupertinoTextField(
                placeholder: 'Phone Number',
                keyboardType: TextInputType.phone,
                onChanged: (value) => setState(() {
                  phoneNumber = value;
                }),
              ),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () {
                  setState(() {
                    phoneNumber = null;
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Sign In'),
              ),
            ],
          );
        },
      );
      if (phoneNumber != null) {
        await FirebaseAuthService().signIn(phoneNumber!, context);
      }
    }

    // Refresh the state of Profile and Events pages
    setState(() {});
  }

  Widget _buildNavigationTitle() {
    const style = TextStyle(
      color: slottedOrange,
      fontWeight: FontWeight.w700,
      fontSize: 30,
    );

    var titleString = 'Slotted';

    switch (_tabController.index) {
      case 0:
        titleString = 'My Events';
      case 1:
        titleString = 'Slotted';
      case 2:
        titleString = 'Profile';
      default:
        titleString = 'Slotted';
    }

    return Text(
      titleString,
      style: style,
    );
  }
}
