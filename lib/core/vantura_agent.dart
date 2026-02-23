import 'dart:async';
import 'dart:convert';
import 'index.dart';
import 'logger.dart';

/// Tracks token usage out of a completed generation or run.
class TokenUsage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  const TokenUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  /// Combines two token usages if tracking accumulated totals.
  TokenUsage operator +(TokenUsage other) {
    return TokenUsage(
      promptTokens: promptTokens + other.promptTokens,
      completionTokens: completionTokens + other.completionTokens,
      totalTokens: totalTokens + other.totalTokens,
    );
  }
}

class VanturaResponse {
  /// Final text response from the agent (optional).
  final String? text;

  /// Tool call information, if the agent requested a tool.
  final List<Map<String, dynamic>>? toolCalls;

  /// A single text chunk for streaming.
  final String? textChunk;

  /// Token usage statistics for billing and observability.
  final TokenUsage? usage;

  /// Creates a VanturaResponse.
  VanturaResponse({this.text, this.toolCalls, this.textChunk, this.usage});
}

/// Agent that interacts with the Vantura API and uses tools.
///
/// Manages conversation memory, executes tool calls, and handles API responses.
class VanturaAgent {
  /// System instructions for the agent.
  final String instructions;

  /// Memory storage for conversation history.
  final VanturaMemory memory;

  /// List of available tools.
  final List<VanturaTool> tools;

  /// Client for API communication.
  final VanturaClient client;

  /// State manager for UI synchronization.
  final VanturaState state;

  /// Internal name for identifying this agent in multi-agent routing.
  final String name;

  /// Clear description of what this agent does, for routing decisions.
  final String description;

  /// Callback when a tool execution fails.
  final void Function(String toolName, String error, StackTrace? stackTrace)? onToolError;

  /// Callback when the overall agent execution fails.
  final void Function(String error, StackTrace? stackTrace)? onAgentFailure;

  /// Callback for non-fatal warnings during execution.
  final void Function(String warning)? onWarning;

  /// Creates an VanturaAgent with the specified components.
  VanturaAgent({
    required this.instructions,
    required this.memory,
    required this.tools,
    required this.client,
    required this.state,
    this.name = 'default_agent',
    this.description = 'General assistant agent',
    this.onToolError,
    this.onAgentFailure,
    this.onWarning,
  });

  /// Adds a tool dynamically at runtime (e.g. injected by AgentCoordinator).
  void addTool(VanturaTool tool) {
    if (!tools.any((t) => t.name == tool.name)) {
      tools.add(tool);
    }
  }

