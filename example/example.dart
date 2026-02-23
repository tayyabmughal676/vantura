import 'package:vantura/core/index.dart';
import 'package:vantura/tools/index.dart';

/// A simple example showing how to initialize and use a Vantura agent.
void main() async {
  // 1. Initialize the Vantura Client
  // In a real app, use your actual API key and base URL.
  final client = VanturaClient(
    apiKey: 'your_api_key_here',
    baseUrl: 'https://api.openai.com/v1/chat/completions',
    model: 'gpt-4o',
  );

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
  print('Thinking...');
  final response = await agent.run(
    'Calculate 15% of 250 and check network status.',
  );

  print('Assistant: ${response.text}');

  // 5. Run the Agent (Streaming)
  print('\nStreaming response:');
  final stream = agent.runStreaming('Tell me a short joke.');

  await for (final chunk in stream) {
    if (chunk.textChunk != null) {
      // In a Flutter app, you would update your UI state here.
      print(chunk.textChunk);
    }
  }

  // Cleanup
  client.close();
}
