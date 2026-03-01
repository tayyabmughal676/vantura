import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/database/database_helper.dart';
import '../../data/repositories/client_repository_impl.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../data/repositories/invoice_repository_impl.dart';
import '../../data/repositories/ledger_repository_impl.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../domain/repositories/client_repository.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/repositories/ledger_repository.dart';
import '../../domain/use_cases/chat_service.dart';

part 'business_providers.g.dart';

// Database provider
@riverpod
DatabaseHelper databaseHelper(Ref ref) {
  return DatabaseHelper();
}

@Riverpod(keepAlive: true)
ChatService chatService(Ref ref) {
  final service = ChatService(
    clientRepository: ref.watch(clientRepositoryProvider),
    inventoryRepository: ref.watch(inventoryRepositoryProvider),
    invoiceRepository: ref.watch(invoiceRepositoryProvider),
    ledgerRepository: ref.watch(ledgerRepositoryProvider),
    onRefresh: () {
      // Refresh all business data when agent modifies it
      ref.invalidate(clientsProvider);
      ref.invalidate(inventoryProvider);
      ref.invalidate(invoicesProvider);
      ref.invalidate(ledgerEntriesProvider);
      ref.invalidate(totalIncomeProvider);
      ref.invalidate(totalExpensesProvider);
      ref.invalidate(lowStockCountProvider);
    },
  );

  ref.onDispose(() {
    service.dispose();
  });

  return service;
}

// Repository providers
@riverpod
ClientRepository clientRepository(Ref ref) {
  return ClientRepositoryImpl(ref.watch(databaseHelperProvider));
}

@riverpod
InventoryRepository inventoryRepository(Ref ref) {
  return InventoryRepositoryImpl(ref.watch(databaseHelperProvider));
}

@riverpod
InvoiceRepository invoiceRepository(Ref ref) {
  return InvoiceRepositoryImpl(ref.watch(databaseHelperProvider));
}

@riverpod
LedgerRepository ledgerRepository(Ref ref) {
  return LedgerRepositoryImpl(ref.watch(databaseHelperProvider));
}

// Data Notifiers
@riverpod
class Clients extends _$Clients {
  @override
  FutureOr<List<Client>> build() async {
    return ref.watch(clientRepositoryProvider).getClients();
  }

  Future<void> addClient(Client client) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(clientRepositoryProvider).insertClient(client);
      return ref.read(clientRepositoryProvider).getClients();
    });
  }

  Future<void> updateClient(Client client) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(clientRepositoryProvider).updateClient(client);
      return ref.read(clientRepositoryProvider).getClients();
    });
  }

  Future<void> deleteClient(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(clientRepositoryProvider).deleteClient(id);
      return ref.read(clientRepositoryProvider).getClients();
    });
  }
}

@riverpod
class Inventory extends _$Inventory {
  @override
  FutureOr<List<InventoryItem>> build() async {
    return ref.watch(inventoryRepositoryProvider).getInventoryItems();
  }

  Future<void> addItem(InventoryItem item) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(inventoryRepositoryProvider).insertInventoryItem(item);
      _refreshAnalytics();
      return ref.read(inventoryRepositoryProvider).getInventoryItems();
    });
  }

  Future<void> updateItem(InventoryItem item) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(inventoryRepositoryProvider).updateInventoryItem(item);
      _refreshAnalytics();
      return ref.read(inventoryRepositoryProvider).getInventoryItems();
    });
  }

  Future<void> deleteItem(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(inventoryRepositoryProvider).deleteInventoryItem(id);
      _refreshAnalytics();
      return ref.read(inventoryRepositoryProvider).getInventoryItems();
    });
  }

  void _refreshAnalytics() {
    ref.invalidate(lowStockCountProvider);
    ref.invalidate(totalInventoryCountProvider);
  }
}

@riverpod
class Invoices extends _$Invoices {
  @override
  FutureOr<List<Invoice>> build() async {
    return ref.watch(invoiceRepositoryProvider).getInvoices();
  }

  Future<void> addInvoice(Invoice invoice) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final id = await ref
          .read(invoiceRepositoryProvider)
          .insertInvoice(invoice);

