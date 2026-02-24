import '../../domain/entities/client.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../domain/repositories/client_repository.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/repositories/ledger_repository.dart';
import 'package:vantura/core/index.dart';

/// Tools for managing business data.
/// These tools allow the agent to interact with clients, inventory, and invoices.

// --- CLIENT TOOLS ---

class CreateClientArgs {
  final String name;
  final String email;
  final String phone;
  final String? address;

  CreateClientArgs({
    required this.name,
    required this.email,
    required this.phone,
    this.address,
  });

  factory CreateClientArgs.fromJson(Map<String, dynamic> json) {
    return CreateClientArgs(
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String?,
    );
  }
}

class CreateClientTool extends VanturaTool<CreateClientArgs> {
  final ClientRepository repository;

  CreateClientTool(this.repository);

  @override
  String get name => 'create_client';

  @override
  String get description => 'Adds a new client to the database';

  @override
  Map<String, dynamic> get parameters => SchemaHelper.generateSchema(
    {
      'name': SchemaHelper.stringProperty(
        description: 'Full name of the client',
      ),
      'email': SchemaHelper.stringProperty(description: 'Email address'),
      'phone': SchemaHelper.stringProperty(description: 'Phone number'),
      'address': SchemaHelper.stringProperty(
        description: 'Mailing address (optional)',
      ),
    },
    required: ['name', 'email', 'phone'],
  );

  @override
  CreateClientArgs parseArgs(Map<String, dynamic> json) =>
      CreateClientArgs.fromJson(json);

  @override
  Future<String> execute(CreateClientArgs args) async {
    try {
      final client = Client(
        name: args.name,
        email: args.email,
        phone: args.phone,
        address: args.address ?? '',
      );
      final id = await repository.insertClient(client);
      return 'Successfully created client "${args.name}" with ID: $id';
    } catch (e) {
      return 'Error creating client: $e';
    }
  }
}

class ListClientsTool extends VanturaTool<NullArgs> {
  final ClientRepository repository;

  ListClientsTool(this.repository);

  @override
  String get name => 'list_clients';

  @override
  String get description => 'Returns a list of all clients in the system';

  @override
  Map<String, dynamic> get parameters => SchemaHelper.emptySchema;

  @override
  NullArgs parseArgs(Map<String, dynamic> json) => const NullArgs();

  @override
  Future<String> execute(NullArgs args) async {
    try {
      final clients = await repository.getClients();
      if (clients.isEmpty) return 'No clients found.';
      return '### Registered Clients\n\n'
          '${clients.map((c) => '**${c.name}**\n- ID: `${c.id}`\n- Email: `${c.email}`\n- Phone: `${c.phone}`').join('\n---\n')}';
    } catch (e) {
      return 'Error listing clients: $e';
    }
  }
}

class UpdateClientArgs {
  final int id;
  final String? name;
  final String? email;
  final String? phone;
  final String? address;

  UpdateClientArgs({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.address,
  });

  factory UpdateClientArgs.fromJson(Map<String, dynamic> json) {
    return UpdateClientArgs(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
    );
  }
}

class UpdateClientTool extends VanturaTool<UpdateClientArgs> {
  final ClientRepository repository;

  UpdateClientTool(this.repository);

  @override
  String get name => 'update_client';

  @override
  String get description => 'Updates an existing client\'s information';

  @override
  bool get requiresConfirmation => true;

  @override
  Map<String, dynamic> get parameters => SchemaHelper.generateSchema(
    {
      'id': SchemaHelper.numberProperty(
        description: 'ID of the client to update',
      ),
      'name': SchemaHelper.stringProperty(description: 'Updated name'),
      'email': SchemaHelper.stringProperty(description: 'Updated email'),
      'phone': SchemaHelper.stringProperty(description: 'Updated phone'),
      'address': SchemaHelper.stringProperty(description: 'Updated address'),
      'confirmed': SchemaHelper.booleanProperty(
        description:
            'Set to true ONLY after the user confirms they want to proceed with this update.',
      ),
    },
    required: ['id'],
  );

