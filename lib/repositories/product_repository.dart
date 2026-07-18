import '../services/database_helper.dart';

class ProductRepository {
  Future<List<Map<String, dynamic>>> getProductsList() async {
    return await DatabaseHelper.instance.getProductsList();
  }

  Future<List<Map<String, dynamic>>> getInventoryList(int storeId) async {
    return await DatabaseHelper.instance.getInventoryList(storeId);
  }

  Future<bool> auditInventory(int storeId, int productId, int actualQty) async {
    return await DatabaseHelper.instance.auditInventory(storeId, productId, actualQty);
  }
}
