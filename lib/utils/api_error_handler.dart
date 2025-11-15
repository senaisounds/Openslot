import 'dart:io';
import 'dart:async';  // For TimeoutException

import 'package:flutter/material.dart';
import 'package:slotted/utils/logger.dart';

/// Error categories for better error classification - sealed classes for exhaustive pattern matching
sealed class ErrorCategory {
  const ErrorCategory();
}

/// Network connectivity issues
final class NetworkErrorCategory extends ErrorCategory {
  const NetworkErrorCategory();
  @override
  String toString() => 'NetworkErrorCategory';
}

/// Authentication/authorization issues
final class AuthErrorCategory extends ErrorCategory {
  const AuthErrorCategory();
  @override
  String toString() => 'AuthErrorCategory';
}

/// Server errors (500 range)
final class ServerErrorCategory extends ErrorCategory {
  const ServerErrorCategory();
  @override
  String toString() => 'ServerErrorCategory';
}

/// Client errors (400 range)
final class ClientErrorCategory extends ErrorCategory {
  const ClientErrorCategory();
  @override
  String toString() => 'ClientErrorCategory';
}

/// Request timeouts
final class TimeoutErrorCategory extends ErrorCategory {
  const TimeoutErrorCategory();
  @override
  String toString() => 'TimeoutErrorCategory';
}

/// Data parsing errors
final class ParseErrorCategory extends ErrorCategory {
  const ParseErrorCategory();
  @override
  String toString() => 'ParseErrorCategory';
}

/// Uncategorized errors
final class UnknownErrorCategory extends ErrorCategory {
  const UnknownErrorCategory();
  @override
  String toString() => 'UnknownErrorCategory';
}

/// A utility class to handle API errors consistently throughout the app
class ApiErrorHandler {
  /// Get a user-friendly error message based on the error
  static String getUserFriendlyMessage(Object error, {String? fallbackMessage}) {
    final category = categorizeError(error);
    
    return switch (category) {
      NetworkErrorCategory() => 'Unable to connect to the server. Please check your internet connection.',
      AuthErrorCategory() => 'Authentication failed. Please sign in again.',
      ServerErrorCategory() => 'We\'re experiencing issues with our servers. Please try again later.',
      ClientErrorCategory() => 'There was an issue with your request. Please try again.',
      TimeoutErrorCategory() => 'Request timed out. Please check your connection and try again.',
      ParseErrorCategory() => 'We had trouble processing the data. Please try again.',
      UnknownErrorCategory() => fallbackMessage ?? 'An unexpected error occurred. Please try again.',
    };
  }

  /// Categorize an error by its type and properties
  static ErrorCategory categorizeError(Object error) {
    if (error is SocketException || error is HandshakeException) {
      return const NetworkErrorCategory();
    } else if (error is TimeoutException) {
      return const TimeoutErrorCategory();
    } else if (error is FormatException) {
      return const ParseErrorCategory();
    } else if (error.toString().contains('401') || 
               error.toString().contains('403') ||
               error.toString().contains('unauthorized') ||
               error.toString().contains('unauthenticated')) {
      return const AuthErrorCategory();
    } else if (error.toString().contains('500') ||
               error.toString().contains('502') ||
               error.toString().contains('503') ||
               error.toString().contains('504')) {
      return const ServerErrorCategory();
    } else if (error.toString().contains('400') ||
               error.toString().contains('404') ||
               error.toString().contains('422')) {
      return const ClientErrorCategory();
    }
    
    return const UnknownErrorCategory();
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
      if (category is NetworkErrorCategory || 
          category is TimeoutErrorCategory || 
          category is ServerErrorCategory) {
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