  @override
  UpdateClientArgs parseArgs(Map<String, dynamic> json) =>
      UpdateClientArgs.fromJson(json);

  @override
  Future<String> execute(UpdateClientArgs args) async {
    try {
      final client = await repository.getClient(args.id);
      if (client == null) return 'Error: Client with ID ${args.id} not found.';

      final updated = client.copyWith(
        name: args.name,
        email: args.email,
        phone: args.phone,
        address: args.address,
      );
      await repository.updateClient(updated);
      return 'Successfully updated client "${updated.name}" (ID: ${args.id})';
    } catch (e) {
      return 'Error updating client: $e';
    }
  }
}

class DeleteClientArgs {
  final int id;
  DeleteClientArgs({required this.id});
  factory DeleteClientArgs.fromJson(Map<String, dynamic> json) =>
      DeleteClientArgs(id: (json['id'] as num).toInt());
}

class DeleteClientTool extends VanturaTool<DeleteClientArgs> {
  final ClientRepository repository;

  DeleteClientTool(this.repository);

  @override
  String get name => 'delete_client';

  @override
  String get description => 'Removes a client from the database';

  @override
  bool get requiresConfirmation => true;

  @override
  Map<String, dynamic> get parameters => SchemaHelper.generateSchema(
    {
      'id': SchemaHelper.numberProperty(
        description: 'ID of the client to delete',
      ),
      'confirmed': SchemaHelper.booleanProperty(
        description:
            'Set to true ONLY after the user confirms they want to delete this client.',
      ),
    },
    required: ['id'],
  );

  @override
  DeleteClientArgs parseArgs(Map<String, dynamic> json) =>
      DeleteClientArgs.fromJson(json);

  @override
  Future<String> execute(DeleteClientArgs args) async {
    try {
      await repository.deleteClient(args.id);
      return 'Successfully deleted client with ID: ${args.id}';
    } catch (e) {
      return 'Error deleting client: $e';
    }
  }
}

// --- INVENTORY TOOLS ---

class CreateInventoryItemArgs {
  final String name;
  final String description;
  final double price;
  final int quantity;
  final String category;
  final int? lowStockThreshold;

  CreateInventoryItemArgs({
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.category,
    this.lowStockThreshold,
  });

  factory CreateInventoryItemArgs.fromJson(Map<String, dynamic> json) {
    return CreateInventoryItemArgs(
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
      category: json['category'] as String,
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt(),
    );
  }
}

class CreateInventoryItemTool extends VanturaTool<CreateInventoryItemArgs> {
  final InventoryRepository repository;

  CreateInventoryItemTool(this.repository);

  @override
  String get name => 'create_inventory_item';

  @override
  String get description => 'Adds a new item to the inventory';

  @override
  Map<String, dynamic> get parameters => SchemaHelper.generateSchema(
    {
      'name': SchemaHelper.stringProperty(description: 'Name of the product'),
      'description': SchemaHelper.stringProperty(
        description: 'Brief description',
      ),
      'price': SchemaHelper.numberProperty(description: 'Unit price'),
      'quantity': SchemaHelper.numberProperty(
        description: 'Initial stock level',
      ),
      'category': SchemaHelper.stringProperty(
        description: 'Product category (e.g. Electronics, Services)',
      ),
      'lowStockThreshold': SchemaHelper.numberProperty(
        description: 'Threshold for low stock alert (defaults to 5)',
      ),
    },
    required: ['name', 'description', 'price', 'quantity', 'category'],
  );

  @override
  CreateInventoryItemArgs parseArgs(Map<String, dynamic> json) =>
      CreateInventoryItemArgs.fromJson(json);

