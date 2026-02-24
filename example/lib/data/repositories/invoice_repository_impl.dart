import '../../data/database/database_helper.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/invoice_repository.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final DatabaseHelper _databaseHelper;

  InvoiceRepositoryImpl(this._databaseHelper);

  @override
  Future<List<Invoice>> getInvoices() async {
    return await _databaseHelper.getInvoices();
  }

  @override
  Future<Invoice?> getInvoice(int id) async {
    return await _databaseHelper.getInvoice(id);
  }

  @override
  Future<int> insertInvoice(Invoice invoice) async {
    return await _databaseHelper.insertInvoice(invoice);
  }

  @override
  Future<int> updateInvoice(Invoice invoice) async {
    return await _databaseHelper.updateInvoice(invoice);
  }

  @override
  Future<int> deleteInvoice(int id) async {
    return await _databaseHelper.deleteInvoice(id);
  }
}