  /// Runs the agent with the given prompt and streams the response.
  /// You can optionally pass a [cancellationToken] to stop the generation early.
  Stream<VanturaResponse> runStreaming(
    String prompt, {
    CancellationToken? cancellationToken,
  }) async* {
    state.startRun();

    sdkLogger.info(
      'Starting VanturaAgent run (streaming)',
      tag: 'AGENT',
      extra: {
        'prompt_length': prompt.length,
        'tool_count': tools.length,
        'memory_messages': memory.getMessages().length,
      },
    );

    await memory.addMessage('user', prompt);

    List<Map<String, dynamic>> messages = [
      {'role': 'system', 'content': instructions},
    ];

    messages.addAll(memory.getMessages());

    List<Map<String, dynamic>> toolsDef = tools
        .map(
          (t) => {
            'type': 'function',
            'function': {
              'name': t.name,
              'description': t.description,
              'parameters': t.parameters,
            },
          },
        )
        .toList();

    const int maxIterations = 10;
    int iterationCount = 0;

    final List<Map<String, dynamic>> executedToolCalls = [];

    while (true) {
      iterationCount++;
      if (iterationCount > maxIterations) {
        sdkLogger.error(
          'Agent exceeded maximum iterations ($maxIterations)',
          tag: 'AGENT',
          extra: {'iteration_count': iterationCount},
        );
        state.failRun('Maximum reasoning iterations exceeded');
        yield VanturaResponse(text: 'Error: Agent exceeded maximum iterations');
        return;
      }

      if (cancellationToken?.isCancelled == true) {
        state.failRun('Cancelled by user');
        yield VanturaResponse(text: '\n[Generation Cancelled]');
        return;
      }

      state.updateStep('Sending streaming API request...');

      final responseStream = client.sendStreamingChatRequest(
        messages,
        toolsDef.isEmpty ? null : toolsDef,
        cancellationToken: cancellationToken,
      );

      StringBuffer contentBuffer = StringBuffer();
      TokenUsage? runUsage;
      Map<int, Map<String, dynamic>> toolCallsDelta = {};
      bool hasContent = false;

      try {
        await for (final chunk in responseStream) {
          final choices = chunk['choices'] as List;
          if (choices.isEmpty) continue;
          final delta = choices[0]['delta'] as Map<String, dynamic>;

          if (delta['content'] != null) {
            hasContent = true;
            final content = delta['content'] as String;
            contentBuffer.write(content);
            yield VanturaResponse(textChunk: content);
          }

          // Handle usage stats, if any (often sent in last chunk)
          final usageData = chunk['usage'] ?? chunk['x_groq']?['usage'];
          if (usageData != null) {
            runUsage = TokenUsage(
              promptTokens: usageData['prompt_tokens'] ?? 0,
              completionTokens: usageData['completion_tokens'] ?? 0,
              totalTokens: usageData['total_tokens'] ?? 0,
            );
          }

          // Handle tool calls delta
          if (delta['tool_calls'] != null) {
            final calls = delta['tool_calls'] as List;
            for (var call in calls) {
              final index = (call['index'] as num).toInt();
              if (!toolCallsDelta.containsKey(index)) {
                toolCallsDelta[index] = {
                  'id': call['id'],
                  'type': 'function',
                  'function': {
                    'name': call['function']?['name'] ?? '',
                    'arguments': call['function']?['arguments'] ?? '',
                  },
                };
              } else {
                final existing = toolCallsDelta[index]!;
                if (call['function']?['arguments'] != null) {
                  existing['function']['arguments'] +=
                      call['function']['arguments'];
                }
              }
            }
          }
        }
      } catch (e, stackTrace) {
        sdkLogger.error(
          'Error in agent streaming loop',
          tag: 'AGENT',
          error: e,
          stackTrace: stackTrace,
        );
        onAgentFailure?.call(e.toString(), stackTrace);
        state.failRun(e.toString());
        rethrow;
      }

      final finalContent = contentBuffer.toString();

      if (hasContent && toolCallsDelta.isEmpty) {
        sdkLogger.debug(
          'Agent generated text response (streaming)',
          tag: 'AGENT',
          extra: {
            'response_length': finalContent.length,
            'usage': runUsage != null ? runUsage.totalTokens : 0,
          },
        );
        await memory.addMessage('assistant', finalContent);
        state.completeRun();
        if (runUsage != null) {
          yield VanturaResponse(usage: runUsage);
        }
        return;
      }

      if (toolCallsDelta.isNotEmpty) {
        final currentToolCalls = toolCallsDelta.values.toList();
        sdkLogger.info(
          'Agent making tool calls from stream',
          tag: 'AGENT',
          extra: {'tool_call_count': currentToolCalls.length},
        );

        // Add the assistant's tool call request to history
        messages.add({
          'role': 'assistant',
          'content': finalContent.isEmpty ? null : finalContent,
          'tool_calls': currentToolCalls,
        });

        for (var call in currentToolCalls) {
          executedToolCalls.add(call);
          final toolName = call['function']['name'];
          final argsString = call['function']['arguments'];

          Map<String, dynamic> args;
          try {
            args = jsonDecode(argsString);
          } catch (e) {
            sdkLogger.error(
              'Failed to decode tool arguments',
              tag: 'AGENT',
              error: e,
              extra: {'args': argsString},
            );
            args = {};
          }

          final tool = tools.firstWhere((t) => t.name == toolName);

          state.updateStep('Executing tool: $toolName');

          sdkLogger.info(
            'Executing tool: $toolName',
            tag: 'AGENT',
            extra: {'tool_name': toolName, 'args': args},
          );

          String result;
          try {
            final typedArgs = tool.parseArgs(args);

            if (tool.requiresConfirmation && args['confirmed'] != true) {
              result =
                  'CONFIRMATION_REQUIRED: This operation (${tool.description}) is sensitive. Please ask the user to confirm.';
            } else {
              result = await tool.execute(typedArgs);
            }
          } catch (e, stackTrace) {
            sdkLogger.error(
              'Tool $toolName execution failed',
              tag: 'AGENT',
              error: e,
              stackTrace: stackTrace,
            );
            onToolError?.call(toolName, e.toString(), stackTrace);
            result = 'Error executing tool: $e';
          }

          messages.add({
            'role': 'tool',
            'tool_call_id': call['id'],
            'content': result,
          });

          yield VanturaResponse(toolCalls: [call]);
        }
      } else {
        break;
      }
    }

    state.completeRun();
  }

