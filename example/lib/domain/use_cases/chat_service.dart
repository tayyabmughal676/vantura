import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/utils/logger.dart';
import '../../data/database/database_helper.dart';
import '../../data/database/persistent_memory_impl.dart';
import '../../domain/repositories/client_repository.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/repositories/ledger_repository.dart';
import '../tools/business_tools.dart';
import '../tools/navigation_tool.dart';
import 'package:vantura/core/index.dart';
import 'package:vantura/tools/index.dart';

/// Manages the lifecycle of a [VanturaAgent], bridging the SDK layer
/// with the app's business tools and navigation.
class ChatService {
  late final VanturaAgent _agent;
  final Function(String, Map<String, dynamic>?)? onNavigate;
  final Function()? onRefresh;

  final ClientRepository _clientRepository;
  final InventoryRepository _inventoryRepository;
  final InvoiceRepository _invoiceRepository;
  final LedgerRepository _ledgerRepository;

  final _initCompleter = Completer<void>();

  ChatService({
    required ClientRepository clientRepository,
    required InventoryRepository inventoryRepository,
    required InvoiceRepository invoiceRepository,
    required LedgerRepository ledgerRepository,
    this.onNavigate,
    this.onRefresh,
  }) : _clientRepository = clientRepository,
       _inventoryRepository = inventoryRepository,
       _invoiceRepository = invoiceRepository,
       _ledgerRepository = ledgerRepository {
    _initializeAgent();
  }

  Future<void> get initialization => _initCompleter.future;

  void dispose() {
    _agent.client.close();
  }

  Future<void> _initializeAgent() async {
    appLogger.info('Initializing ChatService agent', tag: 'SERVICE');

    final state = VanturaState();
    final client = VanturaClient(
      apiKey: dotenv.env['GROQ_API_KEY'] ?? '',
      baseUrl: dotenv.env['BASE_URL'] ?? '',
      model: dotenv.env['MODEL'] ?? '',
    );

    final dbHelper = DatabaseHelper();
    final persistence = PersistentMemoryImpl(dbHelper);
    final memory = VanturaMemory(appLogger, client, persistence: persistence);
    await memory.init();

    final tools = <VanturaTool<dynamic>>[
      ...getStandardTools(),
      CreateClientTool(_clientRepository),
      ListClientsTool(_clientRepository),
      UpdateClientTool(_clientRepository),
      DeleteClientTool(_clientRepository),
      CreateInventoryItemTool(_inventoryRepository),
      ListInventoryTool(_inventoryRepository),
      UpdateInventoryItemTool(_inventoryRepository),
      DeleteInventoryItemTool(_inventoryRepository),
      CreateInvoiceTool(_clientRepository, _invoiceRepository),
      ListInvoicesTool(_invoiceRepository),
      UpdateInvoiceStatusTool(_invoiceRepository, _inventoryRepository),
      DeleteInvoiceTool(_invoiceRepository),
      CreateLedgerEntryTool(_ledgerRepository),
      ListLedgerEntriesTool(_ledgerRepository),
      DeleteLedgerEntryTool(_ledgerRepository),
      GetStatsTool(_ledgerRepository, _inventoryRepository, _clientRepository),
      NavigationTool(
        onNavigate: (screen, params) => onNavigate?.call(screen, params),
      ),
    ];

    _agent = VanturaAgent(
      instructions: '''
You are the Vantura Business Assistant, an expert AI agent designed to help shop owners manage their business efficiently.
Your goal is to perform operations like managing clients, tracking inventory, creating invoices, and providing business insights.

CAPABILITIES:
1. CLIENTS: You can add, list, update (edit), and delete clients.
2. INVENTORY: You can add products, list stock, update item details/shelf counts, and delete items.
3. INVOICING: You can create invoices/quotes, list them, update status (e.g. mark paid), and delete them.
4. LEDGERS: You can record manual transactions (income/expense), list the financial ledger, and delete entries.
5. ANALYTICS: You can provide a financial overview including total income, expenses, and low-stock alerts.
6. NAVIGATION: Process navigation requests by mapping user keywords to the internal routes listed in the ROUTING DICTIONARY below.
7. SYSTEM: You can also use system tools like calculator, connectivity checks, and device info if needed.

ROUTING DICTIONARY (User Term -> Target Screen):
- "home", "dashboard", "main" -> "dashboard" (internal route: /)
- "clients", "customers", "contacts" -> "clients" (internal route: /clients)
- "add client", "new client" -> "clients/add" (internal route: /clients/add)
- "inventory", "products", "stock" -> "inventory" (internal route: /inventory)
- "add product", "new item" -> "inventory/add" (internal route: /inventory/add)
- "invoices", "billing", "payments", "quotes" -> "invoicing" (internal route: /invoicing)
- "create invoice", "new quote" -> "invoicing/create" (internal route: /invoicing/create)
- "ledgers", "accounting", "transactions", "balance" -> "ledgers" (internal route: /ledgers)
- "add transaction", "new entry" -> "ledgers/add" (internal route: /ledgers/add)
- "chat", "messages" -> "chat" (internal route: /chat)

GUIDELINES:
- Be concise and professional.
- Data Mapping: If the user says "invoice", map it to the "invoicing" screen as per the dictionary.
- Human-in-the-Loop: For SENSITIVE operations (delete, update, manual ledger entry), you MUST explicitly ask the user for permission. Explain exactly what you are about to change or delete.
- Message Formatting: Use Markdown headers (###), bold text (**), and lists (-) to present information clearly. For inventory or client lists, always use a structured markdown format.
- If a user asks to "add a client", ask for missing details like phone or email if not provided.
- If a user asks for "stats" or "how is my business doing", use the get_business_stats tool.
- Always confirm when an action (like creating an invoice or deleting a client) is successful.
''',
      memory: memory,
      state: state,
      tools: tools,
      client: client,
      onToolError: (toolName, error, stackTrace) {
        appLogger.error(
          'Tool execution failed in agent',
          tag: 'SERVICE',
          error: error,
          stackTrace: stackTrace,
          extra: {'tool_name': toolName},
        );
      },
      onAgentFailure: (error, stackTrace) {
        appLogger.error(
          'Agent execution critically failed',
          tag: 'SERVICE',
          error: error,
          stackTrace: stackTrace,
        );
      },
      onWarning: (warning) {
        appLogger.warning(
          'Agent runtime warning',
          tag: 'SERVICE',
          extra: {'warning_message': warning},
        );
      },
    );

    appLogger.info(
      'ChatService agent initialized',
      tag: 'SERVICE',
      extra: {'tool_count': tools.length, 'model': client.model},
    );

    _initCompleter.complete();
  }

