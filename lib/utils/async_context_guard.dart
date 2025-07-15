import 'package:flutter/material.dart';
import 'package:slotted/utils/logger.dart';

/// A utility class to safely handle BuildContext across async operations
/// Prevents crashes from using BuildContext after widget disposal
class AsyncContextGuard {
  /// Safely execute a function that requires BuildContext after an async operation
  /// Returns true if the operation was executed, false if the widget was unmounted
  static bool safeBuildContext({
    required bool mounted,
    required VoidCallback operation,
    String? debugName,
  }) {
    if (!mounted) {
      if (debugName != null) {
        Logger.d('Skipping $debugName - widget unmounted', tag: 'AsyncContextGuard');
      }
      return false;
    }
    
    try {
      operation();
      return true;
    } catch (e, stackTrace) {
      Logger.e('Error in ${debugName ?? 'operation'}', 
              tag: 'AsyncContextGuard', 
              error: e, 
              stackTrace: stackTrace);
      return false;
    }
  }

  /// Safely navigate after an async operation
  static bool safeNavigate({
    required bool mounted,
    required BuildContext context,
    required Widget destination,
    bool replace = false,
    String? debugName,
  }) {
    return safeBuildContext(
      mounted: mounted,
      debugName: debugName ?? 'navigation',
      operation: () {
        if (replace) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => destination),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => destination),
          );
        }
      },
    );
  }

  /// Safely show a snackbar after an async operation
  static bool safeShowSnackBar({
    required bool mounted,
    required BuildContext context,
    required String message,
    Color? backgroundColor,
    Duration? duration,
    String? debugName,
  }) {
    return safeBuildContext(
      mounted: mounted,
      debugName: debugName ?? 'snackbar',
      operation: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: duration ?? const Duration(seconds: 3),
          ),
        );
      },
    );
  }

  /// Safely show a dialog after an async operation
  static bool safeShowDialog({
    required bool mounted,
    required BuildContext context,
    required Widget dialog,
    bool barrierDismissible = true,
    String? debugName,
  }) {
    return safeBuildContext(
      mounted: mounted,
      debugName: debugName ?? 'dialog',
      operation: () {
        showDialog(
          context: context,
          barrierDismissible: barrierDismissible,
          builder: (context) => dialog,
        );
      },
    );
  }

  /// Safely update state after an async operation
  static bool safeSetState({
    required bool mounted,
    required VoidCallback setState,
    String? debugName,
  }) {
    return safeBuildContext(
      mounted: mounted,
      debugName: debugName ?? 'setState',
      operation: setState,
    );
  }

  /// Execute an async operation with automatic mounted checks
  /// Useful for handling async operations that might affect UI
  static Future<T?> withMountedCheck<T>({
    required bool mounted,
    required Future<T> Function() asyncOperation,
    required bool Function() isMountedChecker,
    String? debugName,
  }) async {
    if (!mounted) {
      if (debugName != null) {
        Logger.d('Skipping $debugName - widget unmounted before start', tag: 'AsyncContextGuard');
      }
      return null;
    }

    try {
      final result = await asyncOperation();
      
      // Check if still mounted after async operation
      if (!isMountedChecker()) {
        if (debugName != null) {
          Logger.d('Widget unmounted during $debugName', tag: 'AsyncContextGuard');
        }
        return null;
      }
      
      return result;
    } catch (e, stackTrace) {
      Logger.e('Error in ${debugName ?? 'async operation'}', 
              tag: 'AsyncContextGuard', 
              error: e, 
              stackTrace: stackTrace);
      return null;
    }
  }
}

/// Mixin to provide convenient access to AsyncContextGuard methods
mixin AsyncContextMixin<T extends StatefulWidget> on State<T> {
  /// Safely execute a function that requires BuildContext after an async operation
  bool safeBuildContext(VoidCallback operation, {String? debugName}) {
    return AsyncContextGuard.safeBuildContext(
      mounted: mounted,
      operation: operation,
      debugName: debugName,
    );
  }

  /// Safely navigate after an async operation
  bool safeNavigate(Widget destination, {bool replace = false, String? debugName}) {
    return AsyncContextGuard.safeNavigate(
      mounted: mounted,
      context: context,
      destination: destination,
      replace: replace,
      debugName: debugName,
    );
  }

  /// Safely show a snackbar after an async operation
  bool safeShowSnackBar(String message, {Color? backgroundColor, Duration? duration, String? debugName}) {
    return AsyncContextGuard.safeShowSnackBar(
      mounted: mounted,
      context: context,
      message: message,
      backgroundColor: backgroundColor,
      duration: duration,
      debugName: debugName,
    );
  }

  /// Safely show a dialog after an async operation
  bool safeShowDialog(Widget dialog, {bool barrierDismissible = true, String? debugName}) {
    return AsyncContextGuard.safeShowDialog(
      mounted: mounted,
      context: context,
      dialog: dialog,
      barrierDismissible: barrierDismissible,
      debugName: debugName,
    );
  }

  /// Safely update state after an async operation
  bool safeSetState(VoidCallback stateUpdate, {String? debugName}) {
    return AsyncContextGuard.safeSetState(
      mounted: mounted,
      setState: () => setState(stateUpdate),
      debugName: debugName,
    );
  }

  /// Execute an async operation with automatic mounted checks
  Future<T?> withMountedCheck<T>(
    Future<T> Function() asyncOperation, {
    String? debugName,
  }) {
    return AsyncContextGuard.withMountedCheck<T>(
      mounted: mounted,
      asyncOperation: asyncOperation,
      isMountedChecker: () => mounted,
      debugName: debugName,
    );
  }
} 