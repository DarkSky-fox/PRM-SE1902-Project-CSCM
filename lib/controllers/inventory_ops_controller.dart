import '../repositories/inventory_ops_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/store_repository.dart';

class InventoryOpsController {
  final InventoryOpsRepository _inventoryOpsRepository = InventoryOpsRepository();
  final ProductRepository _productRepository = ProductRepository();
  final StoreRepository _storeRepository = StoreRepository();

  Future<List<Map<String, dynamic>>> loadInventory(int storeId) async {
    return await _productRepository.getInventoryList(storeId);
  }

  Future<List<Map<String, dynamic>>> loadProducts() async {
    return await _productRepository.getProductsList();
  }

  Future<List<Map<String, dynamic>>> loadStores() async {
    return await _storeRepository.getStoresList();
  }

  Future<bool> handleImport({
    required int employeeId,
    required int storeId,
    required int productId,
    required int quantity,
    required double importPrice,
  }) async {
    final List<Map<String, dynamic>> items = [
      {
        'ProductID': productId,
        'Quantity': quantity,
        'ImportPrice': importPrice,
      }
    ];
    return await _inventoryOpsRepository.createPurchaseOrder(
      employeeId: employeeId,
      storeId: storeId,
      items: items,
    );
  }

  Future<bool> handleTransferRequest({
    required int fromStoreId,
    required int toStoreId,
    required int productId,
    required int quantity,
    required int requestedByEmployeeId,
  }) async {
    return await _inventoryOpsRepository.createTransferRequest(
      fromStoreId: fromStoreId,
      toStoreId: toStoreId,
      productId: productId,
      quantity: quantity,
      requestedByEmployeeId: requestedByEmployeeId,
    );
  }

  Future<List<Map<String, dynamic>>> loadManagerTransferRequests(
    int storeId,
  ) async {
    return await _inventoryOpsRepository.getTransferRequestsForManager(storeId);
  }

  Future<List<Map<String, dynamic>>> loadStaffTransferRequests(
    int employeeId,
  ) async {
    return await _inventoryOpsRepository.getTransferRequestsForStaff(employeeId);
  }

  Future<String> reviewTransferRequest({
    required int transferId,
    required int managerEmployeeId,
    required bool approve,
  }) async {
    return await _inventoryOpsRepository.reviewTransferRequest(
      transferId: transferId,
      managerEmployeeId: managerEmployeeId,
      approve: approve,
    );
  }

  Future<bool> handleAudit({
    required int storeId,
    required int productId,
    required int actualQty,
  }) async {
    return await _productRepository.auditInventory(storeId, productId, actualQty);
  }
}
