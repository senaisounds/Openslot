/// Safe setState mixin to prevent "setState called after dispose" crashes
/// 
/// This mixin provides a safe way to call setState that automatically checks
/// if the widget is still mounted before updating state. This prevents the
/// common crash: "setState() called after dispose()"
/// 
/// Usage:
/// ```dart
/// class _MyWidgetState extends State<MyWidget> with SafeStateMixin {
///   void updateData() {
///     // Instead of: setState(() { data = newData; });
///     safeSetState(() {
///       data = newData;
///     });
///   }
/// }
/// ```

import 'package:flutter/widgets.dart';

/// Mixin that provides safe setState functionality
/// 
/// Add this mixin to any StatefulWidget's State class to get access
/// to safeSetState(), which automatically checks mounted status
mixin SafeStateMixin<T extends StatefulWidget> on State<T> {
  /// Safe alternative to setState that checks if widget is mounted
  /// 
  /// This prevents crashes from calling setState after dispose.
  /// Use this instead of setState() everywhere in your widget.
  /// 
  /// Example:
  /// ```dart
  /// safeSetState(() {
  ///   _isLoading = false;
  ///   _data = fetchedData;
  /// });
  /// ```
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      // ignore: invalid_use_of_protected_member
      setState(fn);
    }
  }
  
  /// Run an async operation and safely update state when complete
  /// 
  /// Automatically handles the common pattern of:
  /// 1. Starting a loading state
  /// 2. Performing async operation
  /// 3. Updating state with result
  /// 4. Handling errors
  /// 
  /// Example:
  /// ```dart
  /// await safeAsyncSetState(
  ///   () async => await fetchData(),
  ///   onData: (data) => _data = data,
  ///   onError: (error) => _error = error.toString(),
  /// );
  /// ```
  Future<void> safeAsyncSetState<R>(
    Future<R> Function() asyncOperation, {
    void Function(R data)? onData,
    void Function(Object error)? onError,
    VoidCallback? onFinally,
  }) async {
    try {
      final result = await asyncOperation();
      if (onData != null) {
        safeSetState(() => onData(result));
      }
    } catch (error) {
      if (onError != null) {
        safeSetState(() => onError(error));
      }
    } finally {
      if (onFinally != null) {
        safeSetState(onFinally);
      }
    }
  }
  
  /// Safely update state after a delay
  /// 
  /// Common pattern for animations, timeouts, etc.
  /// Automatically cancels if widget is disposed.
  /// 
  /// Example:
  /// ```dart
  /// safeSetStateDelayed(
  ///   Duration(seconds: 2),
  ///   () => _showMessage = false,
  /// );
  /// ```
  void safeSetStateDelayed(Duration delay, VoidCallback fn) {
    Future.delayed(delay, () {
      if (mounted) {
        // ignore: invalid_use_of_protected_member
        setState(fn);
      }
    });
  }
}

/// Extension on State to provide quick access to safe setState
/// 
/// This allows any State class to use safeSetState without the mixin
/// by importing this file.
extension SafeStateExtension<T extends StatefulWidget> on State<T> {
  /// Safe setState that checks mounted status
  /// 
  /// Use this when you can't add the SafeStateMixin
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      // ignore: invalid_use_of_protected_member
      setState(fn);
    }
  }
}

