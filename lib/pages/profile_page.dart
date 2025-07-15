import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slotted/api/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:slotted/common/awards_helper.dart';
import 'package:slotted/pages/edit_profile_page.dart';
import 'package:slotted/pages/my_events.dart';
import 'package:slotted/providers/theme_provider.dart';
import 'package:slotted/utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:slotted/pages/saved_events_page.dart';
import 'package:slotted/pages/notifications_page.dart';
import 'package:flutter/services.dart';
import 'package:slotted/pages/login_page.dart';
import 'package:slotted/pages/host_payout_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:slotted/common/design_system.dart';

import 'package:slotted/widgets/ds_section_header.dart';

// Extension to add capitalize method to String
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

class ProfilePage extends StatefulWidget {
  final String? userId;
  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  SlottedUser? _user;
  bool _isLoading = true;
  
  // Sample awards for demo purposes
  List<Award> _userAwards = [];
  
  // Pull to refresh
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();



  // Check if this is the current user's profile
  bool get _isCurrentUserProfile {
    final currentUserId = _authService.currentUser?.uid;
    // If no userId is provided, it means we're viewing our own profile
    if (widget.userId == null) return true;
    return currentUserId != null && currentUserId == widget.userId;
  }

  // Check if user is authenticated
  bool get _isUserAuthenticated {
    return _authService.currentUser != null;
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    // Debug logging to understand authentication state
    Logger.d('ProfilePage initState - Current user: ${_authService.currentUser?.uid}', tag: 'Profile_page');
    Logger.d('ProfilePage initState - Is authenticated: $_isUserAuthenticated', tag: 'Profile_page');
    Logger.d('ProfilePage initState - Is current user profile: $_isCurrentUserProfile', tag: 'Profile_page');
    Logger.d('ProfilePage initState - Widget userId: ${widget.userId}', tag: 'Profile_page');
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    
    Logger.d('ProfilePage initialized', tag: 'Profile_page');
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // Enhanced haptic feedback
    HapticFeedback.mediumImpact();

    try {
      // If userId is provided, load that user's data
      if (widget.userId != null) {
        final slottedUser = await _authService.getSlottedUser(widget.userId!);
        
        // Load user awards
        _loadUserAwards(slottedUser);
        
        if (mounted) {
          setState(() {
            _user = slottedUser;
            _isLoading = false;
          });
          
          // Success haptic feedback
          HapticFeedback.lightImpact();
        }
      } else {
        // Otherwise, load the current user's data
        final currentUser = _authService.currentUser;
        if (currentUser != null) {
          final slottedUser = await _authService.getSlottedUser(currentUser.uid);
          
          // Load user awards
          _loadUserAwards(slottedUser);
          
          if (mounted) {
            setState(() {
              _user = slottedUser;
              _isLoading = false;
            });
            
            // Success haptic feedback
            HapticFeedback.lightImpact();
          }
        } else {
          // User not authenticated
          if (mounted) {
            setState(() {
              _user = null;
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      Logger.d('Error loading user data: $e', tag: 'Profile_page');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _loadUserAwards(SlottedUser? user) {
    if (user == null) {
      _userAwards = [];
      return;
    }
    
    // Load awards from user data or create sample for demo
    if (user.awards.isEmpty) {
      _userAwards = [
        AwardsHelper.firstPerformance,
        AwardsHelper.connectedSocial,
      ];
    } else {
      _userAwards = user.awards.map((awardMap) {
        return AwardsHelper.getAwardById(awardMap['id']) ?? AwardsHelper.firstPerformance;
      }).toList();
    }
  }



  @override
  Widget build(BuildContext context) {
    // Handle unauthenticated state
    if (!_isUserAuthenticated && widget.userId == null) {
      return CupertinoPageScaffold(
        backgroundColor: context.watch<ThemeProvider>().isDarkMode 
            ? AppColors.backgroundDark 
            : CupertinoColors.white,
        navigationBar: const CupertinoNavigationBar(
          backgroundColor: Colors.transparent,
            border: null,
          middle: Text('Profile'),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.person_circle,
                size: 100,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'Sign in to view your profile',
                style: TextStyle(
                  fontSize: 18,
                  color: context.watch<ThemeProvider>().textColor,
              ),
            ),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
                  );
                },
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    color: Colors.white, // Ensure high contrast
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: context.watch<ThemeProvider>().isDarkMode 
          ? AppColors.backgroundDark 
          : CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        border: null,
        middle: const Text('Profile'),
        trailing: _isCurrentUserProfile ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: const EdgeInsets.only(right: 4),
              onPressed: () {
                HapticFeedback.lightImpact();
                _showSignOutConfirmation();
              },
              child: const Icon(
                CupertinoIcons.square_arrow_right,
                color: CupertinoColors.destructiveRed,
                size: 20,
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.only(right: 8),
              onPressed: () {
                HapticFeedback.lightImpact();
                if (_user == null) return;
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    fullscreenDialog: false,
                    builder: (context) => EditProfilePage(user: _user!),
                  ),
                ).then((edited) {
                  if (edited == true) {
                    _loadUserData();
                  }
                });
              },
              child: const Icon(
                CupertinoIcons.pencil,
                color: CupertinoColors.white,
                size: 22,
              ),
            ),
          ],
        ) : null,
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(
                child: CupertinoActivityIndicator(radius: 20),
              )
            : _user == null
                ? Center(
                    child: Text(
                    'User not found',
                    style: TextStyle(
                      color: context.watch<ThemeProvider>().textColor,
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      // Main content fills the stack
                      Positioned.fill(
                        child: RefreshIndicator(
                          key: _refreshIndicatorKey,
                          onRefresh: () async {
                            HapticFeedback.mediumImpact();
                            await _loadUserData();
                            await Future.delayed(const Duration(milliseconds: 500));
                          },
                          color: AppColors.primary,
                          backgroundColor: context.watch<ThemeProvider>().isDarkMode 
                              ? AppColors.backgroundDark 
                              : CupertinoColors.white,
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  DesignSystem.spacingM,
                                  DesignSystem.spacingL,
                                  DesignSystem.spacingM,
                                  MediaQuery.of(context).padding.bottom,
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildListDelegate([
                                    _buildProfileHeader(),
                                    LayoutHelpers.sectionSpacing,
                                    _buildProfileStats(),
                                    LayoutHelpers.largeSpacing,
                                    _buildBioSection(),
                                    LayoutHelpers.largeSpacing,
                                    _buildAwardsSection(),
                                  ]),
                                ),
                              ),
                              const SliverFillRemaining(
                                hasScrollBody: false,
                                child: SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Floating Action Button
                      if (_user != null)
                        Positioned(
                          bottom: 30,
                          right: 20,
                          child: _buildQuickActionsFAB(),
                        ),
                    ],
                  ),
      ),
    );
  }

  // Quick Actions FAB
  Widget _buildQuickActionsFAB() {
    return Container(
      decoration: ComponentStyles.primaryButton,
      child: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showQuickActions();
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          CupertinoIcons.ellipsis,
          color: CupertinoColors.white,
          size: 24,
        ),
      ),
    );
  }

  void _showQuickActions() {
                      showCupertinoModalPopup(
                        context: context,
                        builder: (context) => CupertinoActionSheet(
        title: Text(_isCurrentUserProfile ? 'Profile Actions' : '${_user?.username}\'s Profile'),
                          actions: [
          if (_isCurrentUserProfile) ...[
                            CupertinoActionSheetAction(
                              onPressed: () {
                                Navigator.pop(context);
                HapticFeedback.lightImpact();
                                Navigator.of(context).push(
                                  CupertinoPageRoute(
                    builder: (context) => EditProfilePage(user: _user!),
                                  ),
                                ).then((edited) {
                                  if (edited == true) {
                                    _loadUserData();
                                  }
                                });
                              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.pencil, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Edit Profile'),
                ],
              ),
                            ),
                            CupertinoActionSheetAction(
                              onPressed: () {
                                Navigator.pop(context);
                HapticFeedback.lightImpact();
                                Navigator.of(context).push(
                                  CupertinoPageRoute(
                                    builder: (context) => MyEventsPage(
                                      user: FirebaseAuth.instance.currentUser,
                                      debug: false,
                      authAction: (context, isLoggedIn, completion) async {},
                      reserveAction: (event, slottedUser) async {},
                      deleteEvent: (eventId) async {},
                                    ),
                                  ),
                                );
                              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.calendar, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('My Events'),
                ],
              ),
                            ),
                            CupertinoActionSheetAction(
                              onPressed: () {
                                Navigator.pop(context);
                HapticFeedback.lightImpact();
                                Navigator.of(context).push(
                                  CupertinoPageRoute(
                                    builder: (context) => const SavedEventsPage(),
                                  ),
                                );
                              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.bookmark, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Saved Events'),
                ],
              ),
                                      ),
                            CupertinoActionSheetAction(
                              onPressed: () {
                                Navigator.pop(context);
                                HapticFeedback.lightImpact();
                                Navigator.of(context).push(
                                  CupertinoPageRoute(
                                    builder: (context) => NotificationsPage(
                                      user: FirebaseAuth.instance.currentUser,
                                    ),
                                  ),
                                );
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.bell, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Text('Notifications'),
                                ],
                              ),
                            ),
                                      CupertinoActionSheetAction(
                                        onPressed: () {
                                          Navigator.pop(context);
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => HostPayoutPage(
                      user: FirebaseAuth.instance.currentUser,
                                      ),
                                  ),
                                );
                              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.money_dollar_circle, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Payout Settings'),
                ],
              ),
            ),
          ],
                                      CupertinoActionSheetAction(
                                        onPressed: () {
                                          Navigator.pop(context);
              HapticFeedback.lightImpact();
              _shareProfile();
                                        },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.share, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Share Profile'),
                                    ],
                                  ),
          ),
          // Sign Out button (only for current user)
          if (_isCurrentUserProfile)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                HapticFeedback.lightImpact();
                _showSignOutConfirmation();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.square_arrow_right, color: CupertinoColors.destructiveRed),
                  SizedBox(width: 8),
                  Text(
                    'Sign Out',
                    style: TextStyle(color: CupertinoColors.destructiveRed),
                  ),
                ],
              ),
            ),
          if (!_isCurrentUserProfile)
                            CupertinoActionSheetAction(
                              onPressed: () {
                                Navigator.pop(context);
                HapticFeedback.lightImpact();
                // TODO: Implement follow/unfollow functionality
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.person_add, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Follow'),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                  ),
                                );
  }

  Future<void> _shareProfile() async {
    final profileUrl = 'https://openslot.app/profile/${_user?.id ?? 'unknown'}';
    final shareText = _isCurrentUserProfile 
        ? 'Check out my OpenSlot profile!'
        : 'Check out ${_user?.username}\'s OpenSlot profile!';
    
    await Share.share('$shareText\n$profileUrl');
  }

  void _showSignOutConfirmation() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.watch<ThemeProvider>().textColor,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Are you sure you want to sign out of your account?',
            style: TextStyle(
              fontSize: 14,
              color: context.watch<ThemeProvider>().textColor.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              HapticFeedback.lightImpact();
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text(
              'Sign Out',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              HapticFeedback.mediumImpact();
              await _performSignOut();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _performSignOut() async {
    try {
      // Show loading state (optional)
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // Sign out from Firebase
      await _authService.signOut();
      
      // Navigate to login page and clear navigation stack
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute(
            builder: (context) => const LoginPage(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      Logger.e('Error signing out: $e', tag: 'Profile_page');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Show error dialog
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Sign Out Failed'),
            content: Text('An error occurred while signing out: ${e.toString()}'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _launchSocialMedia(String platform, String handle) async {
    String url;
    switch (platform.toLowerCase()) {
      case 'instagram':
        url = 'https://instagram.com/$handle';
        break;
      case 'twitter':
        url = 'https://twitter.com/$handle';
        break;
      case 'tiktok':
        url = 'https://tiktok.com/@$handle';
        break;
      case 'youtube':
        url = 'https://youtube.com/@$handle';
        break;
      default:
        url = handle.startsWith('http') ? handle : 'https://$handle';
    }
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      Logger.d('Error launching URL $url: $e', tag: 'Profile_page');
      if (mounted) {
                                showCupertinoDialog(
                                  context: context,
                                  builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Could not open $platform profile'),
                                    actions: [
                                      CupertinoDialogAction(
                                        onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
      }
    }
  }

  // Profile sections
  Widget _buildProfileHeader() {
    return Center(
          child: Column(
            children: [
          // Profile picture
          Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.highlight,
                        AppColors.accent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                    child: CircleAvatar(
                      radius: 55,
              backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 50,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        backgroundImage: _user!.photoUrl.isNotEmpty
                            ? NetworkImage(_user!.photoUrl)
                            : null,
                        child: _user!.photoUrl.isEmpty
                            ? Icon(
                                CupertinoIcons.person_fill,
                                size: 50,
                        color: AppColors.primary.withValues(alpha: 0.5),
                              )
                            : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
          // Username
          Text(
                  _user!.username,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: context.watch<ThemeProvider>().textColor,
                    letterSpacing: -0.5,
                                  ),
                                ),
              const SizedBox(height: 12),
              // Social Media Links
              if (_user?.instagram.isNotEmpty == true || _user?.twitter.isNotEmpty == true)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_user?.instagram.isNotEmpty == true)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _launchSocialMedia('instagram', _user!.instagram),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4405F),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(CupertinoIcons.camera, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '@${_user!.instagram}',
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_user?.twitter.isNotEmpty == true) ...[
                      if (_user?.instagram.isNotEmpty == true) const SizedBox(width: 8),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _launchSocialMedia('twitter', _user!.twitter),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1DA1F2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(CupertinoIcons.at, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '@${_user!.twitter}',
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                              ],
      ),
    );
  }



  Widget _buildProfileStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                 children: [
           _buildStatItem('Events', '${_user?.savedEvents.length ?? 0}', CupertinoIcons.calendar),
           _buildStatItem('Open Mics', '${_user?.openMics.length ?? 0}', CupertinoIcons.mic),
           _buildStatItem('Awards', '${_userAwards.length}', CupertinoIcons.star),
              ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.1),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: context.watch<ThemeProvider>().textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: context.watch<ThemeProvider>().textColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildBioSection() {
    final bool hasBio = _user?.bio.isNotEmpty == true;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DSSectionHeader(
          title: 'About',
          icon: CupertinoIcons.person_alt_circle,
          showBorder: false,
          padding: EdgeInsets.zero,
        ),
        LayoutHelpers.sectionSpacing,
        Container(
          padding: LayoutHelpers.cardPadding,
          decoration: hasBio 
              ? ComponentStyles.card
              : ComponentStyles.elevatedCard,
          child: hasBio
              ? Text(
                  _user!.bio,
                  style: DesignSystem.body1.copyWith(
                    color: CupertinoColors.white,
                    height: 1.5,
                  ),
                )
              : Column(
                  children: [
                    const Icon(
                      CupertinoIcons.doc_text,
                      size: 32,
                      color: CupertinoColors.systemGrey,
                    ),
                    LayoutHelpers.sectionSpacing,
                    Text(
                      'No bio available',
                      style: DesignSystem.body1.copyWith(
                        color: CupertinoColors.systemGrey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
  
  Widget _buildAwardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DSSectionHeader(
          title: 'Awards & Achievements',
          icon: CupertinoIcons.star_circle,
          showBorder: false,
          padding: EdgeInsets.zero,
          trailing: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignSystem.spacingS, 
              vertical: DesignSystem.spacingXS
            ),
            decoration: BoxDecoration(
              color: DesignSystem.primaryOrange,
              borderRadius: BorderRadius.circular(DesignSystem.radiusS),
            ),
            child: Text(
              '${_userAwards.length} earned',
              style: DesignSystem.caption.copyWith(
                color: CupertinoColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        LayoutHelpers.sectionSpacing,
        Container(
          padding: LayoutHelpers.cardPadding,
          decoration: ComponentStyles.card,
          child: _userAwards.isEmpty
              ? _buildEmptyAwardsState()
              : Column(
                  children: [
                    // Featured Awards Grid
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _userAwards.length,
                        itemBuilder: (context, index) {
                          final award = _userAwards[index];
                          return _buildEnhancedAwardCard(award, index);
                        },
                      ),
                    ),
                    
                    LayoutHelpers.sectionSpacing,
                    
                    // Latest Achievement Section - only show if there are incomplete achievements
                    if (_hasIncompleteAchievements())
                      _buildAchievementInProgressSection(),
                  ],
                ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyAwardsState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.star_circle,
            size: 32,
            color: context.watch<ThemeProvider>().textColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'No awards yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.watch<ThemeProvider>().textColor.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Complete performances and events to earn achievements',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: context.watch<ThemeProvider>().textColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEnhancedAwardCard(Award award, int index) {
    return GestureDetector(
      onTap: () => _showAwardPopup(award),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rarity Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AwardsHelper.getRarityColor(award.rarity),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                AwardsHelper.getRarityText(award.rarity),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Award Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                award.icon,
                size: 24,
                color: AppColors.primary,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Award Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                award.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: context.watch<ThemeProvider>().textColor,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Check if there are any achievements that are not yet completed
  bool _hasIncompleteAchievements() {
    // For this demo, we'll check if the user has completed all basic achievements
    // In a real app, you would check against actual user progress data
    

    
    // If user hasn't completed major achievements, show progress section
    // For now, only show if they haven't achieved the 50 Open Mics (major achievement)
    final hasFiftyOpenMics = _userAwards.any((award) => award.id == AwardsHelper.fiftyOpenMics.id);
    
    return !hasFiftyOpenMics;
  }

  Widget _buildAchievementInProgressSection() {
    // Show the 50 Open Mics achievement as the one in progress
    final inProgressAward = AwardsHelper.fiftyOpenMics;
    const currentProgress = 12; // Example: user has done 12 open mics so far
    const totalRequired = 50;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Achievement in Progress',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.watch<ThemeProvider>().textColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'IN PROGRESS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        GestureDetector(
          onTap: () => _showAwardPopup(inProgressAward),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    inProgressAward.icon,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inProgressAward.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.watch<ThemeProvider>().textColor,
                        ),
                      ),
                      Text(
                        inProgressAward.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.watch<ThemeProvider>().textColor.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Always show progress bar for achievements in progress
                      _buildProgressBar(currentProgress, totalRequired),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildProgressBar(int current, int total) {
    final progress = current / total;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress:',
              style: TextStyle(
                fontSize: 12,
                color: context.watch<ThemeProvider>().textColor.withValues(alpha: 0.6),
              ),
            ),
            Text(
              '$current/$total',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.watch<ThemeProvider>().textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            widthFactor: progress,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  void _showAwardPopup(Award award) {
    HapticFeedback.lightImpact();
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        margin: const EdgeInsets.all(20),
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.watch<ThemeProvider>().isDarkMode
                    ? AppColors.backgroundDark
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.xmark,
                            color: context.watch<ThemeProvider>().textColor,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Award Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      award.icon,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Rarity Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AwardsHelper.getRarityColor(award.rarity),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AwardsHelper.getRarityText(award.rarity),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Award Name
                  Text(
                    award.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.watch<ThemeProvider>().textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Award Description
                  Text(
                    award.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.watch<ThemeProvider>().textColor.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Progress Chart (only show for unearned awards)
                  if (award.earnedDate == null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Achievement Progress',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.watch<ThemeProvider>().textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildCircularProgress(0.8), // 80% completion example
                        ],
                      ),
                    ),
                  
                  if (award.earnedDate == null) const SizedBox(height: 16),
                  
                  // Earned Date
                  if (award.earnedDate != null)
                    Text(
                      'Earned ${_formatEarnedDate(award.earnedDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.watch<ThemeProvider>().textColor.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCircularProgress(double progress) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        children: [
          // Progress circle
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: Colors.grey.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          // Progress text
          Positioned.fill(
            child: Center(
              child: Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.watch<ThemeProvider>().textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatEarnedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }
} 