      // Stock management: only for real invoices
      if (invoice.type == InvoiceType.invoice) {
        for (final item in invoice.items) {
          await ref
              .read(inventoryRepositoryProvider)
              .updateStockQuantity(item.description, -item.quantity.toInt());
        }
        ref.invalidate(lowStockCountProvider);
        ref.invalidate(inventoryProvider);
      }

      if (invoice.status == InvoiceStatus.paid) {
        await ref
            .read(ledgerEntriesProvider.notifier)
            .addEntry(
              LedgerEntry(
                description: 'Payment for Invoice ${invoice.invoiceNumber}',
                amount: invoice.total,
                type: TransactionType.income,
                category: 'Sales',
                relatedInvoiceId: id,
                relatedClientId: invoice.clientId,
              ),
            );
      }
      return ref.read(invoiceRepositoryProvider).getInvoices();
    });
  }

  Future<void> updateInvoiceStatus(int id, InvoiceStatus status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final invoice = await ref.read(invoiceRepositoryProvider).getInvoice(id);
      if (invoice != null && invoice.status != status) {
        final updated = invoice.copyWith(status: status);
        await ref.read(invoiceRepositoryProvider).updateInvoice(updated);

        // If changed to PAID, add to ledger if not already there
        if (status == InvoiceStatus.paid) {
          await ref
              .read(ledgerEntriesProvider.notifier)
              .addEntry(
                LedgerEntry(
                  description: 'Payment for Invoice ${invoice.invoiceNumber}',
                  amount: invoice.total,
                  type: TransactionType.income,
                  category: 'Sales',
                  relatedInvoiceId: id,
                  relatedClientId: invoice.clientId,
                ),
              );
        }
      }
      return ref.read(invoiceRepositoryProvider).getInvoices();
    });
  }

  Future<void> convertToInvoice(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final invoice = await ref.read(invoiceRepositoryProvider).getInvoice(id);
      if (invoice != null) {
        final updated = invoice.copyWith(
          type: InvoiceType.invoice,
          status: InvoiceStatus.sent,
          invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
        );
        await ref.read(invoiceRepositoryProvider).updateInvoice(updated);

        // Decrement stock when converting to invoice
        for (final item in invoice.items) {
          await ref
              .read(inventoryRepositoryProvider)
              .updateStockQuantity(item.description, -item.quantity.toInt());
        }
        ref.invalidate(lowStockCountProvider);
        ref.invalidate(inventoryProvider);
      }
      return ref.read(invoiceRepositoryProvider).getInvoices();
    });
  }

  Future<void> deleteInvoice(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // 1. Delete invoice
      await ref.read(invoiceRepositoryProvider).deleteInvoice(id);

      // 2. Cleanup related ledger entries
      await ref.read(ledgerRepositoryProvider).deleteLedgerEntryByInvoiceId(id);
      ref.invalidate(totalIncomeProvider);
      ref.invalidate(totalExpensesProvider);

      return ref.read(invoiceRepositoryProvider).getInvoices();
    });
  }
}

@riverpod
class LedgerEntries extends _$LedgerEntries {
  @override
  FutureOr<List<LedgerEntry>> build() async {
    return ref.watch(ledgerRepositoryProvider).getLedgerEntries();
  }

  Future<void> addEntry(LedgerEntry entry) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(ledgerRepositoryProvider).insertLedgerEntry(entry);
      _refreshAnalytics();
      return ref.read(ledgerRepositoryProvider).getLedgerEntries();
    });
  }

  Future<void> deleteEntry(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(ledgerRepositoryProvider).deleteLedgerEntry(id);
      _refreshAnalytics();
      return ref.read(ledgerRepositoryProvider).getLedgerEntries();
    });
  }

  void _refreshAnalytics() {
    ref.invalidate(totalIncomeProvider);
    ref.invalidate(totalExpensesProvider);
  }
}

// Analytics
@riverpod
Future<double> totalIncome(Ref ref) {
  return ref.watch(ledgerRepositoryProvider).getTotalIncome();
}

@riverpod
Future<double> totalExpenses(Ref ref) {
  return ref.watch(ledgerRepositoryProvider).getTotalExpenses();
}

@riverpod
Future<int> lowStockCount(Ref ref) {
  return ref.watch(inventoryRepositoryProvider).getLowStockItemsCount();
}

@riverpod
Future<int> totalInventoryCount(Ref ref) {
  return ref.watch(inventoryRepositoryProvider).getTotalItemsCount();
}
