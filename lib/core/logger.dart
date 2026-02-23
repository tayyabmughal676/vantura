/// Abstract logger interface for the Vantura SDK.
///
/// This allows the SDK to use logging without depending on a specific implementation.
/// Consumers of the SDK can provide their own logger implementation.
abstract class VanturaLogger {
  /// Log a debug message.
  void debug(String message, {String? tag, Map<String, dynamic>? extra});

  /// Log an info message.
  void info(String message, {String? tag, Map<String, dynamic>? extra});

  /// Log a warning message.
  void warning(
    String message, {
    String? tag,
    Map<String, dynamic>? extra,
    Object? error,
  });

  /// Log an error message.
  void error(
    String message, {
    String? tag,
    Map<String, dynamic>? extra,
    Object? error,
    StackTrace? stackTrace,
  });

  /// Log performance metrics.
  void logPerformance(
    String operation,
    Duration duration, {
    Map<String, dynamic>? context,
  });
}

/// Simple logger implementation for the Vantura SDK.
/// Uses basic print statements with colors for console output.
class SimpleVanturaLogger implements VanturaLogger {
  static const String _reset = '\x1B[0m';
  static const String _cyan = '\x1B[36m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _red = '\x1B[31m';
  static const String _magenta = '\x1B[35m';

  @override
  void debug(String message, {String? tag, Map<String, dynamic>? extra}) {
    _print('$_cyan[DEBUG]${tag != null ? ' [$tag]' : ''} $message$_reset');
  }

  @override
  void info(String message, {String? tag, Map<String, dynamic>? extra}) {
    _print('$_green[INFO]${tag != null ? ' [$tag]' : ''} $message$_reset');
  }

  @override
  void warning(
    String message, {
    String? tag,
    Map<String, dynamic>? extra,
    Object? error,
  }) {
    _print('$_yellow[WARNING]${tag != null ? ' [$tag]' : ''} $message$_reset');
    if (error != null) {
      _print('$_yellow[WARNING ERROR] $error$_reset');
    }
  }

  @override
  void error(
    String message, {
    String? tag,
    Map<String, dynamic>? extra,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _print('$_red[ERROR]${tag != null ? ' [$tag]' : ''} $message$_reset');
    if (error != null) {
      _print('$_red[ERROR] $error$_reset');
    }
    if (stackTrace != null) {
      _print('$_red[STACK TRACE] $stackTrace$_reset');
    }
  }

  @override
  void logPerformance(
    String operation,
    Duration duration, {
    Map<String, dynamic>? context,
  }) {
    _print(
      '$_magenta[PERFORMANCE] $operation took ${duration.inMilliseconds}ms$_reset',
    );
  }

  void _print(String message) {
    // ignore: avoid_print
    print(message);
  }
}

/// Global SDK logger instance
final sdkLogger = SimpleVanturaLogger();
