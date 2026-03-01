import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:vantura/core/index.dart';

import '../mocks/mocks.mocks.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Encodes an Anthropic-format response body as JSON.
String _anthropicResponse({
  String text = 'Hello from Claude!',
  String stopReason = 'end_turn',
  String model = 'claude-sonnet-4-6',
  int inputTokens = 10,
  int outputTokens = 8,
  List<Map<String, dynamic>>? toolUses,
}) {
  final content = <Map<String, dynamic>>[
    if (text.isNotEmpty) {'type': 'text', 'text': text},
    if (toolUses != null) ...toolUses,
  ];
  return jsonEncode({
    'id': 'msg_test_01',
    'type': 'message',
    'role': 'assistant',
    'model': model,
    'content': content,
    'stop_reason': stopReason,
    'usage': {'input_tokens': inputTokens, 'output_tokens': outputTokens},
  });
}

/// Builds a fake SSE line sequence for streaming tests.
String _buildSseStream(List<String> events) => events.join('\n') + '\n';

/// Creates a mock streamed response from raw SSE bytes.
http.StreamedResponse _streamedResponse(
  String sseBody, {
  int statusCode = 200,
}) {
  final bytes = utf8.encode(sseBody);
  return http.StreamedResponse(Stream.fromIterable([bytes]), statusCode);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AnthropicClient', () {
    late MockClient mockHttpClient;
    late AnthropicClient client;

    setUp(() {
      mockHttpClient = MockClient();
      client = AnthropicClient(
        apiKey: 'test-anthropic-key',
        model: 'claude-sonnet-4-6',
        httpClient: mockHttpClient,
      );
    });

    // -------------------------------------------------------------------------
    // sendChatRequest — non-streaming
    // -------------------------------------------------------------------------
    group('sendChatRequest', () {
      test('sends correct headers and receives a text response', () async {
        when(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).thenAnswer((_) async => http.Response(_anthropicResponse(), 200));

        final messages = [
          {'role': 'user', 'content': 'Hello, Claude'},
        ];
        final result = await client.sendChatRequest(messages, null);

        // Verify OpenAI-compatible structure
        expect(result['choices'], isNotNull);
        expect(result['choices'][0]['message']['role'], 'assistant');
        expect(
          result['choices'][0]['message']['content'],
          'Hello from Claude!',
        );
        expect(result['choices'][0]['finish_reason'], 'end_turn');
      });

      test('maps usage fields correctly', () async {
        when(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            _anthropicResponse(inputTokens: 20, outputTokens: 15),
            200,
          ),
        );

        final result = await client.sendChatRequest([
          {'role': 'user', 'content': 'test'},
        ], null);

        expect(result['usage']['prompt_tokens'], 20);
        expect(result['usage']['completion_tokens'], 15);
        expect(result['usage']['total_tokens'], 35);
      });

      test(
        'extracts system prompt and excludes it from messages array',
        () async {
          String? capturedBody;
          when(
            mockHttpClient.post(
              any,
              headers: anyNamed('headers'),
              body: anyNamed('body'),
              encoding: anyNamed('encoding'),
            ),
          ).thenAnswer((inv) async {
            capturedBody = inv.namedArguments[const Symbol('body')] as String?;
            return http.Response(_anthropicResponse(), 200);
          });

          await client.sendChatRequest([
            {'role': 'system', 'content': 'You are a helpful assistant.'},
            {'role': 'user', 'content': 'Hello!'},
          ], null);

          final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
          // System must be at top-level, NOT inside messages
          expect(body['system'], 'You are a helpful assistant.');
          final msgs = body['messages'] as List;
          expect(msgs.any((m) => m['role'] == 'system'), isFalse);
          expect(msgs.length, 1);
          expect(msgs[0]['role'], 'user');
        },
      );

      test(
        'converts tool_calls in assistant messages to Anthropic tool_use blocks',
        () async {
          String? capturedBody;
          when(
            mockHttpClient.post(
              any,
              headers: anyNamed('headers'),
              body: anyNamed('body'),
              encoding: anyNamed('encoding'),
            ),
          ).thenAnswer((inv) async {
            capturedBody = inv.namedArguments[const Symbol('body')] as String?;
            return http.Response(_anthropicResponse(), 200);
          });

          await client.sendChatRequest([
            {'role': 'user', 'content': 'What is 2+2?'},
            {
              'role': 'assistant',
              'content': '',
              'tool_calls': [
                {
                  'id': 'call_abc',
                  'type': 'function',
                  'function': {
                    'name': 'calculator',
                    'arguments': jsonEncode({'expression': '2+2'}),
                  },
                },
              ],
            },
            {'role': 'tool', 'tool_call_id': 'call_abc', 'content': '4'},
          ], null);

          final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
          final msgs = body['messages'] as List;

          // Assistant message should have tool_use content block
          final assistantMsg = msgs.firstWhere((m) => m['role'] == 'assistant');
          final content = assistantMsg['content'] as List;
          final toolUseBlock = content.firstWhere(
            (c) => c['type'] == 'tool_use',
          );
          expect(toolUseBlock['id'], 'call_abc');
          expect(toolUseBlock['name'], 'calculator');
          expect(toolUseBlock['input']['expression'], '2+2');

          // Tool result should become a user message with tool_result block
          final toolResultMsg = msgs.lastWhere((m) => m['role'] == 'user');
          final resultContent = toolResultMsg['content'] as List;
          final resultBlock = resultContent.first;
          expect(resultBlock['type'], 'tool_result');
          expect(resultBlock['tool_use_id'], 'call_abc');
          expect(resultBlock['content'], '4');
        },
      );

      test('converts tools list to Anthropic input_schema format', () async {
        String? capturedBody;
        when(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).thenAnswer((inv) async {
          capturedBody = inv.namedArguments[const Symbol('body')] as String?;
          return http.Response(_anthropicResponse(), 200);
        });

        final tools = [
          {
            'type': 'function',
            'function': {
              'name': 'get_weather',
              'description': 'Get the weather for a location',
              'parameters': {
                'type': 'object',
                'properties': {
                  'location': {'type': 'string'},
                },
              },
            },
          },
        ];

        await client.sendChatRequest([
          {'role': 'user', 'content': 'Weather in London?'},
        ], tools);

        final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
        final anthropicTools = body['tools'] as List;
        expect(anthropicTools.length, 1);
        expect(anthropicTools[0]['name'], 'get_weather');
        expect(anthropicTools[0]['input_schema'], isNotNull);
        // Should NOT use 'parameters' key (that's OpenAI)
        expect(anthropicTools[0].containsKey('parameters'), isFalse);
      });

      test(
        'returns tool_calls in OpenAI-compatible format when Claude uses a tool',
        () async {
          final toolUseResponse = _anthropicResponse(
            text: '',
            stopReason: 'tool_use',
            toolUses: [
              {
                'type': 'tool_use',
                'id': 'tool_use_xyz',
                'name': 'calculator',
                'input': {'expression': '10 * 5'},
              },
            ],
          );

          when(
            mockHttpClient.post(
              any,
              headers: anyNamed('headers'),
              body: anyNamed('body'),
              encoding: anyNamed('encoding'),
            ),
          ).thenAnswer((_) async => http.Response(toolUseResponse, 200));

          final result = await client.sendChatRequest([
            {'role': 'user', 'content': 'What is 10 * 5?'},
          ], null);

          // finish_reason: tool_use → tool_calls
          expect(result['choices'][0]['finish_reason'], 'tool_calls');
          final toolCalls =
              result['choices'][0]['message']['tool_calls'] as List;
          expect(toolCalls.length, 1);
          expect(toolCalls[0]['id'], 'tool_use_xyz');
          expect(toolCalls[0]['function']['name'], 'calculator');
          final args = jsonDecode(toolCalls[0]['function']['arguments']);
          expect(args['expression'], '10 * 5');
        },
      );

      test('throws VanturaApiException on non-200 response', () async {
        when(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).thenAnswer(
          (_) async => http.Response('{"error": "invalid api key"}', 401),
        );

        await expectLater(
          client.sendChatRequest([
            {'role': 'user', 'content': 'hi'},
          ], null),
          throwsA(isA<VanturaApiException>()),
        );
      });

      test('throws VanturaApiException on 529 overloaded', () async {
        when(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).thenAnswer(
          (_) async => http.Response('{"error": "overloaded"}', 529),
        );

        await expectLater(
          client.sendChatRequest([
            {'role': 'user', 'content': 'hi'},
          ], null),
          throwsA(
            isA<VanturaApiException>().having(
              (e) => e.statusCode,
              'statusCode',
              529,
            ),
          ),
        );
      });

      test('aborts immediately when CancellationToken is cancelled', () async {
        final token = CancellationToken()..cancel();

        await expectLater(
          client.sendChatRequest(
            [
              {'role': 'user', 'content': 'hi'},
            ],
            null,
            cancellationToken: token,
          ),
          throwsA(isA<VanturaCancellationException>()),
        );

        verifyNever(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        );
      });

      test('sends correct Anthropic-specific headers', () async {
        Map<String, String>? capturedHeaders;
        when(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).thenAnswer((inv) async {
          capturedHeaders =
              inv.namedArguments[const Symbol('headers')]
                  as Map<String, String>?;
          return http.Response(_anthropicResponse(), 200);
        });

        await client.sendChatRequest([
          {'role': 'user', 'content': 'hi'},
        ], null);

        expect(capturedHeaders?['x-api-key'], 'test-anthropic-key');
        expect(capturedHeaders?['anthropic-version'], '2023-06-01');
        expect(capturedHeaders?['content-type'], 'application/json');
        // Should NOT use Bearer authorization (that's OpenAI)
        expect(capturedHeaders?.containsKey('Authorization'), isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // sendStreamingChatRequest — SSE streaming
    // -------------------------------------------------------------------------
    group('sendStreamingChatRequest', () {
      test('streams incremental text delta chunks', () async {
        final sseBody = _buildSseStream([
          'event: message_start',
          'data: {"type":"message_start","message":{"id":"msg_01","type":"message","role":"assistant","model":"claude-sonnet-4-6","content":[],"stop_reason":null,"usage":{"input_tokens":5,"output_tokens":0}}}',
          '',
          'event: content_block_start',
          'data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}',
          '',
          'event: content_block_delta',
          'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello"}}',
          '',
          'event: content_block_delta',
          'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":" Claude"}}',
          '',
          'event: message_delta',
          'data: {"type":"message_delta","delta":{"stop_reason":"end_turn","stop_sequence":null},"usage":{"output_tokens":2}}',
          '',
          'event: message_stop',
          'data: {"type":"message_stop"}',
        ]);

        when(
          mockHttpClient.send(any),
        ).thenAnswer((_) async => _streamedResponse(sseBody));

        final chunks = await client.sendStreamingChatRequest([
          {'role': 'user', 'content': 'Say hello'},
        ], null).toList();

        // Should have intermediate text chunks + a final aggregate chunk
        final textChunks = chunks
            .where((c) {
              final delta = c['choices']?[0]?['delta'];
              return delta != null &&
                  delta['content'] != null &&
                  delta['tool_calls'] == null;
            })
            .map((c) => c['choices'][0]['delta']['content'] as String)
            .toList();

        expect(textChunks, contains('Hello'));
        expect(textChunks, contains(' Claude'));

        // Final chunk carries usage data
        final finalChunk = chunks.last;
        expect(finalChunk['usage'], isNotNull);
        expect(finalChunk['usage']['prompt_tokens'], 5);
        expect(finalChunk['usage']['completion_tokens'], 2);
        expect(finalChunk['usage']['total_tokens'], 7);
      });

      test('accumulates tool input_json_delta and emits final tool_calls', () async {
        final sseBody = _buildSseStream([
          'event: message_start',
          'data: {"type":"message_start","message":{"usage":{"input_tokens":12,"output_tokens":0}}}',
          '',
          'event: content_block_start',
          'data: {"type":"content_block_start","index":0,"content_block":{"type":"tool_use","id":"tu_001","name":"calculator"}}',
          '',
          'event: content_block_delta',
          'data: {"type":"content_block_delta","index":0,"delta":{"type":"input_json_delta","partial_json":"{\\"expr"}}',
          '',
          'event: content_block_delta',
          'data: {"type":"content_block_delta","index":0,"delta":{"type":"input_json_delta","partial_json":"ession\\": \\"2+2\\"}"}}',
          '',
          'event: message_delta',
          'data: {"type":"message_delta","delta":{"stop_reason":"tool_use"},"usage":{"output_tokens":10}}',
          '',
          'event: message_stop',
          'data: {"type":"message_stop"}',
        ]);

        when(
          mockHttpClient.send(any),
        ).thenAnswer((_) async => _streamedResponse(sseBody));

        final chunks = await client.sendStreamingChatRequest([
          {'role': 'user', 'content': 'What is 2+2?'},
        ], null).toList();

        // Final chunk should carry the resolved tool_calls
        final finalChunk = chunks.last;
        final toolCalls =
            finalChunk['choices'][0]['delta']['tool_calls'] as List?;
        expect(toolCalls, isNotNull);
        expect(toolCalls!.length, 1);
        expect(toolCalls[0]['id'], 'tu_001');
        expect(toolCalls[0]['function']['name'], 'calculator');
        final args = jsonDecode(toolCalls[0]['function']['arguments']);
        expect(args['expression'], '2+2');

        // finish_reason: tool_use → tool_calls
        expect(finalChunk['choices'][0]['finish_reason'], 'tool_calls');
      });

      test('handles multiple tool blocks in a single stream', () async {
        final sseBody = _buildSseStream([
          'event: message_start',
          'data: {"type":"message_start","message":{"usage":{"input_tokens":20,"output_tokens":0}}}',
          '',
          // Tool 1
          'event: content_block_start',
          'data: {"type":"content_block_start","index":0,"content_block":{"type":"tool_use","id":"tu_001","name":"tool_a"}}',
          '',
          'event: content_block_delta',
          'data: {"type":"content_block_delta","index":0,"delta":{"type":"input_json_delta","partial_json":"{\\"key\\":\\"val_a\\"}"}}',
          '',
          // Tool 2
          'event: content_block_start',
          'data: {"type":"content_block_start","index":1,"content_block":{"type":"tool_use","id":"tu_002","name":"tool_b"}}',
          '',
          'event: content_block_delta',
          'data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"{\\"key\\":\\"val_b\\"}"}}',
          '',
          'event: message_delta',
          'data: {"type":"message_delta","delta":{"stop_reason":"tool_use"},"usage":{"output_tokens":20}}',
          '',
          'event: message_stop',
          'data: {"type":"message_stop"}',
        ]);

        when(
          mockHttpClient.send(any),
        ).thenAnswer((_) async => _streamedResponse(sseBody));

        final chunks = await client.sendStreamingChatRequest([
          {'role': 'user', 'content': 'Run both tools'},
        ], null).toList();

        final finalChunk = chunks.last;
        final toolCalls =
            finalChunk['choices'][0]['delta']['tool_calls'] as List?;
        expect(toolCalls, isNotNull);
        expect(toolCalls!.length, 2);

        final names = toolCalls.map((t) => t['function']['name']).toSet();
        expect(names, containsAll(['tool_a', 'tool_b']));
      });

      test('stop_reason end_turn maps correctly in final chunk', () async {
        final sseBody = _buildSseStream([
          'event: message_start',
          'data: {"type":"message_start","message":{"usage":{"input_tokens":5,"output_tokens":0}}}',
          '',
          'event: content_block_delta',
          'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Done."}}',
          '',
          'event: message_delta',
          'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":1}}',
          '',
          'event: message_stop',
          'data: {"type":"message_stop"}',
        ]);

        when(
          mockHttpClient.send(any),
        ).thenAnswer((_) async => _streamedResponse(sseBody));

        final chunks = await client.sendStreamingChatRequest([
          {'role': 'user', 'content': 'Done?'},
        ], null).toList();

        final finalChunk = chunks.last;
        expect(finalChunk['choices'][0]['finish_reason'], 'end_turn');
      });

      test(
        'throws VanturaApiException on non-200 streaming response',
        () async {
          when(mockHttpClient.send(any)).thenAnswer(
            (_) async => _streamedResponse('{"error":"auth"}', statusCode: 401),
          );

          await expectLater(
            client.sendStreamingChatRequest([
              {'role': 'user', 'content': 'hi'},
            ], null),
            emitsError(isA<VanturaApiException>()),
          );
        },
      );

      test('aborts stream when CancellationToken is cancelled', () async {
        final token = CancellationToken()..cancel();

        await expectLater(
          client.sendStreamingChatRequest(
            [
              {'role': 'user', 'content': 'hi'},
            ],
            null,
            cancellationToken: token,
          ),
          emitsError(isA<VanturaCancellationException>()),
        );

        verifyNever(mockHttpClient.send(any));
      });

      test('handles malformed JSON in SSE data lines gracefully', () async {
        final sseBody = _buildSseStream([
          'event: message_start',
          'data: {"type":"message_start","message":{"usage":{"input_tokens":3,"output_tokens":0}}}',
          '',
          'event: content_block_delta',
          'data: NOT_VALID_JSON',
          '',
          'event: content_block_delta',
          'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"OK"}}',
          '',
          'event: message_delta',
          'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":1}}',
          '',
          'event: message_stop',
          'data: {"type":"message_stop"}',
        ]);

        when(
          mockHttpClient.send(any),
        ).thenAnswer((_) async => _streamedResponse(sseBody));

        // Should NOT throw — malformed lines are skipped
        final chunks = await client.sendStreamingChatRequest([
          {'role': 'user', 'content': 'test'},
        ], null).toList();

        expect(chunks, isNotEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // close
    // -------------------------------------------------------------------------
    group('close', () {
      test('delegates close() to the underlying http.Client', () {
        client.close();
        verify(mockHttpClient.close()).called(1);
      });
    });

    // -------------------------------------------------------------------------
    // Constructor / configuration
    // -------------------------------------------------------------------------
    group('configuration', () {
      test('uses default model when none is specified', () {
        final c = AnthropicClient(apiKey: 'key', httpClient: mockHttpClient);
        expect(c.model, isNotEmpty);
      });

      test('accepts a custom baseUrl', () {
        final c = AnthropicClient(
          apiKey: 'key',
          baseUrl: 'https://my-proxy.example.com/v1/messages',
          httpClient: mockHttpClient,
        );
        expect(c.baseUrl, 'https://my-proxy.example.com/v1/messages');
      });

      test('accepts a custom apiVersion', () {
        final c = AnthropicClient(
          apiKey: 'key',
          apiVersion: '2024-01-01',
          httpClient: mockHttpClient,
        );
        expect(c.apiVersion, '2024-01-01');
      });
    });
  });
}
