import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vantura/core/index.dart';
import 'package:vantura/core/logger.dart';
import 'dart:io';

/// Quick integration smoke-test for the Vantura SDK streaming pipeline.
/// Run with: `dart run test_streaming_sdk.dart`
void main() async {
  await dotenv.load(fileName: '.env');

  final client = VanturaClient(
    apiKey: dotenv.env['GROQ_API_KEY'] ?? '',
    baseUrl: dotenv.env['BASE_URL'] ?? '',
    model: dotenv.env['MODEL'] ?? '',
  );

  final state = VanturaState();
  final memory = VanturaMemory(sdkLogger, client);

  final agent = VanturaAgent(
    instructions: 'You are a helpful assistant.',
    memory: memory,
    tools: [],
    client: client,
    state: state,
  );

  stdout.writeln('Starting streaming test...');
  final stream = agent.runStreaming('Hello, how are you?');

  await for (final response in stream) {
    if (response.textChunk != null) {
      stdout.write(response.textChunk);
    }
    if (response.usage != null) {
      stdout.writeln('\n--- Token Usage: ${response.usage!.totalTokens} ---');
    }
  }
  stdout.writeln('\nStreaming test completed.');
  client.close();
}