  @override
  Future<String> execute(CreateInventoryItemArgs args) async {
    try {
      final item = InventoryItem(
        name: args.name,
        description: args.description,
        price: args.price,
        quantity: args.quantity,
        category: args.category,
        lowStockThreshold: args.lowStockThreshold ?? 5,
      );
      final id = await repository.insertInventoryItem(item);
      return 'Successfully added item "${args.name}" to inventory with ID: $id';
    } catch (e) {
      return 'Error adding inventory item: $e';
    }
  }
}

class ListInventoryTool extends VanturaTool<NullArgs> {
  final InventoryRepository repository;

  ListInventoryTool(this.repository);

  @override
  String get name => 'list_inventory';

  @override
  String get description =>
      'Returns all items in the inventory with current stock levels';

  @override
  Map<String, dynamic> get parameters => SchemaHelper.emptySchema;

  @override
  NullArgs parseArgs(Map<String, dynamic> json) => const NullArgs();

  @override
  Future<String> execute(NullArgs args) async {
    try {
      final items = await repository.getInventoryItems();
      if (items.isEmpty) return 'Inventory is empty.';
      return '### Inventory Overview\n\n'
          '${items.map((i) => '**${i.name}**\n- ID: `${i.id}`\n- Stock: `${i.quantity}`\n- Price: `\$${i.price}`\n- Category: *${i.category}*').join('\n---\n')}';
    } catch (e) {
      return 'Error listing inventory: $e';
    }
  }
}

class UpdateInventoryItemArgs {
  final int id;
  final String? name;
  final String? description;
  final double? price;
  final int? quantity;
  final String? category;
  final int? lowStockThreshold;

  UpdateInventoryItemArgs({
    required this.id,
    this.name,
    this.description,
    this.price,
    this.quantity,
    this.category,
    this.lowStockThreshold,
  });

  factory UpdateInventoryItemArgs.fromJson(Map<String, dynamic> json) {
    return UpdateInventoryItemArgs(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String?,
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      quantity: (json['quantity'] as num?)?.toInt(),
      category: json['category'] as String?,
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt(),
    );
  }
}

class UpdateInventoryItemTool extends VanturaTool<UpdateInventoryItemArgs> {
  final InventoryRepository repository;

  UpdateInventoryItemTool(this.repository);

  @override
  String get name => 'update_inventory_item';

  @override
  String get description => 'Updates an existing inventory item';

  @override
  bool get requiresConfirmation => true;

  @override
  Map<String, dynamic> get parameters => SchemaHelper.generateSchema(
    {
      'id': SchemaHelper.numberProperty(
        description: 'ID of the item to update',
      ),
      'name': SchemaHelper.stringProperty(description: 'Updated name'),
      'description': SchemaHelper.stringProperty(
        description: 'Updated description',
      ),
      'price': SchemaHelper.numberProperty(description: 'Updated price'),
      'quantity': SchemaHelper.numberProperty(
        description: 'Updated stock level',
      ),
      'category': SchemaHelper.stringProperty(description: 'Updated category'),
      'lowStockThreshold': SchemaHelper.numberProperty(
        description: 'Updated low stock alert threshold',
      ),
      'confirmed': SchemaHelper.booleanProperty(
        description:
            'Set to true ONLY after the user confirms they want to update this item.',
      ),
    },
    required: ['id'],
  );

  @override
  UpdateInventoryItemArgs parseArgs(Map<String, dynamic> json) =>
      UpdateInventoryItemArgs.fromJson(json);

  @override
  Future<String> execute(UpdateInventoryItemArgs args) async {
    try {
      final item = await repository.getInventoryItem(args.id);
      if (item == null) return 'Error: Item with ID ${args.id} not found.';

      final updated = item.copyWith(
        name: args.name,
        description: args.description,
        price: args.price,
        quantity: args.quantity,
        category: args.category,
        lowStockThreshold: args.lowStockThreshold,
      );
      await repository.updateInventoryItem(updated);
      return 'Successfully updated item "${updated.name}" (ID: ${args.id})';
    } catch (e) {
      return 'Error updating inventory item: $e';
    }
  }
}

