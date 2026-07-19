import '../services/database_helper.dart';

class StoreRepository {
  Future<List<Map<String, dynamic>>> getStoresList() async {
    return await DatabaseHelper.instance.getStoresList();
  }

  Future<List<Map<String, dynamic>>> getStoresWithEmployeeCount() async {
    return await DatabaseHelper.instance.getStoresWithEmployeeCount();
  }

  Future<int> insertStore({
    required String storeName,
    String? address,
    String? phone,
    String? openTime,
    String? closeTime,
    String status = 'Active',
  }) async {
    return await DatabaseHelper.instance.insertStore(
      storeName: storeName,
      address: address,
      phone: phone,
      openTime: openTime,
      closeTime: closeTime,
      status: status,
    );
  }

  Future<int> updateStore({
    required int storeId,
    required String storeName,
    String? address,
    String? phone,
    String? openTime,
    String? closeTime,
    String? status,
  }) async {
    return await DatabaseHelper.instance.updateStore(
      storeId: storeId,
      storeName: storeName,
      address: address,
      phone: phone,
      openTime: openTime,
      closeTime: closeTime,
      status: status,
    );
  }

  Future<int> deleteStore(int storeId) async {
    return await DatabaseHelper.instance.deleteStore(storeId);
  }

  Future<int> toggleStoreStatus(int storeId, String currentStatus) async {
    return await DatabaseHelper.instance.toggleStoreStatus(storeId, currentStatus);
  }
}
