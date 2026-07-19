import '../services/database_helper.dart';

class ProductRepository {
  Future<List<Map<String, dynamic>>> getProductsList() async {
    return await DatabaseHelper.instance.getProductsList();
  }

  Future<List<Map<String, dynamic>>> getProductsWithDetail({int? categoryId}) async {
    return await DatabaseHelper.instance.getProductsWithDetail(categoryId: categoryId);
  }

  Future<List<Map<String, dynamic>>> getInventoryList(int storeId) async {
    return await DatabaseHelper.instance.getInventoryList(storeId);
  }

  Future<bool> auditInventory(int storeId, int productId, int actualQty) async {
    return await DatabaseHelper.instance.auditInventory(storeId, productId, actualQty);
  }

  Future<int> insertProduct({
    required String productName,
    int? categoryId,
    int? supplierId,
    String? description,
    String? imageUrl,
  }) async {
    return await DatabaseHelper.instance.insertProduct(
      productName: productName,
      categoryId: categoryId,
      supplierId: supplierId,
      description: description,
      imageUrl: imageUrl,
    );
  }

  Future<int> updateProduct({
    required int productId,
    required String productName,
    int? categoryId,
    int? supplierId,
    String? description,
    String? imageUrl,
  }) async {
    return await DatabaseHelper.instance.updateProduct(
      productId: productId,
      productName: productName,
      categoryId: categoryId,
      supplierId: supplierId,
      description: description,
      imageUrl: imageUrl,
    );
  }

  Future<int> deleteProduct(int productId) async {
    return await DatabaseHelper.instance.deleteProduct(productId);
  }
}
