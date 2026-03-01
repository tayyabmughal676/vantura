import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:vantura/core/index.dart';

import '../mocks/mocks.mocks.dart';

void main() {
  group('VanturaClient — extended coverage', () {
    late MockClient mockHttpClient;
    late VanturaClient vanturaClient;

    Map<String, dynamic> _successResponse({
      String content = 'Hello!',
      int promptTokens = 10,
      int completionTokens = 5,
    }) {
      return {
        'id': 'chatcmpl-test',
        'choices': [
          {
            'message': {'role': 'assistant', 'content': content},
            'finish_reason': 'stop',
          },
        ],
        'usage': {
          'prompt_tokens': promptTokens,
          'completion_tokens': completionTokens,
          'total_tokens': promptTokens + completionTokens,
        },
        'model': 'test-model',
      };
    }

    setUp(() {
      mockHttpClient = MockClient();
      vanturaClient = VanturaClient(
        apiKey: 'test_key',
        baseUrl: 'https://api.test.com/v1/chat/completions',
        model: 'test-model',
        httpClient: mockHttpClient,
      );
    });

    group('sendChatRequest', () {
      test('sends correct headers including Authorization', () async {
        when(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).thenAnswer(
          (_) async => http.Response(jsonEncode(_successResponse()), 200),
        );

        await vanturaClient.sendChatRequest([
          {'role': 'user', 'content': 'hi'},
        ], null);

        final captured = verify(
          mockHttpClient.post(
            any,
            headers: captureAnyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).captured;

        final headers = captured.first as Map<String, String>;
        expect(headers['Authorization'], 'Bearer test_key');
        expect(headers['Content-Type'], 'application/json');
      });

      test('includes model in request body', () async {
        when(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).thenAnswer(
          (_) async => http.Response(jsonEncode(_successResponse()), 200),
        );

        await vanturaClient.sendChatRequest([
          {'role': 'user', 'content': 'test'},
        ], null);

        final captured = verify(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: captureAnyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).captured;

        final body = jsonDecode(captured.first as String);
        expect(body['model'], 'test-model');
      });

      test('includes tools in request body when provided', () async {
        when(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).thenAnswer(
          (_) async => http.Response(jsonEncode(_successResponse()), 200),
        );

        final tools = [
          {
            'type': 'function',
            'function': {
              'name': 'calculator',
              'description': 'Calculates',
              'parameters': {},
            },
          },
        ];

        await vanturaClient.sendChatRequest([
          {'role': 'user', 'content': 'calc 1+1'},
        ], tools);

        final captured = verify(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: captureAnyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).captured;

        final body = jsonDecode(captured.first as String);
        expect(body['tools'], isNotNull);
        expect(body['tool_choice'], 'auto');
      });

      test('includes optional parameters when provided', () async {
        final client = VanturaClient(
          apiKey: 'key',
          baseUrl: 'https://api.test.com/v1/chat/completions',
          model: 'test',
          temperature: 0.7,
          maxCompletionTokens: 100,
          topP: 0.9,
          httpClient: mockHttpClient,
        );

        when(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).thenAnswer(
          (_) async => http.Response(jsonEncode(_successResponse()), 200),
        );

        await client.sendChatRequest([
          {'role': 'user', 'content': 'hi'},
        ], null);

        final captured = verify(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: captureAnyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).captured;

        final body = jsonDecode(captured.first as String);
        expect(body['temperature'], 0.7);
        expect(body['max_completion_tokens'], 100);
        expect(body['top_p'], 0.9);
      });

      test('throws on non-200/429 status codes', () async {
        when(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).thenAnswer((_) async => http.Response('Internal Server Error', 500));

        await expectLater(
          vanturaClient.sendChatRequest([
            {'role': 'user', 'content': 'hi'},
          ], null),
          throwsException,
        );
      });

      test('retries on ClientException and eventually rethrows', () async {
        when(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).thenThrow(http.ClientException('Connection lost'));

        await expectLater(
          vanturaClient.sendChatRequest([
            {'role': 'user', 'content': 'hi'},
          ], null),
          throwsA(isA<http.ClientException>()),
        );

        // Should have attempted 3 times
        verify(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).called(3);
      });

      test('per-request parameters override client defaults', () async {
        final client = VanturaClient(
          apiKey: 'key',
          baseUrl: 'https://api.test.com/v1/chat/completions',
          model: 'test',
          temperature: 0.5,
          httpClient: mockHttpClient,
        );

        when(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).thenAnswer(
          (_) async => http.Response(jsonEncode(_successResponse()), 200),
        );

        await client.sendChatRequest(
          [
            {'role': 'user', 'content': 'hi'},
          ],
          null,
          temperature: 0.9,
        );

        final captured = verify(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: captureAnyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).captured;

        final body = jsonDecode(captured.first as String);
        expect(body['temperature'], 0.9);
      });
    });
  });
}
