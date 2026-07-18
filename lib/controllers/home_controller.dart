import '../repositories/invoice_repository.dart';
import '../repositories/employee_repository.dart';
import '../repositories/store_repository.dart';

class HomeController {
  final InvoiceRepository _invoiceRepository = InvoiceRepository();
  final EmployeeRepository _employeeRepository = EmployeeRepository();
  final StoreRepository _storeRepository = StoreRepository();

  Future<Map<String, dynamic>> loadDashboardData(int roleId, int? storeId) async {
    // 1. Load revenue
    final storeFilter = roleId == 1 ? null : storeId;
    final List<Map<String, dynamic>> todayRevenueList = await _invoiceRepository.getRevenue(storeFilter, 'Day');
    
    double todayRevenue = 0.0;
    int todayOrdersCount = 0;
    
    if (todayRevenueList.isNotEmpty) {
      todayRevenue = todayRevenueList.first['revenue'] as double? ?? 0.0;
      todayOrdersCount = todayRevenueList.first['orderCount'] as int? ?? 0;
    }

    // 2. Load employees
    final emps = await _employeeRepository.getEmployeeList();
    int employeeCount = 0;
    if (roleId == 2) {
      employeeCount = emps.where((e) => e['StoreID'] == storeId && e['RoleID'] == 3).length;
    } else {
      employeeCount = emps.length;
    }

    // 3. Load stores count
    final stores = await _storeRepository.getStoresList();
    int storeCount = stores.length;

    return {
      'todayRevenue': todayRevenue,
      'todayOrdersCount': todayOrdersCount,
      'employeeCount': employeeCount,
      'storeCount': storeCount,
      'storesList': stores,
    };
  }
}
