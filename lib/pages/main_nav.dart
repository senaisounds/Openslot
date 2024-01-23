import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:slotted/common/colors.dart';
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
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
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

  @override
  Widget build(BuildContext context) {
    bool loggedIn = widget.user != null;
    const double iconSize = 30;
    return Scaffold(
      appBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.secondarySystemBackground,
        // middle: Image.asset(
        //   'lib/assets/images/s_logo.png',
        //   width: 36,
        //   height: 36,
        //   color: slottedOrange,
        // ),
        middle: AnimatedSwitcher(
          duration: const Duration(milliseconds: 333),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
            child: _buildNavigationTitle(),
          ),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation, // Apply fade transition
              child: _buildNavigationTitle(),
            );
          },
        ),
        leading: loggedIn
            ? CupertinoButton(
                onPressed: () {},
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.bell, size: 30),
              )
            : null,

        trailing: loggedIn
            ? CupertinoButton(
                onPressed: () => _openSettings(context),
                padding: EdgeInsets.zero,
                child: const Icon(
                  CupertinoIcons.gear,
                  size: 30,
                ),
              )
            : null,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          MyEventsPage(user: widget.user),
          MyHomePage(user: widget.user),
          ProfilePage(user: widget.user),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: slottedOrange,
      //   onPressed: loggedIn
      //       ? () async {
      //           await FirebaseAuthService().signOut();
      //           setState(() {});
      //         }
      //       : () async {
      //           await FirebaseAuthService().signIn('+1 914 582 2780', context);
      //           setState(() {});
      //         },
      //   tooltip: loggedIn ? 'Sign Out' : 'Sign In',
      //   child: loggedIn ? const Icon(Icons.logout) : const Icon(Icons.login),
      // ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          // Set splash color to Colors.transparent
          splashColor: Colors.transparent,
          // Set highlight color to Colors.transparent
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          showSelectedLabels: false,
          showUnselectedLabels: false,
          backgroundColor: CupertinoColors.secondarySystemBackground,
          selectedItemColor: slottedOrange,
          unselectedItemColor: CupertinoColors.label,
          currentIndex: _tabController.index,
          onTap: (index) {
            _tabController.animateTo(index);
            setState(() {});
          },
          unselectedFontSize: 14,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          iconSize: iconSize,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.list_bullet),
              label: 'My Events',
            ),
            BottomNavigationBarItem(
              icon: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: _tabController.index == 1
                        ? slottedOrange
                        : CupertinoColors.label,
                    width: 3,
                  ),
                ),
                child: Image.asset(
                  'lib/assets/images/s_logo.png',
                  width: iconSize,
                  height: iconSize,
                  color:
                      _tabController.index == 1 ? null : CupertinoColors.label,
                ),
              ),
              label: '',
            ),
            const BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    bool loggedIn = widget.user != null;
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: const Text('Settings'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: loggedIn
            ? () async {
                await FirebaseAuthService().signOut();
                setState(() {});
              }
            : () async {
                await FirebaseAuthService().signIn('+1 914 582 2780', context);
                setState(() {});
              },
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
