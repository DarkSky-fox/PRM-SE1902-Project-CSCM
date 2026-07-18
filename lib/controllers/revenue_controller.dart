import '../repositories/invoice_repository.dart';

class RevenueController {
  final InvoiceRepository _invoiceRepository = InvoiceRepository();

  Future<List<Map<String, dynamic>>> loadRevenueReport({
    required int roleId,
    required int? storeId,
    required String selectedPeriod,
  }) async {
    final storeFilter = roleId == 1 ? null : storeId;
    return await _invoiceRepository.getRevenue(storeFilter, selectedPeriod);
  }
}
