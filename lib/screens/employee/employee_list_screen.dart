import 'package:flutter/material.dart';
import '../../models/employee_model.dart';
import '../../models/store_model.dart';
import '../../services/employee_service.dart';
import '../../services/store_service.dart';
import 'employee_form_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final EmployeeService _empService = EmployeeService();
  final StoreService _storeService = StoreService();

  List<EmployeeModel> _employees = [];
  List<EmployeeModel> _filtered = [];
  List<StoreModel> _stores = [];
  final TextEditingController _searchCtrl = TextEditingController();
  int? _selectedStoreId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final employees = await _empService.getAllEmployees();
    final stores = await _storeService.getAllStores();
    setState(() {
      _employees = employees;
      _stores = stores;
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    final query = _searchCtrl.text.toLowerCase();
    _filtered = _employees.where((e) {
      final nameMatch = e.fullName.toLowerCase().contains(query) ||
          (e.phone ?? '').contains(query);
      final storeMatch =
          _selectedStoreId == null || e.storeId == _selectedStoreId;
      return nameMatch && storeMatch;
    }).toList();
  }

  void _onSearch(String _) => setState(() => _applyFilter());

  String _storeName(int? storeId) {
    if (storeId == null) return 'Chưa phân công';
    try {
      return _stores.firstWhere((s) => s.storeId == storeId).storeName;
    } catch (_) {
      return 'N/A';
    }
  }

  Future<void> _delete(EmployeeModel employee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa'),
        content:
            Text('Bạn có chắc muốn xóa nhân viên "${employee.fullName}" không?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _empService.deleteEmployee(employee.employeeId!);
      _loadAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa "${employee.fullName}"'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openForm({EmployeeModel? employee}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EmployeeFormScreen(employee: employee, stores: _stores),
      ),
    );
    if (result == true) _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStoreFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? _buildEmptyState()
                    : _buildList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFF00BCD4),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Thêm mới',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0097A7),
      foregroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quản Lý Nhân Viên',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          Text('${_filtered.length} nhân viên',
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFF0097A7),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _onSearch,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Tìm theo tên, SĐT...',
          hintStyle: const TextStyle(color: Colors.white60),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  onPressed: () {
                    _searchCtrl.clear();
                    _onSearch('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildStoreFilter() {
    return Container(
      color: const Color(0xFF0097A7),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip(null, 'Tất cả'),
            ..._stores.map((s) => _filterChip(s.storeId, s.storeName)),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(int? storeId, String label) {
    final selected = _selectedStoreId == storeId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedStoreId = storeId;
            _applyFilter();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF0097A7) : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filtered.length,
      itemBuilder: (ctx, i) => _buildCard(_filtered[i]),
    );
  }

  Widget _buildCard(EmployeeModel emp) {
    final genderLabel =
        emp.gender == 1 ? 'Nam' : emp.gender == 0 ? 'Nữ' : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFE0F7FA),
              child: Text(
                emp.fullName.isNotEmpty
                    ? emp.fullName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Color(0xFF0097A7),
                    fontWeight: FontWeight.w800,
                    fontSize: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(emp.fullName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF212121))),
                  const SizedBox(height: 4),
                  if (genderLabel != null)
                    _infoRow(Icons.person_outline, genderLabel),
                  if (emp.phone != null)
                    _infoRow(Icons.phone_outlined, emp.phone!),
                  _infoRow(Icons.store_outlined, _storeName(emp.storeId)),
                  if (emp.salary != null)
                    _infoRow(Icons.payments_outlined,
                        '${emp.salary!.toStringAsFixed(0)} VND'),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: Color(0xFF0097A7)),
                  onPressed: () => _openForm(employee: emp),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _delete(emp),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.grey),
          const SizedBox(width: 4),
          Flexible(
            child: Text(text,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchCtrl.text.isNotEmpty || _selectedStoreId != null
                ? 'Không tìm thấy nhân viên nào'
                : 'Chưa có nhân viên nào',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
