import '../repositories/product_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/supplier_repository.dart';

class ProductController {
  final _productRepo = ProductRepository();
  final _categoryRepo = CategoryRepository();
  final _supplierRepo = SupplierRepository();

  Future<List<Map<String, dynamic>>> loadProducts({int? categoryId}) async {
    return await _productRepo.getProductsWithDetail(categoryId: categoryId);
  }

  Future<List<Map<String, dynamic>>> loadCategories() async {
    return await _categoryRepo.getCategoriesList();
  }

  Future<List<Map<String, dynamic>>> loadSuppliers() async {
    return await _supplierRepo.getSuppliersList();
  }

  Future<bool> addProduct({
    required String productName,
    int? categoryId,
    int? supplierId,
    String? description,
    String? imageUrl,
  }) async {
    final result = await _productRepo.insertProduct(
      productName: productName,
      categoryId: categoryId,
      supplierId: supplierId,
      description: description,
      imageUrl: imageUrl,
    );
    return result > 0;
  }

  Future<bool> editProduct({
    required int productId,
    required String productName,
    int? categoryId,
    int? supplierId,
    String? description,
    String? imageUrl,
  }) async {
    final result = await _productRepo.updateProduct(
      productId: productId,
      productName: productName,
      categoryId: categoryId,
      supplierId: supplierId,
      description: description,
      imageUrl: imageUrl,
    );
    return result > 0;
  }

  /// Returns 'ok', 'has_inventory', 'error'
  Future<String> removeProduct(int productId) async {
    final result = await _productRepo.deleteProduct(productId);
    if (result == -1) return 'has_inventory';
    if (result > 0) return 'ok';
    return 'error';
  }
}
