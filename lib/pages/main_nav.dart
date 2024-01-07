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
    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        children: [
          MyEventsPage(user: widget.user),
          MyHomePage(user: widget.user),
          ProfilePage(user: widget.user),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: slottedOrange,
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
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          // Set splash color to Colors.transparent
          splashColor: Colors.transparent,
          // Set highlight color to Colors.transparent
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
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
          items: [
            const BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.list_bullet, size: 28),
              label: 'My Events',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'lib/assets/images/s_logo.png',
                width: 36,
                height: 36,
                color: _tabController.index == 1
                ? null
                : CupertinoColors.label,
              ),
              label: '',
            ),
            const BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person, size: 28),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
