import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vantura/core/index.dart';

/// A client for communicating with Google's Gemini API via REST.
///
/// Implements [LlmClient] to integrate seamlessly with the Vantura framework.
/// Supports both standard generation and Server-Sent Events (SSE) streaming.
class GeminiClient implements LlmClient {
  /// API key for authentication.
  final String apiKey;

  /// Default model to use for requests (e.g., gemini-1.5-flash-latest).
  final String model;

  /// Base URL for Gemini API.
  final String baseUrl;

  /// Default maximum tokens to sample.
  final int maxTokens;

  /// Default temperature for responses.
  final double? temperature;

  /// Callback emitted when a request is about to be retried.
  final void Function(int attempt, Duration nextDelay, dynamic error)? onRetry;

  /// Optional custom HTTP client.
  final http.Client _httpClient;

  /// Creates a [GeminiClient].
  ///
  /// [apiKey] is required. [model] defaults to 'gemini-1.5-flash-latest'.
  /// [baseUrl] defaults to the v1beta endpoint.
  GeminiClient({
    required this.apiKey,
    this.model = 'gemini-1.5-flash-latest',
    String? baseUrl,
    this.maxTokens = 8192,
    this.temperature,
    this.onRetry,
    http.Client? httpClient,
  }) : baseUrl = baseUrl ?? 'https://generativelanguage.googleapis.com/v1beta',
       _httpClient = httpClient ?? http.Client();

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  // ---------------------------------------------------------------------------
  // Format converters
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _convertToGeminiFormat(
    List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>>? tools,
  ) {
    // Gemini separates system instructions from the conversation history
    Map<String, dynamic>? systemMessage;
    for (final m in messages) {
      if (m['role'] == 'system') {
        systemMessage = m;
        break;
      }
    }
    final systemInstruction = systemMessage?['content'] as String?;

    final formattedContents = messages.where((m) => m['role'] != 'system').map((
      m,
    ) {
      if (m['role'] == 'tool') {
        return {
          'role': 'user',
          'parts': [
            {
              'functionResponse': {
                'name': m['tool_call_id'],
                'response': {'result': m['content']},
              },
            },
          ],
        };
      } else if (m['role'] == 'assistant' && m['tool_calls'] != null) {
        final calls = m['tool_calls'] as List;
        final List<Map<String, dynamic>> parts = [];

        final text = (m['content'] as String?) ?? '';
        if (text.isNotEmpty) {
          parts.add({'text': text});
        }

        parts.addAll(
          calls.map(
            (c) => {
              'functionCall': {
                'name': c['function']['name'],
                'args': c['function']['arguments'] != null
                    ? jsonDecode(c['function']['arguments'] as String)
                    : {},
              },
            },
          ),
        );
        return {'role': 'model', 'parts': parts};
      }

      return {
        'role': m['role'] == 'assistant' ? 'model' : 'user',
        'parts': [
          {'text': m['content'] as String? ?? ''},
        ],
      };
    }).toList();

    List<Map<String, dynamic>>? formattedTools;
    if (tools != null && tools.isNotEmpty) {
      final functionDeclarations = tools.map((t) {
        final func = t['function'] as Map<String, dynamic>;
        return {
          'name': func['name'],
          'description': func['description'],
          'parameters':
              func['parameters'] ?? {'type': 'OBJECT', 'properties': {}},
        };
      }).toList();
      formattedTools = [
        {'functionDeclarations': functionDeclarations},
      ];
    }

    return {
      if (systemInstruction != null)
        'systemInstruction': {
          'parts': [
            {'text': systemInstruction},
          ],
        },
      'contents': formattedContents,
      if (formattedTools != null) 'tools': formattedTools,
    };
  }

  /// Converts a Gemini response chunk into an OpenAI-compatible format.
  Map<String, dynamic> _convertFromGeminiResponse(
    Map<String, dynamic> response, {
    bool isDelta = false,
  }) {
    if (response['candidates'] == null || response['candidates'].isEmpty) {
      if (response['usageMetadata'] != null) {
        return {
          'model': model,
          'choices': [],
          'usage': {
            'prompt_tokens': response['usageMetadata']['promptTokenCount'] ?? 0,
            'completion_tokens':
                response['usageMetadata']['candidatesTokenCount'] ?? 0,
            'total_tokens': response['usageMetadata']['totalTokenCount'] ?? 0,
          },
        };
      }
      return {'model': model, 'choices': []};
    }

    final candidate = response['candidates'][0];
    final content = (candidate != null ? candidate['content'] : null);
    final parts = (content != null ? content['parts'] : null) as List?;

    String textContent = '';
    List<Map<String, dynamic>>? formattedToolCalls;
    String finishReason = 'stop';

    if (parts != null) {
      for (var part in parts) {
        if (part['text'] != null) {
          textContent += part['text'];
        }
        if (part['functionCall'] != null) {
          formattedToolCalls ??= [];
          final call = part['functionCall'];
          formattedToolCalls.add({
            'id': call['name'],
            'type': 'function',
            'function': {
              'name': call['name'],
              'arguments': jsonEncode(call['args']),
            },
          });
        }
      }
    }

    if (formattedToolCalls != null && formattedToolCalls.isNotEmpty) {
      finishReason = 'tool_calls';
    } else if (candidate['finishReason'] != null &&
        candidate['finishReason'] != 'STOP') {
      finishReason = candidate['finishReason'].toString().toLowerCase();
    }

    return {
      'model': model,
      'choices': [
        {
          if (isDelta)
            'delta': {
              'role': 'assistant',
              'content': textContent.isEmpty ? null : textContent,
              if (formattedToolCalls != null) 'tool_calls': formattedToolCalls,
            }
          else
            'message': {
              'role': 'assistant',
              'content': textContent.isEmpty ? null : textContent,
              if (formattedToolCalls != null) 'tool_calls': formattedToolCalls,
            },
          'finish_reason': finishReason == 'stop' ? null : finishReason,
        },
      ],
      if (response['usageMetadata'] != null)
        'usage': {
          'prompt_tokens': response['usageMetadata']['promptTokenCount'] ?? 0,
          'completion_tokens':
              response['usageMetadata']['candidatesTokenCount'] ?? 0,
          'total_tokens': response['usageMetadata']['totalTokenCount'] ?? 0,
        },
    };
  }

