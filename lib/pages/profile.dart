import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage(
      {super.key,
      required this.user,
      required this.authAction,
      this.viewUser,
      this.debug = false});

  final User? user;

  final Future<void> Function(bool)? authAction;

  final String? viewUser;

  final bool debug;

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final bioController = TextEditingController();
  final FocusNode bioFocus = FocusNode();
  Timer? _bioDebounce;
  bool isLoading = false;

  final Color complementaryColor = CupertinoColors.systemTeal;

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
              child: Text(
                'Done',
                style: TextStyle(
                  color: complementaryColor,
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
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              CupertinoColors.systemBlue.withOpacity(0.1),
              CupertinoColors.systemPurple.withOpacity(0.1),
            ],
          ),
        ),
        child: KeyboardActions(
          config: _buildConfig(context),
          child: !loggedIn && widget.viewUser == null
              ? Center(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Sign In'),
                    onPressed: () => widget.authAction?.call(loggedIn),
                  ),
                )
              : StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .doc('users/${widget.viewUser ?? widget.user!.uid}')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: CircularProgressIndicator(
                            strokeCap: StrokeCap.round,
                            backgroundColor: CupertinoColors.systemOrange,
                            strokeWidth: 5,
                            color: complementaryColor,
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

                    final slottedUser =
                        SlottedUser.fromDocument(snapshot.data!);

                    const double pictureSize = 120.0;

                    bioController.text = slottedUser.bio;

                    return SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Static top half of the profile
                          SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 24),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: widget.viewUser != null
                                      ? null
                                      : () {
                                          if (slottedUser.photoUrl.isNotEmpty) {
                                            showCupertinoModalPopup(
                                              context: context,
                                              builder: (context) =>
                                                  CupertinoActionSheet(
                                                actions: [
                                                  CupertinoActionSheetAction(
                                                    onPressed: () async {
                                                      Navigator.pop(context);
                                                      final ImagePicker picker =
                                                          ImagePicker();
                                                      final XFile? image =
                                                          await picker
                                                              .pickImage(
                                                        source:
                                                            ImageSource.gallery,
                                                        maxWidth: 1000,
                                                        maxHeight: 1000,
                                                      );
                                                      if (image != null) {
                                                        setState(() {
                                                          isLoading = true;
                                                        });
                                                        final storageRef =
                                                            FirebaseStorage
                                                                .instance
                                                                .ref()
                                                                .child(
                                                                    'profileImgs/${widget.user!.uid}.png');
                                                        await storageRef
                                                            .putFile(File(
                                                                image.path));
                                                        final url =
                                                            await storageRef
                                                                .getDownloadURL();
                                                        await FirebaseFirestore
                                                            .instance
                                                            .doc(
                                                                'users/${widget.user!.uid}')
                                                            .update({
                                                          'photoUrl': url
                                                        });
                                                        setState(() {
                                                          isLoading = false;
                                                        });
                                                      }
                                                    },
                                                    child: const Text(
                                                        'Upload New Photo'),
                                                  ),
                                                  CupertinoActionSheetAction(
                                                    isDestructiveAction: true,
                                                    onPressed: () async {
                                                      Navigator.pop(context);
                                                      setState(() {
                                                        isLoading = true;
                                                      });
                                                      final storageRef =
                                                          FirebaseStorage
                                                              .instance
                                                              .ref()
                                                              .child(
                                                                  'profileImgs/${widget.user!.uid}.png');
                                                      await storageRef.delete();
                                                      await FirebaseFirestore
                                                          .instance
                                                          .doc(
                                                              'users/${widget.user!.uid}')
                                                          .update(
                                                              {'photoUrl': ''});
                                                      setState(() {
                                                        isLoading = false;
                                                      });
                                                    },
                                                    child: const Text(
                                                        'Delete Photo'),
                                                  ),
                                                ],
                                                cancelButton:
                                                    CupertinoActionSheetAction(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Cancel'),
                                                ),
                                              ),
                                            );
                                          } else {
                                            ImagePicker()
                                                .pickImage(
                                              source: ImageSource.gallery,
                                              maxWidth: 1000,
                                              maxHeight: 1000,
                                            )
                                                .then((image) async {
                                              if (image != null) {
                                                setState(() {
                                                  isLoading = true;
                                                });
                                                final storageRef = FirebaseStorage
                                                    .instance
                                                    .ref()
                                                    .child(
                                                        'profileImgs/${widget.user!.uid}.png');
                                                await storageRef
                                                    .putFile(File(image.path));
                                                final url = await storageRef
                                                    .getDownloadURL();
                                                await FirebaseFirestore.instance
                                                    .doc(
                                                        'users/${widget.user!.uid}')
                                                    .update({'photoUrl': url});
                                                setState(() {
                                                  isLoading = false;
                                                });
                                              }
                                            });
                                          }
                                        },
                                  child: Center(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: pictureSize,
                                          height: pictureSize,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                                pictureSize / 2),
                                            border: Border.all(
                                              color: complementaryColor,
                                              width: 2,
                                            ),
                                          ),
                                          child: slottedUser.photoUrl.isNotEmpty
                                              ? Padding(
                                                  padding:
                                                      const EdgeInsets.all(0),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            pictureSize / 2),
                                                    child: CachedNetworkImage(
                                                      imageUrl:
                                                          slottedUser.photoUrl,
                                                      width: pictureSize,
                                                      height: pictureSize,
                                                      fit: BoxFit.cover,
                                                      useOldImageOnUrlChange:
                                                          true,
                                                      fadeInDuration:
                                                          Duration.zero,
                                                      fadeOutDuration:
                                                          Duration.zero,
                                                      placeholder:
                                                          (context, url) =>
                                                              Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeCap:
                                                              StrokeCap.round,
                                                          backgroundColor:
                                                              CupertinoColors
                                                                  .systemOrange,
                                                          strokeWidth: 5,
                                                          color: complementaryColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : Text(
                                                  slottedUser
                                                          .username.isNotEmpty
                                                      ? isLoading
                                                          ? ''
                                                          : slottedUser.username
                                                              .characters.first
                                                              .toUpperCase()
                                                      : '',
                                                  style: TextStyle(
                                                    fontSize:
                                                        pictureSize * 0.78,
                                                    fontWeight: FontWeight.bold,
                                                    color: complementaryColor,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                        ),
                                        if (isLoading)
                                          CircularProgressIndicator(
                                            strokeCap: StrokeCap.round,
                                            backgroundColor:
                                                CupertinoColors.systemOrange,
                                            strokeWidth: 5,
                                            color: complementaryColor,
                                          ),
                                      ],
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
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        width: 1.5,
                                      ),
                                    ),
                                    child: CupertinoTextField(
                                      enabled: widget.viewUser == null,
                                      onChanged: (value) {
                                        if (_bioDebounce?.isActive ?? false) {
                                          _bioDebounce?.cancel();
                                        }
                                        _bioDebounce = Timer(
                                            const Duration(seconds: 1), () {
                                          FirebaseFirestore.instance
                                              .doc('users/${widget.user!.uid}')
                                              .update({
                                            'bio': value,
                                          });
                                        });
                                      },
                                      keyboardType: TextInputType.multiline,
                                      focusNode: bioFocus,
                                      placeholder:
                                          widget.viewUser == null ? 'Bio' : '',
                                      cursorColor: complementaryColor,
                                      placeholderStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: CupertinoColors.systemGrey,
                                        height: 0.5,
                                      ),
                                      controller: bioController,
                                      maxLines: 3,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: CupertinoColors.systemGrey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (slottedUser.twitter != '')
                                      CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        onPressed: () async {
                                          if (widget.user?.uid ==
                                              slottedUser.id) {
                                            showCupertinoModalPopup(
                                              context: context,
                                              builder: (context) =>
                                                  CupertinoActionSheet(
                                                actions: [
                                                  CupertinoActionSheetAction(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      final url = Uri.parse(
                                                          'https://x.com/${slottedUser.twitter}');
                                                      launchUrl(url,
                                                          mode: LaunchMode
                                                              .inAppBrowserView);
                                                    },
                                                    child: const Text(
                                                        'View Profile'),
                                                  ),
                                                  CupertinoActionSheetAction(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      showCupertinoDialog(
                                                        context: context,
                                                        builder: (context) {
                                                          final controller =
                                                              TextEditingController(
                                                                  text: slottedUser
                                                                      .twitter);
                                                          return CupertinoAlertDialog(
                                                            title: const Text(
                                                                'Edit Twitter'),
                                                            content: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(12),
                                                              child:
                                                                  CupertinoTextField(
                                                                controller:
                                                                    controller,
                                                                placeholder:
                                                                    '@username',
                                                              ),
                                                            ),
                                                            actions: [
                                                              CupertinoDialogAction(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                        context),
                                                                child: const Text(
                                                                    'Cancel'),
                                                              ),
                                                              CupertinoDialogAction(
                                                                onPressed: () {
                                                                  FirebaseFirestore
                                                                      .instance
                                                                      .doc(
                                                                          'users/${widget.user!.uid}')
                                                                      .update({
                                                                    'twitter':
                                                                        controller
                                                                            .text
                                                                  });
                                                                  Navigator.pop(
                                                                      context);
                                                                },
                                                                child:
                                                                    const Text(
                                                                        'Save'),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                    },
                                                    child: const Text(
                                                        'Edit Username'),
                                                  ),
                                                  CupertinoActionSheetAction(
                                                    isDestructiveAction: true,
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      FirebaseFirestore.instance
                                                          .doc(
                                                              'users/${widget.user!.uid}')
                                                          .update(
                                                              {'twitter': ''});
                                                    },
                                                    child: const Text(
                                                        'Remove Twitter'),
                                                  ),
                                                ],
                                                cancelButton:
                                                    CupertinoActionSheetAction(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Cancel'),
                                                ),
                                              ),
                                            );
                                          } else {
                                            // Open Twitter
                                            final url = Uri.parse(
                                                'https://x.com/${slottedUser.twitter}');
                                            try {
                                              await launchUrl(url,
                                                  mode: LaunchMode
                                                      .inAppBrowserView);
                                            } catch (e) {
                                              print(e);
                                            }
                                          }
                                        },
                                        child: Image.asset(
                                          'lib/assets/images/twitter-white.png',
                                          width: 24,
                                          height: 24,
                                        ),
                                      ),
                                    if (slottedUser.instagram != '')
                                      CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        onPressed: () async {
                                          if (widget.user?.uid ==
                                              slottedUser.id) {
                                            showCupertinoModalPopup(
                                              context: context,
                                              builder: (context) =>
                                                  CupertinoActionSheet(
                                                actions: [
                                                  CupertinoActionSheetAction(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      final url = Uri.parse(
                                                          'https://instagram.com/${slottedUser.instagram}');
                                                      launchUrl(url,
                                                          mode: LaunchMode
                                                              .inAppBrowserView);
                                                    },
                                                    child: const Text(
                                                        'View Profile'),
                                                  ),
                                                  CupertinoActionSheetAction(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      showCupertinoDialog(
                                                        context: context,
                                                        builder: (context) {
                                                          final controller =
                                                              TextEditingController(
                                                                  text: slottedUser
                                                                      .instagram);
                                                          return CupertinoAlertDialog(
                                                            title: const Text(
                                                                'Edit Instagram'),
                                                            content: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(12),
                                                              child:
                                                                  CupertinoTextField(
                                                                controller:
                                                                    controller,
                                                                placeholder:
                                                                    '@username',
                                                              ),
                                                            ),
                                                            actions: [
                                                              CupertinoDialogAction(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                        context),
                                                                child: const Text(
                                                                    'Cancel'),
                                                              ),
                                                              CupertinoDialogAction(
                                                                onPressed: () {
                                                                  FirebaseFirestore
                                                                      .instance
                                                                      .doc(
                                                                          'users/${widget.user!.uid}')
                                                                      .update({
                                                                    'instagram':
                                                                        controller
                                                                            .text
                                                                  });
                                                                  Navigator.pop(
                                                                      context);
                                                                },
                                                                child:
                                                                    const Text(
                                                                        'Save'),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                    },
                                                    child: const Text(
                                                        'Edit Username'),
                                                  ),
                                                  CupertinoActionSheetAction(
                                                    isDestructiveAction: true,
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      FirebaseFirestore.instance
                                                          .doc(
                                                              'users/${widget.user!.uid}')
                                                          .update({
                                                        'instagram': ''
                                                      });
                                                    },
                                                    child: const Text(
                                                        'Remove Instagram'),
                                                  ),
                                                ],
                                                cancelButton:
                                                    CupertinoActionSheetAction(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Cancel'),
                                                ),
                                              ),
                                            );
                                          } else {
                                            // Open Instagram
                                            final url = Uri.parse(
                                                'https://instagram.com/${slottedUser.instagram}');
                                            try {
                                              await launchUrl(url,
                                                  mode: LaunchMode
                                                      .inAppBrowserView);
                                            } catch (e) {
                                              print(e);
                                            }
                                          }
                                        },
                                        child: Image.asset(
                                          'lib/assets/images/instagram-white.png',
                                          width: 24,
                                          height: 24,
                                        ),
                                      ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(0, 32, 0, 0),
                                  child: Divider(
                                    color: CupertinoColors.systemGrey,
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Scrollable bottom half for achievements
                          SizedBox(
                            height: 333,
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: 5,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 1, 0, 24),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: List.generate(3, (i) {
                                      return Container(
                                        width: 88,
                                        height: 88,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: CupertinoColors.systemGrey,
                                            width: 2,
                                            style: BorderStyle.solid,
                                            strokeAlign:
                                                BorderSide.strokeAlignCenter,
                                            // strokeCap: StrokeCap.round,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            "?",
                                            style: TextStyle(
                                              color: CupertinoColors.systemGrey,
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _profilePictureAction(BuildContext context) {}

  void _signIn(BuildContext context) {
    Navigator.of(context).pushNamed('/login');
  }
}
