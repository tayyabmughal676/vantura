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

String _geminiResponse({
  String text = 'Hello from Gemini!',
  String finishReason = 'STOP',
  int promptTokens = 10,
  int completionTokens = 5,
  List<Map<String, dynamic>>? functionCalls,
}) {
  return jsonEncode({
    'candidates': [
      {
        'content': {
          'role': 'model',
          'parts': [
            if (text.isNotEmpty) {'text': text},
            if (functionCalls != null)
              ...functionCalls.map((fc) => {'functionCall': fc}),
          ],
        },
        'finishReason': finishReason,
      },
    ],
    'usageMetadata': {
      'promptTokenCount': promptTokens,
      'candidatesTokenCount': completionTokens,
      'totalTokenCount': promptTokens + completionTokens,
    },
  });
}

http.StreamedResponse _streamedResponse(String body, {int statusCode = 200}) {
  return http.StreamedResponse(
    Stream.fromIterable([utf8.encode(body)]),
    statusCode,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('GeminiClient', () {
    late MockClient mockHttpClient;
    late GeminiClient client;

    setUp(() {
      mockHttpClient = MockClient();
      client = GeminiClient(
        apiKey: 'test-gemini-key',
        model: 'gemini-1.5-pro-latest',
        httpClient: mockHttpClient,
      );
    });

    group('sendChatRequest', () {
      test('sends successful request and returns formatted data', () async {
        when(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).thenAnswer((_) async => http.Response(_geminiResponse(), 200));

        final result = await client.sendChatRequest([
          {'role': 'user', 'content': 'hi'},
        ], null);

        expect(
          result['choices'][0]['message']['content'],
          'Hello from Gemini!',
        );
        expect(result['usage']['total_tokens'], 15);
      });

      test('extracts system instructions correctly', () async {
        String? capturedBody;
        when(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).thenAnswer((inv) async {
          capturedBody = inv.namedArguments[const Symbol('body')];
          return http.Response(_geminiResponse(), 200);
        });

        await client.sendChatRequest([
          {'role': 'system', 'content': 'Be a cat.'},
          {'role': 'user', 'content': 'Meow?'},
        ], null);

        final body = jsonDecode(capturedBody!);
        expect(body['systemInstruction']['parts'][0]['text'], 'Be a cat.');
        expect(body['contents'][0]['role'], 'user');
        expect(body['contents'].length, 1);
      });

      test('handles function calls (tools) in response', () async {
        final toolResponse = _geminiResponse(
          text: '',
          finishReason: 'STOP',
          functionCalls: [
            {
              'name': 'get_time',
              'args': {'zone': 'UTC'},
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
        ).thenAnswer((_) async => http.Response(toolResponse, 200));

        final result = await client.sendChatRequest([
          {'role': 'user', 'content': 'Time?'},
        ], null);

        final toolCalls = result['choices'][0]['message']['tool_calls'] as List;
        expect(toolCalls[0]['function']['name'], 'get_time');
        expect(
          jsonDecode(toolCalls[0]['function']['arguments'])['zone'],
          'UTC',
        );
        expect(result['choices'][0]['finish_reason'], 'tool_calls');
      });

      test(
        'converts OpenAI tool results back to Gemini functionResponse',
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
            capturedBody = inv.namedArguments[const Symbol('body')];
            return http.Response(_geminiResponse(), 200);
          });

          await client.sendChatRequest([
            {'role': 'tool', 'tool_call_id': 'get_time', 'content': '12:00 PM'},
          ], null);

          final body = jsonDecode(capturedBody!);
          final parts = body['contents'][0]['parts'] as List;
          expect(parts[0]['functionResponse']['name'], 'get_time');
          expect(
            parts[0]['functionResponse']['response']['result'],
            '12:00 PM',
          );
        },
      );

      test('throws VanturaApiException on error', () async {
        when(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).thenAnswer((_) async => http.Response('{"error": "bad"}', 400));

        await expectLater(
          client.sendChatRequest([
            {'role': 'user', 'content': 'hi'},
          ], null),
          throwsA(isA<VanturaApiException>()),
        );
      });
    });

    group('sendStreamingChatRequest', () {
      test('streams text chunks correctly', () async {
        final sseData =
            'data: ' +
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'Hello '},
                    ],
                  },
                },
              ],
            }) +
            '\n\ndata: ' +
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'world!'},
                    ],
                  },
                },
              ],
            }) +
            '\n\ndata: ' +
            jsonEncode({
              'usageMetadata': {'totalTokenCount': 10},
            });

        when(
          mockHttpClient.send(any),
        ).thenAnswer((_) async => _streamedResponse(sseData));

        final stream = client.sendStreamingChatRequest([
          {'role': 'user', 'content': 'hi'},
        ], null);
        final list = await stream.toList();

        expect(list[0]['choices'][0]['delta']['content'], 'Hello ');
        expect(list[1]['choices'][0]['delta']['content'], 'world!');
        expect(list[2]['usage']['total_tokens'], 10);
      });

      test('handles tool calls in stream', () async {
        final sseData =
            'data: ' +
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {
                        'functionCall': {
                          'name': 'test_tool',
                          'args': {'a': 1},
                        },
                      },
                    ],
                  },
                },
              ],
            });

        when(
          mockHttpClient.send(any),
        ).thenAnswer((_) async => _streamedResponse(sseData));

        final list = await client.sendStreamingChatRequest([
          {'role': 'user', 'content': 'hi'},
        ], null).toList();

        final toolCalls = list[0]['choices'][0]['delta']['tool_calls'] as List;
        expect(toolCalls[0]['function']['name'], 'test_tool');
        expect(list[0]['choices'][0]['finish_reason'], 'tool_calls');
      });
    });
  });
}
