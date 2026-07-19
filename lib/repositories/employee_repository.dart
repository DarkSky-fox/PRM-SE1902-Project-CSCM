import '../services/database_helper.dart';

class EmployeeRepository {
  Future<List<Map<String, dynamic>>> getEmployeeList() async {
    return await DatabaseHelper.instance.getEmployeeList();
  }

  Future<List<Map<String, dynamic>>> getEmployeesWithDetail({
    int? storeId,
    int? roleId,
  }) async {
    return await DatabaseHelper.instance
        .getEmployeesWithDetail(storeId: storeId, roleId: roleId);
  }

  Future<Map<String, dynamic>?> getEmployeeById(int employeeId) async {
    return await DatabaseHelper.instance.getEmployeeById(employeeId);
  }

  Future<int> updateEmployeeDetail({
    required int employeeId,
    required String fullName,
    String? dob,
    int? gender,
    String? address,
    String? phone,
    double? salary,
    int? storeId,
  }) async {
    return await DatabaseHelper.instance.updateEmployeeDetail(
      employeeId: employeeId,
      fullName: fullName,
      dob: dob,
      gender: gender,
      address: address,
      phone: phone,
      salary: salary,
      storeId: storeId,
    );
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

