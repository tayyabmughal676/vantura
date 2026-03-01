# 🎓 Vantura Implementation Guide: From Zero to Hero

Welcome to the official Vantura implementation guide. This document provides a step-by-step roadmap for integrating Vantura into your Flutter application, progressing from a basic chatbot to a sophisticated multi-agent system.

---

## 🛠️ Table of Contents
1. [Phase 1: The Basic Chatbot](#phase-1-the-basic-chatbot)
2. [Phase 2: Empowering with Custom Tools](#phase-2-empowering-with-custom-tools)
3. [Phase 3: Adding Long-Term Memory](#phase-3-adding-long-term-memory)
4. [Phase 4: Advanced Streaming & UI State](#phase-4-advanced-streaming--ui-state)
5. [Phase 5: Multi-Agent Coordination (Handoffs)](#phase-5-multi-agent-coordination-handoffs)
6. [Phase 6: Agent Checkpointing (Resiliency)](#phase-6-agent-checkpointing-resiliency)
7. [Phase 7: Security & Production Hardening](#phase-7-security--production-hardening)

---

## Phase 1: The Multi-Provider Chatbot
Vantura supports multiple LLM providers natively. You can switch between them by simply changing the `LlmClient` implementation.

### 1. Initialize your preferred Client
```dart
// Option A: OpenAI-compatible (Groq, Together, Ollama)
final client = VanturaClient(
  apiKey: 'your_api_key',
  baseUrl: 'https://api.groq.com/openai/v1/chat/completions',
  model: 'llama-3.3-70b-versatile',
);

// Option B: Native Anthropic (Claude)
final anthropic = AnthropicClient(
  apiKey: 'your_anthropic_key',
  model: 'claude-3-5-sonnet-latest',
);

// Option C: Native Google Gemini
final gemini = GeminiClient(
  apiKey: 'your_gemini_key',
  model: 'gemini-1.5-pro-latest',
);
```

### 2. Create the Agent
```dart
final agent = VanturaAgent(
  name: 'Assistant',
  instructions: 'You are a helpful assistant.',
  client: client, // Pass any of the client implementations above
  memory: VanturaMemory(sdkLogger, client), // Default in-memory
  state: VanturaState(),
  tools: [], // No tools yet
);
```

### 3. Run a Request
```dart
final response = await agent.run('Hello, who are you?');
print(response.text);
```

---

## Phase 2: Empowering with Custom Tools
Vantura's power lies in "Local Tool Calling." Unlike server-side agents, Vantura calls functions directly inside your Flutter app.

### 1. Define your Tool Arguments
```dart
class WeatherArgs {
  final String city;
  WeatherArgs(this.city);
  
  factory WeatherArgs.fromJson(Map<String, dynamic> json) => 
      WeatherArgs(json['city'] as String);
}
```

### 2. Create the Tool Class
```dart
class WeatherTool extends VanturaTool<WeatherArgs> {
  @override String get name => 'get_weather';
  @override String get description => 'Get current weather for a city';

  @override
  Map<String, dynamic> get parameters => SchemaHelper.generateSchema({
    'city': SchemaHelper.stringProperty(description: 'Name of the city'),
  }, required: ['city']);

  @override
  Future<String> execute(WeatherArgs args) async {
    // Call your actual API or local service here
    return "The weather in ${args.city} is sunny, 25°C.";
  }

  @override
  WeatherArgs parseArgs(Map<String, dynamic> json) => WeatherArgs.fromJson(json);
}
```

### 3. Register the Tool
```dart
final agent = VanturaAgent(
  // ... other properties
  tools: [WeatherTool(), CalculatorTool()],
);
```

---

## Phase 3: Adding Long-Term Memory
By default, memory is lost when the app closes. Implement `VanturaPersistence` to save it to your local database (Hive, Floor, SQFlite).

### 1. Implement the Persistence Interface
```dart
class MyHivePersistence implements VanturaPersistence {
  @override
  Future<void> saveMessage(String role, String content, {
    bool isSummary = false,
    List<Map<String, dynamic>>? toolCalls,
    String? toolCallId,
  }) async {
    // Save to Hive/Database
  }

  @override
  Future<List<Map<String, dynamic>>> loadMessages() async {
    // Load from Hive/Database
    return [];
  }
  
  // Implement clearMessages and deleteOldMessages...
}
```

### 2. Inject and Initialize
```dart
final memory = VanturaMemory(
  sdkLogger, 
  client, 
  persistence: MyHivePersistence(),
);

await memory.init(); // CRITICAL: Loads history from DB
```

---

## Phase 4: Advanced Streaming & UI State
For a premium experience, use streaming to show tokens as they are generated.

### 1. Implementation
```dart
final responseStream = agent.runStreaming('Write a long poem about Flutter');

await for (final chunk in responseStream) {
  if (chunk.textChunk != null) {
    // Update your UI state/List with the new chunk
    myTerminalController.append(chunk.textChunk!);
  }
}
```

### 2. Monitoring State
Use `VanturaState` to show "Thinking" indicators or Step-by-Step progress.
```dart
ValueListenableBuilder(
  valueListenable: agent.state,
  builder: (context, state, child) {
    if (state.isRunning) {
      return Text('Agent is: ${state.currentStep}');
    }
    return SizedBox.shrink();
  },
);
```

---

## Phase 5: Multi-Agent Coordination (Handoffs)
For complex apps, don't use one giant agent. Use specialized agents and a `AgentCoordinator`.

### 1. Setup the Team
```dart
final support = VanturaAgent(name: 'Support', instructions: 'General help...', ...);
final billing = VanturaAgent(name: 'Billing', instructions: 'Payment help...', ...);

final coordinator = AgentCoordinator([support, billing]);
```

### 2. Run through the Coordinator
```dart
// If user says "My invoice is wrong", Support will automatically
// call "transfer_to_agent" to hand off to Billing.
await coordinator.run('I need help with my last payment');
```

---

## Phase 6: Agent Checkpointing (Resiliency)
Long-running agent loops can be interrupted by app termination or backgrounding. Vantura's checkpointing system allows you to save and resume the exact state of a reasoning cycle.

### 1. Enable Persistence
Checkpointing requires a `VanturaPersistence` implementation (see Phase 3). Vantura will automatically save the agent's state to this layer between tool executions.

### 2. Resume an Interrupted Loop
```dart
Future<void> resumeAgent() async {
  // Load the last known checkpoint from the database
  final checkpoint = await persistence.loadCheckpoint();
  
  if (checkpoint != null && checkpoint.isRunning) {
    // Resume the session exactly where it left off
    await for (final response in agent.resume(resumeFrom: checkpoint)) {
      print(chunk.textChunk);
    }
  }
}
```

---

## Phase 7: Security & Production Hardening
Before publishing your app, ensure it is secure.

### 1. Redact Sensitive Data in Logs
```dart
sdkLogger = SimpleVanturaLogger(
  options: VanturaLoggerOptions(
    logSensitiveContent: false, // Prevents logging user prompts in console
    redactedKeys: ['api_key', 'token', 'ssn'],
  ),
);
```

### 2. Implement Tool Timeouts
By default, Vantura tools have a 30-second timeout. You can customize this per tool:
```dart
class HeavyComputeTool extends VanturaTool<NoArgs> {
  @override
  Duration get timeout => Duration(minutes: 5); // Allow more time
  
  // ...
}
```

### 3. Safety Guardrails
Vantura agents automatically include hidden SDK-level guardrails to prevent users from saying "Ignore previous instructions." No extra code required!

---

## 🎉 Conclusion
You are now ready to build world-class Agentic AI applications with Flutter. 

For real-world examples, check the `/example` directory in the repository or visit our [Online Documentation](https://github.com/tayyabmughal676/vantura).
