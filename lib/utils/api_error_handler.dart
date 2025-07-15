import 'dart:io';
import 'dart:async';  // For TimeoutException

import 'package:flutter/material.dart';
import 'package:slotted/utils/logger.dart';

/// Error categories for better error classification
enum ErrorCategory {
  network,    // Network connectivity issues
  auth,       // Authentication/authorization issues
  server,     // Server errors (500 range)
  client,     // Client errors (400 range)
  timeout,    // Request timeouts
  parse,      // Data parsing errors
  unknown     // Uncategorized errors
}

/// A utility class to handle API errors consistently throughout the app
class ApiErrorHandler {
  /// Get a user-friendly error message based on the error
  static String getUserFriendlyMessage(Object error, {String? fallbackMessage}) {
    final category = categorizeError(error);
    
    switch (category) {
      case ErrorCategory.network:
        return 'Unable to connect to the server. Please check your internet connection.';
      case ErrorCategory.auth:
        return 'Authentication failed. Please sign in again.';
      case ErrorCategory.server:
        return 'We\'re experiencing issues with our servers. Please try again later.';
      case ErrorCategory.client:
        return 'There was an issue with your request. Please try again.';
      case ErrorCategory.timeout:
        return 'Request timed out. Please check your connection and try again.';
      case ErrorCategory.parse:
        return 'We had trouble processing the data. Please try again.';
      case ErrorCategory.unknown:
        return fallbackMessage ?? 'An unexpected error occurred. Please try again.';
    }
  }

  /// Categorize an error by its type and properties
  static ErrorCategory categorizeError(Object error) {
    if (error is SocketException || error is HandshakeException) {
      return ErrorCategory.network;
    } else if (error is TimeoutException) {
      return ErrorCategory.timeout;
    } else if (error is FormatException) {
      return ErrorCategory.parse;
    } else if (error.toString().contains('401') || 
               error.toString().contains('403') ||
               error.toString().contains('unauthorized') ||
               error.toString().contains('unauthenticated')) {
      return ErrorCategory.auth;
    } else if (error.toString().contains('500') ||
               error.toString().contains('502') ||
               error.toString().contains('503') ||
               error.toString().contains('504')) {
      return ErrorCategory.server;
    } else if (error.toString().contains('400') ||
               error.toString().contains('404') ||
               error.toString().contains('422')) {
      return ErrorCategory.client;
    }
    
    return ErrorCategory.unknown;
  }

  /// Handle an API error with proper logging and optional UI feedback
  static void handleError(
    Object error, 
    {
      required String context,
      StackTrace? stackTrace,
      String? tag,
      Function(String message)? onShowSnackBar,
      VoidCallback? onRetry,
    }
  ) {
    // Log the error
    Logger.e(
      'API Error in $context: $error', 
      tag: tag ?? 'API',
      error: error,
      stackTrace: stackTrace
    );
    
    final message = getUserFriendlyMessage(error);
    
    // Show snackbar if callback provided
    if (onShowSnackBar != null) {
      onShowSnackBar(message);
    }
    
    // Retry if callback provided
    if (onRetry != null) {
      // Only retry for certain error types that might be transient
      final category = categorizeError(error);
      if (category == ErrorCategory.network || 
          category == ErrorCategory.timeout || 
          category == ErrorCategory.server) {
        onRetry();
      }
    }
  }
  
  /// Show a standard error dialog
  static Future<void> showErrorDialog(
    BuildContext context, 
    Object error, 
    {
      String? title,
      VoidCallback? onRetry,
      bool barrierDismissible = true,
    }
  ) async {
    try {
      final message = getUserFriendlyMessage(error);
      
      return showDialog(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title ?? 'Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onRetry();
                  },
                  child: const Text('Retry'),
                ),
            ],
          );
        },
      );
          } catch (e, stackTrace) {
        Logger.e('Error in async operation', 
                tag: 'ApiErrorHandler', 
                error: e, 
                stackTrace: stackTrace);
      // Handle error gracefully
    }
  }
  
  /// Show a standard error snackbar
  static void showErrorSnackBar(
    BuildContext context, 
    Object error, 
    {
      VoidCallback? onRetry,
      Duration duration = const Duration(seconds: 4),
    }
  ) {
    final message = getUserFriendlyMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: onRetry != null 
          ? SnackBarAction(
              label: 'Retry',
              onPressed: onRetry,
            )
          : null,
      ),
    );
  }
} 