import 'package:flutter/widgets.dart';
import 'package:vantura/vantura.dart';

/// A simple example showing how to initialize and use a Vantura agent.
void main() async {
  // 1. Initialize the LLM Client
  // Vantura supports multi-provider swapping out-of-the-box via the LlmClient interface.
  // In a real app, use your actual API key and base URL.
  final LlmClient client = VanturaClient(
    apiKey: 'your_api_key_here',
    baseUrl: 'https://api.openai.com/v1/chat/completions',
    model: 'gpt-4o',
  );

  // Example: Hot-swap to Anthropic Claude
  // final LlmClient claudeClient = AnthropicClient(
  //   apiKey: 'your_anthropic_key',
  //   model: 'claude-3-7-sonnet-latest',
  // );

  // Example: Hot-swap to Google Gemini
  // final LlmClient geminiClient = GeminiClient(
  //   apiKey: 'your_gemini_key',
  //   model: 'gemini-2.5-pro',
  // );

  // 1b. Checkpointing example (requires persistence implementation)
  // If the app was closed during generation, you can reload the interrupted state:
  // final checkpoint = await memory.persistence?.loadCheckpoint();
  // if (checkpoint != null && checkpoint.isRunning) {
  //   agent.resume(checkpoint).listen((response) => print(response.textChunk));
  // }

  // 2. Setup Memory and State
  final state = VanturaState();
  final memory = VanturaMemory(sdkLogger, client);

  // 3. Define the Agent
  final agent = VanturaAgent(
    name: 'smart_assistant',
    instructions: 'You are a helpful and concise assistant.',
    memory: memory,
    tools:
        getStandardTools(), // Standard tools like Calculator, Device Info, etc.
    client: client,
    state: state,
  );

  // 4. Run the Agent (Non-streaming)
  // We wrap this in a try-catch to handle standardized VanturaException types.
  debugPrint('Thinking...');
  try {
    final response = await agent.run(
      'Calculate 15% of 250 and check network status.',
    );
    debugPrint('Assistant: ${response.text}');
  } on VanturaException catch (e) {
    debugPrint('Agent execution failed: $e');
  }

  // 5. Run the Agent (Streaming token-by-token)
  debugPrint('\nStreaming response:');
  try {
    final stream = agent.runStreaming('Tell me a short joke.');

    await for (final response in stream) {
      if (response.textChunk != null) {
        // In a terminal, use stdout.write for smooth streaming feel
        debugPrint(response.textChunk);
      }
    }
  } on VanturaException catch (e) {
    debugPrint('Streaming failed: $e');
  }

  // Cleanup: Always close the client to release HTTP resources
  client.close();
}
