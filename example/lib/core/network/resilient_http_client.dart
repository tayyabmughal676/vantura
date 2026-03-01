import 'dart:async';

import 'package:http/http.dart' as http;

import '../utils/logger.dart';

/// A resilient HTTP client wrapper that demonstrates how to use custom
/// HTTP clients with [VanturaClient] to monitor and log network health
/// during streaming operations.
///
/// ## Vantura SDK Integration
/// Pass this client to `VanturaClient` via the `httpClient` parameter:
/// ```dart
/// final resilientClient = ResilientHttpClient();
///
/// final vanturaClient = VanturaClient(
///   apiKey: 'YOUR_API_KEY',
///   baseUrl: 'https://api.groq.com/openai/v1/chat/completions',
///   model: 'llama-3.3-70b-versatile',
///   httpClient: resilientClient,
///   onRetry: (attempt, delay, error) {
///     print('Retry #$attempt after ${delay.inSeconds}s — $error');
///   },
/// );
/// ```
///
/// This showcases Vantura's support for dependency-injected HTTP clients,
/// enabling developers to add:
/// - Connection drop detection and logging
/// - Request/response timing metrics
/// - Custom headers or auth token refresh logic
/// - Network health monitoring during streaming
class ResilientHttpClient extends http.BaseClient {
  final http.Client _inner;
  final Duration timeout;

  int _totalRequests = 0;
  int _failedRequests = 0;
  int _successfulRequests = 0;

  ResilientHttpClient({
    http.Client? inner,
    this.timeout = const Duration(seconds: 30),
  }) : _inner = inner ?? http.Client();

  /// Returns a snapshot of the network health metrics.
  Map<String, dynamic> get healthMetrics => {
    'total_requests': _totalRequests,
    'successful_requests': _successfulRequests,
    'failed_requests': _failedRequests,
    'success_rate': _totalRequests > 0
        ? '${((_successfulRequests / _totalRequests) * 100).toStringAsFixed(1)}%'
        : 'N/A',
  };

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    _totalRequests++;
    final stopwatch = Stopwatch()..start();

    appLogger.info(
      'HTTP ${request.method} → ${request.url.host}${request.url.path}',
      tag: 'NETWORK',
      extra: {
        'method': request.method,
        'url': request.url.toString(),
        'request_number': _totalRequests,
      },
    );

    try {
      final response = await _inner
          .send(request)
          .timeout(
            timeout,
            onTimeout: () {
              throw TimeoutException(
                'Request to ${request.url.host} timed out after ${timeout.inSeconds}s',
                timeout,
              );
            },
          );

      stopwatch.stop();
      _successfulRequests++;

      appLogger.info(
        'HTTP ${response.statusCode} ← ${request.url.host} (${stopwatch.elapsedMilliseconds}ms)',
        tag: 'NETWORK',
        extra: {
          'status_code': response.statusCode,
          'duration_ms': stopwatch.elapsedMilliseconds,
          'content_length': response.contentLength,
        },
      );

      // Log warnings for slow requests
      if (stopwatch.elapsedMilliseconds > 5000) {
        appLogger.warning(
          'Slow network request detected: ${stopwatch.elapsedMilliseconds}ms to ${request.url.host}',
          tag: 'NETWORK',
          extra: {'duration_ms': stopwatch.elapsedMilliseconds},
        );
      }

      // Log warnings for non-200 responses
      if (response.statusCode >= 400) {
        appLogger.warning(
          'HTTP error ${response.statusCode} from ${request.url.host}',
          tag: 'NETWORK',
          extra: {
            'status_code': response.statusCode,
            'reason': response.reasonPhrase,
          },
        );
      }

      return response;
    } on TimeoutException catch (e) {
      stopwatch.stop();
      _failedRequests++;

      appLogger.error(
        'Network timeout: ${request.url.host} (${timeout.inSeconds}s)',
        tag: 'NETWORK',
        error: e,
        extra: {
          'url': request.url.toString(),
          'timeout_seconds': timeout.inSeconds,
          'health': healthMetrics,
        },
      );
      rethrow;
    } catch (e, stackTrace) {
      stopwatch.stop();
      _failedRequests++;

      appLogger.error(
        'Network error: Connection to ${request.url.host} failed',
        tag: 'NETWORK',
        error: e,
        stackTrace: stackTrace,
        extra: {
          'url': request.url.toString(),
          'duration_ms': stopwatch.elapsedMilliseconds,
          'health': healthMetrics,
        },
      );
      rethrow;
    }
  }

  @override
  void close() {
    appLogger.info(
      'Closing ResilientHttpClient',
      tag: 'NETWORK',
      extra: healthMetrics,
    );
    _inner.close();
  }
}
