import '../models/product_model.dart';
import 'database_helper.dart';

class ProductService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> createProduct(ProductModel product) async {
    final db = await _db.database;
    final map = product.toMap()..remove('ProductID');
    return await db.insert('Product', map);
  }

  Future<List<ProductModel>> getAllProducts() async {
    final db = await _db.database;
    final result = await db.query('Product', orderBy: 'ProductName ASC');
    return result.map((e) => ProductModel.fromMap(e)).toList();
  }

  Future<List<ProductModel>> getProductsByCategory(int categoryId) async {
    final db = await _db.database;
    final result = await db.query(
      'Product',
      where: 'CategoryID = ?',
      whereArgs: [categoryId],
      orderBy: 'ProductName ASC',
    );
    return result.map((e) => ProductModel.fromMap(e)).toList();
  }

  Future<ProductModel?> getProductById(int id) async {
    final db = await _db.database;
    final result =
        await db.query('Product', where: 'ProductID = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return ProductModel.fromMap(result.first);
  }

  Future<int> updateProduct(ProductModel product) async {
    final db = await _db.database;
    return await db.update(
      'Product',
      product.toMap(),
      where: 'ProductID = ?',
      whereArgs: [product.productId],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await _db.database;
    return await db.delete('Product', where: 'ProductID = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAllProductsWithDetails() async {
    final db = await _db.database;
    return await db.rawQuery('''
      SELECT p.*, c.CategoryName, s.SupplierName
      FROM Product p
      LEFT JOIN Category c ON p.CategoryID = c.CategoryID
      LEFT JOIN Supplier s ON p.SupplierID = s.SupplierID
      ORDER BY p.ProductName ASC
    ''');
  }
}
