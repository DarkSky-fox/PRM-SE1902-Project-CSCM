import '../models/store_model.dart';
import 'database_helper.dart';

class StoreService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> createStore(StoreModel store) async {
    final db = await _db.database;
    final map = store.toMap()..remove('StoreID');
    return await db.insert('Store', map);
  }

  Future<List<StoreModel>> getAllStores() async {
    final db = await _db.database;
    final result = await db.query('Store', orderBy: 'StoreName ASC');
    return result.map((e) => StoreModel.fromMap(e)).toList();
  }

  Future<StoreModel?> getStoreById(int id) async {
    final db = await _db.database;
    final result = await db.query('Store', where: 'StoreID = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return StoreModel.fromMap(result.first);
  }

  Future<int> updateStore(StoreModel store) async {
    final db = await _db.database;
    return await db.update(
      'Store',
      store.toMap(),
      where: 'StoreID = ?',
      whereArgs: [store.storeId],
    );
  }

  Future<int> deleteStore(int id) async {
    final db = await _db.database;
    return await db.delete('Store', where: 'StoreID = ?', whereArgs: [id]);
  }
}
