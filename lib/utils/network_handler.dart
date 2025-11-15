import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'logger.dart';
/// Network error types for better error classification - sealed classes for exhaustive pattern matching
sealed class NetworkErrorType {
  const NetworkErrorType();
}

/// No internet connection available
final class NoInternetError extends NetworkErrorType {
  const NoInternetError();
  @override
  String toString() => 'NoInternetError';
}

/// Request timed out
final class TimeoutError extends NetworkErrorType {
  const TimeoutError();
  @override
  String toString() => 'TimeoutError';
}

/// Server error (5xx status codes)
final class ServerError extends NetworkErrorType {
  const ServerError();
  @override
  String toString() => 'ServerError';
}

/// Bad request (4xx status codes)
final class BadRequestError extends NetworkErrorType {
  const BadRequestError();
  @override
  String toString() => 'BadRequestError';
}

/// Unauthorized access (401, 403)
final class UnauthorizedError extends NetworkErrorType {
  const UnauthorizedError();
  @override
  String toString() => 'UnauthorizedError';
}

/// Resource not found (404)
final class NotFoundError extends NetworkErrorType {
  const NotFoundError();
  @override
  String toString() => 'NotFoundError';
}

/// Unknown error type
final class UnknownNetworkError extends NetworkErrorType {
  const UnknownNetworkError();
  @override
  String toString() => 'UnknownNetworkError';
}

/// Custom exception for network errors
class NetworkException implements Exception {
  final String message;
  final NetworkErrorType type;
  final int? statusCode;
  final dynamic originalError;

  NetworkException({
    required this.message,
    required this.type,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'NetworkException: $message (Type: $type, Status: $statusCode)';
}

/// Network handler for making API requests with proper error handling
class NetworkHandler {
  static final Dio _dio = _setupDio();
  
  /// Setup Dio with interceptors for logging and error handling
  static Dio _setupDio() {
    final dio = Dio();
    
    // Default configurations
    dio.options.connectTimeout = const Duration(seconds: 15);
    dio.options.receiveTimeout = const Duration(seconds: 15);
    dio.options.sendTimeout = const Duration(seconds: 15);
    
    // Add interceptors
    dio.interceptors.add(LogInterceptor(
      request: false,
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
      logPrint: (obj) {
        Logger.d('DIO: $obj');
      },
    ));
    
    return dio;
  }
  
  /// Check if the device has internet connection
  static Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      // Handle both single result and list of results properly
      bool hasConnection = false;
      hasConnection = connectivityResult.any((result) => result != ConnectivityResult.none);
          
      if (!hasConnection) {
        return false;
      }
      
      // Double-check with an actual network request
      final response = await http.get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return false;
    }
  }
  
  /// Generic method for handling API requests
  static Future<T> request<T>({
    required String url,
    required String method,
    Map<String, dynamic>? queryParameters,
    dynamic data,
    Map<String, dynamic>? headers,
    Duration? timeout,
    T Function(dynamic data)? responseConverter,
  }) async {
    // Check internet connection first
    if (!await hasInternetConnection()) {
      throw NetworkException(
        message: 'No internet connection available',
        type: const NoInternetError(),
      );
    }
    
    try {
      final response = await _dio.request(
        url,
        options: Options(
          method: method,
          headers: headers,
          sendTimeout: timeout,
          receiveTimeout: timeout,
        ),
        data: data,
        queryParameters: queryParameters,
      );
      
      final responseData = response.data;
      
      // Use converter if provided, otherwise return the data as is
      if (responseConverter != null) {
        return responseConverter(responseData);
      } else {
        return responseData as T;
      }
    } on DioException catch (e, stackTrace) {
      throw _handleDioError(e, stackTrace);
    } catch (e, stackTrace) {
      Logger.e('Unexpected error during network request', error: e, stackTrace: stackTrace);
      throw NetworkException(
        message: 'An unexpected error occurred',
        type: const UnknownNetworkError(),
        originalError: e,
      );
    }
  }
  
  /// Helper method to handle Dio errors
  static NetworkException _handleDioError(DioException error, StackTrace stackTrace) {
    Logger.e('Network error: ${error.message}', error: error, stackTrace: stackTrace);
    
    // Default values
    String message = 'An unexpected error occurred';
    NetworkErrorType errorType = const UnknownNetworkError();
    int? statusCode = error.response?.statusCode;
    
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Request timed out. Please check your internet connection and try again.';
        errorType = const TimeoutError();
        break;
        
      case DioExceptionType.badResponse:
        if (statusCode != null && statusCode >= 500) {
          message = 'Server error. Please try again later.';
          errorType = const ServerError();
        } else if (statusCode == 404) {
          message = 'Resource not found.';
          errorType = const NotFoundError();
        } else if (statusCode == 401) {
          message = 'Unauthorized. Please log in again.';
          errorType = const UnauthorizedError();
        } else if (statusCode != null && statusCode >= 400 && statusCode < 500) {
          message = 'Invalid request.';
          errorType = const BadRequestError();
        }
                    break;
        
      case DioExceptionType.cancel:
        message = 'Request was cancelled';
        break;
        
      case DioExceptionType.connectionError:
        message = 'Connection error. Please check your internet and try again.';
        errorType = const NoInternetError();
        break;
        
      case DioExceptionType.unknown:
      default:
        if (error.error is SocketException) {
          message = 'Network connection error. Please check your internet.';
          errorType = const NoInternetError();
        }
        break;
    }
    
    return NetworkException(
      message: message,
      type: errorType,
      statusCode: statusCode,
      originalError: error,
    );
  }
  
  // Convenience methods for common HTTP methods
  
  /// GET request
  static Future<T> get<T>({
    required String url,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Duration? timeout,
    T Function(dynamic data)? responseConverter,
  }) {
    return request<T>(
      url: url,
      method: 'GET',
      queryParameters: queryParameters,
      headers: headers,
      timeout: timeout,
      responseConverter: responseConverter,
    );
  }
  
  /// POST request
  static Future<T> post<T>({
    required String url,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Duration? timeout,
    T Function(dynamic data)? responseConverter,
  }) {
    return request<T>(
      url: url,
      method: 'POST',
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      timeout: timeout,
      responseConverter: responseConverter,
    );
  }
  
  /// PUT request
  static Future<T> put<T>({
    required String url,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Duration? timeout,
    T Function(dynamic data)? responseConverter,
  }) {
    return request<T>(
      url: url,
      method: 'PUT',
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      timeout: timeout,
      responseConverter: responseConverter,
    );
  }
  
  /// DELETE request
  static Future<T> delete<T>({
    required String url,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Duration? timeout,
    T Function(dynamic data)? responseConverter,
  }) {
    return request<T>(
      url: url,
      method: 'DELETE',
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      timeout: timeout,
      responseConverter: responseConverter,
    );
  }
} 