import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:vantura/core/logger.dart';

/// Captures all print() output during [fn] execution.
List<String> capturePrints(void Function() fn) {
  final logs = <String>[];
  final spec = ZoneSpecification(
    print: (self, parent, zone, line) {
      logs.add(line);
    },
  );
  Zone.current.fork(specification: spec).run(fn);
  return logs;
}

void main() {
  group('VanturaLogLevel', () {
    test('has correct ordering from debug to none', () {
      expect(VanturaLogLevel.debug.index, lessThan(VanturaLogLevel.info.index));
      expect(
        VanturaLogLevel.info.index,
        lessThan(VanturaLogLevel.warning.index),
      );
      expect(
        VanturaLogLevel.warning.index,
        lessThan(VanturaLogLevel.error.index),
      );
      expect(VanturaLogLevel.error.index, lessThan(VanturaLogLevel.none.index));
    });
  });

  group('VanturaLoggerOptions', () {
    test('has sensible defaults', () {
      const options = VanturaLoggerOptions();
      expect(options.logSensitiveContent, isFalse);
      expect(options.logLevel, VanturaLogLevel.info);
      expect(options.redactedKeys, contains('api_key'));
      expect(options.redactedKeys, contains('password'));
      expect(options.redactedKeys, contains('secret'));
    });

    test('can be constructed with custom values', () {
      const options = VanturaLoggerOptions(
        logSensitiveContent: true,
        logLevel: VanturaLogLevel.debug,
        redactedKeys: ['my_secret'],
      );
      expect(options.logSensitiveContent, isTrue);
      expect(options.logLevel, VanturaLogLevel.debug);
      expect(options.redactedKeys, ['my_secret']);
    });
  });

  group('SimpleVanturaLogger', () {
    group('log level filtering', () {
      test('debug messages appear when level is debug', () {
        final logger = SimpleVanturaLogger(
          options: const VanturaLoggerOptions(logLevel: VanturaLogLevel.debug),
        );
        final logs = capturePrints(() => logger.debug('test debug'));
        expect(logs, isNotEmpty);
        expect(logs.first, contains('[DEBUG]'));
      });

      test('debug messages are suppressed when level is info', () {
        final logger = SimpleVanturaLogger(
          options: const VanturaLoggerOptions(logLevel: VanturaLogLevel.info),
        );
        final logs = capturePrints(() => logger.debug('test debug'));
        expect(logs, isEmpty);
      });

      test('info messages appear when level is info', () {
        final logger = SimpleVanturaLogger(
          options: const VanturaLoggerOptions(logLevel: VanturaLogLevel.info),
        );
        final logs = capturePrints(() => logger.info('test info'));
        expect(logs, isNotEmpty);
        expect(logs.first, contains('[INFO]'));
      });

      test('info messages are suppressed when level is warning', () {
        final logger = SimpleVanturaLogger(
          options: const VanturaLoggerOptions(
            logLevel: VanturaLogLevel.warning,
          ),
        );
        final logs = capturePrints(() => logger.info('test info'));
        expect(logs, isEmpty);
      });

      test('warning messages appear when level is warning', () {
        final logger = SimpleVanturaLogger(
          options: const VanturaLoggerOptions(
            logLevel: VanturaLogLevel.warning,
          ),
        );
        final logs = capturePrints(() => logger.warning('test warning'));
        expect(logs, isNotEmpty);
        expect(logs.first, contains('[WARNING]'));
      });

      test('error messages appear when level is error', () {
        final logger = SimpleVanturaLogger(
          options: const VanturaLoggerOptions(logLevel: VanturaLogLevel.error),
        );
        final logs = capturePrints(() => logger.error('test error'));
        expect(logs, isNotEmpty);
        expect(logs.first, contains('[ERROR]'));
      });

      test('nothing is logged when level is none', () {
        final logger = SimpleVanturaLogger(
          options: const VanturaLoggerOptions(logLevel: VanturaLogLevel.none),
        );
        final logs = capturePrints(() {
          logger.debug('d');
          logger.info('i');
          logger.warning('w');
          logger.error('e');
          logger.logPerformance('op', const Duration(milliseconds: 100));
        });
        expect(logs, isEmpty);
      });
    });

    group('tag support', () {
      test('includes tag in log output when provided', () {
        final logger = SimpleVanturaLogger(
          options: const VanturaLoggerOptions(logLevel: VanturaLogLevel.debug),
        );
        final logs = capturePrints(() => logger.info('hello', tag: 'MY_TAG'));
        expect(logs.first, contains('[MY_TAG]'));
      });

      test('omits tag bracket when tag is null', () {
        final logger = SimpleVanturaLogger(
          options: const VanturaLoggerOptions(logLevel: VanturaLogLevel.debug),
        );
        final logs = capturePrints(() => logger.info('hello'));
        // With no tag, format is "[INFO] hello" with no extra brackets
        expect(logs.first, isNot(contains('] [')));
      });
    });

    group('extra data', () {
      test('includes extra data in log output', () {
        final logger = SimpleVanturaLogger(
          options: const VanturaLoggerOptions(logLevel: VanturaLogLevel.debug),
        );
        final logs = capturePrints(
          () => logger.info('test', extra: {'key': 'value'}),
        );
        expect(logs.first, contains('Extra:'));
        expect(logs.first, contains('key'));
      });
    });

    group('redaction', () {
      test('redacts default sensitive keys', () {
        final logger = SimpleVanturaLogger(
          options: const VanturaLoggerOptions(logLevel: VanturaLogLevel.debug),
        );
        final logs = capturePrints(
          () => logger.info(
            'test',
            extra: {'api_key': 'sk-12345', 'name': 'John'},
          ),
        );
        expect(logs.first, contains('[REDACTED]'));
        expect(logs.first, isNot(contains('sk-12345')));
        expect(logs.first, contains('John'));
      });

      test('redacts nested sensitive keys', () {
        final logger = SimpleVanturaLogger(
          options: const VanturaLoggerOptions(logLevel: VanturaLogLevel.debug),
        );
        final logs = capturePrints(
          () => logger.info(
            'test',
            extra: {
              'config': {'password': 'abc123', 'host': 'localhost'},
            },
          ),
        );
        expect(logs.first, contains('[REDACTED]'));
        expect(logs.first, isNot(contains('abc123')));
        expect(logs.first, contains('localhost'));
      });

      test('redacts case-insensitively (key contains redacted substring)', () {
        final logger = SimpleVanturaLogger(
          options: const VanturaLoggerOptions(logLevel: VanturaLogLevel.debug),
        );
        final logs = capturePrints(
          () => logger.info('test', extra: {'Authorization': 'Bearer xyz'}),
        );
        expect(logs.first, contains('[REDACTED]'));
        expect(logs.first, isNot(contains('Bearer xyz')));
      });

      test('custom redacted keys are used', () {
        final logger = SimpleVanturaLogger(
          options: const VanturaLoggerOptions(
            logLevel: VanturaLogLevel.debug,
            redactedKeys: ['ssn'],
          ),
        );
        final logs = capturePrints(
          () => logger.info(
            'test',
            extra: {'ssn': '111-22-3333', 'name': 'Jane'},
          ),
        );
        expect(logs.first, contains('[REDACTED]'));
        expect(logs.first, isNot(contains('111-22-3333')));
        expect(logs.first, contains('Jane'));
      });
    });

    group('warning with error', () {
      test('logs the error object when provided', () {
        final logger = SimpleVanturaLogger(
          options: const VanturaLoggerOptions(
            logLevel: VanturaLogLevel.warning,
          ),
        );
        final logs = capturePrints(
          () => logger.warning('oops', error: 'some error detail'),
        );
        expect(logs.length, 2);
        expect(logs[1], contains('[WARNING ERROR]'));
        expect(logs[1], contains('some error detail'));
      });
    });

    group('error with error and stackTrace', () {
      test('logs error and stack trace when provided', () {
        final logger = SimpleVanturaLogger(
          options: const VanturaLoggerOptions(logLevel: VanturaLogLevel.error),
        );
        final trace = StackTrace.current;
        final logs = capturePrints(
          () => logger.error('bad', error: 'err obj', stackTrace: trace),
        );
        expect(logs.length, 3);
        expect(logs[1], contains('[ERROR]'));
        expect(logs[1], contains('err obj'));
        expect(logs[2], contains('[STACK TRACE]'));
      });
    });

    group('logPerformance', () {
      test('logs performance with duration in milliseconds', () {
        final logger = SimpleVanturaLogger(
          options: const VanturaLoggerOptions(logLevel: VanturaLogLevel.debug),
        );
        final logs = capturePrints(
          () => logger.logPerformance(
            'loadData',
            const Duration(milliseconds: 250),
          ),
        );
        expect(logs.first, contains('[PERFORMANCE]'));
        expect(logs.first, contains('loadData'));
        expect(logs.first, contains('250ms'));
      });

      test('includes context when provided', () {
        final logger = SimpleVanturaLogger(
          options: const VanturaLoggerOptions(logLevel: VanturaLogLevel.debug),
        );
        final logs = capturePrints(
          () => logger.logPerformance(
            'apiCall',
            const Duration(milliseconds: 100),
            context: {'model': 'gpt-4'},
          ),
        );
        expect(logs.first, contains('Context:'));
        expect(logs.first, contains('gpt-4'));
      });

      test('redacts sensitive keys in context', () {
        final logger = SimpleVanturaLogger(
          options: const VanturaLoggerOptions(logLevel: VanturaLogLevel.debug),
        );
        final logs = capturePrints(
          () => logger.logPerformance(
            'apiCall',
            const Duration(milliseconds: 50),
            context: {'api_key': 'sk-secret', 'model': 'gpt-4'},
          ),
        );
        expect(logs.first, contains('[REDACTED]'));
        expect(logs.first, isNot(contains('sk-secret')));
      });

      test('is suppressed when log level is too high', () {
        final logger = SimpleVanturaLogger(
          options: const VanturaLoggerOptions(logLevel: VanturaLogLevel.error),
        );
        final logs = capturePrints(
          () => logger.logPerformance('op', const Duration(milliseconds: 50)),
        );
        expect(logs, isEmpty);
      });
    });
  });

  group('sdkLogger global', () {
    test('sdkLogger is a SimpleVanturaLogger by default', () {
      expect(sdkLogger, isA<SimpleVanturaLogger>());
    });

    test('sdkLogger can be replaced', () {
      final original = sdkLogger;
      final custom = SimpleVanturaLogger(
        options: const VanturaLoggerOptions(logLevel: VanturaLogLevel.none),
      );
      sdkLogger = custom;
      expect(sdkLogger, same(custom));
      // Restore
      sdkLogger = original;
    });
  });
}
