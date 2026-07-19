import '../repositories/supplier_repository.dart';

class SupplierController {
  final _repo = SupplierRepository();

  Future<List<Map<String, dynamic>>> loadSuppliers() async {
    return await _repo.getSuppliersList();
  }

  Future<bool> addSupplier({
    required String supplierName,
    String? address,
    String? email,
    String? phone,
  }) async {
    final result = await _repo.insertSupplier(
      supplierName: supplierName,
      address: address,
      email: email,
      phone: phone,
    );
    return result > 0;
  }

  Future<bool> editSupplier({
    required int supplierId,
    required String supplierName,
    String? address,
    String? email,
    String? phone,
  }) async {
    final result = await _repo.updateSupplier(
      supplierId: supplierId,
      supplierName: supplierName,
      address: address,
      email: email,
      phone: phone,
    );
    return result > 0;
  }

  /// Returns 'ok', 'has_products', 'error'
  Future<String> removeSupplier(int supplierId) async {
    final result = await _repo.deleteSupplier(supplierId);
    if (result == -1) return 'has_products';
    if (result > 0) return 'ok';
    return 'error';
  }
}
