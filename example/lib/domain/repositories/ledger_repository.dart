import '../../domain/entities/ledger_entry.dart';

abstract class LedgerRepository {
  Future<List<LedgerEntry>> getLedgerEntries();
  Future<LedgerEntry?> getLedgerEntry(int id);
  Future<int> insertLedgerEntry(LedgerEntry entry);
  Future<int> updateLedgerEntry(LedgerEntry entry);
  Future<int> deleteLedgerEntry(int id);
  Future<int> deleteLedgerEntryByInvoiceId(int invoiceId);
  Future<double> getTotalIncome();
  Future<double> getTotalExpenses();
}
