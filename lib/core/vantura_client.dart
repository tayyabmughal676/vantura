import 'dart:convert';
import 'package:http/http.dart' as http;
import 'logger.dart';
import 'cancellation_token.dart';

/// Client for interacting with the Vantura AI API.
///
/// Handles authentication, request building, and response parsing for chat completions.
class VanturaClient {
  /// API key for authentication.
  final String apiKey;

  /// Base URL of the API endpoint.
  final String baseUrl;

  /// Default model to use for requests.
  final String model;

  /// Default temperature for responses.
  final double? temperature;

  /// Default maximum completion tokens.
  final int? maxCompletionTokens;

  /// Default top-p sampling parameter.
  final double? topP;

  /// Default stream flag.
  final bool? stream;

  /// Default reasoning effort.
  final String? reasoningEffort;

  /// Default stop sequences.
  final dynamic stop;

  /// Shared HTTP client for connection pooling.
  final http.Client _httpClient;

  /// Creates an VanturaClient with the specified configuration.
  VanturaClient({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
    this.temperature,
    this.maxCompletionTokens,
    this.topP,
    this.stream,
    this.reasoningEffort,
    this.stop,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Sends a chat request to the API.
  ///
  /// [messages] should be a list of message maps with 'role' and 'content'.
  /// [tools] is an optional list of tool definitions.
  /// Other parameters override defaults if provided.
  ///
  /// Returns the API response as a map.
  /// Throws an exception on failure.
  Future<Map<String, dynamic>> sendChatRequest(
    List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>>? tools, {
    double? temperature,
    int? maxCompletionTokens,
    double? topP,
    bool? stream,
    String? reasoningEffort,
    dynamic stop,
    CancellationToken? cancellationToken,
  }) async {
    sdkLogger.info(
      'Sending chat request to API (model: $model)',
      tag: 'API',
      extra: {
        'model': model,
        'message_count': messages.length,
        'has_tools': tools != null && tools.isNotEmpty,
        if (sdkLogger.options.logSensitiveContent) 'messages': messages,
      },
    );

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final bodyMap = {
      'model': model,
      'messages': messages,
      'tools': tools,
      'tool_choice': 'auto',
      if ((temperature ?? this.temperature) != null)
        'temperature': temperature ?? this.temperature,
      if ((maxCompletionTokens ?? this.maxCompletionTokens) != null)
        'max_completion_tokens':
            maxCompletionTokens ?? this.maxCompletionTokens,
      if ((topP ?? this.topP) != null) 'top_p': topP ?? this.topP,
      if ((stream ?? this.stream) != null) 'stream': stream ?? this.stream,
      if ((reasoningEffort ?? this.reasoningEffort) != null)
        'reasoning_effort': reasoningEffort ?? this.reasoningEffort,
      if ((stop ?? this.stop) != null) 'stop': stop ?? this.stop,
    };

    final body = jsonEncode(bodyMap);

    const int maxRetries = 3;
    const Duration baseDelay = Duration(seconds: 1);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      if (cancellationToken?.isCancelled == true) {
        sdkLogger.info('API request cancelled by user', tag: 'API');
        throw Exception('Request cancelled by user');
      }

      try {
        final stopwatch = Stopwatch()..start();

        sdkLogger.info(
          'Sending API request (model: $model) attempt $attempt',
          tag: 'API',
          extra: {
            'model': model,
            'url': baseUrl,
            'body_length': body.length,
            'headers': {...headers, 'Authorization': 'Bearer [REDACTED]'},
          },
        );

        final response = await _httpClient.post(
          Uri.parse(baseUrl),
          headers: headers,
          body: body,
        );

        stopwatch.stop();
        sdkLogger.logPerformance(
          'API request (model: $model)',
          stopwatch.elapsed,
          context: {'model': model, 'status_code': response.statusCode},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['usage'] != null) {
            final usage = data['usage'];
            final promptTokens = usage['prompt_tokens'] ?? 0;
            final completionTokens = usage['completion_tokens'] ?? 0;
            final totalTokens = usage['total_tokens'] ?? 0;

            final cost =
                (promptTokens * 0.00059 / 1000) +
                (completionTokens * 0.00079 / 1000);

            sdkLogger.info(
              'API request successful. Model: ${data['model']}',
              tag: 'API',
              extra: {
                'usage': {
                  'prompt_tokens': promptTokens,
                  'completion_tokens': completionTokens,
                  'total_tokens': totalTokens,
                  'estimated_cost_usd': cost.toStringAsFixed(6),
                },
                if (sdkLogger.options.logSensitiveContent) 'response': data,
              },
            );
          }
          return data;
        } else if (response.statusCode == 429) {
          if (attempt == maxRetries) {
            throw Exception(
              'Rate limit exceeded after $maxRetries attempts: ${response.body}',
            );
          }

          final retryAfterContent = response.headers['retry-after'];
          int retrySeconds = attempt * 2;

          if (retryAfterContent != null) {
            retrySeconds = int.tryParse(retryAfterContent) ?? retrySeconds;
          }

          sdkLogger.warning(
            'Rate limit hit (429). Retrying in ${retrySeconds}s... (Attempt $attempt/$maxRetries)',
            tag: 'API',
            extra: {'response_redacted': '[REDACTED]'},
          );

          await Future.delayed(Duration(seconds: retrySeconds));
          continue;
        } else {
          sdkLogger.error(
            'API request (model: $model) failed',
            tag: 'API',
            extra: {
              'status_code': response.statusCode,
              if (sdkLogger.options.logSensitiveContent)
                'response_body': response.body,
            },
          );
          throw Exception('Failed to get response: ${response.statusCode}');
        }
      } on http.ClientException catch (e) {
        if (attempt == maxRetries) {
          sdkLogger.error(
            'API request (model: $model) failed after $maxRetries attempts',
            tag: 'API',
            error: e,
          );
          rethrow;
        }
        sdkLogger.warning(
          'API request (model: $model) attempt $attempt failed, retrying...',
          tag: 'API',
          error: e,
        );
        await Future.delayed(baseDelay * attempt);
      } catch (e, stackTrace) {
        sdkLogger.error(
          'API request (model: $model) error',
          tag: 'API',
          error: e,
          stackTrace: stackTrace,
        );
        rethrow;
      }
    }

    throw Exception('Unexpected error in API request');
  }

