import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:slotted/widgets/code_verification_page.dart';
import 'package:slotted/widgets/terms_of_service_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:slotted/api/firebase_auth_service.dart';

import 'package:slotted/common/design_system.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:slotted/common/responsive_system.dart';
import 'package:slotted/widgets/responsive_safe_area.dart';
import 'package:slotted/pages/home_page.dart';
import 'package:slotted/utils/logger.dart';
import 'package:provider/provider.dart';
import 'package:slotted/providers/theme_provider.dart';

class AppleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CupertinoColors.white
      ..style = PaintingStyle.fill;
    
    // Draw the official Apple logo with the characteristic bite
    final path = Path();
    
    // Apple body - starting from the top
    path.moveTo(size.width * 0.5, size.height * 0.05);
    
    // Top curve
    path.quadraticBezierTo(size.width * 0.7, size.height * 0.05, size.width * 0.8, size.height * 0.15);
    path.quadraticBezierTo(size.width * 0.85, size.height * 0.25, size.width * 0.85, size.height * 0.4);
    
    // Right side curve (before the bite)
    path.quadraticBezierTo(size.width * 0.85, size.height * 0.55, size.width * 0.8, size.height * 0.65);
    
    // The bite - curve inward on the right side
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.6, size.width * 0.7, size.height * 0.65);
    path.quadraticBezierTo(size.width * 0.65, size.height * 0.7, size.width * 0.6, size.height * 0.65);
    
    // Continue the right side after the bite
    path.quadraticBezierTo(size.width * 0.55, size.height * 0.6, size.width * 0.5, size.height * 0.65);
    
    // Bottom curve
    path.quadraticBezierTo(size.width * 0.45, size.height * 0.6, size.width * 0.4, size.height * 0.65);
    path.quadraticBezierTo(size.width * 0.35, size.height * 0.7, size.width * 0.3, size.height * 0.65);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.6, size.width * 0.2, size.height * 0.65);
    
    // Left side curve
    path.quadraticBezierTo(size.width * 0.15, size.height * 0.55, size.width * 0.15, size.height * 0.4);
    path.quadraticBezierTo(size.width * 0.15, size.height * 0.25, size.width * 0.2, size.height * 0.15);
    path.quadraticBezierTo(size.width * 0.3, size.height * 0.05, size.width * 0.5, size.height * 0.05);
    path.close();
    
    // Apple stem
    final stemPath = Path();
    stemPath.moveTo(size.width * 0.45, size.height * 0.05);
    stemPath.lineTo(size.width * 0.55, size.height * 0.05);
    stemPath.lineTo(size.width * 0.52, size.height * 0.15);
    stemPath.lineTo(size.width * 0.48, size.height * 0.15);
    stemPath.close();
    
    // Apple leaf
    final leafPath = Path();
    leafPath.moveTo(size.width * 0.52, size.height * 0.15);
    leafPath.quadraticBezierTo(size.width * 0.6, size.height * 0.1, size.width * 0.65, size.height * 0.2);
    leafPath.quadraticBezierTo(size.width * 0.6, size.height * 0.25, size.width * 0.52, size.height * 0.15);
    leafPath.close();
    
    canvas.drawPath(path, paint);
    canvas.drawPath(stemPath, paint);
    canvas.drawPath(leafPath, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FocusNode _phoneFocusNode = FocusNode();
  
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    ));
    
    // Start animation
    _animationController.forward();
    
    // Pre-fill with test credentials for development
    if (kDebugMode) {
      // Debug credentials removed for security
      // Use test accounts through proper channels instead
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
    
    // Haptic feedback for errors
    HapticFeedback.mediumImpact();
    
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: const Row(
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: CupertinoColors.destructiveRed,
              size: 20,
            ),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text(
              'OK',
              style: TextStyle(
                color: DesignSystem.primaryOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              HapticFeedback.lightImpact();
            },
          ),
        ],
      ),
    );
  }

  String _formatPhoneNumber(String input) {
    // Remove all non-digit characters
    final digits = input.replaceAll(RegExp(r'\D'), '');
    
    // Format as (XXX) XXX-XXXX
    if (digits.length >= 6) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, digits.length > 10 ? 10 : digits.length)}';
    } else if (digits.length >= 3) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3)}';
    } else {
      return digits;
    }
  }

  Future<void> _signInWithPhone() async {
    final phoneNumber = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    
    if (phoneNumber.isEmpty) {
      _showError('Please enter your phone number');
      return;
    }
    
    if (phoneNumber.length != 10) {
      _showError('Please enter a valid 10-digit phone number');
      return;
    }
    
    // Format phone number with country code
    final formattedPhoneNumber = '+1$phoneNumber';
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    // Success haptic feedback
    HapticFeedback.lightImpact();

    try {
      await _authService.signInWithPhone(
        phoneNumber: formattedPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final userCredential = await _authService.firebaseAuth.signInWithCredential(credential);
            if (userCredential.user != null) {
              await _handleSuccessfulLogin(userCredential.user!);
            }
          } catch (e) {
            _showError('Authentication failed: ${e.toString()}');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          String errorMessage;
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'Invalid phone number format';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many attempts. Please try again later';
              break;
            case 'quota-exceeded':
              errorMessage = 'SMS quota exceeded. Please try again later';
              break;
            default:
              errorMessage = e.message ?? 'Verification failed';
          }
          _showError(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isLoading = false;
          });
          
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => CodeVerificationPage(
                verificationId: verificationId,
                onVerificationComplete: () async {
                  final user = _authService.currentUser;
                  if (user != null) {
                    await _handleSuccessfulLogin(user);
                  }
                },
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (_isLoading) {
            setState(() {
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      Logger.e('Phone sign in error: $e', tag: 'Login_page');
      _showError('Failed to send verification code. Please try again.');
    }
  }
  
  Future<void> _handleSuccessfulLogin(User user) async {
    try {
      // Check if user exists in Firestore
      SlottedUser? slottedUser = await _authService.getSlottedUser(user.uid);
      
      // If user doesn't exist, create a new one
      if (slottedUser == null) {
        slottedUser = SlottedUser();
        slottedUser.id = user.uid;
        slottedUser.username = user.displayName ?? '';
        slottedUser.phoneNumber = user.phoneNumber;
        slottedUser.email = user.email;
        slottedUser.photoUrl = user.photoURL ?? '';
        slottedUser.isHost = false;
        slottedUser.createdAt = DateTime.now();
        slottedUser.lastLogin = DateTime.now();
        
        await _authService.updateUserData(slottedUser);
        
        // Show Terms of Service for new users
        if (mounted) {
          _showTermsOfServiceDialog();
        }
      } else {
        // Update last login time
        await _authService.updateLastLogin(user.uid);
        
        // Success haptic feedback
        HapticFeedback.mediumImpact();
        
        // Navigate to home page for existing users
        if (mounted) {
          _navigateToHomePage();
        }
      }
    } catch (e) {
      Logger.e('Error setting up user profile: $e', tag: 'Login_page');
      _showError('Error setting up user profile. Please try again.');
    }
  }

  void _showTermsOfServiceDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TermsOfServiceDialog(
        onAccept: () {
          // Success haptic feedback
          HapticFeedback.mediumImpact();
          _navigateToHomePage();
        },
        onDecline: () {
          // Sign out the user if they decline terms
          _authService.signOut();
          _showError('You must accept the Terms of Service to use the app.');
        },
      ),
    );
  }

  void _navigateToHomePage() {
    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
          child: const HomePage(),
        ),
      ),
      (route) => false,
    );
  }
  
  Future<void> _debugSkipLogin() async {
    if (!kDebugMode) return;
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      final userCredential = await _authService.firebaseAuth.signInAnonymously();
      
      if (userCredential.user != null) {
        await _handleSuccessfulLogin(userCredential.user!);
      }
    } catch (e) {
      Logger.d('Debug skip login error: $e', tag: 'Login_page');
      _showError('Error skipping login: $e');
    }
  }
  
  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticFeedback.lightImpact();

    try {
      final userCredential = await _authService.signInWithApple();
      
      if (userCredential.user != null) {
        await _handleSuccessfulLogin(userCredential.user!);
      }
    } catch (e) {
      Logger.e('Apple Sign In error: $e', tag: 'Login_page');
      
      // Provide more specific error messages
      String errorMessage = 'Apple Sign In failed. Please try again or use phone number.';
      
      if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('cancelled')) {
        errorMessage = 'Apple Sign In was cancelled.';
      } else if (e.toString().contains('not supported')) {
        errorMessage = 'Apple Sign In is not supported on this device.';
      } else if (e.toString().contains('invalid')) {
        errorMessage = 'Invalid Apple Sign In configuration. Please contact support.';
      }
      
      _showError(errorMessage);
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
      backgroundColor: CupertinoColors.white,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              CupertinoColors.white,
              DesignSystem.primaryOrange.withValues(alpha: 0.05),
              CupertinoColors.white,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: ResponsivePageWrapper(
          constrainWidth: true,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.horizontal,
                  vertical: context.spacing.vertical,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    
                    // Welcome text
                     Text(
                       'Welcome to openslot',
                       textAlign: TextAlign.center,
                       style: DesignSystem.h1.copyWith(
                         color: DesignSystem.primaryOrange,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                     
                     const SizedBox(height: DesignSystem.spacingS),
                     
                     Text(
                       'Sign in with your phone number to continue',
                       textAlign: TextAlign.center,
                       style: DesignSystem.body1.copyWith(
                         color: CupertinoColors.systemGrey,
                       ),
                     ),
                    
                    const SizedBox(height: DesignSystem.spacingXXL),
                    
                    // Phone input section
                    Container(
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                        boxShadow: [
                          BoxShadow(
                            color: DesignSystem.primaryOrange.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Country code prefix
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DesignSystem.spacingM,
                              vertical: DesignSystem.spacingM,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(
                                  color: CupertinoColors.systemGrey4.withAlpha(77),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  "🇺🇸",
                                  style: TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: DesignSystem.spacingXS),
                                                                 Text(
                                   "+1",
                                   style: DesignSystem.body1.copyWith(
                                     color: CupertinoColors.black,
                                     fontWeight: FontWeight.w600,
                                   ),
                                 ),
                              ],
                            ),
                          ),
                          
                          // Phone number input
                          Expanded(
                            child: CupertinoTextField(
                              controller: _phoneController,
                              focusNode: _phoneFocusNode,
                              placeholder: '(555) 123-4567',
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              padding: const EdgeInsets.symmetric(
                                vertical: DesignSystem.spacingM,
                                horizontal: DesignSystem.spacingM,
                              ),
                              prefix: Container(
                                padding: const EdgeInsets.only(right: DesignSystem.spacingXS),
                                child: const Icon(
                                  CupertinoIcons.phone,
                                  color: DesignSystem.primaryOrange,
                                  size: 22,
                                ),
                              ),
                                                             style: DesignSystem.body1.copyWith(
                                 color: CupertinoColors.black,
                                 letterSpacing: 0.5,
                                 fontWeight: FontWeight.w600,
                               ),
                              placeholderStyle: TextStyle(
                                color: CupertinoColors.systemGrey.withAlpha(179),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                              decoration: null,
                              clearButtonMode: OverlayVisibilityMode.editing,
                              onChanged: (value) {
                                // Clear any previous error
                                if (_errorMessage != null) {
                                  setState(() {
                                    _errorMessage = null;
                                  });
                                }
                                
                                // Format phone number as user types
                                final formatted = _formatPhoneNumber(value);
                                if (formatted != value) {
                                  _phoneController.value = TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(offset: formatted.length),
                                  );
                                }
                              },
                              onSubmitted: (_) => _signInWithPhone(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Error message
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: DesignSystem.spacingS,
                          left: DesignSystem.spacingM,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.exclamationmark_circle,
                              color: CupertinoColors.destructiveRed,
                              size: 16,
                            ),
                            const SizedBox(width: DesignSystem.spacingXS),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: DesignSystem.caption.copyWith(
                                  color: CupertinoColors.destructiveRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: DesignSystem.spacingXL),
                    
                    // Continue button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                        gradient: LinearGradient(
                          colors: [
                            DesignSystem.primaryOrange,
                            DesignSystem.primaryOrange.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: DesignSystem.primaryOrange.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: DesignSystem.spacingM),
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                        onPressed: _isLoading ? null : _signInWithPhone,
                        child: _isLoading
                            ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                                                         : Text(
                                 'Continue',
                                 style: DesignSystem.body1.copyWith(
                                   color: CupertinoColors.white,
                                   fontWeight: FontWeight.w600,
                                   fontSize: 18,
                                 ),
                               ),
                      ),
                    ),
                    
                    const SizedBox(height: DesignSystem.spacingXL),
                    
                    // Divider
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            color: CupertinoColors.systemGrey4,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingM),
                          child: Text(
                            'OR',
                            style: DesignSystem.caption.copyWith(
                              color: CupertinoColors.systemGrey,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(
                            color: CupertinoColors.systemGrey4,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: DesignSystem.spacingXL),
                    
                    // Apple Sign In button - Updated to match Apple's official design
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: CupertinoColors.black,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: CupertinoColors.black,
                          width: 1,
                        ),
                      ),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        onPressed: _isLoading ? null : _signInWithApple,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Apple logo
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CustomPaint(
                                size: const Size(20, 20),
                                painter: AppleLogoPainter(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Text
                            const Text(
                              'Sign in with Apple',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    

                    
                    const Spacer(),
                    
                    // Debug skip login button (only in debug mode)
                    if (kDebugMode)
                      GestureDetector(
                        onTap: _debugSkipLogin,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: DesignSystem.spacingS,
                            horizontal: DesignSystem.spacingL,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(DesignSystem.radiusS),
                            border: Border.all(
                              color: CupertinoColors.systemGrey5,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Debug: Skip Login',
                            textAlign: TextAlign.center,
                            style: DesignSystem.caption.copyWith(
                              color: CupertinoColors.systemGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 