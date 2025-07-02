import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:slotted/api/firebase_auth_service.dart';
import 'package:slotted/utils/validation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slotted/utils/logger.dart';

/// A secure authentication service that extends Firebase auth with additional security features
class SecureAuthService {
  // Singleton pattern
  SecureAuthService._privateConstructor();
  static final SecureAuthService instance = SecureAuthService._privateConstructor();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseAuthService _baseAuthService = FirebaseAuthService();
  
  // Login attempt tracking
  static const int _maxFailedAttempts = 5;
  static const int _lockoutDurationMinutes = 15;
  static const int _maxAttemptsPerHour = 10;
  
  /// Regular expression for strong passwords
  /// Requires at least 8 characters, one uppercase letter, one lowercase letter,
  /// one number, and one special character
  static final RegExp _strongPasswordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$'
  );
  
  /// Get the current authenticated user
  User? get currentUser => _auth.currentUser;
  
  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  /// Sign in with email and password with rate limiting and account lockout
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      // Check for too many login attempts
      if (await _isTooManyLoginAttempts(email)) {
        throw FirebaseAuthException(
          code: 'too-many-requests',
          message: 'Too many unsuccessful login attempts. Please try again later.',
        );
      }
      
      // Check if account is locked
      if (await _isAccountLocked(email)) {
        final lockoutEndTime = await _getLockoutEndTime(email);
        final now = DateTime.now();
        final remainingMinutes = lockoutEndTime.difference(now).inMinutes + 1;
        
        throw FirebaseAuthException(
          code: 'account-locked',
          message: 'Account temporarily locked due to too many failed attempts. '
              'Please try again in $remainingMinutes minutes.',
        );
      }
      
      // Attempt login
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Reset failed attempts counter on successful login
      await _resetFailedAttempts(email);
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        // Increment failed attempts
        await _incrementFailedAttempts(email);
        
        // Check if account should be locked after this failed attempt
        final failedAttempts = await _getFailedAttempts(email);
        if (failedAttempts >= _maxFailedAttempts) {
          await _lockAccount(email);
          throw FirebaseAuthException(
            code: 'account-locked',
            message: 'Account temporarily locked due to too many failed attempts. '
                'Please try again in $_lockoutDurationMinutes minutes.',
          );
        }
        
        // For security, use same error message for both conditions
        throw FirebaseAuthException(
          code: 'invalid-credentials',
          message: 'Invalid email or password. '
              '${_maxFailedAttempts - failedAttempts} attempts remaining before account lockout.',
        );
      }
      
      // Pass through all other Firebase auth exceptions
      rethrow;
    }
  }
  
  /// Create a new user account with enhanced password validation
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required BuildContext context,
  }) async {
    // Validate email
    if (!ValidationService.instance.validateEmail(email)) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Please enter a valid email address.',
      );
    }
    
    // Validate password strength
    if (!_isStrongPassword(password)) {
      throw FirebaseAuthException(
        code: 'weak-password',
        message: 'Password must be at least 8 characters long and include uppercase, '
            'lowercase, number, and special character.',
      );
    }
    
    try {
      // Check if email is already in use
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'An account already exists for this email.',
        );
      }
      
      // Create the user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Set display name
      await userCredential.user?.updateDisplayName(displayName);
      
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }
  
  /// Check if a password is strong enough
  bool _isStrongPassword(String password) {
    return _strongPasswordRegex.hasMatch(password);
  }
  
  /// Sign out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    // Check for too many requests
    if (await _isTooManyResetRequests(email)) {
      throw FirebaseAuthException(
        code: 'too-many-requests',
        message: 'Too many password reset requests. Please try again later.',
      );
    }
    
    await _auth.sendPasswordResetEmail(email: email);
    await _recordPasswordResetRequest(email);
  }
  
  /// Update user password with validation
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is signed in');
    }
    
    // Validate current password
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      throw FirebaseAuthException(
        code: 'wrong-password',
        message: 'Current password is incorrect',
      );
    }
    
    // Validate new password strength
    if (!_isStrongPassword(newPassword)) {
      throw FirebaseAuthException(
        code: 'weak-password',
        message: 'Password must be at least 8 characters long and include uppercase, '
            'lowercase, number, and special character.',
      );
    }
    
    // Update password
    await user.updatePassword(newPassword);
  }
  
  /// Get current number of failed attempts for an email
  Future<int> _getFailedAttempts(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('failed_attempts_$email') ?? 0;
  }
  
  /// Increment failed attempts for an email
  Future<void> _incrementFailedAttempts(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = (prefs.getInt('failed_attempts_$email') ?? 0) + 1;
    await prefs.setInt('failed_attempts_$email', attempts);
    
    // Also increment hourly counter
    await _recordLoginAttempt(email);
  }
  
  /// Reset failed attempts for an email
  Future<void> _resetFailedAttempts(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('failed_attempts_$email');
    await prefs.remove('account_locked_until_$email');
  }
  
  /// Lock an account for a period of time
  Future<void> _lockAccount(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutEnd = DateTime.now().add(const Duration(minutes: _lockoutDurationMinutes));
    await prefs.setString('account_locked_until_$email', lockoutEnd.toIso8601String());
  }
  
  /// Check if an account is currently locked
  Future<bool> _isAccountLocked(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutUntilStr = prefs.getString('account_locked_until_$email');
    if (lockoutUntilStr == null) {
      return false;
    }
    
    final lockoutUntil = DateTime.parse(lockoutUntilStr);
    return DateTime.now().isBefore(lockoutUntil);
  }
  
  /// Get the time when account lockout ends
  Future<DateTime> _getLockoutEndTime(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutUntilStr = prefs.getString('account_locked_until_$email');
    if (lockoutUntilStr == null) {
      return DateTime.now();
    }
    
    return DateTime.parse(lockoutUntilStr);
  }
  
  /// Record a login attempt for rate limiting
  Future<void> _recordLoginAttempt(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final attemptKey = 'login_attempts_${email}_${_getHourKey()}';
    final attempts = (prefs.getInt(attemptKey) ?? 0) + 1;
    await prefs.setInt(attemptKey, attempts);
  }
  
  /// Check if too many login attempts have been made within the hour
  Future<bool> _isTooManyLoginAttempts(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final attemptKey = 'login_attempts_${email}_${_getHourKey()}';
    final attempts = prefs.getInt(attemptKey) ?? 0;
    return attempts >= _maxAttemptsPerHour;
  }
  
  /// Record a password reset request for rate limiting
  Future<void> _recordPasswordResetRequest(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final resetKey = 'pwd_reset_${email}_${_getDayKey()}';
    final attempts = (prefs.getInt(resetKey) ?? 0) + 1;
    await prefs.setInt(resetKey, attempts);
  }
  
  /// Check if too many password reset requests have been made
  Future<bool> _isTooManyResetRequests(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final resetKey = 'pwd_reset_${email}_${_getDayKey()}';
    final attempts = prefs.getInt(resetKey) ?? 0;
    return attempts >= 3; // Limit to 3 reset requests per day
  }
  
  /// Get a key representing the current hour for rate limiting
  String _getHourKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}-${now.hour}';
  }
  
  /// Get a key representing the current day for rate limiting
  String _getDayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
  
  /// Get a user-friendly error message for Firebase auth exceptions
  static String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credentials':
        return e.message ?? 'Invalid email or password.';
      case 'account-locked':
        return e.message ?? 'Account temporarily locked. Please try again later.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'weak-password':
        return 'Please use a stronger password.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'credential-already-in-use':
        return 'This credential is already associated with a different user account.';
      default:
        if (kDebugMode) {
          Logger.d('Firebase Auth Error: ${e.code} - ${e.message}', tag: 'Secure_auth_service');
        }
        return 'An unexpected error occurred. Please try again.';
    }
  }
} 