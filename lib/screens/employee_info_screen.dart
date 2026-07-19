import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../repositories/employee_repository.dart';
import '../repositories/store_repository.dart';

class EmployeeInfoScreen extends StatefulWidget {
  const EmployeeInfoScreen({super.key});

  @override
  State<EmployeeInfoScreen> createState() => _EmployeeInfoScreenState();
}

class _EmployeeInfoScreenState extends State<EmployeeInfoScreen>
    with SingleTickerProviderStateMixin {
  final _empRepo = EmployeeRepository();
  final _storeRepo = StoreRepository();

  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = false;
  int? _filterStoreId;
  final _searchCtrl = TextEditingController();

  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _loadData();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final emps = await _empRepo.getEmployeesWithDetail();
    final stores = await _storeRepo.getStoresList();
    setState(() {
      _employees = emps;
      _stores = stores;
      _isLoading = false;
      _applyFilter();
    });
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _employees.where((e) {
        final matchStore = _filterStoreId == null || e['StoreID'] == _filterStoreId;
        final matchSearch = q.isEmpty ||
            (e['FullName'] as String? ?? '').toLowerCase().contains(q) ||
            (e['Phone'] as String? ?? '').contains(q);
        return matchStore && matchSearch;
      }).toList();
    });
  }

  void _showEditForm(Map<String, dynamic> emp) {
    final nameCtrl = TextEditingController(text: emp['FullName'] ?? '');
    final dobCtrl = TextEditingController(text: emp['DOB'] ?? '');
    final addrCtrl = TextEditingController(text: emp['Address'] ?? '');
    final phoneCtrl = TextEditingController(text: emp['Phone'] ?? '');
    final salaryCtrl = TextEditingController(
      text: emp['Salary'] != null ? emp['Salary'].toStringAsFixed(0) : '',
    );
    int gender = emp['Gender'] as int? ?? 1;
    int? storeId = emp['StoreID'] as int?;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: EdgeInsets.only(
            top: 4, left: 20, right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 20),
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.darkBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Sửa thông tin nhân viên',
                    style: GoogleFonts.inter(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    )),
                const SizedBox(height: 4),
                Text('@${emp['Username'] ?? ''}',
                    style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 20),
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      _field(nameCtrl, 'Họ và tên', Icons.person_rounded,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Vui lòng nhập tên' : null),
                      const SizedBox(height: 12),
                      // Gender row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.darkElevated,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.darkBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.wc_rounded, color: AppTheme.textSecondary, size: 20),
                            const SizedBox(width: 10),
                            Text('Giới tính:', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14)),
                            const SizedBox(width: 12),
                            _genderChip('Nam', 1, gender, (v) => setModal(() => gender = v)),
                            const SizedBox(width: 8),
                            _genderChip('Nữ', 0, gender, (v) => setModal(() => gender = v)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // DOB
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.tryParse(dobCtrl.text) ?? DateTime(1995),
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
                          );
                          if (picked != null) {
                            dobCtrl.text = picked.toIso8601String().substring(0, 10);
                          }
                        },
                        child: AbsorbPointer(
                          child: _field(dobCtrl, 'Ngày sinh (yyyy-mm-dd)', Icons.cake_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _field(addrCtrl, 'Địa chỉ', Icons.home_rounded),
                      const SizedBox(height: 12),
                      _field(phoneCtrl, 'Số điện thoại', Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                      const SizedBox(height: 12),
                      _field(salaryCtrl, 'Lương (₫)', Icons.payments_rounded,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                      const SizedBox(height: 12),
                      // Store dropdown
                      DropdownButtonFormField<int?>(
                        value: storeId,
                        dropdownColor: AppTheme.darkElevated,
                        decoration: InputDecoration(
                          labelText: 'Chi nhánh',
                          prefixIcon: const Icon(Icons.store_rounded, size: 20),
                        ),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text('-- Chủ chuỗi (không store) --',
                                style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14)),
                          ),
                          ..._stores.map((s) => DropdownMenuItem<int?>(
                                value: s['StoreID'] as int,
                                child: Text(s['StoreName'] as String,
                                    style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14)),
                              )),
                        ],
                        onChanged: (v) => setModal(() => storeId = v),
                        style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            Navigator.pop(ctx);
                            await _empRepo.updateEmployeeDetail(
                              employeeId: emp['EmployeeID'] as int,
                              fullName: nameCtrl.text.trim(),
                              dob: dobCtrl.text.trim().isEmpty ? null : dobCtrl.text.trim(),
                              gender: gender,
                              address: addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
                              phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                              salary: salaryCtrl.text.trim().isEmpty
                                  ? null
                                  : double.tryParse(salaryCtrl.text.trim()),
                              storeId: storeId,
                            );
                            await _loadData();
                            if (mounted) _showSnack('Đã cập nhật thông tin nhân viên!');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('Lưu thay đổi',
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? AppTheme.error : AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text('Quản lý Nhân viên',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white)),
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            color: AppTheme.darkCard,
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  style: GoogleFonts.inter(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên, SĐT...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _applyFilter();
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('Tất cả', null),
                      ..._stores.map((s) => _filterChip(s['StoreName'] as String, s['StoreID'] as int)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Employee count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Text('${_filtered.length} nhân viên',
                    style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FadeTransition(
                    opacity: _fadeIn,
                    child: _filtered.isEmpty
                        ? Center(
                            child: Text('Không có nhân viên',
                                style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _filtered.length,
                            itemBuilder: (context, i) => _buildEmpCard(_filtered[i], i),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, int? storeId) {
    final selected = _filterStoreId == storeId;
    return GestureDetector(
      onTap: () {
        setState(() => _filterStoreId = storeId);
        _applyFilter();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.darkElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primaryLight : AppTheme.darkBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpCard(Map<String, dynamic> emp, int index) {
    final name = emp['FullName'] as String? ?? '';
    final role = emp['RoleName'] as String? ?? '';
    final store = emp['StoreName'] as String? ?? 'Chủ chuỗi';
    final phone = emp['Phone'] as String? ?? '';
    final salary = emp['Salary'] as double?;
    final isActive = (emp['AccountStatus'] as int? ?? 1) == 1;
    final roleId = emp['RoleID'] as int? ?? 3;

    final roleColor = roleId == 1
        ? AppTheme.accent
        : roleId == 2
            ? AppTheme.info
            : AppTheme.success;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 280 + index * 50),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.darkBorder),
          boxShadow: AppTheme.cardShadow,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: roleColor.withAlpha(40),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.inter(
                color: roleColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(name,
                    style: GoogleFonts.inter(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: roleColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(role,
                    style: GoogleFonts.inter(
                        color: roleColor, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              if (phone.isNotEmpty)
                _subtitleRow(Icons.phone_rounded, phone),
              _subtitleRow(Icons.store_rounded, store),
              if (salary != null)
                _subtitleRow(Icons.payments_rounded, AppTheme.formatMoney(salary),
                    color: AppTheme.success),
              if (!isActive)
                _subtitleRow(Icons.lock_rounded, 'Tài khoản bị khóa', color: AppTheme.error),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.edit_rounded, color: AppTheme.info, size: 20),
            onPressed: () => _showEditForm(emp),
          ),
        ),
      ),
    );
  }

  Widget _subtitleRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color ?? AppTheme.textSecondary),
          const SizedBox(width: 5),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(
                    color: color ?? AppTheme.textSecondary, fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _genderChip(String label, int value, int current, void Function(int) onTap) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.primaryLight : AppTheme.darkBorder),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                color: selected ? Colors.white : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }
}
