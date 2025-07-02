// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:slotted/common/design_system.dart';
import 'package:slotted/utils/logger.dart';

class CodeVerificationPage extends StatefulWidget {
  final String verificationId;
  final VoidCallback? onVerificationComplete;

  const CodeVerificationPage({
    super.key, 
    required this.verificationId, 
    this.onVerificationComplete,
  });

  @override
  CodeVerificationPageState createState() => CodeVerificationPageState();
}

class CodeVerificationPageState extends State<CodeVerificationPage> with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();
  bool _loading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
      curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
    ));
    
    // Start animation and focus the input
    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _codeFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _formatVerificationCode(String input) {
    // Remove all non-digit characters
    final digits = input.replaceAll(RegExp(r'\D'), '');
    
    // Format with spaces for better readability: X X X X X X
    String formatted = '';
    for (int i = 0; i < digits.length && i < 6; i++) {
      if (i > 0) formatted += ' ';
      formatted += digits[i];
    }
    
    return formatted;
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _loading = false;
    });
    
    // Error haptic feedback
    HapticFeedback.heavyImpact();
    
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
            Text('Verification Failed'),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text(
              'Try Again',
              style: TextStyle(
                color: DesignSystem.primaryOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              HapticFeedback.lightImpact();
              _codeFocusNode.requestFocus();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        border: null,
        middle: const Text(
          'Enter Verification Code',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: _loading 
            ? null 
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                child: const Icon(
                  CupertinoIcons.back,
                  color: DesignSystem.primaryOrange,
                ),
              ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              CupertinoColors.white,
              DesignSystem.primaryOrange.withValues(alpha: 0.03),
              CupertinoColors.white,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(DesignSystem.spacingL),
                child: Column(
                  children: [
                    const SizedBox(height: DesignSystem.spacingXXL),
                    
                    // Icon and instruction
                    Container(
                      padding: const EdgeInsets.all(DesignSystem.spacingL),
                      decoration: BoxDecoration(
                        color: DesignSystem.primaryOrange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: DesignSystem.primaryOrange.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.chat_bubble_text,
                        size: 60,
                        color: DesignSystem.primaryOrange,
                      ),
                    ),
                    
                    const SizedBox(height: DesignSystem.spacingXL),
                    
                    Text(
                      'Check Your Messages',
                      style: DesignSystem.h2.copyWith(
                        color: DesignSystem.primaryOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: DesignSystem.spacingS),
                    
                    Text(
                      'We sent a 6-digit verification code to your phone number',
                      textAlign: TextAlign.center,
                      style: DesignSystem.body1.copyWith(
                        color: CupertinoColors.systemGrey,
                        height: 1.4,
                      ),
                    ),
                    
                    const SizedBox(height: DesignSystem.spacingXXL),
                    
                    // Code input field
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
                        border: Border.all(
                          color: _errorMessage != null 
                              ? CupertinoColors.destructiveRed 
                              : DesignSystem.primaryOrange.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: CupertinoTextField(
                        controller: _codeController,
                        focusNode: _codeFocusNode,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(
                          color: CupertinoColors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          letterSpacing: 8.0,
                        ),
                        padding: const EdgeInsets.all(DesignSystem.spacingL),
                        placeholder: '0 0 0 0 0 0',
                        placeholderStyle: const TextStyle(
                          color: CupertinoColors.systemGrey3,
                          fontWeight: FontWeight.w400,
                          fontSize: 24,
                          letterSpacing: 8.0,
                        ),
                        autofocus: false,
                        maxLength: 11, // 6 digits + 5 spaces
                        decoration: null,
                        onChanged: (value) {
                          // Clear any previous error
                          if (_errorMessage != null) {
                            setState(() {
                              _errorMessage = null;
                            });
                          }
                          
                          // Format verification code as user types
                          final formatted = _formatVerificationCode(value);
                          if (formatted != value) {
                            _codeController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(offset: formatted.length),
                            );
                          }
                          
                          // Auto-verify when 6 digits are entered
                          final digits = value.replaceAll(RegExp(r'\D'), '');
                          if (digits.length == 6) {
                            _verifyCode(digits);
                          }
                        },
                        onSubmitted: (value) {
                          final digits = value.replaceAll(RegExp(r'\D'), '');
                          if (digits.length == 6) {
                            _verifyCode(digits);
                          }
                        },
                      ),
                    ),
                    
                    // Error message
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: DesignSystem.spacingS,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                                textAlign: TextAlign.center,
                                style: DesignSystem.caption.copyWith(
                                  color: CupertinoColors.destructiveRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: DesignSystem.spacingXL),
                    
                    // Verify button
                    Container(
                      width: double.infinity,
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
                        onPressed: _loading
                            ? null
                            : () {
                                final code = _codeController.text.replaceAll(RegExp(r'\D'), '');
                                _verifyCode(code);
                              },
                        child: _loading
                            ? const CupertinoActivityIndicator(
                                radius: 12,
                                color: CupertinoColors.white,
                              )
                            : Text(
                                'Verify Code',
                                style: DesignSystem.body1.copyWith(
                                  color: CupertinoColors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: DesignSystem.spacingL),
                    
                    // Resend code option
                    CupertinoButton(
                      onPressed: _loading ? null : _resendCode,
                      child: Text(
                        'Didn\'t receive the code? Resend',
                        style: DesignSystem.body2.copyWith(
                          color: DesignSystem.primaryOrange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _verifyCode(String code) async {
    if (code.length != 6) {
      _showError('Please enter the complete 6-digit verification code');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    // Success haptic feedback
    HapticFeedback.lightImpact();

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: code,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Check if widget is still mounted after async operation
      if (!mounted) return;
      
      // Success haptic feedback
      HapticFeedback.mediumImpact();
      
      Navigator.of(context).pop();
      
      // Call the callback if provided
      if (widget.onVerificationComplete != null) {
        widget.onVerificationComplete!();
      }
    } catch (e) {
      // Check if widget is still mounted after async operation
      if (!mounted) return;
      
      Logger.e('Verification error: $e', tag: 'CodeVerification');
      
      String errorMessage;
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-verification-code':
            errorMessage = 'Invalid verification code. Please try again.';
            break;
          case 'session-expired':
            errorMessage = 'Verification session expired. Please request a new code.';
            break;
          default:
            errorMessage = e.message ?? 'Verification failed. Please try again.';
        }
      } else {
        errorMessage = 'Verification failed. Please try again.';
      }
      
      _showError(errorMessage);
    } finally {
      // Check if widget is still mounted before updating state
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    HapticFeedback.lightImpact();
    
    // Show success message
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(
          'Code Sent',
          style: TextStyle(
            color: DesignSystem.primaryOrange,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text('A new verification code has been sent to your phone number.'),
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
              _codeFocusNode.requestFocus();
            },
          ),
        ],
      ),
    );
  }
}
