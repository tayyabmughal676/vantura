import '../../domain/entities/invoice.dart';

abstract class InvoiceRepository {
  Future<List<Invoice>> getInvoices();
  Future<Invoice?> getInvoice(int id);
  Future<int> insertInvoice(Invoice invoice);
  Future<int> updateInvoice(Invoice invoice);
  Future<int> deleteInvoice(int id);
}
