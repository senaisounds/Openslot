import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.user, required this.authAction});

  final User? user;

  final Future<void> Function(bool) authAction;

  @override
  Widget build(BuildContext context) {
    final bool loggedIn = user != null;
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: user == null
          ? Center(
              child: CupertinoButton(
                child: const Text('Sign In'),
                onPressed: () => authAction(loggedIn),
              ),
            )
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .doc('users/${user!.uid}')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CupertinoButton(
                      child: const Text('Sign In'),
                      onPressed: () => authAction(loggedIn),
                    ),
                  );
                }

                final slottedUser = SlottedUser.fromDocument(snapshot.data!);

                const double pictureSize = 120.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    // Load profile image from firebase storage
                    FutureBuilder<String>(
                      future: FirebaseStorage.instance
                          .ref('profileImgs/${user!.uid}.png')
                          .getDownloadURL(),
                      builder: (context, snapshot) {
                        return CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _profilePictureAction(context),
                          child: Center(
                            child: Container(
                              width: pictureSize,
                              height: pictureSize,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(pictureSize / 2),
                                // color: slottedOrange,
                                border: Border.all(
                                  color: slottedOrange,
                                  width: 2,
                                ),
                              ),
                              child: snapshot.hasData
                                  ? Padding(
                                      padding: const EdgeInsets.all(0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            pictureSize / 2),
                                        child: Image.network(
                                          snapshot.data!,
                                          width: pictureSize,
                                          height: pictureSize,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      slottedUser.username.characters.first,
                                      style: const TextStyle(
                                        fontSize: pictureSize * 0.78,
                                        fontWeight: FontWeight.bold,
                                        color: slottedOrange,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    Text(
                      slottedUser.username,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.systemBackground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      slottedUser.bio,
                      style: const TextStyle(
                        height: 0.7,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.systemBackground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    // Insert twitter and instagram links
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (slottedUser.twitter != null)
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () async {
                              // Open Twitter
                              final url = Uri.parse(
                                  'https://x.com/${slottedUser.twitter}');
                              try {
                                await launchUrl(url);
                              } catch (e) {
                                print(e);
                              }
                            },
                            child: Image.asset(
                              'lib/assets/images/twitter-white.png',
                              width: 48,
                              height: 48,
                            ),
                          ),
                        const SizedBox(width: 16),
                        if (slottedUser.instagram != null)
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () async {
                              // Open Instagram
                              final url = Uri.parse(
                                  'https://instagram.com/${slottedUser.instagram}');
                              try {
                                await launchUrl(url);
                              } catch (e) {
                                print(e);
                              }
                            },
                            child: Image.asset(
                              'lib/assets/images/instagram-white.png',
                              width: 48,
                              height: 48,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // CupertinoButton(
                    //   padding: const EdgeInsets.all(16),
                    //   color: slottedOrange,
                    //   onPressed: () => _signIn(context),
                    //   child: const Text(
                    //     'Sign Out',
                    //     style: TextStyle(
                    //       color: CupertinoColors.white,
                    //       fontWeight: FontWeight.bold,
                    //     ),
                    //   ),
                    // ),
                  ],
                );
              },
            ),
    );
  }

  void _profilePictureAction(BuildContext context) {
    // showCupertinoModalPopup(
    //   context: context,
    //   builder: (context) {
    //     return CupertinoActionSheet(
    //       title: const Text('Profile Picture'),
    //       actions: [
    //         CupertinoActionSheetAction(
    //           onPressed: () => {},
    //           child: const Text('Sign In'),
    //         ),
    //       ],
    //       cancelButton: CupertinoActionSheetAction(
    //         onPressed: () => Navigator.pop(context),
    //         child: const Text('Cancel'),
    //       ),
    //     );
    //   },
    // );
  }

  void _signIn(BuildContext context) {
    Navigator.of(context).pushNamed('/login');
  }
}
