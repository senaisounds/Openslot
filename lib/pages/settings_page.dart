import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:provider/provider.dart';
import 'package:slotted/providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import 'package:slotted/api/firebase_auth_service.dart';
import 'package:slotted/pages/login_page.dart';
import 'package:slotted/common/colors.dart' as app_colors;

class SettingsPage extends StatefulWidget {
  final User? user;

  const SettingsPage({super.key, required this.user});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  late AnimationController _smokeController;
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _isLoggingOut = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize smoke effect animation
    _smokeController = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    );
    _smokeController.repeat();
  }
  
  @override
  void dispose() {
    _smokeController.dispose();
    super.dispose();
  }

  // Handle logout
  Future<void> _handleLogout() async {
    // Show confirmation dialog first
    final bool shouldLogout = await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            child: const Text('Log Out'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ) ?? false;
    
    if (!shouldLogout) return;
    
    setState(() {
      _isLoggingOut = true;
    });
    
    try {
      await _authService.signOut();
      // Check if widget is still mounted before using context
      if (!mounted) return;
      // Navigate to login page and remove all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        CupertinoPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      // Check if widget is still mounted before using context
      if (!mounted) return;
      // Show error dialog
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Logout Failed'),
          content: Text('An error occurred: $e'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return CupertinoPageScaffold(
      backgroundColor: isDarkMode ? app_colors.AppColors.backgroundDark : app_colors.AppColors.backgroundLight,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDarkMode ? app_colors.AppColors.backgroundDark : app_colors.AppColors.backgroundLight,
        middle: Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? app_colors.AppColors.accent : app_colors.AppColors.primary,
          ),
        ),
      ),
      child: AnimatedBuilder(
        animation: _smokeController,
        builder: (context, child) {
          final progress = _smokeController.value;
          return Container(
            decoration: BoxDecoration(
              gradient: isDarkMode 
                ? RadialGradient(
                    center: Alignment(
                      math.sin(progress * math.pi * 2) * 0.3,
                      math.cos(progress * math.pi * 2) * 0.3,
                    ),
                    focal: Alignment(
                      math.cos(progress * math.pi) * 0.5,
                      math.sin(progress * math.pi) * 0.5,
                    ),
                    colors: [
                      app_colors.AppColors.primary.withValues(alpha: 0.15),
                      app_colors.AppColors.secondary.withValues(alpha: 0.15),
                      app_colors.AppColors.accent.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.3, 0.6, 1.0],
                    radius: 1.8,
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      app_colors.AppColors.primary.withValues(alpha: 0.05),
                      app_colors.AppColors.secondary.withValues(alpha: 0.05),
                    ],
                  ),
            ),
            child: SafeArea(
              child: ListView(
                children: [
                  const SizedBox(height: 20),
                  _buildSection(
                    'Notifications',
                    [
                      _buildSettingItem(
                        context,
                        icon: CupertinoIcons.bell_fill,
                        title: 'Event Reminders',
                        trailing: const CupertinoSwitch(
                          value: true,
                          activeTrackColor: app_colors.AppColors.primary,
                          onChanged: null,
                        ),
                        isDarkMode: isDarkMode,
                      ),
                    ],
                    isDarkMode: isDarkMode,
                  ),
                  if (widget.user != null) ...[
                    const SizedBox(height: 20),
                    _buildSection(
                      'Account',
                      [
                        _buildSettingItem(
                          context,
                          icon: CupertinoIcons.person_fill,
                          title: 'Edit Profile',
                          onTap: () {
                            // Navigate to profile editing
                          },
                          isDarkMode: isDarkMode,
                        ),
                        _buildSettingItem(
                          context,
                          icon: CupertinoIcons.envelope_fill,
                          title: 'Change Email',
                          onTap: () {
                            // Handle email change
                          },
                          isDarkMode: isDarkMode,
                        ),
                        _buildSettingItem(
                          context,
                          icon: CupertinoIcons.lock_fill,
                          title: 'Change Password',
                          onTap: () {
                            // Handle password change
                          },
                          isDarkMode: isDarkMode,
                        ),
                        _buildSettingItem(
                          context,
                          icon: CupertinoIcons.square_arrow_right,
                          title: 'Log Out',
                          onTap: _isLoggingOut ? null : _handleLogout,
                          trailing: _isLoggingOut 
                            ? const CupertinoActivityIndicator() 
                            : null,
                          isDarkMode: isDarkMode,
                          isDestructive: true,
                        ),
                      ],
                      isDarkMode: isDarkMode,
                    ),
                  ],
                  const SizedBox(height: 20),
                  _buildSection(
                    'About',
                    [
                      _buildSettingItem(
                        context,
                        icon: CupertinoIcons.info_circle_fill,
                        title: 'Version',
                        trailing: Text(
                          '1.0.0',
                          style: TextStyle(
                            color: isDarkMode
                                ? app_colors.AppColors.backgroundLight.withValues(alpha: 0.5)
                                : app_colors.AppColors.backgroundDark.withValues(alpha: 0.5),
                          ),
                        ),
                        isDarkMode: isDarkMode,
                      ),
                    ],
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items, {required bool isDarkMode}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode
                  ? app_colors.AppColors.accent.withValues(alpha: 0.8)
                  : app_colors.AppColors.primary,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDarkMode
                ? app_colors.AppColors.backgroundDark.withValues(alpha: 0.8)
                : app_colors.AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode
                  ? app_colors.AppColors.primary.withValues(alpha: 0.2)
                  : app_colors.AppColors.secondary.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? app_colors.AppColors.primary.withValues(alpha: 0.1)
                    : app_colors.AppColors.secondary.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    required bool isDarkMode,
    bool isDestructive = false,
  }) {
    final Color textColor = isDestructive 
        ? CupertinoColors.destructiveRed 
        : (isDarkMode
            ? app_colors.AppColors.backgroundLight.withValues(alpha: 0.9)
            : app_colors.AppColors.backgroundDark.withValues(alpha: 0.8));
            
    final Color iconColor = isDestructive
        ? CupertinoColors.destructiveRed
        : (isDarkMode ? app_colors.AppColors.primary : app_colors.AppColors.primary.withValues(alpha: 0.8));
        
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.95, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return Transform.scale(
            scale: onTap != null ? value : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? (isDestructive 
                              ? CupertinoColors.destructiveRed.withValues(alpha: 0.1)
                              : app_colors.AppColors.primary.withValues(alpha: 0.1))
                          : (isDestructive
                              ? CupertinoColors.destructiveRed.withValues(alpha: 0.05)
                              : app_colors.AppColors.primary.withValues(alpha: 0.05)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 