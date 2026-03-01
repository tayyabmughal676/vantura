import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:vantura/core/index.dart';

import '../mocks/mocks.mocks.dart';

/// A simple concrete tool for testing.
class _EchoTool extends VanturaTool<Map<String, dynamic>> {
  @override
  String get name => 'echo';

  @override
  String get description => 'Echoes the input';

  @override
  Map<String, dynamic> get parameters => SchemaHelper.generateSchema({
    'text': SchemaHelper.stringProperty(description: 'Text to echo'),
  });

  @override
  Map<String, dynamic> parseArgs(Map<String, dynamic> json) => json;

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    return 'Echo: ${args['text']}';
  }
}

/// A tool that always throws for error-path testing.
class _FailingTool extends VanturaTool<Map<String, dynamic>> {
  @override
  String get name => 'failing_tool';

  @override
  String get description => 'Always fails';

  @override
  Map<String, dynamic> get parameters => SchemaHelper.emptySchema;

  @override
  Map<String, dynamic> parseArgs(Map<String, dynamic> json) => json;

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    throw Exception('Tool intentionally failed');
  }
}

void main() {
  group('VanturaAgent', () {
    late MockVanturaClient mockClient;
    late MockVanturaMemory mockMemory;
    late VanturaState state;

    Map<String, dynamic> _textResponse(String text) {
      return {
        'choices': [
          {
            'message': {'role': 'assistant', 'content': text},
            'finish_reason': 'stop',
          },
        ],
        'usage': {
          'prompt_tokens': 10,
          'completion_tokens': 5,
          'total_tokens': 15,
        },
      };
    }

    Map<String, dynamic> _toolCallResponse(
      String toolName,
      Map<String, dynamic> args, {
      String callId = 'call_1',
    }) {
      return {
        'choices': [
          {
            'message': {
              'role': 'assistant',
              'content': null,
              'tool_calls': [
                {
                  'id': callId,
                  'type': 'function',
                  'function': {'name': toolName, 'arguments': jsonEncode(args)},
                },
              ],
            },
            'finish_reason': 'tool_calls',
          },
        ],
        'usage': {
          'prompt_tokens': 15,
          'completion_tokens': 10,
          'total_tokens': 25,
        },
      };
    }

    setUp(() {
      mockClient = MockVanturaClient();
      mockMemory = MockVanturaMemory();
      when(mockMemory.persistence).thenReturn(null);
      state = VanturaState();

      // Default stubs
      when(mockMemory.getMessages()).thenReturn([]);
      when(
        mockMemory.addMessage(
          any,
          any,
          toolCalls: anyNamed('toolCalls'),
          toolCallId: anyNamed('toolCallId'),
        ),
      ).thenAnswer((_) async {});
    });

    VanturaAgent _createAgent({List<VanturaTool>? tools}) {
      return VanturaAgent(
        instructions: 'You are a test assistant.',
        memory: mockMemory,
        tools: tools ?? [],
        client: mockClient,
        state: state,
        name: 'test_agent',
        description: 'A test agent',
      );
    }

    group('run() — text responses', () {
      test('returns text from a simple text response', () async {
        when(
          mockClient.sendChatRequest(
            any,
            any,
            cancellationToken: anyNamed('cancellationToken'),
          ),
        ).thenAnswer((_) async => _textResponse('Hello, world!'));

        final agent = _createAgent();
        final response = await agent.run('Say hello');

        expect(response.text, 'Hello, world!');
        expect(response.usage, isNotNull);
        expect(response.usage!.totalTokens, 15);
        expect(response.finishReason, 'stop');
      });

      test('adds user prompt and assistant reply to memory', () async {
        when(
          mockClient.sendChatRequest(
            any,
            any,
            cancellationToken: anyNamed('cancellationToken'),
          ),
        ).thenAnswer((_) async => _textResponse('Reply'));

        final agent = _createAgent();
        await agent.run('Hello');

        // user message
        verify(mockMemory.addMessage('user', 'Hello')).called(1);
        // assistant reply
        verify(mockMemory.addMessage('assistant', 'Reply')).called(1);
      });

      test('state transitions through start → update → complete', () async {
        when(
          mockClient.sendChatRequest(
            any,
            any,
            cancellationToken: anyNamed('cancellationToken'),
          ),
        ).thenAnswer((_) async => _textResponse('Done'));

        final agent = _createAgent();
        await agent.run('go');

        // After completion, state should be done
        expect(state.isRunning, isFalse);
        expect(state.currentStep, 'Run completed');
      });
    });

    group('run() — tool calls', () {
      test('executes a tool and re-calls the API with the result', () async {
        final echoTool = _EchoTool();
        int callCount = 0;

        when(
          mockClient.sendChatRequest(
            any,
            any,
            cancellationToken: anyNamed('cancellationToken'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            return _toolCallResponse('echo', {'text': 'ping'});
          }
          return _textResponse('Tool completed: Echo: ping');
        });

        final agent = _createAgent(tools: [echoTool]);
        final response = await agent.run('Echo something');

        expect(response.text, 'Tool completed: Echo: ping');
        expect(response.toolCalls, isNotEmpty);
      });

      test(
        'verifies complex ReAct loop with sequential tool dependencies',
        () async {
          final echoTool = _EchoTool();
          int callCount = 0;

          // Sequence: 1. call echo(ping) -> 2. call echo(pong) -> 3. final text
          when(
            mockClient.sendChatRequest(
              captureAny,
              any,
              cancellationToken: anyNamed('cancellationToken'),
            ),
          ).thenAnswer((_) async {
            callCount++;
            if (callCount == 1) {
              return _toolCallResponse('echo', {'text': 'ping'}, callId: 'c1');
            } else if (callCount == 2) {
              return _toolCallResponse('echo', {'text': 'pong'}, callId: 'c2');
            }
            return _textResponse('Final Answer');
          });

          final agent = _createAgent(tools: [echoTool]);
          final response = await agent.run('start loop');

          expect(response.text, 'Final Answer');
          expect(callCount, 3);

          // Verify memory history growth
          // 1 (user) + 1 (tool call 1) + 1 (tool result 1) + 1 (tool call 2) + 1 (tool result 2) + 1 (assistant final) = 6
          verify(
            mockMemory.addMessage(
              any,
              any,
              toolCalls: anyNamed('toolCalls'),
              toolCallId: anyNamed('toolCallId'),
            ),
          ).called(6);
        },
      );

      test('handles tool execution errors gracefully', () async {
        final failingTool = _FailingTool();
        int callCount = 0;
        String? capturedToolError;

        when(
          mockClient.sendChatRequest(
            any,
            any,
            cancellationToken: anyNamed('cancellationToken'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            return _toolCallResponse('failing_tool', {});
          }
          return _textResponse('I encountered an error.');
        });

        final agent = VanturaAgent(
          instructions: 'test',
          memory: mockMemory,
          tools: [failingTool],
          client: mockClient,
          state: state,
          onToolError: (name, error, stackTrace) {
            capturedToolError = '$name: $error';
          },
        );

        final response = await agent.run('do something');
        expect(response.text, 'I encountered an error.');
        expect(capturedToolError, isNotNull);
        expect(capturedToolError, contains('failing_tool'));
      });
    });

    group('run() — cancellation', () {
      test(
        'returns cancelled response when token is already cancelled',
        () async {
          final token = CancellationToken()..cancel();

          final agent = _createAgent();
          expect(
            () => agent.run('hi', cancellationToken: token),
            throwsA(isA<VanturaCancellationException>()),
          );
        },
      );
    });

    group('run() — max iterations', () {
      test('stops after maximum iterations (10)', () async {
        // Always return tool calls to force infinite loop
        when(
          mockClient.sendChatRequest(
            any,
            any,
            cancellationToken: anyNamed('cancellationToken'),
          ),
        ).thenAnswer((_) async => _toolCallResponse('echo', {'text': 'loop'}));

        final agent = _createAgent(tools: [_EchoTool()]);
        expect(
          () => agent.run('loop forever'),
          throwsA(isA<VanturaIterationException>()),
        );
      });
    });

    group('run() — guardrails', () {
      test('system instructions include SDK_DIRECTIVE guardrail', () async {
        when(
          mockClient.sendChatRequest(
            any,
            any,
            cancellationToken: anyNamed('cancellationToken'),
          ),
        ).thenAnswer((_) async => _textResponse('ok'));

        final agent = _createAgent();
        await agent.run('test');

        final captured = verify(
          mockClient.sendChatRequest(
            captureAny,
            any,
            cancellationToken: anyNamed('cancellationToken'),
          ),
        ).captured;

        final messages = captured.first as List<Map<String, dynamic>>;
        final systemMsg = messages.first['content'] as String;
        expect(systemMsg, contains('[SDK_DIRECTIVE]'));
        expect(systemMsg, contains('You are a test assistant.'));
      });
    });

    group('addTool', () {
      test('adds a new tool dynamically', () {
        final agent = _createAgent();
        expect(agent.tools, isEmpty);

        agent.addTool(_EchoTool());
        expect(agent.tools.length, 1);
        expect(agent.tools.first.name, 'echo');
      });

      test('does not add duplicate tools', () {
        final agent = _createAgent();
        agent.addTool(_EchoTool());
        agent.addTool(_EchoTool());
        expect(agent.tools.length, 1);
      });
    });

    group('TokenUsage', () {
      test('fields are correct', () {
        const usage = TokenUsage(
          promptTokens: 10,
          completionTokens: 5,
          totalTokens: 15,
        );
        expect(usage.promptTokens, 10);
        expect(usage.completionTokens, 5);
        expect(usage.totalTokens, 15);
      });

      test('addition operator works', () {
        const a = TokenUsage(
          promptTokens: 10,
          completionTokens: 5,
          totalTokens: 15,
        );
        const b = TokenUsage(
          promptTokens: 20,
          completionTokens: 10,
          totalTokens: 30,
        );
        final sum = a + b;
        expect(sum.promptTokens, 30);
        expect(sum.completionTokens, 15);
        expect(sum.totalTokens, 45);
      });
    });

    group('VanturaResponse', () {
      test('can be created with all fields', () {
        final response = VanturaResponse(
          text: 'hello',
          toolCalls: [
            {'id': '1'},
          ],
          textChunk: 'hel',
          usage: const TokenUsage(
            promptTokens: 1,
            completionTokens: 1,
            totalTokens: 2,
          ),
          finishReason: 'stop',
        );
        expect(response.text, 'hello');
        expect(response.toolCalls, isNotNull);
        expect(response.textChunk, 'hel');
        expect(response.usage, isNotNull);
        expect(response.finishReason, 'stop');
      });

      test('fields default to null', () {
        final response = VanturaResponse();
        expect(response.text, isNull);
        expect(response.toolCalls, isNull);
        expect(response.textChunk, isNull);
        expect(response.usage, isNull);
        expect(response.finishReason, isNull);
      });
    });
  });
}