class DeleteInventoryItemArgs {
  final int id;
  DeleteInventoryItemArgs({required this.id});
  factory DeleteInventoryItemArgs.fromJson(Map<String, dynamic> json) =>
      DeleteInventoryItemArgs(id: (json['id'] as num).toInt());
}

class DeleteInventoryItemTool extends VanturaTool<DeleteInventoryItemArgs> {
  final InventoryRepository repository;

  DeleteInventoryItemTool(this.repository);

  @override
  String get name => 'delete_inventory_item';

  @override
  String get description => 'Removes an item from the inventory';

  @override
  bool get requiresConfirmation => true;

  @override
  Map<String, dynamic> get parameters => SchemaHelper.generateSchema(
    {
      'id': SchemaHelper.numberProperty(
        description: 'ID of the item to delete',
      ),
      'confirmed': SchemaHelper.booleanProperty(
        description:
            'Set to true ONLY after the user confirms they want to delete this item.',
      ),
    },
    required: ['id'],
  );

  @override
  DeleteInventoryItemArgs parseArgs(Map<String, dynamic> json) =>
      DeleteInventoryItemArgs.fromJson(json);

  @override
  Future<String> execute(DeleteInventoryItemArgs args) async {
    try {
      await repository.deleteInventoryItem(args.id);
      return 'Successfully deleted inventory item with ID: ${args.id}';
    } catch (e) {
      return 'Error deleting inventory item: $e';
    }
  }
}

// --- INVOICE TOOLS ---

class CreateInvoiceArgs {
  final int clientId;
  final List<Map<String, dynamic>> items;
  final double taxRate;
  final String? notes;
  final String type; // 'invoice' or 'quote'

  CreateInvoiceArgs({
    required this.clientId,
    required this.items,
    this.taxRate = 0.0,
    this.notes,
    required this.type,
  });

  factory CreateInvoiceArgs.fromJson(Map<String, dynamic> json) {
    return CreateInvoiceArgs(
      clientId: (json['clientId'] as num).toInt(),
      items: List<Map<String, dynamic>>.from(json['items']),
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      type: json['type'] as String? ?? 'invoice',
    );
  }
}

class CreateInvoiceTool extends VanturaTool<CreateInvoiceArgs> {
  final ClientRepository clientRepository;
  final InvoiceRepository invoiceRepository;

  CreateInvoiceTool(this.clientRepository, this.invoiceRepository);

  @override
  String get name => 'create_invoice_or_quote';

  @override
  String get description => 'Creates a new invoice or quotation for a client';

  @override
  Map<String, dynamic> get parameters => SchemaHelper.generateSchema(
    {
      'clientId': SchemaHelper.numberProperty(description: 'ID of the client'),
      'type': SchemaHelper.stringProperty(
        description: 'Type of document',
        enumValues: ['invoice', 'quote'],
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
      'taxRate': SchemaHelper.numberProperty(
        description: 'Tax rate percentage (e.g. 5.0 for 5%)',
      ),
      'notes': SchemaHelper.stringProperty(description: 'Additional notes'),
    },
    required: ['clientId', 'items', 'type'],
  );

  @override
  CreateInvoiceArgs parseArgs(Map<String, dynamic> json) =>
      CreateInvoiceArgs.fromJson(json);

  @override
  Future<String> execute(CreateInvoiceArgs args) async {
    try {
      final client = await clientRepository.getClient(args.clientId);
      if (client == null) {
        return 'Error: Client with ID ${args.clientId} not found.';
      }

      final invoiceItems = args.items
          .map(
            (it) => InvoiceItem(
              description: it['description'] as String,
              quantity: (it['quantity'] as num).toInt(),
              unitPrice: (it['unitPrice'] as num).toDouble(),
            ),
          )
          .toList();

      final subtotal = invoiceItems.fold<double>(
        0,
        (sum, item) => sum + item.total,
      );

      final invoice = Invoice(
        invoiceNumber:
            '${args.type.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}',
        clientId: client.id,
        clientName: client.name,
        items: invoiceItems,
        subtotal: subtotal,
        taxRate: args.taxRate / 100,
        notes: args.notes ?? '',
        status: InvoiceStatus.draft,
        type: args.type == 'quote' ? InvoiceType.quote : InvoiceType.invoice,
      );

      final id = await invoiceRepository.insertInvoice(invoice);
      return 'Successfully created ${args.type} with ID: $id and Number: ${invoice.invoiceNumber}';
    } catch (e) {
      return 'Error creating ${args.type}: $e';
    }
  }
}

class ListInvoicesTool extends VanturaTool<NullArgs> {
  final InvoiceRepository repository;

