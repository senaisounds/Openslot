import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// A utility class for logging messages with different severity levels.
class Logger {
  /// Controls the verbosity of logging
  /// When false, only errors, warnings, and critical messages will be shown
  static bool isVerbose = false;
  
  /// Controls whether debug messages are shown even in verbose mode
  static bool showDebugMessages = false;
  
  // In-memory log buffer for the most recent logs
  static final List<String> _recentLogs = [];
  static const int _maxLogBufferSize = 100;
  
  // Log file handling
  static File? _logFile;
  static bool _initialized = false;
  static final Completer<void> _initCompleter = Completer<void>();
  
  /// Initialize the logger with quiet mode (minimal logging)
  static void setQuietMode() {
    isVerbose = false;
    showDebugMessages = false;
  }
  
  /// Initialize the logger with verbose mode (show all logs)
  static void setVerboseMode() {
    isVerbose = true;
    showDebugMessages = true;
  }
  
  /// Initialize the logger
  static Future<void> initialize() async {
    // Default to quiet mode
    setQuietMode();
    
    if (_initialized) return _initCompleter.future;
    
    try {
      if (!kIsWeb) {
        try {
          final directory = await getApplicationDocumentsDirectory();
          final logDir = Directory('${directory.path}/logs');
          
          // Ensure logs directory exists with proper error handling
          if (!await logDir.exists()) {
            await logDir.create(recursive: true);
          }
          
          _logFile = File('${logDir.path}/app_log.txt');
          
          // Test write permissions by creating the file if it doesn't exist
          if (!await _logFile!.exists()) {
            await _logFile!.create(recursive: true);
            await _logFile!.writeAsString('Log initialized at ${DateTime.now().toIso8601String()}\n');
          }
          
          // Clean old logs if file is too large (> 5MB)
          final fileStats = await _logFile!.stat();
          if (fileStats.size > 5 * 1024 * 1024) {
            await _logFile!.writeAsString('Log reset at ${DateTime.now().toIso8601String()}\n');
          }
          
          Logger.d('Logger initialized successfully with file: ${_logFile!.path}', tag: 'Logger');
        } catch (fileError) {
          // If file operations fail, disable file logging but continue
          Logger.w('Failed to initialize log file, continuing without file logging: $fileError', tag: 'Logger');
          _logFile = null;
        }
      }
      _initialized = true;
      _initCompleter.complete();
    } catch (e) {
      Logger.w('Logger initialization failed: $e', tag: 'Logger');
      _initialized = true;
      _initCompleter.completeError(e);
    }
    
    return _initCompleter.future;
  }
  
  /// Log a debug message
  static void d(String message, {String tag = 'Slotted'}) {
    // Only log debug messages if explicitly enabled
    if (!showDebugMessages) return;
    
    _logMessage('DEBUG', tag, message);
  }
  
  /// Log an info message
  static void i(String message, {String tag = 'Slotted'}) {
    // Only log info if verbose mode is enabled
    if (!isVerbose) return;
    
    _logMessage('INFO', tag, message);
  }
  
  /// Log a warning message
  static void w(String message, {String tag = 'Slotted', Object? warning}) {
    _logMessage('WARNING', tag, message);
    
    // Record warnings in production
    if (!kDebugMode) {
      try {
        FirebaseCrashlytics.instance.log('WARNING: ${warning?.toString() ?? message}');
        FirebaseCrashlytics.instance.setCustomKey('warning_source', tag);
      } catch (_) {
        // Silent catch if Crashlytics isn't initialized
      }
    }
  }
  
  /// Log an error message
  static void e(String message, {String tag = 'Slotted', Object? error, StackTrace? stackTrace}) {
    _logMessage('ERROR', tag, message);
    
    if (error != null) {
      _logMessage('ERROR', tag, 'Error details: ${error.toString()}');
    }
    
    if (stackTrace != null) {
      _logMessage('ERROR', tag, 'Stack trace: $stackTrace');
    }
    
    // Report non-debug errors to Crashlytics
    if (!kDebugMode) {
      try {
        FirebaseCrashlytics.instance.recordError(
          error ?? message,
          stackTrace,
          reason: message,
          fatal: false,
        );
      } catch (_) {
        // Silent catch if Crashlytics isn't initialized
      }
    }
  }
  
  /// Log a critical error that might crash the app
  static void critical(String message, {String tag = 'Slotted', Object? error, StackTrace? stackTrace}) {
    _logMessage('CRITICAL', tag, message);
    
    if (error != null) {
      _logMessage('CRITICAL', tag, 'Error details: ${error.toString()}');
    }
    
    if (stackTrace != null) {
      _logMessage('CRITICAL', tag, 'Stack trace: $stackTrace');
    }
    
    // Report critical errors to Crashlytics
    if (!kDebugMode) {
      try {
        FirebaseCrashlytics.instance.recordError(
          error ?? message,
          stackTrace,
          reason: message,
          fatal: true,
        );
      } catch (_) {
        // Silent catch if Crashlytics isn't initialized
      }
    }
  }
  
  /// Private method to handle the actual logging
  static void _logMessage(String level, String tag, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] [$level] [$tag] $message';
    
    // Always keep recent logs in memory
    _recentLogs.add(logEntry);
    if (_recentLogs.length > _maxLogBufferSize) {
      _recentLogs.removeAt(0);
    }
    
    // In debug mode, print to console
    if (kDebugMode) {
      // Use debugPrint instead of print for better Flutter integration
      debugPrint(logEntry);
    }
    
    // In production, write to log file
    if (!kIsWeb && _initialized && _logFile != null) {
      _writeToLogFile(logEntry);
    }
  }
  
  /// Write log entry to file asynchronously
  static void _writeToLogFile(String logEntry) {
    // Don't attempt to write if file logging is disabled
    if (_logFile == null) return;
    
    _logFile?.writeAsString('$logEntry\n', mode: FileMode.append).catchError((e) {
      // Only log file write errors in debug mode to prevent spam
      if (kDebugMode && _logFile != null) {
        debugPrint('Failed to write to log file: $e');
        // Disable further file logging attempts after first failure
        _logFile = null;
      }
      return File(''); // Return empty File to satisfy return type
    });
  }
  
  /// Get recent logs as a string
  static String getRecentLogs() {
    return _recentLogs.join('\n');
  }
  
  /// Clear recent logs buffer
  static void clearRecentLogs() {
    _recentLogs.clear();
  }
} 