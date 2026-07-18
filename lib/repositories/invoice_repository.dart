import '../services/database_helper.dart';

class InvoiceRepository {
  Future<bool> createInvoice({
    required int storeId,
    required int employeeId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
  }) async {
    return await DatabaseHelper.instance.createInvoice(
      storeId: storeId,
      employeeId: employeeId,
      items: items,
      totalAmount: totalAmount,
    );
  }

  Future<List<Map<String, dynamic>>> getRevenue(int? storeId, String period) async {
    return await DatabaseHelper.instance.getRevenue(storeId, period);
  }
}