  ListInvoicesTool(this.repository);

  @override
  String get name => 'list_invoices';

  @override
  String get description => 'Returns a list of all invoices and quotations';

  @override
  Map<String, dynamic> get parameters => SchemaHelper.emptySchema;

  @override
  NullArgs parseArgs(Map<String, dynamic> json) => const NullArgs();

  @override
  Future<String> execute(NullArgs args) async {
    try {
      final invoices = await repository.getInvoices();
      if (invoices.isEmpty) return 'No invoices found.';
      return '### Invoices & Quotations\n\n'
          '${invoices.map((i) => '**${i.invoiceNumber}**\n- ID: `${i.id}`\n- Client: *${i.clientName}*\n- Total: `\$${i.total.toStringAsFixed(2)}`\n- Status: `${i.status.name.toUpperCase()}`').join('\n---\n')}';
    } catch (e) {
      return 'Error listing invoices: $e';
    }
  }
}

class UpdateInvoiceStatusArgs {
  final int invoiceId;
  final String status;

  UpdateInvoiceStatusArgs({required this.invoiceId, required this.status});

  factory UpdateInvoiceStatusArgs.fromJson(Map<String, dynamic> json) {
    return UpdateInvoiceStatusArgs(
      invoiceId: (json['invoiceId'] as num).toInt(),
      status: json['status'] as String,
    );
  }
}

class UpdateInvoiceStatusTool extends VanturaTool<UpdateInvoiceStatusArgs> {
  final InvoiceRepository invoiceRepository;
  final InventoryRepository inventoryRepository;

  UpdateInvoiceStatusTool(this.invoiceRepository, this.inventoryRepository);

  @override
  String get name => 'update_invoice_status';

  @override
  String get description =>
      'Updates the status of an existing invoice (e.g. mark it as paid)';

  @override
  bool get requiresConfirmation => true;

  @override
  Map<String, dynamic> get parameters => SchemaHelper.generateSchema(
    {
      'invoiceId': SchemaHelper.numberProperty(
        description: 'ID of the invoice to update',
      ),
      'status': SchemaHelper.stringProperty(
        description: 'New status',
        enumValues: ['draft', 'sent', 'paid', 'overdue', 'cancelled'],
      ),
      'confirmed': SchemaHelper.booleanProperty(
        description:
            'Set to true ONLY after the user confirms they want to update the invoice status.',
      ),
    },
    required: ['invoiceId', 'status'],
  );

  @override
  UpdateInvoiceStatusArgs parseArgs(Map<String, dynamic> json) =>
      UpdateInvoiceStatusArgs.fromJson(json);

  @override
  Future<String> execute(UpdateInvoiceStatusArgs args) async {
    try {
      final invoice = await invoiceRepository.getInvoice(args.invoiceId);
      if (invoice == null) {
        return 'Error: Invoice with ID ${args.invoiceId} not found.';
      }

      final newStatus = InvoiceStatus.values.firstWhere(
        (e) => e.name == args.status,
        orElse: () => invoice.status,
      );
      final updated = invoice.copyWith(status: newStatus);
      await invoiceRepository.updateInvoice(updated);

      // If status changed to PAID, decrement inventory stock
      if (newStatus == InvoiceStatus.paid &&
          invoice.status != InvoiceStatus.paid) {
        for (var item in invoice.items) {
          await inventoryRepository.updateStockQuantity(
            item.description,
            -item.quantity.toInt(),
          );
        }
      }

      return 'Successfully updated invoice ${invoice.invoiceNumber} to ${args.status}';
    } catch (e) {
      return 'Error updating invoice: $e';
    }
  }
}

class DeleteInvoiceArgs {
  final int id;
  DeleteInvoiceArgs({required this.id});
  factory DeleteInvoiceArgs.fromJson(Map<String, dynamic> json) =>
      DeleteInvoiceArgs(id: (json['id'] as num).toInt());
}

class DeleteInvoiceTool extends VanturaTool<DeleteInvoiceArgs> {
  final InvoiceRepository repository;

