/// Configuration for Vantura logging.
class VanturaLoggerOptions {
  /// Whether to log the actual content of prompts and AI responses.
  /// Set to false to prevent logging PII in production.
  final bool logSensitiveContent;

  /// List of keys in 'extra' or 'context' maps that should be redacted.
  final List<String> redactedKeys;

  const VanturaLoggerOptions({
    this.logSensitiveContent = false,
    this.redactedKeys = const [
      'api_key',
      'apiKey',
      'authorization',
      'token',
      'password',
      'secret',
    ],
  });
}

/// Abstract logger interface for the Vantura SDK.
abstract class VanturaLogger {
  VanturaLoggerOptions get options;

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
class SimpleVanturaLogger implements VanturaLogger {
  @override
  final VanturaLoggerOptions options;

  static const String _reset = '\x1B[0m';
  static const String _cyan = '\x1B[36m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _red = '\x1B[31m';
  static const String _magenta = '\x1B[35m';

  SimpleVanturaLogger({this.options = const VanturaLoggerOptions()});

  Map<String, dynamic>? _redact(Map<String, dynamic>? data) {
    if (data == null) return null;
    final Map<String, dynamic> result = Map.from(data);
    for (final key in result.keys) {
      if (options.redactedKeys.any((rk) => key.toLowerCase().contains(rk))) {
        result[key] = '[REDACTED]';
      } else if (result[key] is Map<String, dynamic>) {
        result[key] = _redact(result[key] as Map<String, dynamic>);
      }
    }
    return result;
  }

  void _printLog(
    String level,
    String color,
    String message,
    String? tag,
    Map<String, dynamic>? extra,
  ) {
    final redactedExtra = _redact(extra);
    final tagStr = tag != null ? ' [$tag]' : '';
    final extraStr = (redactedExtra != null && redactedExtra.isNotEmpty)
        ? ' | Extra: $redactedExtra'
        : '';
    _print('$color[$level]$tagStr $message$extraStr$_reset');
  }

  @override
  void debug(String message, {String? tag, Map<String, dynamic>? extra}) {
    _printLog('DEBUG', _cyan, message, tag, extra);
  }

  @override
  void info(String message, {String? tag, Map<String, dynamic>? extra}) {
    _printLog('INFO', _green, message, tag, extra);
  }

  @override
  void warning(
    String message, {
    String? tag,
    Map<String, dynamic>? extra,
    Object? error,
  }) {
    _printLog('WARNING', _yellow, message, tag, extra);
    if (error != null) _print('$_yellow[WARNING ERROR] $error$_reset');
  }

  @override
  void error(
    String message, {
    String? tag,
    Map<String, dynamic>? extra,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _printLog('ERROR', _red, message, tag, extra);
    if (error != null) _print('$_red[ERROR] $error$_reset');
    if (stackTrace != null) _print('$_red[STACK TRACE] $stackTrace$_reset');
  }

  @override
  void logPerformance(
    String operation,
    Duration duration, {
    Map<String, dynamic>? context,
  }) {
    final redactedContext = _redact(context);
    final contextStr = (redactedContext != null && redactedContext.isNotEmpty)
        ? ' | Context: $redactedContext'
        : '';
    _print(
      '$_magenta[PERFORMANCE] $operation took ${duration.inMilliseconds}ms$contextStr$_reset',
    );
  }

  void _print(String message) {
    // ignore: avoid_print
    print(message);
  }
}

/// Global SDK logger instance.
/// In a real app, developers should be able to replace this.
VanturaLogger sdkLogger = SimpleVanturaLogger();