  /// Runs the agent with the given prompt.
  /// You can optionally pass a [cancellationToken] to stop the generation early.
  Future<VanturaResponse> run(
    String prompt, {
    CancellationToken? cancellationToken,
  }) async {
    state.startRun();

    sdkLogger.info(
      'Starting VanturaAgent run',
      tag: 'AGENT',
      extra: {
        'prompt_length': prompt.length,
        'tool_count': tools.length,
        'memory_messages': memory.getMessages().length,
      },
    );

    await memory.addMessage('user', prompt);

    List<Map<String, dynamic>> messages = [
      {'role': 'system', 'content': instructions},
    ];

    messages.addAll(memory.getMessages());

    List<Map<String, dynamic>> toolsDef = tools
        .map(
          (t) => {
            'type': 'function',
            'function': {
              'name': t.name,
              'description': t.description,
              'parameters': t.parameters,
            },
          },
        )
        .toList();

    const int maxIterations = 10;
    int iterationCount = 0;

    state.updateStep('Starting reasoning loop...');
    final List<Map<String, dynamic>> executedToolCalls = [];

    while (true) {
      iterationCount++;
      if (iterationCount > maxIterations) {
        sdkLogger.error(
          'Agent exceeded maximum iterations ($maxIterations)',
          tag: 'AGENT',
          extra: {'iteration_count': iterationCount},
        );
        onAgentFailure?.call('Maximum reasoning iterations exceeded', null);
        state.failRun('Maximum reasoning iterations exceeded');
        return VanturaResponse(
          text: 'Error: Agent exceeded maximum iterations',
          toolCalls: executedToolCalls,
        );
      }

      if (cancellationToken?.isCancelled == true) {
        state.failRun('Cancelled by user');
        return VanturaResponse(
          text: '\n[Generation Cancelled]',
          toolCalls: executedToolCalls,
        );
      }

      state.updateStep('Sending API request...');

      final response = await client.sendChatRequest(
        messages,
        toolsDef.isEmpty ? null : toolsDef,
        cancellationToken: cancellationToken,
      );
      final choice = response['choices'][0]['message'];
      final content = choice['content'];

      TokenUsage? usage;
      final usageData = response['usage'] ?? response['x_groq']?['usage'];
      if (usageData != null) {
        usage = TokenUsage(
          promptTokens: usageData['prompt_tokens'] ?? 0,
          completionTokens: usageData['completion_tokens'] ?? 0,
          totalTokens: usageData['total_tokens'] ?? 0,
        );
      }

      if (content != null &&
          content.isNotEmpty &&
          (choice['tool_calls'] == null ||
              (choice['tool_calls'] as List).isEmpty)) {
        sdkLogger.debug(
          'Agent generated text response',
          tag: 'AGENT',
          extra: {'response_length': content.length},
        );
        await memory.addMessage('assistant', content);
        state.completeRun();
        return VanturaResponse(
          text: content,
          toolCalls: executedToolCalls,
          usage: usage,
        );
      }

      final toolCalls = choice['tool_calls'];
      if (toolCalls != null && toolCalls.isNotEmpty) {
        sdkLogger.info(
          'Agent making tool calls',
          tag: 'AGENT',
          extra: {'tool_call_count': toolCalls.length},
        );

        messages.add({
          'role': 'assistant',
          'content': content,
          'tool_calls': toolCalls,
        });

        for (var call in toolCalls) {
          executedToolCalls.add(call as Map<String, dynamic>);
          final toolName = call['function']['name'];
          final args = jsonDecode(call['function']['arguments']);
          final tool = tools.firstWhere((t) => t.name == toolName);

          state.updateStep('Executing tool: $toolName');

          sdkLogger.info(
            'Executing tool: $toolName',
            tag: 'AGENT',
            extra: {'tool_name': toolName, 'args': args},
          );

          String result;
          try {
            final typedArgs = tool.parseArgs(args);

            if (tool.requiresConfirmation && args['confirmed'] != true) {
              result =
                  'CONFIRMATION_REQUIRED: This operation (${tool.description}) is sensitive. Please ask the user to confirm.';
            } else {
              result = await tool.execute(typedArgs);
            }
          } catch (e, stackTrace) {
            sdkLogger.error(
              'Tool $toolName execution failed',
              tag: 'AGENT',
              error: e,
              stackTrace: stackTrace,
            );
            onToolError?.call(toolName, e.toString(), stackTrace);
            result = 'Error executing tool: $e';
          }

          messages.add({
            'role': 'tool',
            'tool_call_id': call['id'],
            'content': result,
          });
        }
      } else {
        break;
      }
    }

    sdkLogger.warning('Agent run completed without final text', tag: 'AGENT');
    onWarning?.call('Agent run completed without final text');
    state.completeRun();
    return VanturaResponse(
      text: 'I have finished the requested tasks.',
      toolCalls: executedToolCalls,
    );
  }
}
