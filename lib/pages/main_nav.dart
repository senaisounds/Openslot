// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:slotted/pages/my_events.dart';
import 'package:slotted/pages/my_home_page.dart';
import 'package:slotted/pages/profile.dart';
import 'package:slotted/api/firebase_auth_service.dart';
import 'package:slotted/widgets/code_verification_page.dart';

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

  bool isLoading = false;

  final double iconSize = 30;

  String titleString = 'Slotted';

  late final List<Widget> tabViews;

  @override
  void initState() {
    super.initState();
    _tabController = CupertinoTabController(
      initialIndex: 1,
    );
    tabViews = [
      StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) => MyEventsPage(
          user: snapshot.data,
          authAction: (isLoggedIn) => _authAction(context, isLoggedIn),
        ),
      ),
      StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) => MyHomePage(
          user: snapshot.data,
        ),
      ),
      StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) => ProfilePage(
          user: snapshot.data,
          authAction: (isLoggedIn) => _authAction(context, isLoggedIn),
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool loggedIn = widget.user != null;
    return Stack(
      children: [
        CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            backgroundColor: CupertinoColors.secondarySystemBackground,
            middle: _buildNavigationTitle(),
            leading: loggedIn
                ? CupertinoButton(
                    onPressed: isLoading ? null : () {},
                    padding: EdgeInsets.zero,
                    child: const Icon(CupertinoIcons.bell, size: 30),
                  )
                : null,
            trailing: CupertinoButton(
              onPressed:
                  isLoading ? null : () => _openSettings(context, loggedIn),
              padding: EdgeInsets.zero,
              child: loggedIn
                  ? const Icon(
                      CupertinoIcons.gear,
                      size: 30,
                    )
                  : const Text(
                      'Sign In',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
                setState(() {
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
                });
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
              return tabViews[index];
            },
          ),
        ),
        if (isLoading)
          const Opacity(
            opacity: 0.5,
            child: ModalBarrier(
              color: CupertinoColors.black,
              dismissible: false,
            ),
          ),
        if (isLoading)
          const Center(
            child: CupertinoActivityIndicator(),
          ),
      ],
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
              child: Text(
                loggedIn ? 'Sign Out' : 'Sign In',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
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
    setState(() {
      isLoading = true;
    });
    try {
      if (loggedIn) {
        await FirebaseAuthService().signOut();
        setState(() {
          isLoading = false;
        });
        Navigator.of(context).pop();
      } else {
        // Present sign in modal to collect phone number
        await showCupertinoModalPopup(
          context: context,
          builder: (builder) {
            return CupertinoAlertDialog(
              title: const Text(
                'Sign In',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              content: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                child: CupertinoTextField(
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  placeholder: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  onChanged: (value) {
                    setState(() {
                      phoneNumber = value;
                    });
                  },
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () {
                    setState(() {
                      phoneNumber = null;
                      isLoading = false;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                CupertinoDialogAction(
                  onPressed: () async {
                    if (phoneNumber == null || phoneNumber!.isEmpty) {
                      return;
                    }
                    final formattedNumber =
                        '+1${phoneNumber!.replaceAll(RegExp(r'[^0-9]'), '')}';
                    await FirebaseAuthService().firebaseAuth.verifyPhoneNumber(
                          phoneNumber: formattedNumber,
                          verificationCompleted:
                              (PhoneAuthCredential credential) async {
                            // Auto-retrieval or instant verification completed
                            await FirebaseAuthService()
                                .firebaseAuth
                                .signInWithCredential(credential);
                            setState(() {
                              isLoading = false;
                            });
                          },
                          verificationFailed: (FirebaseAuthException e) {
                            // Handle error
                            showCupertinoDialog(
                              context: context,
                              builder: (context) => CupertinoAlertDialog(
                                title: const Text('Error'),
                                content: Text(e.message ?? e.toString()),
                                actions: [
                                  CupertinoButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                            setState(() {
                              isLoading = false;
                            });
                          },
                          codeSent: (String verificationId, int? resendToken) {
                            // Code sent for manual entry
                            Navigator.of(context)
                                .push(CupertinoPageRoute(
                              builder: (context) => CodeVerificationPage(
                                  verificationId: verificationId),
                            ))
                                .then((value) {
                              setState(() {
                                isLoading = false;
                              });
                            });
                          },
                          codeAutoRetrievalTimeout: (String verificationId) {
                            // Auto retrieval timeout
                            showCupertinoDialog(
                              context: context,
                              builder: (context) => CupertinoAlertDialog(
                                title: const Text('Error'),
                                content: const Text('Verifcation timed out.'),
                                actions: [
                                  CupertinoButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                            setState(() {
                              isLoading = false;
                            });
                          },
                        );
                    Navigator.of(context).pop(phoneNumber);
                  },
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            );
          },
        );

        if (phoneNumber == null) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
      rethrow;
    }
  }

  Widget _buildNavigationTitle() {
    const style = TextStyle(
      color: slottedOrange,
      fontWeight: FontWeight.w700,
      fontSize: 30,
    );

    return Text(
      titleString,
      style: style,
    );
  }
}