  DeleteInvoiceTool(this.repository);

  @override
  String get name => 'delete_invoice';

  @override
  String get description => 'Removes an invoice from the database';

  @override
  bool get requiresConfirmation => true;

  @override
  Map<String, dynamic> get parameters => SchemaHelper.generateSchema(
    {
      'id': SchemaHelper.numberProperty(
        description: 'ID of the invoice to delete',
      ),
      'confirmed': SchemaHelper.booleanProperty(
        description:
            'Set to true ONLY after the user confirms they want to delete this invoice.',
      ),
    },
    required: ['id'],
  );

  @override
  DeleteInvoiceArgs parseArgs(Map<String, dynamic> json) =>
      DeleteInvoiceArgs.fromJson(json);

  @override
  Future<String> execute(DeleteInvoiceArgs args) async {
    try {
      await repository.deleteInvoice(args.id);
      return 'Successfully deleted invoice with ID: ${args.id}';
    } catch (e) {
      return 'Error deleting invoice: $e';
    }
  }
}

// --- ANALYTICS TOOLS ---

class GetStatsTool extends VanturaTool<NullArgs> {
  final LedgerRepository ledgerRepository;
  final InventoryRepository inventoryRepository;
  final ClientRepository clientRepository;

  GetStatsTool(
    this.ledgerRepository,
    this.inventoryRepository,
    this.clientRepository,
  );

  @override
  String get name => 'get_business_stats';

  @override
  String get description =>
      'Returns key business metrics like income, expenses, and low stock items';

  @override
  Map<String, dynamic> get parameters => SchemaHelper.emptySchema;

  @override
  NullArgs parseArgs(Map<String, dynamic> json) => const NullArgs();

  @override
  Future<String> execute(NullArgs args) async {
    try {
      final income = await ledgerRepository.getTotalIncome();
      final expenses = await ledgerRepository.getTotalExpenses();
      final lowStock = await inventoryRepository.getLowStockItemsCount();
      final clients = await clientRepository.getClients();

      return '''
BUSINESS STATUS OVERVIEW:
- Total Income: \$${income.toStringAsFixed(2)}
- Total Expenses: \$${expenses.toStringAsFixed(2)}
- Net Profit: \$${(income - expenses).toStringAsFixed(2)}
- Total Clients: ${clients.length}
- Low Stock Alerts: $lowStock
''';
    } catch (e) {
      return 'Error fetching stats: $e';
    }
  }
}

// --- LEDGER TOOLS ---

class CreateLedgerEntryArgs {
  final String description;
  final double amount;
  final String type; // income, expense, asset, liability
  final String category;
  final String? reference;

  CreateLedgerEntryArgs({
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    this.reference,
  });

  factory CreateLedgerEntryArgs.fromJson(Map<String, dynamic> json) {
    return CreateLedgerEntryArgs(
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      category: json['category'] as String,
      reference: json['reference'] as String?,
    );
  }
}

class CreateLedgerEntryTool extends VanturaTool<CreateLedgerEntryArgs> {
  final LedgerRepository repository;

  CreateLedgerEntryTool(this.repository);

  @override
  String get name => 'create_ledger_entry';

  @override
  String get description => 'Adds a new transaction to the financial ledger';

  @override
  bool get requiresConfirmation => true;

