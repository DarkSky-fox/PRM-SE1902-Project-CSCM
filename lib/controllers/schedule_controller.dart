import '../repositories/schedule_repository.dart';
import '../repositories/employee_repository.dart';

class ScheduleController {
  final ScheduleRepository _scheduleRepository = ScheduleRepository();
  final EmployeeRepository _employeeRepository = EmployeeRepository();

  Future<List<Map<String, dynamic>>> loadStoreStaffs(int storeId) async {
    final list = await _employeeRepository.getEmployeeList();
    return list.where((e) => e['StoreID'] == storeId && e['RoleID'] == 3).toList();
  }

  Future<Map<int, Map<String, String>>> loadSchedulesForWeek({
    required int storeId,
    required List<DateTime> weekDays,
    required List<Map<String, dynamic>> employees,
  }) async {
    final list = await _scheduleRepository.getSchedulesForStore(storeId);
    final weekDateStrs = weekDays.map((d) => d.toIso8601String().substring(0, 10)).toSet();

    final Map<int, Map<String, String>> shifts = {};
    for (final emp in employees) {
      final empId = emp['EmployeeID'] as int;
      shifts[empId] = {};
      for (final dateStr in weekDateStrs) {
        shifts[empId]![dateStr] = 'Nghỉ';
      }
    }

    for (final s in list) {
      final dateStr = s['WorkDate'] as String;
      if (weekDateStrs.contains(dateStr)) {
        final empId = s['EmployeeID'] as int;
        if (shifts.containsKey(empId)) {
          shifts[empId]![dateStr] = s['Shift'] as String;
        }
      }
    }

    return shifts;
  }

  Future<int> saveWeekSchedule(Map<int, Map<String, String>> weekShifts) async {
    int count = 0;
    for (final entry in weekShifts.entries) {
      final empId = entry.key;
      for (final dayEntry in entry.value.entries) {
        await _scheduleRepository.saveSchedule(empId, dayEntry.key, dayEntry.value);
        count++;
      }
    }
    return count;
  }
}
