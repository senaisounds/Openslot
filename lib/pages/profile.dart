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
                          child: const CircularProgressIndicator(
                            strokeCap: StrokeCap.round,
                            backgroundColor: CupertinoColors.systemOrange,
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
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: widget.viewUser != null
                              ? null
                              : () {
                                  if (slottedUser.photoUrl.isNotEmpty) {
                                    showCupertinoModalPopup(
                                      context: context,
                                      builder: (context) => CupertinoActionSheet(
                                        actions: [
                                          CupertinoActionSheetAction(
                                            onPressed: () async {
                                              Navigator.pop(context);
                                              final ImagePicker picker =
                                                  ImagePicker();
                                              final XFile? image =
                                                  await picker.pickImage(
                                                source: ImageSource.gallery,
                                                maxWidth: 1000,
                                                maxHeight: 1000,
                                              );
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
                                            },
                                            child: const Text('Upload New Photo'),
                                          ),
                                          CupertinoActionSheetAction(
                                            isDestructiveAction: true,
                                            onPressed: () async {
                                              Navigator.pop(context);
                                              setState(() {
                                                isLoading = true;
                                              });
                                              final storageRef = FirebaseStorage
                                                  .instance
                                                  .ref()
                                                  .child(
                                                      'profileImgs/${widget.user!.uid}.png');
                                              await storageRef.delete();
                                              await FirebaseFirestore.instance
                                                  .doc(
                                                      'users/${widget.user!.uid}')
                                                  .update({'photoUrl': ''});
                                              setState(() {
                                                isLoading = false;
                                              });
                                            },
                                            child: const Text('Delete Photo'),
                                          ),
                                        ],
                                        cancelButton: CupertinoActionSheetAction(
                                          onPressed: () => Navigator.pop(context),
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
                                            final storageRef =
                                                FirebaseStorage.instance.ref().child(
                                                    'profileImgs/${widget.user!.uid}.png');
                                            await storageRef
                                                .putFile(File(image.path));
                                            final url =
                                                await storageRef.getDownloadURL();
                                            await FirebaseFirestore.instance
                                                .doc('users/${widget.user!.uid}')
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
                                    borderRadius:
                                        BorderRadius.circular(pictureSize / 2),
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
                                              fadeOutDuration: Duration.zero,
                                              placeholder: (context, url) =>
                                                  const Center(
                                                child: CircularProgressIndicator(
                                                  strokeCap: StrokeCap.round,
                                                  backgroundColor: CupertinoColors
                                                      .systemOrange,
                                                  strokeWidth: 5,
                                                  color: slottedOrange,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Text(
                                          slottedUser.username.isNotEmpty
                                              ? isLoading
                                                  ? ''
                                                  : slottedUser
                                                      .username.characters.first
                                                      .toUpperCase()
                                              : '',
                                          style: const TextStyle(
                                            fontSize: pictureSize * 0.78,
                                            fontWeight: FontWeight.bold,
                                            color: slottedOrange,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                ),
                                if (isLoading)
                                  const CircularProgressIndicator(
                                    strokeCap: StrokeCap.round,
                                    backgroundColor: CupertinoColors.systemOrange,
                                    strokeWidth: 5,
                                    color: slottedOrange,
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
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                // color: slottedOrange.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            child: CupertinoTextField(
                              enabled: widget.viewUser == null,
                              onChanged: (value) {
                                if (_bioDebounce?.isActive ?? false) {
                                  _bioDebounce?.cancel();
                                }
                                _bioDebounce = Timer(const Duration(seconds: 1), () {
                                  FirebaseFirestore.instance
                                      .doc('users/${widget.user!.uid}')
                                      .update({
                                    'bio': value,
                                  });
                                });
                              },
                              keyboardType: TextInputType.multiline,
                              focusNode: bioFocus,
                              placeholder: 'Bio',
                              cursorColor: slottedOrange,
                              placeholderStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: CupertinoColors.systemGrey,
                                height: 0.5,
                              ),
                              controller: bioController,
                              maxLines: 6,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: CupertinoColors.label,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Insert twitter and instagram links
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (slottedUser.twitter != '')
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () async {
                                      if (widget.user?.uid == slottedUser.id) {
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
                                                child: const Text('View Profile'),
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
                                                            child: const Text(
                                                                'Save'),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                                child:
                                                    const Text('Edit Username'),
                                              ),
                                              CupertinoActionSheetAction(
                                                isDestructiveAction: true,
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  FirebaseFirestore.instance
                                                      .doc(
                                                          'users/${widget.user!.uid}')
                                                      .update({'twitter': ''});
                                                },
                                                child:
                                                    const Text('Remove Twitter'),
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
                                              mode: LaunchMode.inAppBrowserView);
                                        } catch (e) {
                                          print(e);
                                        }
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
                                            color:
                                                CupertinoColors.systemBackground,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            else
                              widget.viewUser != null
                                  ? const SizedBox()
                                  : CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        showCupertinoDialog(
                                          context: context,
                                          builder: (context) {
                                            final controller =
                                                TextEditingController();
                                            return CupertinoAlertDialog(
                                              title: const Text('Add Twitter'),
                                              content: CupertinoTextField(
                                                controller: controller,
                                                placeholder: '@username',
                                                prefix: const Text('@'),
                                                autofocus: true,
                                              ),
                                              actions: [
                                                CupertinoDialogAction(
                                                  child: const Text('Cancel'),
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                ),
                                                CupertinoDialogAction(
                                                  child: const Text('Save'),
                                                  onPressed: () {
                                                    FirebaseFirestore.instance
                                                        .doc(
                                                            'users/${widget.user!.uid}')
                                                        .update({
                                                      'twitter': controller.text,
                                                    });
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            'lib/assets/images/twitter-white.png',
                                            width: 48,
                                            height: 48,
                                          ),
                                          const SizedBox(width: 16),
                                          const Text(
                                            'Add Twitter',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: CupertinoColors
                                                  .systemBackground,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            const SizedBox(height: 24),
                            if (slottedUser.instagram != '')
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () async {
                                      if (widget.user?.uid == slottedUser.id) {
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
                                                child: const Text('View Profile'),
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
                                                            child: const Text(
                                                                'Save'),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                                child:
                                                    const Text('Edit Username'),
                                              ),
                                              CupertinoActionSheetAction(
                                                isDestructiveAction: true,
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  FirebaseFirestore.instance
                                                      .doc(
                                                          'users/${widget.user!.uid}')
                                                      .update({'instagram': ''});
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
                                              mode: LaunchMode.inAppBrowserView);
                                        } catch (e) {
                                          print(e);
                                        }
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
                                            color:
                                                CupertinoColors.systemBackground,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            else
                              widget.viewUser != null
                                  ? const SizedBox()
                                  : CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        showCupertinoDialog(
                                          context: context,
                                          builder: (context) {
                                            final controller =
                                                TextEditingController();
                                            return CupertinoAlertDialog(
                                              title: const Text('Add Instagram'),
                                              content: CupertinoTextField(
                                                controller: controller,
                                                placeholder: '@username',
                                                prefix: const Text('@'),
                                                autofocus: true,
                                              ),
                                              actions: [
                                                CupertinoDialogAction(
                                                  child: const Text('Cancel'),
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                ),
                                                CupertinoDialogAction(
                                                  child: const Text('Save'),
                                                  onPressed: () {
                                                    FirebaseFirestore.instance
                                                        .doc(
                                                            'users/${widget.user!.uid}')
                                                        .update({
                                                      'instagram':
                                                          controller.text,
                                                    });
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            'lib/assets/images/instagram-white.png',
                                            width: 48,
                                            height: 48,
                                          ),
                                          const SizedBox(width: 16),
                                          const Text(
                                            'Add Instagram',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: CupertinoColors
                                                  .systemBackground,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
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