  @override
  Map<String, dynamic> get parameters => SchemaHelper.generateSchema(
    {
      'description': SchemaHelper.stringProperty(
        description: 'What was this for?',
      ),
      'amount': SchemaHelper.numberProperty(description: 'Transaction amount'),
      'type': SchemaHelper.stringProperty(
        description: 'Transaction type',
        enumValues: ['income', 'expense', 'asset', 'liability'],
      ),
      'category': SchemaHelper.stringProperty(
        description: 'Category (e.g. Sales, Rent)',
      ),
      'reference': SchemaHelper.stringProperty(
        description: 'Optional reference marker',
      ),
      'confirmed': SchemaHelper.booleanProperty(
        description:
            'Set to true ONLY after the user confirms they want to create this transaction.',
      ),
    },
    required: ['description', 'amount', 'type', 'category'],
  );

  @override
  CreateLedgerEntryArgs parseArgs(Map<String, dynamic> json) =>
      CreateLedgerEntryArgs.fromJson(json);

  @override
  Future<String> execute(CreateLedgerEntryArgs args) async {
    try {
      final entry = LedgerEntry(
        description: args.description,
        amount: args.amount,
        type: TransactionType.values.firstWhere((e) => e.name == args.type),
        category: args.category,
        reference: args.reference,
      );
      final id = await repository.insertLedgerEntry(entry);
      return 'Successfully added ledger entry with ID: $id';
    } catch (e) {
      return 'Error creating ledger entry: $e';
    }
  }
}

class ListLedgerEntriesTool extends VanturaTool<NullArgs> {
  final LedgerRepository repository;

  ListLedgerEntriesTool(this.repository);

  @override
  String get name => 'list_ledger_entries';

  @override
  String get description => 'Returns all recent ledger transactions';

  @override
  Map<String, dynamic> get parameters => SchemaHelper.emptySchema;

  @override
  NullArgs parseArgs(Map<String, dynamic> json) => const NullArgs();

  @override
  Future<String> execute(NullArgs args) async {
    try {
      final entries = await repository.getLedgerEntries();
      if (entries.isEmpty) return 'No ledger entries found.';
      return '### Financial Ledger\n\n'
          '${entries.map((e) => '**${e.type.name.toUpperCase()}** | `\$${e.amount}`\n- ID: `${e.id}`\n- Date: *${e.date.toIso8601String().substring(0, 10)}*\n- Description: ${e.description}').join('\n---\n')}';
    } catch (e) {
      return 'Error listing ledger entries: $e';
    }
  }
}

class DeleteLedgerEntryArgs {
  final int id;
  DeleteLedgerEntryArgs({required this.id});
  factory DeleteLedgerEntryArgs.fromJson(Map<String, dynamic> json) =>
      DeleteLedgerEntryArgs(id: (json['id'] as num).toInt());
}

class DeleteLedgerEntryTool extends VanturaTool<DeleteLedgerEntryArgs> {
  final LedgerRepository repository;

  DeleteLedgerEntryTool(this.repository);

  @override
  String get name => 'delete_ledger_entry';

  @override
  String get description => 'Removes a transaction from the ledger';

  @override
  bool get requiresConfirmation => true;

  @override
  Map<String, dynamic> get parameters => SchemaHelper.generateSchema(
    {
      'id': SchemaHelper.numberProperty(
        description: 'ID of the entry to delete',
      ),
      'confirmed': SchemaHelper.booleanProperty(
        description:
            'Set to true ONLY after the user confirms they want to delete this ledger entry.',
      ),
    },
    required: ['id'],
  );

  @override
  DeleteLedgerEntryArgs parseArgs(Map<String, dynamic> json) =>
      DeleteLedgerEntryArgs.fromJson(json);

  @override
  Future<String> execute(DeleteLedgerEntryArgs args) async {
    try {
      await repository.deleteLedgerEntry(args.id);
      return 'Successfully deleted ledger entry with ID: ${args.id}';
    } catch (e) {
      return 'Error deleting ledger entry: $e';
    }
  }
}