  /// Sends a streaming chat request to the API.
  Stream<Map<String, dynamic>> sendStreamingChatRequest(
    List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>>? tools, {
    double? temperature,
    int? maxCompletionTokens,
    double? topP,
    String? reasoningEffort,
    dynamic stop,
    CancellationToken? cancellationToken,
  }) async* {
    sdkLogger.info(
      'Sending streaming chat request to API (model: $model)',
      tag: 'API',
      extra: {
        'model': model,
        'message_count': messages.length,
        'has_tools': tools != null && tools.isNotEmpty,
        if (sdkLogger.options.logSensitiveContent) 'messages': messages,
      },
    );

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      'model': model,
      'messages': messages,
      'tools': tools,
      'tool_choice': 'auto',
      'stream': true,
      'stream_options': {"include_usage": true},
      if ((temperature ?? this.temperature) != null)
        'temperature': temperature ?? this.temperature,
      if ((maxCompletionTokens ?? this.maxCompletionTokens) != null)
        'max_completion_tokens':
            maxCompletionTokens ?? this.maxCompletionTokens,
      if ((topP ?? this.topP) != null) 'top_p': topP ?? this.topP,
      if ((reasoningEffort ?? this.reasoningEffort) != null)
        'reasoning_effort': reasoningEffort ?? this.reasoningEffort,
      if ((stop ?? this.stop) != null) 'stop': stop ?? this.stop,
    });

    try {
      final request = http.Request('POST', Uri.parse(baseUrl));
      request.headers.addAll(headers);
      request.body = body;

      sdkLogger.debug(
        'Opening API stream connection',
        tag: 'API',
        extra: {
          'headers': {...headers, 'Authorization': 'Bearer [REDACTED]'},
        },
      );

      final response = await _httpClient.send(request);

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        sdkLogger.error(
          'Streaming requested failed',
          tag: 'API',
          extra: {
            'status_code': response.statusCode,
            if (sdkLogger.options.logSensitiveContent) 'error_body': errorBody,
          },
        );
        throw Exception('Streaming request failed: ${response.statusCode}');
      }

      yield* response.stream
          .takeWhile((_) => !(cancellationToken?.isCancelled ?? false))
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .where((line) => line.trim().isNotEmpty)
          .map((line) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6).trim();
              if (data == '[DONE]') return null;
              try {
                return jsonDecode(data) as Map<String, dynamic>;
              } catch (e) {
                sdkLogger.error('Error decoding SSE chunk', tag: 'API');
                return null;
              }
            }
            return null;
          })
          .where((json) => json != null)
          .cast<Map<String, dynamic>>();
    } catch (e, stackTrace) {
      sdkLogger.error(
        'Error in streaming request',
        tag: 'API',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Closes the shared HTTP client.
  void close() {
    _httpClient.close();
  }
}
