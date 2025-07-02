import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:slotted/utils/logger.dart';
import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:slotted/common/error_handler.dart';

/// A utility class for handling network errors and retrying HTTP requests
class NetworkErrorHandler {
  static const int defaultMaxRetries = 3;
  static const Duration defaultBaseDelay = Duration(milliseconds: 500);
  
  /// Executes a HTTP request with automatic retry on transient errors
  static Future<http.Response> executeWithRetry({
    required Future<http.Response> Function() requestFn,
    required String requestName,
    int maxRetries = defaultMaxRetries,
    Duration baseDelay = defaultBaseDelay,
    bool Function(http.Response)? isSuccessful,
    String? tag,
  }) async {
    int attempt = 0;
    Duration delay = baseDelay;
    
    while (true) {
      attempt++;
      
      try {
        // Execute the request
        final response = await requestFn();
        
        // Check if response is successful
        final success = isSuccessful?.call(response) ?? 
                        (response.statusCode >= 200 && response.statusCode < 300);
        
        if (success) {
          if (attempt > 1) {
            Logger.i('$requestName succeeded after $attempt attempts', tag: tag ?? 'Network');
          }
          return response;
        }
        
        // Log error details for non-successful responses
        final message = 'HTTP error in $requestName (attempt $attempt/$maxRetries): Status ${response.statusCode}';
        
        // Don't retry if it's a client error (4xx)
        if (response.statusCode >= 400 && response.statusCode < 500) {
          String bodyPreview = '';
          try {
            // Try to parse response body as JSON for better error messages
            final body = json.decode(response.body);
            bodyPreview = body is Map ? 
              (body['message'] ?? body['error'] ?? body.toString().substring(0, body.toString().length.clamp(0, 100))) : 
              response.body.substring(0, response.body.length.clamp(0, 100));
          } catch (_) {
            bodyPreview = response.body.length > 100 ? 
              '${response.body.substring(0, 100)}...' : 
              response.body;
          }
          
          Logger.e('$message - $bodyPreview', tag: tag ?? 'Network');
          return response;  // Return the error response for 4xx errors
        }
        
        // Log server errors
        Logger.w('$message - Server error', tag: tag ?? 'Network');
        
        // If we've reached max retries, give up
        if (attempt >= maxRetries) {
          Logger.e('$requestName failed after $maxRetries attempts', tag: tag ?? 'Network');
          return response;
        }
        
      } catch (e, stackTrace) {
        // Handle exceptions during request
        final isLastAttempt = attempt >= maxRetries;
        final message = '$requestName failed (attempt $attempt/$maxRetries): $e';
        
        // Check if the error is retryable
        final isRetryable = _isRetryableError(e);
        
        if (isLastAttempt || !isRetryable) {
          Logger.e(message, error: e, stackTrace: stackTrace, tag: tag ?? 'Network');
          rethrow;  // Rethrow on last attempt or non-retryable errors
        } else {
          Logger.w(message, tag: tag ?? 'Network');
        }
      }
      
      // Calculate backoff delay with jitter
      delay = baseDelay * attempt * (0.5 + 0.5 * (DateTime.now().millisecondsSinceEpoch % 10) / 10);
      await Future.delayed(delay);
    }
  }
  
  /// Determines if an error is retryable
  static bool _isRetryableError(Object error) {
    return error is SocketException ||           // Network connectivity issues
           error is TimeoutException ||          // Timeouts
           error is HttpException && error is! HandshakeException ||  // General HTTP errors except SSL
           error.toString().contains('timeout') ||
           error.toString().contains('Connection refused') ||
           error.toString().contains('Network is unreachable') ||
           (error is DioException && (
             error.type == DioExceptionType.connectionTimeout ||
             error.type == DioExceptionType.sendTimeout ||
             error.type == DioExceptionType.receiveTimeout ||
             (error.response?.statusCode != null && error.response!.statusCode! >= 500)
           ));
  }
  
  /// Check if a response has a server error status code (5xx)
  static bool isServerError(http.Response response) {
    return response.statusCode >= 500 && response.statusCode < 600;
  }
  
  /// Safely parse JSON with error handling
  static dynamic parseJson(String body, {String? context, String? tag}) {
    try {
      return json.decode(body);
    } catch (e, stackTrace) {
      final truncatedBody = body.length > 100 ? '${body.substring(0, 100)}...' : body;
      final contextMsg = context != null ? ' when parsing JSON for $context' : '';
      Logger.e('JSON parse error$contextMsg: $e. Body: $truncatedBody', 
              error: e, 
              stackTrace: stackTrace,
              tag: tag ?? 'Network');
      return null;
    }
  }

  /// Check if the device is currently connected to the internet
  static Future<bool> isConnected() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      // Handle both single result and list of results properly
      if (connectivityResults is List<ConnectivityResult>) {
        return connectivityResults.any((result) => result != ConnectivityResult.none);
      } else {
        // This handles the older single result API
        final result = connectivityResults as ConnectivityResult;
        return result != ConnectivityResult.none;
      }
    } catch (e) {
      Logger.e('Error checking connectivity: $e', tag: 'Network');
      return false;
    }
  }
  
  /// Convenience method to use ErrorHandler's snackbar with network errors
  static void showErrorSnackBar(BuildContext context, Object error) {
    ErrorHandler.showErrorSnackBar(context, error);
  }
} 