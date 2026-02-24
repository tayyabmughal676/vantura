# 🚀 Vantura

### The Agentic AI Framework for Flutter. Build "Brains" directly in your app.

Vantura is an **Agentic AI Framework** for building LLM-powered agents that **reason, think, and execute local tools** — all entirely on the client. Forget complex Python backends; Vantura gives your Flutter app an orchestrator that lives where your data lives.

## Screenshots

<img src="./screenshots/vantura-example.png" alt="Vantura App Screenshot" width="400">

[![Pub Version](https://img.shields.io/pub/v/vantura.svg)](https://pub.dev/packages/vantura)
[![License: BSD-3](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](LICENSE)
[![Dart SDK](https://img.shields.io/badge/Dart-3.11+-blue.svg)](https://dart.dev)
[![Flutter SDK](https://img.shields.io/badge/Flutter-3.22+-blue.svg)](https://flutter.dev)

---

## 📖 Table of Contents
1. [Core Concepts](#-core-concepts)
2. [Getting Started (One-Go Guide)](#-getting-started-one-go-guide)
3. [The Memory System & Persistence](#-the-memory-system--persistence)
4. [Custom Tools & JSON Schema](#-custom-tools--json-schema)
5. [State & UI Integration](#-state--ui-integration)
6. [Multi-Agent Coordination](#-multi-agent-coordination)
7. [Error Handling & Resilience](#-error-handling--resilience)
8. [Security & Data Privacy](#-security--data-privacy)
9. [Architectural Comparison](#-architectural-comparison)
10. [Full Implementation Guide (Advanced)](#-full-implementation-guide-advanced)
11. [Examples](#-examples)

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
  vantura: latest
```

### 2. Full Implementation Snippet
Here is how you implement a fully-functional agent with tools and streaming in one go:

```dart
import 'package:vantura/core/index.dart';
import 'package:vantura/tools/index.dart';
import 'dart:async';
import 'dart:io';

void main() async {
  // 1. Initialize the Provider Client
  final client = VanturaClient(
    apiKey: 'YOUR_API_KEY',
    baseUrl: 'https://api.groq.com/openai/v1/chat/completions', // Or OpenAI/Ollama
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

  @override
  Future<void> clearMessages() async => await db.delete('messages');

  @override
  Future<void> deleteOldMessages(int limit) async {
    // Logic to prune oldest messages
  }
}

// Inject it:
final memory = VanturaMemory(sdkLogger, client, persistence: SQLitePersistence(myDb));
await memory.init(); // Loads history into memory
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
        enumOptions: ['/settings', '/profile', '/home'],
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

#### Confirmation Flows
For sensitive operations like data updates or deletions, tools can require explicit user confirmation:

```dart
class UpdateClientTool extends VanturaTool<UpdateClientArgs> {
  @override
  bool get requiresConfirmation => true;

  @override
  Map<String, dynamic> get parameters => SchemaHelper.generateSchema({
    'id': SchemaHelper.numberProperty(description: 'Client ID'),
    'name': SchemaHelper.stringProperty(description: 'Updated name'),
    'confirmed': SchemaHelper.booleanProperty(
      description: 'Set to true ONLY after the user confirms the update.',
    ),
  }, required: ['id']);

  @override
  Future<String> execute(UpdateClientArgs args) async {
    // Business logic here
    return 'Client updated successfully';
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

#### Business Logic Integration
Tools can execute complex workflows, such as cross-entity updates or analytics:

```dart
class UpdateInvoiceStatusTool extends VanturaTool<UpdateInvoiceStatusArgs> {
  final InvoiceRepository invoiceRepository;
  final InventoryRepository inventoryRepository;

  UpdateInvoiceStatusTool(this.invoiceRepository, this.inventoryRepository);

  @override
  bool get requiresConfirmation => true;

  @override
  Map<String, dynamic> get parameters => SchemaHelper.generateSchema({
    'invoiceId': SchemaHelper.numberProperty(description: 'Invoice ID'),
    'status': SchemaHelper.stringProperty(
      description: 'New status',
      enumValues: ['draft', 'sent', 'paid'],
    ),
    'confirmed': SchemaHelper.booleanProperty(
      description: 'Set to true ONLY after user confirms.',
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

    return 'Invoice status updated to ${args.status}';
  }
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

Vantura includes hooks for structured telemetry:

```dart
final agent = VanturaAgent(
  // ...
  onToolError: (tool, error, stack) => FirebaseCrashlytics.instance.recordError(error, stack),
  onWarning: (msg) => print('⚠️ Vantura Warning: $msg'),
  onAgentFailure: (err) => showGlobalErrorSnackBar(err),
);
```

---

## 🛡️ Security & Data Privacy

Vantura is built for production environments where data privacy is paramount.

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
