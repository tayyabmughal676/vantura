import '../../data/database/database_helper.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../domain/repositories/ledger_repository.dart';

class LedgerRepositoryImpl implements LedgerRepository {
  final DatabaseHelper _databaseHelper;

  LedgerRepositoryImpl(this._databaseHelper);

  @override
  Future<List<LedgerEntry>> getLedgerEntries() async {
    return await _databaseHelper.getLedgerEntries();
  }

  @override
  Future<LedgerEntry?> getLedgerEntry(int id) async {
    return await _databaseHelper.getLedgerEntry(id);
  }

  @override
  Future<int> insertLedgerEntry(LedgerEntry entry) async {
    return await _databaseHelper.insertLedgerEntry(entry);
  }

  @override
  Future<int> updateLedgerEntry(LedgerEntry entry) async {
    return await _databaseHelper.updateLedgerEntry(entry);
  }

  @override
  Future<int> deleteLedgerEntry(int id) async {
    return await _databaseHelper.deleteLedgerEntry(id);
  }

  @override
  Future<int> deleteLedgerEntryByInvoiceId(int invoiceId) async {
    return await _databaseHelper.deleteLedgerEntryByInvoiceId(invoiceId);
  }

  @override
  Future<double> getTotalIncome() async {
    return await _databaseHelper.getTotalIncome();
  }

  @override
  Future<double> getTotalExpenses() async {
    return await _databaseHelper.getTotalExpenses();
  }
}
