import 'dart:io';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:slotted/api/firebase_auth_service.dart';
import 'package:slotted/utils/logger.dart';
import 'package:dio/dio.dart';

/// A utility class for handling and displaying errors
class ErrorHandler {
  /// Handle an error and return a user-friendly message
  static String getUserFriendlyMessage(Object error) {
    if (error is AuthException) {
      return error.message;
    } else if (error is FirebaseAuthException) {
      return _getFirebaseAuthErrorMessage(error);
    } else if (error is FirebaseException) {
      return 'Firebase error: ${error.message ?? error.code}';
    } else if (error is SocketException) {
      return 'Cannot connect to the server. Please check your internet connection.';
    } else if (error is TimeoutException) {
      return 'Connection timed out. Please try again later.';
    } else if (error is HttpException) {
      return 'An HTTP error occurred. Please try again.';
    } else if (error is FormatException) {
      return 'Invalid response format. Please try again later.';
    } else if (error is DioException) {
      return _getDioErrorMessage(error);
    } else {
      return 'An error occurred: ${error.toString()}';
    }
  }
  
  /// Get a user-friendly message for Dio errors
  static String _getDioErrorMessage(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please try again later.';
    } else if (error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) {
        return 'Unauthorized access. Please sign in again.';
      } else if (statusCode == 403) {
        return 'You don\'t have permission to access this resource.';
      } else if (statusCode == 404) {
        return 'The requested resource was not found.';
      } else if (statusCode != null && statusCode >= 500) {
        return 'Server error. Please try again later.';
      }
    } else if (error.type == DioExceptionType.cancel) {
      return 'Request was cancelled.';
    }
    return 'A network error occurred. Please try again.';
  }
  
  /// Handle an error by logging it and returning a user-friendly message
  static String handleError(Object error, {StackTrace? stackTrace, String? tag}) {
    // Log the error
    Logger.e(
      'Error: ${error.toString()}', 
      error: error, 
      stackTrace: stackTrace,
      tag: tag ?? 'ErrorHandler',
    );
    
    // Return user-friendly message
    return getUserFriendlyMessage(error);
  }
  
  /// Show an error snackbar
  static void showErrorSnackBar(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getUserFriendlyMessage(error)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
  
  /// Show an error dialog
  static Future<void> showErrorDialog(
    BuildContext context, 
    Object error, {
    String? title,
    VoidCallback? onRetry,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title ?? 'Error'),
          ],
        ),
        content: Text(getUserFriendlyMessage(error)),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  /// Get a user-friendly error message for Firebase Auth errors
  static String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'This email address is already associated with an account.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'operation-not-allowed':
        return 'This sign-in method is not allowed. Please contact support.';
      case 'invalid-verification-code':
        return 'The verification code is invalid. Please try again.';
      case 'invalid-verification-id':
        return 'The verification session has expired. Please request a new code.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in method.';
      case 'invalid-credential':
        return 'The sign-in credentials are invalid. Please try again.';
      case 'network-request-failed':
        return 'A network error occurred. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many sign-in attempts. Please try again later.';
      default:
        return 'Authentication error: ${e.message ?? e.code}';
    }
  }
  
  /// Show a fatal error screen when app cannot continue
  static Widget buildFatalErrorScreen(Object error, {VoidCallback? onRetry}) {
    return Material(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 24),
              const Text(
                'Critical Error',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                getUserFriendlyMessage(error),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              if (onRetry != null)
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 