  // ---------------------------------------------------------------------------
  // LlmClient Implementation
  // ---------------------------------------------------------------------------

  @override
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
      'Sending chat request to Gemini (model: $model)',
      tag: 'API',
      extra: {
        'model': model,
        'message_count': messages.length,
        'has_tools': tools != null && tools.isNotEmpty,
      },
    );

    final geminiData = _convertToGeminiFormat(messages, tools);

    final generationConfig = {
      'maxOutputTokens': maxCompletionTokens ?? maxTokens,
      if ((temperature ?? this.temperature) != null)
        'temperature': temperature ?? this.temperature,
      if (topP != null) 'topP': topP,
      if (stop != null) 'stopSequences': stop is List ? stop : [stop],
    };

    final bodyMap = {
      if (geminiData['systemInstruction'] != null)
        'systemInstruction': geminiData['systemInstruction'],
      'contents': geminiData['contents'],
      if (geminiData['tools'] != null) 'tools': geminiData['tools'],
      'generationConfig': generationConfig,
    };

    const int maxRetries = 3;
    const Duration baseDelay = Duration(seconds: 1);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      if (cancellationToken?.isCancelled == true) {
        throw VanturaCancellationException();
      }

      final url = '$baseUrl/models/$model:generateContent?key=$apiKey';

      try {
        final stopwatch = Stopwatch()..start();
        final response = await _httpClient.post(
          Uri.parse(url),
          headers: _headers,
          body: jsonEncode(bodyMap),
        );
        stopwatch.stop();

        sdkLogger.logPerformance(
          'Gemini API request ($model)',
          stopwatch.elapsed,
          context: {'status_code': response.statusCode},
        );

        if (response.statusCode == 200) {
          return _convertFromGeminiResponse(jsonDecode(response.body));
        } else if (response.statusCode == 429 || response.statusCode >= 500) {
          if (attempt == maxRetries) {
            throw VanturaApiException(
              'Gemini API error after $maxRetries attempts',
              statusCode: response.statusCode,
              responseBody: response.body,
            );
          }

          final retrySeconds = attempt * 2;
          sdkLogger.warning(
            'Gemini API hit ${response.statusCode}. Retrying in ${retrySeconds}s... (Attempt $attempt/$maxRetries)',
            tag: 'API',
          );

          if (onRetry != null) {
            onRetry!(
              attempt,
              Duration(seconds: retrySeconds),
              'HTTP ${response.statusCode}',
            );
          }

          await Future.delayed(Duration(seconds: retrySeconds));
          continue;
        } else {
          throw VanturaApiException(
            'Gemini API error',
            statusCode: response.statusCode,
            responseBody: response.body,
          );
        }
      } on http.ClientException catch (_) {
        if (attempt == maxRetries) rethrow;
        await Future.delayed(baseDelay * attempt);
      }
    }

    throw Exception('Unexpected error in Gemini request');
  }

  @override
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
      'Opening Gemini stream (model: $model)',
      tag: 'API',
      extra: {'model': model, 'message_count': messages.length},
    );

    final geminiData = _convertToGeminiFormat(messages, tools);

    final generationConfig = {
      'maxOutputTokens': maxCompletionTokens ?? maxTokens,
      if ((temperature ?? this.temperature) != null)
        'temperature': temperature ?? this.temperature,
      if (topP != null) 'topP': topP,
      if (stop != null) 'stopSequences': stop is List ? stop : [stop],
    };

    final bodyMap = {
      if (geminiData['systemInstruction'] != null)
        'systemInstruction': geminiData['systemInstruction'],
      'contents': geminiData['contents'],
      if (geminiData['tools'] != null) 'tools': geminiData['tools'],
      'generationConfig': generationConfig,
    };

    if (cancellationToken?.isCancelled == true) {
      throw VanturaCancellationException();
    }

    final url =
        '$baseUrl/models/$model:streamGenerateContent?alt=sse&key=$apiKey';

    final request = http.Request('POST', Uri.parse(url));
    request.headers.addAll(_headers);
    request.body = jsonEncode(bodyMap);

    final streamedResponse = await _httpClient.send(request);

    if (streamedResponse.statusCode != 200) {
      final errorBody = await streamedResponse.stream.bytesToString();
      throw VanturaApiException(
        'Gemini streaming error',
        statusCode: streamedResponse.statusCode,
        responseBody: errorBody,
      );
    }

    await for (final line
        in streamedResponse.stream
            .takeWhile((_) => !(cancellationToken?.isCancelled ?? false))
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (cancellationToken?.isCancelled == true) break;

      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (!trimmed.startsWith('data: ')) continue;
      final data = trimmed.substring(6).trim();

      try {
        final json = jsonDecode(data);
        yield _convertFromGeminiResponse(json, isDelta: true);
      } catch (_) {
        continue;
      }
    }
  }

  @override
  void close() {
    _httpClient.close();
  }
}
