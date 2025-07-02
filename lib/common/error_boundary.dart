import 'package:flutter/material.dart';
import 'package:slotted/utils/logger.dart';

/// A widget that catches errors in its child widget tree and displays a fallback UI.
class ErrorBoundary extends StatefulWidget {
  /// The child widget that may throw errors.
  final Widget child;
  
  /// Optional fallback widget to display when an error occurs.
  final Widget? fallback;
  
  /// Optional callback to execute when retrying after an error.
  final VoidCallback? onRetry;
  
  /// Optional callback to handle the error.
  final Function(Object, StackTrace)? onError;
  
  /// Creates an error boundary widget.
  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.onRetry,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;


  @override
  void initState() {
    super.initState();
    // Replace the default error widget builder with our custom one
    final originalErrorWidgetBuilder = ErrorWidget.builder;
    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (_hasError) {
        return _buildErrorWidget();
      }
      return originalErrorWidgetBuilder(details);
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }
    
    try {
      return widget.child;
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
      return _buildErrorWidget();
    }
  }
  
  Widget _buildErrorWidget() {
    return widget.fallback ?? 
      Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (widget.onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                    });
                    widget.onRetry?.call();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      );
  }
  
  void _reportError(Object error, StackTrace stackTrace) {
    setState(() {
      _hasError = true;
    });
    
    // Log the error
    Logger.e('Error caught by ErrorBoundary: $error', 
      error: error, 
      stackTrace: stackTrace);
    
    // Call the onError callback if provided
    widget.onError?.call(error, stackTrace);
  }
} 