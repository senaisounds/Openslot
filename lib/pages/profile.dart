import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage(
      {super.key,
      required this.user,
      required this.authAction,
      this.debug = false});

  final User? user;

  final Future<void> Function(bool)? authAction;

  final bool debug;

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final bioController = TextEditingController();
  final FocusNode bioFocus = FocusNode();

  KeyboardActionsConfig _buildConfig(BuildContext context) {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      keyboardBarColor: CupertinoColors.secondaryLabel.withOpacity(1),
      nextFocus: false,
      actions: [
        KeyboardActionsItem(focusNode: bioFocus, toolbarButtons: [
          (node) {
            return CupertinoButton(
              padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
              onPressed: () => node.unfocus(),
              child: const Text(
                'Done',
                style: TextStyle(
                  color: slottedOrange,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool loggedIn = widget.user != null;
    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: CupertinoColors.systemBackground,
      child: KeyboardActions(
        config: _buildConfig(context),
        child: !loggedIn
            ? Center(
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('Sign In'),
                  onPressed: () => widget.authAction?.call(loggedIn),
                ),
              )
            : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .doc('users/${widget.user!.uid}')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          // color: CupertinoColors.black.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const CircularProgressIndicator(
                          strokeCap: StrokeCap.round,
                          backgroundColor: CupertinoColors.systemOrange,
                          strokeAlign: -8,
                          strokeWidth: 5,
                          color: slottedOrange,
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return Center(
                      child: CupertinoButton(
                        child: const Text('Sign In'),
                        onPressed: () => widget.authAction?.call(loggedIn),
                      ),
                    );
                  }

                  final slottedUser = SlottedUser.fromDocument(snapshot.data!);

                  const double pictureSize = 120.0;

                  bioController.text = slottedUser.bio;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      // Load profile image from firebase storage
                      CupertinoButton(
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
                            child: slottedUser.photoUrl.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          pictureSize / 2),
                                      child: CachedNetworkImage(
                                        imageUrl: slottedUser.photoUrl,
                                        width: pictureSize,
                                        height: pictureSize,
                                        fit: BoxFit.cover,
                                        useOldImageOnUrlChange: true,
                                        fadeInDuration: Duration.zero,
                                      ),
                                    ),
                                  )
                                : Text(
                                    slottedUser.username.isNotEmpty
                                        ? slottedUser.username.characters.first
                                        : '',
                                    style: const TextStyle(
                                      fontSize: pictureSize * 0.78,
                                      fontWeight: FontWeight.bold,
                                      color: slottedOrange,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        slottedUser.username,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: CupertinoColors.systemBackground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      CupertinoTextField(
                        onChanged: (value) {
                          FirebaseFirestore.instance
                              .doc('users/${widget.user!.uid}')
                              .update({
                            'bio': value,
                          }).then((value) => print('Bio updated'));
                        },
                        keyboardType: TextInputType.multiline,
                        focusNode: bioFocus,
                        placeholder: 'Bio',
                        cursorColor: slottedOrange,
                        placeholderStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: CupertinoColors.systemGrey,
                        ),
                        controller: bioController,
                        maxLines: 6,
                        style: const TextStyle(
                          // height: 0.7,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: CupertinoColors.label,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      // Insert twitter and instagram links
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (slottedUser.twitter != '')
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () async {
                                // Open Twitter
                                final url = Uri.parse(
                                    'https://x.com/${slottedUser.twitter}');
                                try {
                                  await launchUrl(url,
                                      mode: LaunchMode.inAppBrowserView);
                                } catch (e) {
                                  print(e);
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'lib/assets/images/twitter-white.png',
                                    width: 48,
                                    height: 48,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '@${slottedUser.twitter}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: CupertinoColors.systemBackground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 24),
                          if (slottedUser.instagram != '')
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () async {
                                // Open Instagram
                                final url = Uri.parse(
                                    'https://instagram.com/${slottedUser.instagram}');
                                try {
                                  await launchUrl(url,
                                      mode: LaunchMode.inAppBrowserView);
                                } catch (e) {
                                  print(e);
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'lib/assets/images/instagram-white.png',
                                    width: 48,
                                    height: 48,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '@${slottedUser.instagram}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: CupertinoColors.systemBackground,
                                    ),
                                  ),
                                ],
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
