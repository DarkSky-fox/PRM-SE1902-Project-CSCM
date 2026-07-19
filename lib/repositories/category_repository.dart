import '../services/database_helper.dart';

class CategoryRepository {
  Future<List<Map<String, dynamic>>> getCategoriesList() async {
    return await DatabaseHelper.instance.getCategoriesList();
  }

  Future<int> insertCategory(String categoryName) async {
    return await DatabaseHelper.instance.insertCategory(categoryName);
  }

  Future<int> updateCategory(int categoryId, String categoryName) async {
    return await DatabaseHelper.instance.updateCategory(categoryId, categoryName);
  }

  Future<int> deleteCategory(int categoryId) async {
    return await DatabaseHelper.instance.deleteCategory(categoryId);
  }
}
