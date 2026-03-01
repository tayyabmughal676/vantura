import 'dart:developer' as developer;

import 'package:vantura/core/logger.dart';

import 'logging_config.dart';

class AppLogger implements VanturaLogger {
  static final AppLogger _instance = AppLogger._internal();

  factory AppLogger() => _instance;

  AppLogger._internal();

  @override
  VanturaLoggerOptions get options {
    final VanturaLogLevel mappedLevel = switch (LoggingConfig.minimumLevel) {
      LogLevel.debug => VanturaLogLevel.debug,
      LogLevel.info => VanturaLogLevel.info,
      LogLevel.warning => VanturaLogLevel.warning,
      LogLevel.error => VanturaLogLevel.error,
      LogLevel.fatal => VanturaLogLevel.error, // Map fatal to error
    };
    return VanturaLoggerOptions(
      logSensitiveContent: false, // App doesn't log sensitive content
      logLevel: mappedLevel,
      redactedKeys: const [
        'api_key',
        'apiKey',
        'authorization',
        'token',
        'password',
        'secret',
      ],
    );
  }

  final bool _enableConsoleLogging = LoggingConfig.enableConsoleLogging;

  /// Log a debug message
  @override
  void debug(String message, {String? tag, Map<String, dynamic>? extra}) {
    _log(LogLevel.debug, message, tag: tag, extra: extra);
  }

  /// Log an info message
  @override
  void info(String message, {String? tag, Map<String, dynamic>? extra}) {
    _log(LogLevel.info, message, tag: tag, extra: extra);
  }

  /// Log a warning message
  @override
  void warning(
    String message, {
    String? tag,
    Map<String, dynamic>? extra,
    Object? error,
  }) {
    _log(LogLevel.warning, message, tag: tag, extra: extra, error: error);
  }

  /// Log an error message
  @override
  void error(
    String message, {
    String? tag,
    Map<String, dynamic>? extra,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      extra: extra,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log a fatal error
  void fatal(
    String message, {
    String? tag,
    Map<String, dynamic>? extra,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.fatal,
      message,
      tag: tag,
      extra: extra,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log user action for analytics
  void logUserAction(String action, {Map<String, dynamic>? parameters}) {
    if (!LoggingConfig.enableUserActionTracking) return;

    info(
      'User Action: $action',
      tag: 'USER_ACTION',
      extra: {
        'action': action,
        if (parameters != null) ...parameters,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log screen navigation
  void logScreenNavigation(String fromScreen, String toScreen) {
    if (!LoggingConfig.enableNavigationTracking) return;

    info(
      'Navigation: $fromScreen -> $toScreen',
      tag: 'NAVIGATION',
      extra: {
        'from': fromScreen,
        'to': toScreen,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log performance metrics
  @override
  void logPerformance(
    String operation,
    Duration duration, {
    Map<String, dynamic>? context,
  }) {
    if (!LoggingConfig.enablePerformanceLogging) return;

    info(
      'Performance: $operation took ${duration.inMilliseconds}ms',
      tag: 'PERFORMANCE',
      extra: {
        'operation': operation,
        'duration_ms': duration.inMilliseconds,
        if (context != null) ...context,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  void _log(
    LogLevel level,
    String message, {
    String? tag,
    Map<String, dynamic>? extra,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Check if this level should be logged
    if (!level.shouldLog(LoggingConfig.minimumLevel)) {
      return;
    }

    final timestamp = DateTime.now();
    final logTag = tag ?? 'APP';
    final logMessage = '[$timestamp] [$logTag] $message';

    // Console logging
    if (_enableConsoleLogging) {
      _logToConsole(level, logMessage, error: error, stackTrace: stackTrace);
    }
  }

  void _logToConsole(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final colorCode = switch (level) {
      LogLevel.debug => '\x1B[36m', // Cyan
      LogLevel.info => '\x1B[32m', // Green
      LogLevel.warning => '\x1B[33m', // Yellow
      LogLevel.error => '\x1B[31m', // Red
      LogLevel.fatal => '\x1B[35m', // Magenta
    };

    final resetCode = '\x1B[0m';

    switch (level) {
      case LogLevel.debug:
        developer.log('$colorCode$message$resetCode', level: level.value);
        break;
      case LogLevel.info:
        developer.log('$colorCode$message$resetCode', level: level.value);
        break;
      case LogLevel.warning:
        developer.log('$colorCode$message$resetCode', level: level.value);
        if (error != null) {
          developer.log(
            '$colorCode Warning Error: $error$resetCode',
            level: level.value,
          );
        }
        break;
      case LogLevel.error:
        developer.log(
          '$colorCode$message$resetCode',
          level: level.value,
          error: error,
          stackTrace: stackTrace,
        );
        break;
      case LogLevel.fatal:
        developer.log(
          '$colorCode FATAL: $message$resetCode',
          level: level.value,
          error: error,
          stackTrace: stackTrace,
        );
        break;
    }
  }
}

/// Global app logger instance
final appLogger = AppLogger();
