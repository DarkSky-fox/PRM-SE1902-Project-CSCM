import '../models/category_model.dart';
import 'database_helper.dart';

class CategoryService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> createCategory(CategoryModel category) async {
    final db = await _db.database;
    final map = category.toMap()..remove('CategoryID');
    return await db.insert('Category', map);
  }

  Future<List<CategoryModel>> getAllCategories() async {
    final db = await _db.database;
    final result = await db.query('Category', orderBy: 'CategoryName ASC');
    return result.map((e) => CategoryModel.fromMap(e)).toList();
  }

  Future<CategoryModel?> getCategoryById(int id) async {
    final db = await _db.database;
    final result =
        await db.query('Category', where: 'CategoryID = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return CategoryModel.fromMap(result.first);
  }

  Future<int> updateCategory(CategoryModel category) async {
    final db = await _db.database;
    return await db.update(
      'Category',
      category.toMap(),
      where: 'CategoryID = ?',
      whereArgs: [category.categoryId],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await _db.database;
    return await db
        .delete('Category', where: 'CategoryID = ?', whereArgs: [id]);
  }

  Future<bool> isDuplicate(String name, {int? excludeId}) async {
    final db = await _db.database;
    final result = excludeId != null
        ? await db.query(
            'Category',
            where: 'CategoryName = ? AND CategoryID != ?',
            whereArgs: [name, excludeId],
          )
        : await db.query(
            'Category',
            where: 'CategoryName = ?',
            whereArgs: [name],
          );
    return result.isNotEmpty;
  }
}
