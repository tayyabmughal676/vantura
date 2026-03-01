import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/client.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/ledger_entry.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'vantura_business.db');

    return await openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create clients table
    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create inventory table
    await db.execute('''
      CREATE TABLE inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        lowStockThreshold INTEGER DEFAULT 5,
        category TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Create invoices table
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceNumber TEXT NOT NULL,
        clientId INTEGER,
        clientName TEXT NOT NULL,
        items TEXT NOT NULL,
        subtotal REAL NOT NULL,
        taxRate REAL DEFAULT 0.0,
        taxAmount REAL NOT NULL,
        total REAL NOT NULL,
        status TEXT NOT NULL,
        type TEXT NOT NULL,
        issueDate TEXT NOT NULL,
        dueDate TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (clientId) REFERENCES clients (id)
      )
    ''');

    // Create ledger table
    await db.execute('''
      CREATE TABLE ledger (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        reference TEXT,
        relatedInvoiceId INTEGER,
        relatedClientId INTEGER,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (relatedInvoiceId) REFERENCES invoices (id),
        FOREIGN KEY (relatedClientId) REFERENCES clients (id)
      )
    ''');

    // Create chat_messages table for conversation persistence
    await db.execute('''
      CREATE TABLE chat_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        isSummary INTEGER DEFAULT 0,
        toolCallId TEXT,
        toolCalls TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create agent_checkpoints table for task resumption
    await db.execute('''
      CREATE TABLE agent_checkpoints (
        id INTEGER PRIMARY KEY DEFAULT 1,
        agentName TEXT NOT NULL,
        lastPrompt TEXT NOT NULL,
        checkpointData TEXT NOT NULL,
        isRunning INTEGER DEFAULT 0,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE invoices ADD COLUMN type TEXT NOT NULL DEFAULT "invoice"',
      );
    }
    if (oldVersion < 3) {
      try {
        await db.execute(
          'ALTER TABLE ledger ADD COLUMN relatedInvoiceId INTEGER',
        );
        await db.execute(
          'ALTER TABLE ledger ADD COLUMN relatedClientId INTEGER',
        );
      } catch (e) {
        // Columns might already exist
      }
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE chat_messages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          role TEXT NOT NULL,
          content TEXT NOT NULL,
          isSummary INTEGER DEFAULT 0,
          createdAt TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE chat_messages ADD COLUMN toolCallId TEXT');
      await db.execute('ALTER TABLE chat_messages ADD COLUMN toolCalls TEXT');
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE agent_checkpoints (
          id INTEGER PRIMARY KEY DEFAULT 1,
          agentName TEXT NOT NULL,
          lastPrompt TEXT NOT NULL,
          checkpointData TEXT NOT NULL,
          isRunning INTEGER DEFAULT 0,
          updatedAt TEXT NOT NULL
        )
      ''');
    }
  }

  // Chat Message CRUD operations
  Future<int> insertChatMessage(
    String role,
    String content, {
    bool isSummary = false,
    String? toolCallId,
    List<Map<String, dynamic>>? toolCalls,
  }) async {
    final db = await database;
    return await db.insert('chat_messages', {
      'role': role,
      'content': content,
      'isSummary': isSummary ? 1 : 0,
      'toolCallId': toolCallId,
      'toolCalls': toolCalls != null ? jsonEncode(toolCalls) : null,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getChatMessages() async {
    final db = await database;
    return await db.query('chat_messages', orderBy: 'createdAt ASC');
  }

  Future<void> clearChatHistory() async {
    final db = await database;
    await db.delete('chat_messages');
  }

  // Agent Checkpoint operations
  Future<void> saveCheckpoint(Map<String, dynamic> checkpointJson) async {
    final db = await database;
    await db.insert('agent_checkpoints', {
      'id': 1, // We only keep one active checkpoint for simplicity in example
      'agentName': checkpointJson['agentName'] ?? 'default',
      'lastPrompt': checkpointJson['lastPrompt'] ?? '',
      'checkpointData': jsonEncode(checkpointJson),
      'isRunning': (checkpointJson['isRunning'] as bool? ?? false) ? 1 : 0,
      'updatedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> loadCheckpoint() async {
    final db = await database;
    final maps = await db.query('agent_checkpoints', where: 'id = 1');
    if (maps.isNotEmpty) {
      final jsonStr = maps.first['checkpointData'] as String;
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> clearCheckpoint() async {
    final db = await database;
    await db.delete('agent_checkpoints', where: 'id = 1');
  }

  Future<void> deleteOldMessages(int limit) async {
    final db = await database;
    final messages = await db.query(
      'chat_messages',
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    if (messages.isNotEmpty) {
      final oldestId = messages.last['id'];
      await db.delete(
        'chat_messages',
        where: 'id < ? AND isSummary = 0',
        whereArgs: [oldestId],
      );
    }
  }

  // Client CRUD operations
  Future<int> insertClient(Client client) async {
    final db = await database;
    return await db.insert('clients', client.toMap());
  }

  Future<List<Client>> getClients() async {
    final db = await database;
    final maps = await db.query('clients', orderBy: 'createdAt DESC');
    return maps.map((map) => Client.fromMap(map)).toList();
  }

  Future<Client?> getClient(int id) async {
    final db = await database;
    final maps = await db.query('clients', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Client.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateClient(Client client) async {
    final db = await database;
    return await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<int> deleteClient(int id) async {
    final db = await database;
    return await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  // Inventory CRUD operations
  Future<int> insertInventoryItem(InventoryItem item) async {
    final db = await database;
    return await db.insert('inventory', item.toMap());
  }

  Future<List<InventoryItem>> getInventoryItems() async {
    final db = await database;
    final maps = await db.query('inventory', orderBy: 'name ASC');
    return maps.map((map) => InventoryItem.fromMap(map)).toList();
  }

  Future<InventoryItem?> getInventoryItem(int id) async {
    final db = await database;
    final maps = await db.query('inventory', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return InventoryItem.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateInventoryItem(InventoryItem item) async {
    final db = await database;
    return await db.update(
      'inventory',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteInventoryItem(int id) async {
    final db = await database;
    return await db.delete('inventory', where: 'id = ?', whereArgs: [id]);
  }

  // Invoice CRUD operations
  Future<int> insertInvoice(Invoice invoice) async {
    final db = await database;
    final invoiceMap = invoice.toMap();
    invoiceMap['items'] = jsonEncode(
      invoice.items.map((item) => item.toMap()).toList(),
    );
    return await db.insert('invoices', invoiceMap);
  }

  Future<List<Invoice>> getInvoices() async {
    final db = await database;
    final maps = await db.query('invoices', orderBy: 'createdAt DESC');
    return maps.map((map) {
      final mutableMap = Map<String, dynamic>.from(map);
      mutableMap['items'] = jsonDecode(map['items'] as String);
      return Invoice.fromMap(mutableMap);
    }).toList();
  }

  Future<Invoice?> getInvoice(int id) async {
    final db = await database;
    final maps = await db.query('invoices', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      final mutableMap = Map<String, dynamic>.from(maps.first);
      mutableMap['items'] = jsonDecode(mutableMap['items'] as String);
      return Invoice.fromMap(mutableMap);
    }
    return null;
  }

  Future<int> updateInvoice(Invoice invoice) async {
    final db = await database;
    final invoiceMap = invoice.toMap();
    invoiceMap['items'] = jsonEncode(
      invoice.items.map((item) => item.toMap()).toList(),
    );
    return await db.update(
      'invoices',
      invoiceMap,
      where: 'id = ?',
      whereArgs: [invoice.id],
    );
  }

  Future<int> deleteInvoice(int id) async {
    final db = await database;
    return await db.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }

  // Ledger CRUD operations
  Future<int> insertLedgerEntry(LedgerEntry entry) async {
    final db = await database;
    return await db.insert('ledger', entry.toMap());
  }

  Future<List<LedgerEntry>> getLedgerEntries() async {
    final db = await database;
    final maps = await db.query('ledger', orderBy: 'date DESC');
    return maps.map((map) => LedgerEntry.fromMap(map)).toList();
  }

  Future<LedgerEntry?> getLedgerEntry(int id) async {
    final db = await database;
    final maps = await db.query('ledger', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return LedgerEntry.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateLedgerEntry(LedgerEntry entry) async {
    final db = await database;
    return await db.update(
      'ledger',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteLedgerEntry(int id) async {
    final db = await database;
    return await db.delete('ledger', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteLedgerEntryByInvoiceId(int invoiceId) async {
    final db = await database;
    return await db.delete(
      'ledger',
      where: 'relatedInvoiceId = ?',
      whereArgs: [invoiceId],
    );
  }

  // Analytics methods
  Future<double> getTotalIncome() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM ledger
      WHERE type = 'income'
    ''');
    return (result.first['total'] as double?) ?? 0.0;
  }

  Future<double> getTotalExpenses() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM ledger
      WHERE type = 'expense'
    ''');
    return (result.first['total'] as double?) ?? 0.0;
  }

  Future<int> getLowStockItemsCount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM inventory
      WHERE quantity <= lowStockThreshold
    ''');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> getTotalInventoryItems() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM inventory');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<void> updateStockQuantity(String name, int change) async {
    final db = await database;
    await db.rawUpdate(
      '''
      UPDATE inventory 
      SET quantity = quantity + ? 
      WHERE name = ?
    ''',
      [change, name],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
