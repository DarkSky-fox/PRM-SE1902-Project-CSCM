import '../models/employee_model.dart';
import 'database_helper.dart';

class EmployeeService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> createEmployee(EmployeeModel employee) async {
    final db = await _db.database;
    final map = employee.toMap()..remove('EmployeeID');
    return await db.insert('Employee', map);
  }

  Future<List<EmployeeModel>> getAllEmployees() async {
    final db = await _db.database;
    final result = await db.query('Employee', orderBy: 'FullName ASC');
    return result.map((e) => EmployeeModel.fromMap(e)).toList();
  }

  Future<List<EmployeeModel>> getEmployeesByStore(int storeId) async {
    final db = await _db.database;
    final result = await db.query(
      'Employee',
      where: 'StoreID = ?',
      whereArgs: [storeId],
      orderBy: 'FullName ASC',
    );
    return result.map((e) => EmployeeModel.fromMap(e)).toList();
  }

  Future<EmployeeModel?> getEmployeeById(int id) async {
    final db = await _db.database;
    final result =
        await db.query('Employee', where: 'EmployeeID = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return EmployeeModel.fromMap(result.first);
  }

  Future<int> updateEmployee(EmployeeModel employee) async {
    final db = await _db.database;
    return await db.update(
      'Employee',
      employee.toMap(),
      where: 'EmployeeID = ?',
      whereArgs: [employee.employeeId],
    );
  }

  Future<int> deleteEmployee(int id) async {
    final db = await _db.database;
    return await db.delete('Employee', where: 'EmployeeID = ?', whereArgs: [id]);
  }
}
