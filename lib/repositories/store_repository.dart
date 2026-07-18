import '../services/database_helper.dart';

class StoreRepository {
  Future<List<Map<String, dynamic>>> getStoresList() async {
    return await DatabaseHelper.instance.getStoresList();
  }
}
