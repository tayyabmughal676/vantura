import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:vantura/core/index.dart';

import '../mocks/mocks.mocks.dart';

void main() {
  group('VanturaMemory', () {
    late MockVanturaClient mockClient;
    late MockVanturaLogger mockLogger;
    late MockVanturaPersistence mockPersistence;
    late VanturaMemory memory;

    setUp(() {
      mockClient = MockVanturaClient();
      mockLogger = MockVanturaLogger();
      mockPersistence = MockVanturaPersistence();

      // Stub the logger options to return sensible defaults
      when(mockLogger.options).thenReturn(const VanturaLoggerOptions());

      memory = VanturaMemory(
        mockLogger,
        mockClient,
        shortLimit: 3,
        longLimit: 2,
      );
    });

    group('constructor', () {
      test('defaults shortLimit to 10 and longLimit to 5', () {
        final mem = VanturaMemory(mockLogger, mockClient);
        expect(mem.shortLimit, 10);
        expect(mem.longLimit, 5);
      });

      test('accepts custom shortLimit and longLimit', () {
        expect(memory.shortLimit, 3);
        expect(memory.longLimit, 2);
      });
    });

    group('addMessage', () {
      test('adds a user message to short-term memory', () async {
        await memory.addMessage('user', 'Hello');
        final messages = memory.getMessages();
        expect(messages.length, 1);
        expect(messages.first['role'], 'user');
        expect(messages.first['content'], 'Hello');
      });

      test('adds a message with null content when content is empty', () async {
        await memory.addMessage(
          'assistant',
          '',
          toolCalls: [
            {
              'id': 'tc_1',
              'function': {'name': 'calc', 'arguments': '{}'},
            },
          ],
        );
        final messages = memory.getMessages();
        expect(messages.length, 1);
        expect(messages.first['content'], isNull);
        expect(messages.first['tool_calls'], isNotNull);
      });

      test('adds a tool result with toolCallId', () async {
        await memory.addMessage('tool', 'Result: 42', toolCallId: 'tc_1');
        final messages = memory.getMessages();
        expect(messages.length, 1);
        expect(messages.first['role'], 'tool');
        expect(messages.first['tool_call_id'], 'tc_1');
      });

      test('ignores invalid messages (empty role, no toolCalls)', () async {
        await memory.addMessage('', 'should be ignored');
        final messages = memory.getMessages();
        expect(messages, isEmpty);
      });
    });

    group('getMessages', () {
      test(
        'returns messages in order: long-term first, then short-term',
        () async {
          // Add 3 messages within limit first
          await memory.addMessage('user', 'msg1');
          await memory.addMessage('assistant', 'reply1');

          final messages = memory.getMessages();
          expect(messages.length, 2);
          expect(messages[0]['content'], 'msg1');
          expect(messages[1]['content'], 'reply1');
        },
      );
    });

    group('short-to-long memory summarization', () {
      test('triggers summarization when short-term exceeds limit', () async {
        // Stub the client to return a summary
        when(mockClient.sendChatRequest(any, any)).thenAnswer(
          (_) async => {
            'choices': [
              {
                'message': {
                  'role': 'assistant',
                  'content': 'Summary of conversation',
                },
              },
            ],
          },
        );

        // Add messages up to and exceeding shortLimit (3)
        await memory.addMessage('user', 'msg1');
        await memory.addMessage('assistant', 'reply1');
        await memory.addMessage('user', 'msg2');
        // This 4th message should trigger summarization (exceeds limit of 3)
        await memory.addMessage('assistant', 'reply2');

        // After summarization, short memory should be empty and
        // we should have a long-term summary entry
        final messages = memory.getMessages();
        // Long-term has the summary, short-term was cleared
        expect(
          messages.any(
            (m) =>
                m['content']?.toString().contains('Historical context:') ??
                false,
          ),
          isTrue,
        );
      });

      test('uses fallback summary when summarization API fails', () async {
        when(
          mockClient.sendChatRequest(any, any),
        ).thenThrow(Exception('API error'));

        await memory.addMessage('user', 'msg1');
        await memory.addMessage('assistant', 'reply1');
        await memory.addMessage('user', 'msg2');
        await memory.addMessage('assistant', 'reply2');

        final messages = memory.getMessages();
        expect(
          messages.any(
            (m) =>
                m['content']?.toString().contains(
                  'Previous conversation context:',
                ) ??
                false,
          ),
          isTrue,
        );
      });
    });

    group('clear', () {
      test('clears all short and long memory', () async {
        await memory.addMessage('user', 'hello');
        expect(memory.getMessages(), isNotEmpty);

        memory.clear();
        expect(memory.getMessages(), isEmpty);
      });
    });

    group('persistence integration', () {
      late VanturaMemory memoryWithPersistence;

      setUp(() {
        memoryWithPersistence = VanturaMemory(
          mockLogger,
          mockClient,
          shortLimit: 3,
          longLimit: 2,
          persistence: mockPersistence,
        );
      });

      test('init loads messages from persistence', () async {
        when(mockPersistence.loadMessages()).thenAnswer(
          (_) async => [
            {'role': 'user', 'content': 'old msg'},
            {'role': 'assistant', 'content': 'old reply'},
          ],
        );

        await memoryWithPersistence.init();
        final messages = memoryWithPersistence.getMessages();
        expect(messages.length, 2);
      });

      test('init loads summary messages into long-term', () async {
        when(mockPersistence.loadMessages()).thenAnswer(
          (_) async => [
            {
              'role': 'system',
              'content': 'Historical context: ...',
              'isSummary': true,
            },
          ],
        );

        await memoryWithPersistence.init();
        final messages = memoryWithPersistence.getMessages();
        expect(messages.length, 1);
        expect(messages.first['role'], 'system');
      });

      test('init handles persistence errors gracefully', () async {
        when(mockPersistence.loadMessages()).thenThrow(Exception('disk error'));

        // Should not throw
        await memoryWithPersistence.init();
        expect(memoryWithPersistence.getMessages(), isEmpty);
      });

      test('addMessage saves to persistence', () async {
        when(
          mockPersistence.saveMessage(
            any,
            any,
            toolCalls: anyNamed('toolCalls'),
            toolCallId: anyNamed('toolCallId'),
          ),
        ).thenAnswer((_) async {});

        await memoryWithPersistence.addMessage('user', 'hello');

        verify(
          mockPersistence.saveMessage(
            'user',
            'hello',
            toolCalls: null,
            toolCallId: null,
          ),
        ).called(1);
      });

      test('clear calls persistence clearMessages', () {
        when(mockPersistence.clearMessages()).thenAnswer((_) async {});
        memoryWithPersistence.clear();
        verify(mockPersistence.clearMessages()).called(1);
      });
    });
  });
}
