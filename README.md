# 🚀 Vantura

### The Stateful Agentic AI Framework for Flutter. Build "Brains" directly in your app.

Vantura is a **Stateful Agentic AI Framework** for building LLM-powered agents that **reason, think, maintain state, and execute local tools** — all entirely on the client. Forget complex Python backends; Vantura gives your Flutter app an intelligent, context-aware orchestrator that lives where your data lives.

## Screenshots

<img src="./screenshots/vantura-example.png" alt="Vantura App Screenshot" width="400">

[![Pub Version](https://img.shields.io/pub/v/vantura.svg)](https://pub.dev/packages/vantura)
[![License: BSD-3](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](LICENSE)
[![Dart SDK](https://img.shields.io/badge/Dart-3.11+-blue.svg)](https://dart.dev)
[![Flutter SDK](https://img.shields.io/badge/Flutter-3.22+-blue.svg)](https://flutter.dev)

---

## ✨ Key Features

| Feature | Description |
|---|---|
| 🧠 **On-Device ReAct Loop** | Orchestration runs locally in Dart, minimizing latency and letting the agent interact directly with Flutter APIs. |
| 🛠️ **Type-Safe Tools** | Define custom tools using strongly-typed Dart classes with automatic JSON Schema generation for the LLM. |
| 🤖 **Multi-Provider Support** | Seamlessly swap between OpenAI-compatible backends (Groq, TogetherAI, local Ollama), Anthropic Claude, and Google Gemini via a unified `LlmClient` interface. |
| 💾 **Dual-Layer Memory** | Short-term sliding window context mixed with automatic, LLM-powered long-term conversation summarization. |
| ⏸️ **Agent Checkpointing** | Persist and resume interrupted reasoning cycles (ReAct loops) to recover from app backgrounding or terminations. |
| 🤝 **Multi-Agent Coordination** | Easily delegate specialized tasks across multiple agents using the built-in `AgentCoordinator`. |
| 🛡️ **Dynamic Confirmation** | Request human-in-the-loop permission `requiresConfirmation` for sensitive actions, skipping dynamically for low-risk actions. |
| 🔒 **Privacy-First Security** | Built-in redaction logging, automatic PII protection tools, and local execution keep your data from leaking into middleware logs. |
| � **State Sync UI** | `ChangeNotifier` and reactive state models expose the current "thought" step and token streams straight to your Flutter UI. |

---

## �📖 Table of Contents
1. [Key Features](#-key-features)
2. [Core Concepts](#core-concepts)
3. [Getting Started (One-Go Guide)](#getting-started-one-go-guide)
4. [Multi-Provider LLMs](#multi-provider-llms)
5. [The Memory System & Persistence](#the-memory-system--persistence)
6. [Agent Checkpointing](#agent-checkpointing)
7. [Custom Tools & JSON Schema](#custom-tools--json-schema)
8. [State & UI Integration](#state--ui-integration)
9. [Multi-Agent Coordination](#multi-agent-coordination)
10. [Error Handling & Resilience](#error-handling--resilience)
11. [Security & Data Privacy](#security--data-privacy)
12. [Architectural Comparison](#architectural-comparison)
13. [Full Implementation Guide (Advanced)](#full-implementation-guide-advanced)
14. [Examples](#examples)

---

## 🧠 Core Concepts

Vantura is built on the **ReAct (Reason + Act) loop**. 
1. **Thought**: The agent analyzes the user request.
2. **Action**: It decides which local tool to call.
3. **Observation**: It reads the tool's result.
4. **Iteration**: It repeats until it has a final answer for the user.

This loop happens **on-device**, allowing the agent to call functions that exist only in your Flutter world (like `Navigator.push` or `sqflite.insert`).

---

## 🚀 Getting Started (One-Go Guide)

### 1. Installation
Add `vantura` to your `pubspec.yaml`:
```yaml
dependencies:
  vantura: ^1.0.0
```

### 2. Full Implementation Snippet
Here is how you implement a fully-functional agent with tools and streaming in one go:

```dart
import 'package:vantura/vantura.dart';
import 'dart:async';
import 'dart:io';

void main() async {
  // 1. Initialize the Provider Client (Supports OpenAI, Anthropic, Gemini, etc.)
  final LlmClient client = VanturaClient(
    apiKey: 'YOUR_API_KEY',
    baseUrl: 'https://api.groq.com/openai/v1/chat/completions',
    model: 'llama-3.3-70b-versatile',
  );

  // 2. Setup Memory (In-memory for now)
  final memory = VanturaMemory(sdkLogger, client);

  // 3. Define the Agent
  final agent = VanturaAgent(
    name: 'orbit_assistant',
    instructions: 'You are a helpful assistant. Use tools to help the user.',
    memory: memory,
    client: client,
    tools: [
      ...getStandardTools(), // Includes Calculator, Connectivity, Device Info
      MyCustomTool(),        // Your app-specific logic
    ],
    state: VanturaState(),    // Tracks loading/progress
    onToolError: (tool, error, stack) => print('Tool $tool failed: $error'),
  );

  // 4. Run with Streaming (SSE)
  final cancellationToken = CancellationToken();
  
  await for (final response in agent.runStreaming(
    'Check my internet and tell me the time',
    cancellationToken: cancellationToken,
  )) {
    if (response.textChunk != null) {
      stdout.write(response.textChunk); // Streamed token-by-token
    }
  }
}
```

---

## 🤖 Multi-Provider LLMs

Vantura abstracts all communication through the unified `LlmClient` interface. You are not locked into a single provider or standard. 

Out-of-the-box, Vantura ships with three deeply integrated clients:
1. **`VanturaClient`**: The standard REST wrapper for any OpenAI-compatible API (Groq, TogetherAI, OpenAI, local Ollama).
2. **`AnthropicClient`**: Fully native wrapper for Anthropic's Claude 3.5/3.7+ Messages API format.
3. **`GeminiClient`**: Fully native wrapper for Google's Gemini 1.5/2.0+ REST endpoints with structured tool injection.

```dart
// Hot-swap providers without changing your Agent logic:
final LlmClient openai = VanturaClient(apiKey: 'sk-...', model: 'gpt-4o');
final LlmClient claude = AnthropicClient(apiKey: 'sk-ant-...', model: 'claude-3-7-sonnet-latest');
final LlmClient gemini = GeminiClient(apiKey: 'AIza...', model: 'gemini-1.5-flash-latest');
```

---

## 💾 The Memory System & Persistence

Vantura features a **Dual-Layer Memory**:
- **Short-term**: A sliding window of the last X messages.
- **Long-term memory**: Automatic LLM-powered **summarization**. When the message history exceeds the token limit, Vantura asks the LLM to compress older messages into a summary, preserving context without bloating the prompt.

### Implementing Persistence (SQLite Example)
To keep conversations after an app restart, implement `VanturaPersistence`:

```dart
class SQLitePersistence implements VanturaPersistence {
  final Database db; // Your sqflite instance
  
  @override
  Future<void> saveMessage(String role, String content, {bool isSummary = false}) async {
    await db.insert('messages', {'role': role, 'content': content, 'is_summary': isSummary ? 1 : 0});
  }

  @override
  Future<List<Map<String, dynamic>>> loadMessages() async {
    return await db.query('messages', orderBy: 'id ASC');
  }

  // ... implement clearMessages(), deleteOldMessages(), and checkpointing hooks
}

// Inject it:
final memory = VanturaMemory(sdkLogger, client, persistence: SQLitePersistence(myDb));
await memory.init(); // Loads history into memory
```

---

## ⏸️ Agent Checkpointing

Agent reasoning cycles (ReAct loops) can sometimes take several seconds. If a user backgrounds or kills the app mid-generation, progress is lost. Vantura's checkpointing system automatically serializes the agent's exact loop state `_saveCurrentState()` between tool executions. 

When your app restarts, you can seamlessly resume the loop right where it left off:

```dart
class MyService {
  Future<void> resumeLastSession() async {
    // 1. Load the interrupted state from your persistence layer
    final AgentStateCheckpoint? checkpoint = await memory.persistence?.loadCheckpoint();
    
    if (checkpoint != null && checkpoint.isRunning) {
      // 2. Resume the agent with the loaded checkpoint
      await for (final response in agent.resume(resumeFrom: checkpoint)) {
        print(response.textChunk);
      }
    }
  }
}
```

---

## 🛠️ Custom Tools & JSON Schema

Vantura uses a **Type-Safe Tool Framework**. You define the arguments as a class and Vantura generates the JSON Schema for the LLM.

### Example: Navigation Tool
Give your agent the ability to navigate your app by creating a tool that interacts with your `Router`.

```dart
class NavArgs {
  final String route;
  NavArgs(this.route);
  factory NavArgs.fromJson(Map<String, dynamic> j) => NavArgs(j['route']);
}

class NavigationTool extends VanturaTool<NavArgs> {
  @override String get name => 'navigate';
  @override String get description => 'Navigates to a specific screen in the app.';

  @override
  Map<String, dynamic> get parameters => SchemaHelper.generateSchema({
    'route': SchemaHelper.stringProperty(
        description: 'Target route (e.g. /settings, /profile)',
        enumValues: ['/settings', '/profile', '/home'],
    ),
  });

  @override
  Future<String> execute(NavArgs args) async {
    // Access your app router here
    // myRouter.go(args.route);
    return "Successfully navigated to ${args.route}";
  }

  @override NavArgs parseArgs(Map<String, dynamic> j) => NavArgs.fromJson(j);
}
```

### Advanced Tool Features

Vantura supports sophisticated tool implementations for complex applications.

#### Conditional Confirmations & Business Logic Integration
Tools can dynamically request explicit user confirmation based on the requested action, and execute complex workflows like cross-entity updates:

```dart
class UpdateInvoiceStatusTool extends VanturaTool<UpdateInvoiceStatusArgs> {
  final InvoiceRepository invoiceRepository;
  final InventoryRepository inventoryRepository;

  UpdateInvoiceStatusTool(this.invoiceRepository, this.inventoryRepository);
  
  // Conditionally skip the confirmation modal if it's a low-risk change
  @override
  bool requiresConfirmationFor(UpdateInvoiceStatusArgs args) {
    // Only pause the loop to ask the user if it deducts real inventory
    return ['paid', 'cancelled'].contains(args.status); 
  }

  @override
  Map<String, dynamic> get parameters => SchemaHelper.generateSchema({
    'invoiceId': SchemaHelper.numberProperty(description: 'Invoice ID'),
    'status': SchemaHelper.stringProperty(
      description: 'New status',
      enumValues: ['draft', 'sent', 'paid', 'cancelled'],
    ),
    'confirmed': SchemaHelper.booleanProperty(
      description: 'Set to true ONLY after the user confirms.',
    ),
  }, required: ['invoiceId', 'status']);

  @override
  Future<String> execute(UpdateInvoiceStatusArgs args) async {
    final invoice = await invoiceRepository.getInvoice(args.invoiceId);
    if (invoice == null) return 'Invoice not found';

    // Update status
    final newStatus = InvoiceStatus.values.firstWhere(
      (e) => e.name == args.status,
      orElse: () => invoice.status,
    );

    final updated = invoice.copyWith(status: newStatus);
    await invoiceRepository.updateInvoice(updated);

    // Business logic: decrement inventory on payment
    if (newStatus == InvoiceStatus.paid && invoice.status != InvoiceStatus.paid) {
      for (var item in invoice.items) {
        await inventoryRepository.updateStock(item.description, -item.quantity.toInt());
      }
    }

    return 'Invoice status updated successfully to ${args.status}';
  }
}
```

#### Complex Parameter Schemas
Tools can handle arrays, enums, and nested objects for rich interactions:

```dart
class CreateInvoiceTool extends VanturaTool<CreateInvoiceArgs> {
  @override
  Map<String, dynamic> get parameters => SchemaHelper.generateSchema({
    'clientId': SchemaHelper.numberProperty(description: 'Client ID'),
    'status': SchemaHelper.stringProperty(
      description: 'Invoice status',
      enumValues: ['draft', 'sent', 'paid', 'overdue'],
    ),
    'items': {
      'type': 'array',
      'items': {
        'type': 'object',
        'properties': {
          'description': {'type': 'string'},
          'quantity': {'type': 'number'},
          'unitPrice': {'type': 'number'},
        },
        'required': ['description', 'quantity', 'unitPrice'],
      },
    },
  }, required: ['clientId', 'items']);
}
```

---

## 📱 State & UI Integration

Vantura provides `VanturaState` (a `ChangeNotifier`) to sync the SDK's internal loop with your Flutter UI.

```dart
class ChatScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Assuming agent.state is exposed via a provider
    final state = ref.watch(agentStateProvider);

    return Column(
      children: [
        if (state.isRunning) 
           Text('Thinking... (Step: ${state.currentStep})'),
        
        if (state.errorMessage != null)
           ErrorWidget(state.errorMessage!),
      ],
    );
  }
}
```

---

## 🤝 Multi-Agent Coordination

Need a team? `AgentCoordinator` lets you define specialized agents and automatically handles the hand-offs.

```dart
final billingAgent = VanturaAgent(name: 'BillingBot', instructions: 'Handle invoices...', ...);
final supportAgent = VanturaAgent(name: 'SupportBot', instructions: 'Help with general queries...', ...);

final coordinator = AgentCoordinator([billingAgent, supportAgent]);

// The coordinator will call "transfer_to_agent" automatically!
await for (final r in coordinator.runStreaming('Create an invoice for \$50')) { ... }
```

---

## 🛡️ Error Handling & Resilience

Vantura includes robust hooks for structured telemetry:

```dart
final agent = VanturaAgent(
  // ...
  onToolError: (tool, error, stack) => FirebaseCrashlytics.instance.recordError(error, stack),
  onWarning: (msg) => print('⚠️ Vantura Warning: $msg'),
  onAgentFailure: (err, stack) => showGlobalErrorSnackBar(err),
);

// Vantura throws standardized exceptions you can catch:
try {
  await agent.run('...');
} on VanturaException catch (e) {
  print('Caught Vantura-specific error: $e');
}
```

---

## 🛡️ Security & Data Privacy

Vantura is built for production environments where data privacy is paramount.

- **Hardened Input Sanitization**: Automatic length validation (100KB) and control-character stripping (SEC-003) to prevent OOM attacks and prompt injection.
- **Resilient Tooling**: Agents now handle hallucinated tool names gracefully by informing the LLM and allowing self-correction instead of crashing the loop (SEC-002).
- **Automatic Redaction**: Integrated logger automatically strips API keys, Authorization tokens, and sensitive fields from logs.
- **Privacy-First Logging**: `logSensitiveContent` is disabled by default, ensuring user prompts and AI responses never touch your console logs in production.
- **Anti-SSRF Guard**: Built-in tools like `ApiTestTool` feature hostname blacklisting to prevent internal network scanning.
- **SDK Guardrails**: Injected system directives prevent the LLM from being "ordered" to ignore its original instructions (Anti-Jailbreak).

---

## 📊 Architectural Comparison

| Feature | OpenAI direct | LangChain (Backend) | **Vantura (Flutter)** |
|---|---|---|---|
| **Storage Access** | Cloud-only | Server-level | **Local (SQLite, Hive)** |
| **System APIs** | No | Remote only | **Native (Sensors, GPS)** |
| **Latency** | 1 Round-trip | 2+ Round-trips | **1 Round-trip (Direct)** |
| **Auth** | Managed in app | Proxy required | **Native in app** |
| **Privacy** | Shared via Server | Shared via Server | **Local-First (Private)** |

---

## 🎓 Full Implementation Guide (Advanced)

For a step-by-step roadmap from basic chatbot setup to advanced multi-agent systems and security hardening, please refer to the **[Implementation Guide (example.md)](example.md)**.

---

## 📚 Examples

For a complete Flutter app demonstrating Vantura, see the [example/](example/) folder. This business management suite showcases advanced capabilities including:

- **Client Management**: CRUD operations for customer data with natural language queries
- **Inventory Tracking**: Real-time stock management with low-stock alerts and automated updates
- **Invoice Generation**: Complex invoicing with line items, tax calculations, and status workflows
- **Financial Ledger**: Transaction recording and business analytics
- **Confirmation Flows**: User approval for sensitive operations like updates and deletions
- **Cross-Entity Workflows**: Automatic inventory adjustments when invoices are paid
- **UI Integration**: Streaming responses and real-time state synchronization

The example includes a full Clean Architecture implementation with SQLite persistence, Riverpod dependency injection, and responsive Flutter UI.

---

## 📄 License
Vantura is open-source and released under the **BSD 3-Clause License**.

---

Built with ❤️ for the Flutter community by [**DataDaur AI Consulting**](https://datadaur.com). 
For bug reports and feature requests, visit our [GitHub Repository](https://github.com/tayyabmughal676/vantura).
