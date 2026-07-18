import '../services/database_helper.dart';

class ScheduleRepository {
  Future<int> saveSchedule(int employeeId, String date, String shift) async {
    return await DatabaseHelper.instance.saveSchedule(employeeId, date, shift);
  }

  Future<List<Map<String, dynamic>>> getSchedulesForEmployee(int employeeId) async {
    return await DatabaseHelper.instance.getSchedulesForEmployee(employeeId);
  }

  Future<List<Map<String, dynamic>>> getSchedulesForStore(int storeId) async {
    return await DatabaseHelper.instance.getSchedulesForStore(storeId);
  }
}
