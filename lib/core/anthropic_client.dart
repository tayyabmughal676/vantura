import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vantura/core/index.dart';

/// A client for communicating with Anthropic's Claude API.
///
/// Implements [LlmClient] to integrate seamlessly with the Vantura framework.
/// Supports both the standard Messages API (non-streaming) and the
/// Server-Sent Events (SSE) streaming format.
class AnthropicClient implements LlmClient {
  /// API key for authentication.
  final String apiKey;

  /// Anthropic API version header.
  final String apiVersion;

  /// Default model to use for requests.
  final String model;

  /// Default maximum tokens to sample.
  final int maxTokens;

  /// Default temperature for responses.
  final double? temperature;

  /// Optional custom HTTP client.
  final http.Client _httpClient;

  /// Base URL for Anthropic API.
  final String baseUrl;

  /// Callback emitted when a request is about to be retried.
  final void Function(int attempt, Duration nextDelay, dynamic error)? onRetry;

  /// Creates an [AnthropicClient].
  ///
  /// [apiKey] is required. All other parameters have sensible defaults.
  /// You can swap [model] to any supported Claude model name, such as
  /// `'claude-3-7-sonnet-latest'`, `'claude-3-5-sonnet-latest'`, or `'claude-3-5-haiku-latest'`.
  AnthropicClient({
    required this.apiKey,
    this.model = 'claude-3-5-sonnet-latest',
    this.baseUrl = 'https://api.anthropic.com/v1/messages',
    this.apiVersion = '2023-06-01',
    this.maxTokens = 4096,
    this.temperature,
    this.onRetry,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  Map<String, String> get _headers => {
    'x-api-key': apiKey,
    'anthropic-version': apiVersion,
    'content-type': 'application/json',
  };

  // ---------------------------------------------------------------------------
  // Format converters
  // ---------------------------------------------------------------------------

  /// Converts OpenAI-format messages + tools into Anthropic's request format.
  Map<String, dynamic> _convertToAnthropicFormat(
    List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>>? tools,
  ) {
    // Extract the system prompt if present (Anthropic separates it from messages)
    Map<String, dynamic>? systemMessage;
    for (final m in messages) {
      if (m['role'] == 'system') {
        systemMessage = m;
        break;
      }
    }
    final systemPrompt = systemMessage?['content'] as String?;

    final formattedMessages = messages.where((m) => m['role'] != 'system').map((
      m,
    ) {
      if (m['role'] == 'tool') {
        // OpenAI tool results → Anthropic tool_result inside a user message
        return {
          'role': 'user',
          'content': [
            {
              'type': 'tool_result',
              'tool_use_id': m['tool_call_id'],
              'content': m['content'],
            },
          ],
        };
      }

      if (m['role'] == 'assistant' && m['tool_calls'] != null) {
        // OpenAI assistant tool_calls → Anthropic tool_use content blocks
        final calls = m['tool_calls'] as List;
        final contentBlocks = <Map<String, dynamic>>[];

        final text = (m['content'] as String?) ?? '';
        if (text.isNotEmpty) {
          contentBlocks.add({'type': 'text', 'text': text});
        }

        for (final c in calls) {
          dynamic input;
          try {
            input = jsonDecode(c['function']['arguments'] as String);
          } catch (_) {
            input = {};
          }
          contentBlocks.add({
            'type': 'tool_use',
            'id': c['id'],
            'name': c['function']['name'],
            'input': input,
          });
        }
        return {'role': 'assistant', 'content': contentBlocks};
      }

      // Plain user / assistant text message
      return {'role': m['role'], 'content': m['content']};
    }).toList();

    List<Map<String, dynamic>>? formattedTools;
    if (tools != null && tools.isNotEmpty) {
      formattedTools = tools.map((t) {
        final func = t['function'] as Map<String, dynamic>;
        return {
          'name': func['name'],
          'description': func['description'],
          'input_schema': func['parameters'],
        };
      }).toList();
    }

    return {
      if (systemPrompt != null) 'system': systemPrompt,
      'messages': formattedMessages,
      if (formattedTools != null) 'tools': formattedTools,
    };
  }

  /// Converts a complete Anthropic response body to OpenAI-compatible format.
  Map<String, dynamic> _convertFromAnthropicResponse(
    Map<String, dynamic> response,
  ) {
    final content = response['content'] as List;
    final textContent = content
        .where((c) => c['type'] == 'text')
        .map((c) => c['text'])
        .join('\n');
    final toolUses = content.where((c) => c['type'] == 'tool_use').toList();

    List<Map<String, dynamic>>? formattedToolCalls;
    if (toolUses.isNotEmpty) {
      formattedToolCalls = toolUses.map((t) {
        return {
          'id': t['id'],
          'type': 'function',
          'function': {'name': t['name'], 'arguments': jsonEncode(t['input'])},
        };
      }).toList();
    }

    return {
      'model': response['model'],
      'choices': [
        {
          'message': {
            'role': 'assistant',
            'content': textContent.isEmpty ? null : textContent,
            if (formattedToolCalls != null) 'tool_calls': formattedToolCalls,
          },
          'finish_reason': response['stop_reason'] == 'tool_use'
              ? 'tool_calls'
              : response['stop_reason'],
        },
      ],
      'usage': {
        'prompt_tokens': response['usage']?['input_tokens'] ?? 0,
        'completion_tokens': response['usage']?['output_tokens'] ?? 0,
        'total_tokens':
            (response['usage']?['input_tokens'] ?? 0) +
            (response['usage']?['output_tokens'] ?? 0),
      },
    };
  }

  // ---------------------------------------------------------------------------
  // LlmClient interface
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
      'Sending chat request to Anthropic (model: $model)',
      tag: 'API',
      extra: {
        'model': model,
        'message_count': messages.length,
        'has_tools': tools != null && tools.isNotEmpty,
      },
    );

    final anthropicData = _convertToAnthropicFormat(messages, tools);

    final body = jsonEncode({
      'model': model,
      'max_tokens': maxCompletionTokens ?? maxTokens,
      if (anthropicData['system'] != null) 'system': anthropicData['system'],
      'messages': anthropicData['messages'],
      if (anthropicData['tools'] != null) 'tools': anthropicData['tools'],
      if ((temperature ?? this.temperature) != null)
        'temperature': temperature ?? this.temperature,
    });

    const int maxRetries = 3;
    const Duration baseDelay = Duration(seconds: 1);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      if (cancellationToken?.isCancelled == true) {
        throw VanturaCancellationException();
      }

      try {
        final stopwatch = Stopwatch()..start();
        final response = await _httpClient.post(
          Uri.parse(baseUrl),
          headers: _headers,
          body: body,
        );
        stopwatch.stop();

        sdkLogger.logPerformance(
          'Anthropic API request ($model)',
          stopwatch.elapsed,
          context: {'status_code': response.statusCode},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return _convertFromAnthropicResponse(data);
        } else if (response.statusCode == 429 || response.statusCode >= 500) {
          if (attempt == maxRetries) {
            throw VanturaApiException(
              'Anthropic API error after $maxRetries attempts',
              statusCode: response.statusCode,
              responseBody: response.body,
            );
          }

          final retrySeconds = attempt * 2;
          sdkLogger.warning(
            'Anthropic API hit ${response.statusCode}. Retrying in ${retrySeconds}s... (Attempt $attempt/$maxRetries)',
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
            'Anthropic API error',
            statusCode: response.statusCode,
            responseBody: response.body,
          );
        }
      } on http.ClientException catch (_) {
        if (attempt == maxRetries) rethrow;
        await Future.delayed(baseDelay * attempt);
      }
    }

