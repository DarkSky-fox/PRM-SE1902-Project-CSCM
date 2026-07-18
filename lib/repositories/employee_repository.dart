import '../services/database_helper.dart';

class EmployeeRepository {
  Future<List<Map<String, dynamic>>> getEmployeeList() async {
    return await DatabaseHelper.instance.getEmployeeList();
  }

  Future<int> createAccount({
    required String username,
    required String password,
    required int roleId,
    required int storeId,
    required String fullName,
    required int gender,
    required String phone,
  }) async {
    return await DatabaseHelper.instance.createAccount(
      username: username,
      password: password,
      roleId: roleId,
      storeId: storeId,
      fullName: fullName,
      gender: gender,
      phone: phone,
    );
  }

  Future<int> updateAccount({
    required int accountId,
    required int employeeId,
    required String username,
    required String password,
    required int roleId,
    required int storeId,
    required String fullName,
    required int gender,
    required String phone,
  }) async {
    return await DatabaseHelper.instance.updateAccount(
      accountId: accountId,
      employeeId: employeeId,
      username: username,
      password: password,
      roleId: roleId,
      storeId: storeId,
      fullName: fullName,
      gender: gender,
      phone: phone,
    );
  }

  Future<int> toggleAccountStatus(int accountId, int currentStatus) async {
    return await DatabaseHelper.instance.toggleAccountStatus(accountId, currentStatus);
  }
}
