import 'package:flutter/foundation.dart';

/// Logging configuration for the Orbit app
class LoggingConfig {
  /// Current minimum log level
  static LogLevel minimumLevel = kDebugMode ? LogLevel.debug : LogLevel.info;

  /// Enable console logging
  static bool enableConsoleLogging = kDebugMode;

  /// Enable Crashlytics logging
  static bool enableCrashlyticsLogging = kReleaseMode;

  /// Enable performance logging
  static bool enablePerformanceLogging = kDebugMode;

  /// Enable security event logging
  static bool enableSecurityLogging = true;

  /// Enable database operation logging
  static bool enableDatabaseLogging = kDebugMode;

  /// Maximum number of log entries to keep in memory
  static const int maxLogEntries = 1000;

  /// Enable user action tracking
  static bool enableUserActionTracking = true;

  /// Enable navigation tracking
  static bool enableNavigationTracking = true;
}

enum LogLevel {
  debug(0),
  info(1),
  warning(2),
  error(3),
  fatal(4);

  const LogLevel(this.value);
  final int value;

  bool shouldLog(LogLevel minimumLevel) {
    return value >= minimumLevel.value;
  }
}
