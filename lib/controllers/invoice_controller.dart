import '../repositories/invoice_repository.dart';

class InvoiceController {
  final _repository = InvoiceRepository();

  Future<List<Map<String, dynamic>>> loadInvoices([int? storeId]) async {
    try {
      return await _repository.getInvoices(storeId);
    } catch (e) {
      print('Error loading invoices: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> loadInvoiceDetails(int invoiceId) async {
    try {
      return await _repository.getInvoiceDetails(invoiceId);
    } catch (e) {
      print('Error loading invoice details: $e');
      return [];
    }
  }
}
