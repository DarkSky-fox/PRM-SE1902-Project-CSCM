import '../models/supplier_model.dart';
import 'database_helper.dart';

class SupplierService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> createSupplier(SupplierModel supplier) async {
    final db = await _db.database;
    final map = supplier.toMap()..remove('SupplierID');
    return await db.insert('Supplier', map);
  }

  Future<List<SupplierModel>> getAllSuppliers() async {
    final db = await _db.database;
    final result = await db.query('Supplier', orderBy: 'SupplierName ASC');
    return result.map((e) => SupplierModel.fromMap(e)).toList();
  }

  Future<SupplierModel?> getSupplierById(int id) async {
    final db = await _db.database;
    final result =
        await db.query('Supplier', where: 'SupplierID = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return SupplierModel.fromMap(result.first);
  }

  Future<int> updateSupplier(SupplierModel supplier) async {
    final db = await _db.database;
    return await db.update(
      'Supplier',
      supplier.toMap(),
      where: 'SupplierID = ?',
      whereArgs: [supplier.supplierId],
    );
  }

  Future<int> deleteSupplier(int id) async {
    final db = await _db.database;
    return await db
        .delete('Supplier', where: 'SupplierID = ?', whereArgs: [id]);
  }
}
