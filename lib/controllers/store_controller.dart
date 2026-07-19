import '../repositories/store_repository.dart';

class StoreController {
  final _repo = StoreRepository();

  Future<List<Map<String, dynamic>>> loadStores() async {
    return await _repo.getStoresWithEmployeeCount();
  }

  Future<bool> addStore({
    required String storeName,
    String? address,
    String? phone,
    String? openTime,
    String? closeTime,
    String status = 'Active',
  }) async {
    final result = await _repo.insertStore(
      storeName: storeName,
      address: address,
      phone: phone,
      openTime: openTime,
      closeTime: closeTime,
      status: status,
    );
    return result > 0;
  }

  Future<bool> editStore({
    required int storeId,
    required String storeName,
    String? address,
    String? phone,
    String? openTime,
    String? closeTime,
    String? status,
  }) async {
    final result = await _repo.updateStore(
      storeId: storeId,
      storeName: storeName,
      address: address,
      phone: phone,
      openTime: openTime,
      closeTime: closeTime,
      status: status,
    );
    return result > 0;
  }

  /// Returns 'ok', 'has_employees', 'has_inventory', 'error'
  Future<String> removeStore(int storeId) async {
    final result = await _repo.deleteStore(storeId);
    if (result == -1) return 'has_employees';
    if (result == -2) return 'has_inventory';
    if (result > 0) return 'ok';
    return 'error';
  }

  Future<bool> toggleStatus(int storeId, String currentStatus) async {
    final result = await _repo.toggleStoreStatus(storeId, currentStatus);
    return result > 0;
  }
}
