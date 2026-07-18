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

  Future<bool> handleTransfer({
    required int fromStoreId,
    required int toStoreId,
    required int productId,
    required int quantity,
  }) async {
    return await _inventoryOpsRepository.createTransferOrder(
      fromStoreId: fromStoreId,
      toStoreId: toStoreId,
      productId: productId,
      quantity: quantity,
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
