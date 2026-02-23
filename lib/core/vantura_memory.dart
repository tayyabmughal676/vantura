import 'dart:collection';
import 'logger.dart';
import 'vantura_client.dart';
import 'vantura_persistence.dart';

class VanturaMemory {
  final Queue<Map<String, dynamic>> _shortMemory =
      Queue<Map<String, dynamic>>();
  final List<Map<String, dynamic>> _longMemory = [];

  final int shortLimit;
  final int longLimit;

  /// Logger instance for logging operations.
  final VanturaLogger logger;

  /// Client for AI communication, used for summarization.
  final VanturaClient client;

  /// Persistence provider for conversation history.
  final VanturaPersistence? persistence;

  /// Creates an VanturaMemory with the specified logger and client.
  VanturaMemory(
    this.logger,
    this.client, {
    this.shortLimit = 10,
    this.longLimit = 5,
    this.persistence,
  });

  /// Initializes memory by loading history from persistence.
  Future<void> init() async {
    if (persistence == null) return;

    try {
      logger.info('Loading chat history from persistence', tag: 'MEMORY');
      final messages = await persistence!.loadMessages();

      for (var msg in messages) {
        final chatMsg = {
          'role': msg['role'],
          'content': msg['content'],
          if (msg['toolCalls'] != null) 'tool_calls': msg['toolCalls'],
          if (msg['toolCallId'] != null) 'tool_call_id': msg['toolCallId'],
        };

        if (msg['isSummary'] == 1 || msg['isSummary'] == true) {
          _longMemory.add(chatMsg);
        } else {
          _shortMemory.add(chatMsg);
        }
      }

      logger.info(
        'Chat history loaded',
        tag: 'MEMORY',
        extra: {
          'short_count': _shortMemory.length,
          'long_count': _longMemory.length,
        },
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to load chat history',
        tag: 'MEMORY',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<String> _summarizeMessages(List<Map<String, dynamic>> messages) async {
    const summaryPrompt =
        'You are a helpful summarizer. Summarize the following conversation history into a single concise paragraph that captures the key points, ongoing topics, and current context. Keep it under 500 words.';

    // Format the conversation
    final formattedConversation = messages
        .map((msg) => '${msg['role']}: ${msg['content']}')
        .join('\n');

    final summaryMessages = [
      {'role': 'system', 'content': summaryPrompt},
      {'role': 'user', 'content': formattedConversation},
    ];

    try {
      final response = await client.sendChatRequest(summaryMessages, null);
      final choice = response['choices'][0]['message'];
      final content = choice['content'];
      if (content != null && content.isNotEmpty) {
        logger.info(
          'Successfully summarized conversation history',
          tag: 'MEMORY',
          extra: {
            'original_messages': messages.length,
            'summary_length': content.length,
          },
        );
        return content;
      } else {
        throw Exception('Empty summary response');
      }
    } catch (e, stackTrace) {
      logger.error(
        'Failed to summarize messages',
        tag: 'MEMORY',
        error: e,
        stackTrace: stackTrace,
        extra: {'message_count': messages.length},
      );
      // Fallback: return a basic summary
      return 'Previous conversation context: ${messages.length} messages exchanged, focusing on user queries and agent responses.';
    }
  }

  Future<void> addMessage(
    String role,
    String content, {
    List<Map<String, dynamic>>? toolCalls,
    String? toolCallId,
  }) async {
    if (role.isEmpty && (toolCalls == null || toolCalls.isEmpty)) {
      logger.warning(
        'Attempted to add invalid message to memory',
        tag: 'MEMORY',
        extra: {'role': role, 'content_length': content.length},
      );
      return;
    }

    final message = {
      'role': role,
      'content': content.isEmpty ? null : content,
      if (toolCalls != null) 'tool_calls': toolCalls,
      if (toolCallId != null) 'tool_call_id': toolCallId,
    };

    // Save to persistence if available
    if (persistence != null) {
      await persistence!.saveMessage(
        role,
        content,
        toolCalls: toolCalls,
        toolCallId: toolCallId,
      );
    }

    _shortMemory.add(message);
    logger.debug(
      'Added message to short-term memory',
      tag: 'MEMORY',
      extra: {
        'role': role,
        'content_length': content.length,
        'has_tools': toolCalls != null,
        'short_count': _shortMemory.length,
      },
    );

    if (_shortMemory.length > shortLimit) {
      logger.info(
        'Short-term memory limit reached, summarizing to long-term memory',
        tag: 'MEMORY',
        extra: {'short_count': _shortMemory.length},
      );
      final messagesToSummarize = _shortMemory.toList();
      final summary = await _summarizeMessages(messagesToSummarize);

      final summaryMsg = {
        'role': 'system',
        'content': 'Historical context: $summary',
      };

      // Save summary to persistence
      if (persistence != null) {
        await persistence!.saveMessage(
          'system',
          'Historical context: $summary',
          isSummary: true,
        );
        // Prune old non-summarized messages from persistence to save space
        await persistence!.deleteOldMessages(shortLimit);
      }

      _longMemory.add(summaryMsg);
      _shortMemory.clear();
      logger.info(
        'Added summary to long-term memory',
        tag: 'MEMORY',
        extra: {
          'long_count': _longMemory.length,
          'summary_length': summary.length,
        },
      );

      // Prune long memory if needed
      if (_longMemory.length > longLimit) {
        final removed = _longMemory.removeAt(0);
        logger.info(
          'Pruned oldest long-term memory entry',
          tag: 'MEMORY',
          extra: {
            'removed_length': removed['content'].length,
            'long_count': _longMemory.length,
          },
        );
      }
    }
  }

  List<Map<String, dynamic>> getMessages() {
    final messages = _longMemory + _shortMemory.toList();
    logger.debug(
      'Retrieving messages from memory',
      tag: 'MEMORY',
      extra: {
        'count': messages.length,
        'long_count': _longMemory.length,
        'short_count': _shortMemory.length,
      },
    );
    return messages;
  }

  void clear() {
    _shortMemory.clear();
    _longMemory.clear();
    persistence?.clearMessages();
    logger.info('Cleared all memory', tag: 'MEMORY');
  }
}
