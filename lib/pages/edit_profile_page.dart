import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:slotted/api/firebase_auth_service.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class EditProfilePage extends StatefulWidget {
  final SlottedUser user;

  const EditProfilePage({
    super.key,
    required this.user,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _instagramController;
  late TextEditingController _twitterController;
  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _bioController = TextEditingController(text: widget.user.bio);
    _instagramController = TextEditingController(text: widget.user.instagram);
    _twitterController = TextEditingController(text: widget.user.twitter);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    try {
      final String fileName = path.basename(_imageFile!.path);
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${widget.user.id}_$fileName');

      final UploadTask uploadTask = storageRef.putFile(_imageFile!);
      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? photoUrl;
      if (_imageFile != null) {
        photoUrl = await _uploadImage();
      }

      final updatedUser = SlottedUser()
        ..id = widget.user.id
        ..username = _usernameController.text
        ..email = _emailController.text
        ..phoneNumber = _phoneController.text
        ..photoUrl = photoUrl ?? widget.user.photoUrl
        ..bio = _bioController.text
        ..instagram = _instagramController.text
        ..twitter = _twitterController.text
        ..customerID = widget.user.customerID
        ..testCustomerID = widget.user.testCustomerID
        ..isHost = widget.user.isHost
        ..openMics = widget.user.openMics
        ..pushToken = widget.user.pushToken
        ..isFirstTimer = widget.user.isFirstTimer
        ..awards = widget.user.awards
        ..createdAt = widget.user.createdAt
        ..lastLogin = widget.user.lastLogin
        ..savedEvents = widget.user.savedEvents;

      await _authService.updateUserData(updatedUser);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to update profile: $e'),
            actions: [
              CupertinoButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundDark,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(
            CupertinoIcons.back,
            color: AppColors.backgroundLight,
          ),
        ),
        middle: const Text(
          'Edit Profile',
          style: TextStyle(
            color: AppColors.backgroundLight,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        trailing: _isLoading
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _saveProfile,
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: AppColors.orangeBackground,
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                  ),
                ),
              ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundDark.withValues(alpha: 0.95),
              AppColors.backgroundDark,
            ],
            stops: const [0.2, 1.0],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 24),
                
                // Profile Photo Section
                _buildProfilePhotoSection(),
                const SizedBox(height: 40),
                
                // Basic Info Section
                _buildSectionHeader('Basic Info'),
                const SizedBox(height: 12),
                _buildFormSection(
                  children: [
                    _buildFormField(
                      controller: _usernameController,
                      prefix: const Icon(CupertinoIcons.person_fill, color: AppColors.orangeBackground),
                      placeholder: 'Username',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a username';
                        }
                        return null;
                      },
                    ),
                    _buildFormField(
                      controller: _emailController,
                      prefix: const Icon(CupertinoIcons.mail_solid, color: AppColors.orangeBackground),
                      placeholder: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    _buildFormField(
                      controller: _phoneController,
                      prefix: const Icon(CupertinoIcons.phone_fill, color: AppColors.orangeBackground),
                      placeholder: 'Phone Number',
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),

                // About You Section
                _buildSectionHeader('About You'),
                const SizedBox(height: 12),
                _buildBioSection(
                  controller: _bioController,
                  placeholder: 'Tell us about yourself...',
                ),
                
                const SizedBox(height: 32),

                // Social Media Section
                _buildSectionHeader('Social Media'),
                const SizedBox(height: 12),
                _buildSocialMediaSection(),
                
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePhotoSection() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.31),
                    AppColors.orangeBackground.withValues(alpha: 0.16),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.orangeBackground.withValues(alpha: 0.16),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : (widget.user.photoUrl.isNotEmpty
                        ? NetworkImage(widget.user.photoUrl)
                        : null) as ImageProvider?,
                child: (_imageFile == null && widget.user.photoUrl.isEmpty)
                    ? Icon(
                        CupertinoIcons.person_fill,
                        size: 60,
                        color: AppColors.backgroundLight.withValues(alpha: 0.5),
                      )
                    : null,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.orangeBackground,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.backgroundDark,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 6,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.camera_fill,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.orangeBackground,
        ),
      ),
    );
  }

  Widget _buildFormSection({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required Widget prefix,
    required String placeholder,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    String? iconPrefix,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.12),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: prefix,
          ),
          const SizedBox(width: 12),
          if (iconPrefix != null) 
            Text(
              iconPrefix,
              style: const TextStyle(
                color: AppColors.orangeBackground,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          Expanded(
            child: CupertinoTextFormFieldRow(
              controller: controller,
              placeholder: placeholder,
              validator: validator,
              keyboardType: keyboardType,
              padding: EdgeInsets.zero,
              style: const TextStyle(
                color: AppColors.backgroundLight,
                fontSize: 16,
              ),
              placeholderStyle: TextStyle(
                color: AppColors.backgroundLight.withValues(alpha: 0.59),
                fontSize: 16,
              ),
              decoration: const BoxDecoration(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection({
    required TextEditingController controller,
    required String placeholder,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.text_quote,
                color: AppColors.orangeBackground,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                placeholder,
                style: TextStyle(
                  color: AppColors.backgroundLight.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 120,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.16),
                width: 1,
              ),
            ),
            child: CupertinoTextField(
              controller: controller,
              placeholder: "I'm a comedian/DJ/host...",
              padding: const EdgeInsets.all(8),
              maxLines: 5,
              style: const TextStyle(
                color: AppColors.backgroundLight,
                fontSize: 16,
              ),
              placeholderStyle: TextStyle(
                color: AppColors.backgroundLight.withValues(alpha: 0.47),
                fontSize: 16,
              ),
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Instagram
          _buildSocialMediaField(
            controller: _instagramController,
            icon: Image.asset(
              'lib/assets/images/instagram-white.png',
              width: 22,
              height: 22,
            ),
            fallbackIcon: CupertinoIcons.photo_camera_solid,
            platform: 'Instagram',
            iconPrefix: '@',
            placeholder: 'senaisounds',
          ),
          
          // X (Twitter)
          _buildSocialMediaField(
            controller: _twitterController,
            icon: Image.asset(
              'lib/assets/images/twitter-white.png',
              width: 22,
              height: 22,
            ),
            fallbackIcon: CupertinoIcons.at,
            platform: 'X (Twitter)',
            iconPrefix: '@',
            placeholder: 'Heysenai',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaField({
    required TextEditingController controller,
    Widget? icon,
    required IconData fallbackIcon, 
    required String platform,
    required String iconPrefix,
    required String placeholder,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast ? null : Border(
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.12),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            child: icon ?? Icon(
              fallbackIcon,  
              color: platform == 'Instagram' 
                  ? const Color(0xFFE1306C) 
                  : Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            iconPrefix,
            style: TextStyle(
              color: platform == 'Instagram' 
                  ? const Color(0xFFE1306C)
                  : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: CupertinoTextFormFieldRow(
              controller: controller,
              placeholder: placeholder,
              padding: EdgeInsets.zero,
              style: const TextStyle(
                color: AppColors.backgroundLight,
                fontSize: 16,
              ),
              placeholderStyle: TextStyle(
                color: AppColors.backgroundLight.withValues(alpha: 0.59),
                fontSize: 16,
              ),
              decoration: const BoxDecoration(),
            ),
          ),
        ],
      ),
    );
  }
} 