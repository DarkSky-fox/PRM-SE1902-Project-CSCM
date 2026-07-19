import '../repositories/category_repository.dart';

class CategoryController {
  final _repo = CategoryRepository();

  Future<List<Map<String, dynamic>>> loadCategories() async {
    return await _repo.getCategoriesList();
  }

  Future<bool> addCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    final result = await _repo.insertCategory(trimmed);
    return result > 0;
  }

  Future<bool> editCategory(int categoryId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    final result = await _repo.updateCategory(categoryId, trimmed);
    return result > 0;
  }

  /// Returns 'ok', 'has_products', 'error'
  Future<String> removeCategory(int categoryId) async {
    final result = await _repo.deleteCategory(categoryId);
    if (result == -1) return 'has_products';
    if (result > 0) return 'ok';
    return 'error';
  }
}
