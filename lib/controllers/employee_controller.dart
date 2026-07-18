import '../repositories/employee_repository.dart';
import '../repositories/store_repository.dart';

class EmployeeController {
  final EmployeeRepository _employeeRepository = EmployeeRepository();
  final StoreRepository _storeRepository = StoreRepository();

  Future<List<Map<String, dynamic>>> loadEmployees(int roleId, int? storeId) async {
    final list = await _employeeRepository.getEmployeeList();
    if (roleId == 2) {
      return list.where((e) => e['StoreID'] == storeId && e['RoleID'] == 3).toList();
    }
    return list;
  }

  Future<List<Map<String, dynamic>>> loadStores() async {
    return await _storeRepository.getStoresList();
  }

  Future<int> createEmployee({
    required String username,
    required String password,
    required int roleId,
    required int storeId,
    required String fullName,
    required int gender,
    required String phone,
  }) async {
    return await _employeeRepository.createAccount(
      username: username,
      password: password,
      roleId: roleId,
      storeId: storeId,
      fullName: fullName,
      gender: gender,
      phone: phone,
    );
  }

  Future<int> updateEmployee({
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
    return await _employeeRepository.updateAccount(
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

  Future<int> toggleEmployeeStatus(int accountId, int currentStatus) async {
    return await _employeeRepository.toggleAccountStatus(accountId, currentStatus);
  }
}
