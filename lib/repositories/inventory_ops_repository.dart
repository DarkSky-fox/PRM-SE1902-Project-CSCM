import '../services/database_helper.dart';

class InventoryOpsRepository {
  Future<bool> createPurchaseOrder({
    required int employeeId,
    required int storeId,
    required List<Map<String, dynamic>> items,
  }) async {
    return await DatabaseHelper.instance.createPurchaseOrder(
      employeeId: employeeId,
      storeId: storeId,
      items: items,
    );
  }

  Future<bool> createTransferOrder({
    required int fromStoreId,
    required int toStoreId,
    required int productId,
    required int quantity,
  }) async {
    return await DatabaseHelper.instance.createTransferOrder(
      fromStoreId: fromStoreId,
      toStoreId: toStoreId,
      productId: productId,
      quantity: quantity,
    );
  }
}
