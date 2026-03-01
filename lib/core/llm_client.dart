import 'package:vantura/core/index.dart';

/// Common interface for all LLM clients in the Vantura framework.
///
/// Implementing this interface allows [VanturaAgent] to interact
/// with various LLM providers (e.g., OpenAI, Anthropic, Gemini)
/// using a unified API.
abstract class LlmClient {
  /// Sends a single, complete chat request to the LLM.
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
  });

  /// Sends a streaming chat request to the LLM, yielding chunks as they arrive.
  Stream<Map<String, dynamic>> sendStreamingChatRequest(
    List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>>? tools, {
    double? temperature,
    int? maxCompletionTokens,
    double? topP,
    String? reasoningEffort,
    dynamic stop,
    CancellationToken? cancellationToken,
  });

  /// Closes the client and cleans up any resources.
  void close();
}