  /// Streams the agent's response token-by-token.
  Stream<String> streamMessage(
    String message, {
    CancellationToken? cancellationToken,
    void Function(TokenUsage)? onUsage,
  }) async* {
    await initialization;

    appLogger.logUserAction(
      'stream_message_via_service',
      parameters: {'message_length': message.length},
    );

    try {
      final stream = _agent.runStreaming(
        message,
        cancellationToken: cancellationToken,
      );

      await for (final response in stream) {
        if (response.textChunk != null) {
          yield response.textChunk!;
        }

        if (response.text != null) {
          yield response.text!;
        }

        if (response.usage != null) {
          onUsage?.call(response.usage!);
        }

        // If tools are called during the streaming run, refresh the UI
        if (response.toolCalls != null && response.toolCalls!.isNotEmpty) {
          onRefresh?.call();
        }
      }
    } catch (e, stackTrace) {
      appLogger.error(
        'Error in ChatService streaming',
        tag: 'SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Sends a message and waits for the full response.
  Future<String> sendMessage(
    String message, {
    CancellationToken? cancellationToken,
    void Function(TokenUsage)? onUsage,
  }) async {
    await initialization;

    appLogger.logUserAction(
      'send_message_via_service',
      parameters: {'message_length': message.length},
    );

    final stopwatch = Stopwatch()..start();

    try {
      appLogger.info(
        'Processing message via ChatService',
        tag: 'SERVICE',
        extra: {'message_length': message.length},
      );

      final response = await _agent.run(
        message,
        cancellationToken: cancellationToken,
      );

      if (response.usage != null) {
        onUsage?.call(response.usage!);
      }

      // check if any tool was called, if so, trigger a refresh
      if (response.toolCalls != null && response.toolCalls!.isNotEmpty) {
        onRefresh?.call();
        appLogger.info(
          'Tool calls detected, triggering UI refresh',
          tag: 'SERVICE',
        );
      }

      if (response.text != null) {
        appLogger.debug(
          'Service response received',
          tag: 'SERVICE',
          extra: {'response_length': response.text!.length},
        );
        return response.text!;
      } else {
        appLogger.warning('Service returned null response', tag: 'SERVICE');
        return 'No response from agent';
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      appLogger.error(
        'Error in ChatService message processing',
        tag: 'SERVICE',
        error: e,
        stackTrace: stackTrace,
        extra: {
          'message_length': message.length,
          'duration_ms': stopwatch.elapsedMilliseconds,
        },
      );
      rethrow;
    }
  }
}