    throw Exception('Unexpected error in Anthropic request');
  }

  /// Sends a streaming chat request using Anthropic's SSE protocol.
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
      'Opening Anthropic stream (model: $model)',
      tag: 'API',
      extra: {'model': model, 'message_count': messages.length},
    );

    if (cancellationToken?.isCancelled == true) {
      throw VanturaCancellationException();
    }

    final anthropicData = _convertToAnthropicFormat(messages, tools);

    final body = jsonEncode({
      'model': model,
      'max_tokens': maxCompletionTokens ?? maxTokens,
      'stream': true,
      if (anthropicData['system'] != null) 'system': anthropicData['system'],
      'messages': anthropicData['messages'],
      if (anthropicData['tools'] != null) 'tools': anthropicData['tools'],
      if ((temperature ?? this.temperature) != null)
        'temperature': temperature ?? this.temperature,
    });

    final request = http.Request('POST', Uri.parse(baseUrl));
    request.headers.addAll({..._headers, 'accept': 'text/event-stream'});
    request.body = body;

    final streamed = await _httpClient.send(request);

    if (streamed.statusCode != 200) {
      final errorBody = await streamed.stream.bytesToString();
      throw VanturaApiException(
        'Anthropic streaming error',
        statusCode: streamed.statusCode,
        responseBody: errorBody,
      );
    }

    // --- SSE state machine ---
    final StringBuffer textBuffer = StringBuffer();
    // Map from content block index → {id, name, inputBuffer}
    final Map<int, Map<String, dynamic>> toolBlocks = {};
    String? stopReason;
    int inputTokens = 0;
    int outputTokens = 0;
    String? currentEventType;

    await for (final line
        in streamed.stream
            .takeWhile((_) => !(cancellationToken?.isCancelled ?? false))
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (cancellationToken?.isCancelled == true) break;

      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Capture the event-type line (comes before the data line in Anthropic SSE)
      if (trimmed.startsWith('event: ')) {
        currentEventType = trimmed.substring(7).trim();
        continue;
      }

      if (!trimmed.startsWith('data: ')) continue;
      final rawData = trimmed.substring(6).trim();
      if (rawData == '[DONE]') break;

      Map<String, dynamic> event;
      try {
        event = jsonDecode(rawData) as Map<String, dynamic>;
      } catch (_) {
        continue; // skip malformed lines
      }

      // Prefer the explicit event: line; fall back to the 'type' field in data
      final eventType = currentEventType ?? event['type'] as String?;
      currentEventType = null; // reset after consuming

      switch (eventType) {
        case 'message_start':
          // Capture input token count from the opening message event
          final msg = event['message'] as Map<String, dynamic>?;
          final usage = msg?['usage'] as Map<String, dynamic>?;
          inputTokens = (usage?['input_tokens'] as int?) ?? 0;

        case 'content_block_start':
          // Register a new content block — only care about tool_use blocks
          final index = (event['index'] as int?) ?? 0;
          final block = event['content_block'] as Map<String, dynamic>?;
          if (block?['type'] == 'tool_use') {
            toolBlocks[index] = {
              'id': block!['id'],
              'name': block['name'],
              'inputBuffer': StringBuffer(),
            };
          }

        case 'content_block_delta':
          final index = (event['index'] as int?) ?? 0;
          final delta = event['delta'] as Map<String, dynamic>?;
          if (delta == null) break;

          if (delta['type'] == 'text_delta') {
            // Incremental text token — yield immediately and accumulate
            final chunk = (delta['text'] as String?) ?? '';
            textBuffer.write(chunk);
            yield {
              'choices': [
                {
                  'delta': {'role': 'assistant', 'content': chunk},
                  'finish_reason': null,
                },
              ],
            };
          } else if (delta['type'] == 'input_json_delta') {
            // Partial JSON for tool arguments — accumulate only, don't yield
            final partial = (delta['partial_json'] as String?) ?? '';
            (toolBlocks[index]?['inputBuffer'] as StringBuffer?)?.write(
              partial,
            );
          }

        case 'message_delta':
          // Capture stop_reason and final output token count
          final delta = event['delta'] as Map<String, dynamic>?;
          stopReason = delta?['stop_reason'] as String?;
          final usage = event['usage'] as Map<String, dynamic>?;
          outputTokens = (usage?['output_tokens'] as int?) ?? outputTokens;

        case 'message_stop':
          break;

        default:
          break;
      }
    }

    // --- Emit the final aggregate chunk ---
    final finalText = textBuffer.toString();

    List<Map<String, dynamic>>? toolCalls;
    if (toolBlocks.isNotEmpty) {
      toolCalls = toolBlocks.entries.map((e) {
        final block = e.value;
        final inputStr = (block['inputBuffer'] as StringBuffer).toString();
        dynamic parsedInput;
        try {
          parsedInput = jsonDecode(inputStr.isEmpty ? '{}' : inputStr);
        } catch (_) {
          parsedInput = <String, dynamic>{};
        }
        return {
          'id': block['id'],
          'type': 'function',
          'function': {
            'name': block['name'],
            'arguments': jsonEncode(parsedInput),
          },
        };
      }).toList();
    }

    yield {
      'choices': [
        {
          'delta': {
            'role': 'assistant',
            'content': finalText.isEmpty ? null : finalText,
            if (toolCalls != null) 'tool_calls': toolCalls,
          },
          'finish_reason': stopReason == 'tool_use' ? 'tool_calls' : stopReason,
        },
      ],
      'usage': {
        'prompt_tokens': inputTokens,
        'completion_tokens': outputTokens,
        'total_tokens': inputTokens + outputTokens,
      },
    };
  }

  @override
  void close() {
    _httpClient.close();
  }
}
