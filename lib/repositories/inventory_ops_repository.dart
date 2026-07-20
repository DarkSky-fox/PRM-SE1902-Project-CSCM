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

  Future<bool> createTransferRequest({
    required int fromStoreId,
    required int toStoreId,
    required int productId,
    required int quantity,
    required int requestedByEmployeeId,
  }) async {
    return await DatabaseHelper.instance.createTransferRequest(
      fromStoreId: fromStoreId,
      toStoreId: toStoreId,
      productId: productId,
      quantity: quantity,
      requestedByEmployeeId: requestedByEmployeeId,
    );
  }

  Future<List<Map<String, dynamic>>> getTransferRequestsForManager(
    int storeId,
  ) async {
    return await DatabaseHelper.instance.getTransferRequestsForManager(storeId);
  }

  Future<List<Map<String, dynamic>>> getTransferRequestsForStaff(
    int employeeId,
  ) async {
    return await DatabaseHelper.instance.getTransferRequestsForStaff(employeeId);
  }

  Future<String> reviewTransferRequest({
    required int transferId,
    required int managerEmployeeId,
    required bool approve,
  }) async {
    return await DatabaseHelper.instance.reviewTransferRequest(
      transferId: transferId,
      managerEmployeeId: managerEmployeeId,
      approve: approve,
    );
  }
}
