import '../services/database_helper.dart';

class SupplierRepository {
  Future<List<Map<String, dynamic>>> getSuppliersList() async {
    return await DatabaseHelper.instance.getSuppliersList();
  }

  Future<int> insertSupplier({
    required String supplierName,
    String? address,
    String? email,
    String? phone,
  }) async {
    return await DatabaseHelper.instance.insertSupplier(
      supplierName: supplierName,
      address: address,
      email: email,
      phone: phone,
    );
  }

  Future<int> updateSupplier({
    required int supplierId,
    required String supplierName,
    String? address,
    String? email,
    String? phone,
  }) async {
    return await DatabaseHelper.instance.updateSupplier(
      supplierId: supplierId,
      supplierName: supplierName,
      address: address,
      email: email,
      phone: phone,
    );
  }

  Future<int> deleteSupplier(int supplierId) async {
    return await DatabaseHelper.instance.deleteSupplier(supplierId);
  }
}
