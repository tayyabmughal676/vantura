import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:vantura/core/index.dart';

import '../mocks/mocks.mocks.dart';

void main() {
  group('VanturaClient', () {
    late MockClient mockHttpClient;
    late VanturaClient vanturaClient;

    setUp(() {
      mockHttpClient = MockClient();
      vanturaClient = VanturaClient(
        apiKey: 'test_key',
        baseUrl: 'https://api.test.com/v1/chat/completions',
        model: 'test-model',
        httpClient: mockHttpClient,
      );
    });

    test('sendChatRequest sends successful request and returns data', () async {
      // Arrange
      final expectedResponse = {
        'id': 'chatcmpl-123',
        'choices': [
          {
            'message': {'role': 'assistant', 'content': 'Hello, world!'},
          },
        ],
        'usage': {
          'prompt_tokens': 10,
          'completion_tokens': 5,
          'total_tokens': 15,
        },
      };

      when(
        mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
          encoding: anyNamed('encoding'),
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode(expectedResponse), 200),
      );

      // Act
      final messages = [
        {'role': 'user', 'content': 'Say hello'},
      ];
      final response = await vanturaClient.sendChatRequest(messages, null);

      // Assert
      expect(response['choices'][0]['message']['content'], 'Hello, world!');
      expect(response['usage']['total_tokens'], 15);

      verify(
        mockHttpClient.post(
          Uri.parse('https://api.test.com/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer test_key',
          },
          body: argThat(contains('Say hello')),
        ),
      ).called(1);
    });

    test(
      'sendChatRequest retries on 429 Rate Limit',
      () async {
        // Arrange
        // First call returns 429
        when(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            'Rate limit exceeded',
            429,
            headers: {'retry-after': '1'},
          ),
        );

        // Wait for 429 to be triggered
        // Note: testing actual retry logic cleanly usually involves faking time or accepting the small delay. We'll let it delay for 1 second.
        // But since we want to check it throws after max retries:

        // Act & Assert
        await expectLater(
          vanturaClient.sendChatRequest([
            {'role': 'user', 'content': 'hi'},
          ], null),
          throwsException, // Will retry 3 times and then throw
        );
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    test(
      'sendChatRequest aborts immediately if cancellationToken is active',
      () async {
        // Arrange
        final token = CancellationToken()..cancel();

        // Act & Assert
        await expectLater(
          vanturaClient.sendChatRequest(
            [
              {'role': 'user', 'content': 'hi'},
            ],
            null,
            cancellationToken: token,
          ),
          throwsA(
            predicate(
              (e) => e.toString().contains('Request cancelled by user'),
            ),
          ),
        );

        verifyNever(
          mockHttpClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        );
      },
    );
  });
}
