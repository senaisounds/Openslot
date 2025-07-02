import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'logger.dart';
import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:slotted/common/error_boundary.dart';

/// A utility class to handle errors in a consistent way across the application
class ErrorHandler {
  /// Handle API errors with proper logging and user feedback
  static Future<T?> handleApiError<T>({
    required BuildContext context,
    required Future<T> Function() apiCall,
    String? customErrorMessage,
    bool showErrorDialog = true,
    bool retry = false,
    int maxRetries = 2,
  }) async {
    int attempts = 0;
    
    while (attempts <= maxRetries) {
      try {
        attempts++;
        return await apiCall();
      } catch (e, stackTrace) {
        final errorMessage = customErrorMessage ?? 'An error occurred while communicating with the server';
        
        // If we still have retries left and retries are enabled
        if (retry && attempts <= maxRetries) {
          Logger.w('API call failed, retrying ($attempts/$maxRetries): $errorMessage', warning: e);
          await Future.delayed(Duration(milliseconds: 500 * attempts)); // Backoff strategy
          continue;
        }
        
        // No more retries or retries disabled
        Logger.e(errorMessage, error: e, stackTrace: stackTrace);
        
        if (showErrorDialog && context.mounted) {
          showErrorNotification(
            context: context,
            title: 'Error',
            message: '$errorMessage. Please try again later.',
          );
        }
        
        // Propagate error for further handling
        return Future.error(e, stackTrace);
      }
    }
    
    return null;
  }
  
  /// Handle general errors with proper logging
  static T handleError<T>({
    required T Function() operation,
    required T fallbackValue,
    String? errorMessage,
    bool logError = true,
  }) {
    try {
      return operation();
    } catch (e, stackTrace) {
      if (logError) {
        final message = errorMessage ?? 'An error occurred';
        Logger.e(message, error: e, stackTrace: stackTrace);
      }
      return fallbackValue;
    }
  }
  
  /// Display an error dialog to the user
  static Future<void> showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(message),
          ),
          actions: <Widget>[
            if (onAction != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onAction();
                },
                child: Text(actionText ?? 'Retry'),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
  /// Display a non-intrusive error notification
  static void showErrorNotification({
    required BuildContext context,
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
        duration: duration,
      ),
    );
  }
  
  /// Initialize error handling for the entire app
  static void initGlobalErrorHandling() {
    // Set up Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        // In debug mode, use default error reporting
        FlutterError.dumpErrorToConsole(details);
      } else {
        // In production, log to Crashlytics via our logger
        Logger.critical(
          'Flutter framework error',
          error: details.exception,
          stackTrace: details.stack,
        );
      }
    };
    
    // Catch errors that aren't caught by the Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      Logger.critical(
        'Uncaught platform error',
        error: error,
        stackTrace: stack,
      );
      return true; // Prevents the error from propagating
    };
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
              const Text(
                'An unexpected error occurred that prevented the app from loading properly.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (kDebugMode)
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.red),
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

  // Log the error to our analytics service
  static void _logError(String errorType, dynamic error, StackTrace stack) {
    // Create a simplified error message
    final errorMessage = 'Error: $errorType - ${error.toString()}';
    
    try {
      // Only use Crashlytics for non-web platforms
      if (!kIsWeb) {
        // Log to Firebase Crashlytics
        FirebaseCrashlytics.instance.recordError(
          error,
          stack,
          reason: errorType,
          printDetails: true, // Log to console in debug mode
        );
      } else {
        // For web, just use the logger
        Logger.e(errorMessage, error: error, stackTrace: stack);
      }
    } catch (e) {
      // If crash reporting fails, at least log to console
      Logger.e(errorMessage, error: e, stackTrace: stack);
    }
  }

  // Display a friendly error UI
  static Widget buildErrorUI(BuildContext context, Object error) {
    return const Center(
      child: ErrorBoundary(
        fallback: Text('An error occurred. Please restart the app.'),
        child: Text('Something went wrong. Please try again.'),
      ),
    );
  }
} 