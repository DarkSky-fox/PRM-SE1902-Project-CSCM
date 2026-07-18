import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../controllers/employee_controller.dart';
import '../controllers/schedule_controller.dart';

class EmployeeAdminScreen extends StatefulWidget {
  final int roleId; // 1: Chủ chuỗi, 2: Cửa hàng trưởng
  final int? storeId;
  final int employeeId;

  const EmployeeAdminScreen({
    super.key,
    required this.roleId,
    this.storeId,
    required this.employeeId,
  });

  @override
  State<EmployeeAdminScreen> createState() => _EmployeeAdminScreenState();
}

class _EmployeeAdminScreenState extends State<EmployeeAdminScreen>
    with SingleTickerProviderStateMixin {
  final _employeeController = EmployeeController();
  final _scheduleController = ScheduleController();

  late TabController _tabController;
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _stores = [];

  // Account creation fields
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  int _selectedRoleId = 3;
  int? _selectedStoreId;
  int _selectedGender = 1;

  // Scheduling fields - weekly timetable
  late DateTime _weekStart;
  Map<int, Map<String, String>> _weekShifts = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
    _weekStart = DateTime(_weekStart.year, _weekStart.month, _weekStart.day);
    _loadData();
  }

  Future<void> _loadData() async {
    final list = await _employeeController.loadEmployees(widget.roleId, widget.storeId);
    final stores = await _employeeController.loadStores();

    setState(() {
      _employees = list;
      _stores = stores;
      if (_stores.isNotEmpty && _selectedStoreId == null) {
        _selectedStoreId = _stores.first['StoreID'];
      }
    });

    if (widget.roleId == 2) {
      await _loadSchedulesForWeek();
    }
  }

  List<DateTime> get _weekDays => List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  Future<void> _loadSchedulesForWeek() async {
    final storeId = widget.storeId ?? 1;
    final shifts = await _scheduleController.loadSchedulesForWeek(
      storeId: storeId,
      weekDays: _weekDays,
      employees: _employees,
    );

    setState(() => _weekShifts = shifts);
  }

  Future<void> _saveWeekSchedule() async {
    setState(() => _isLoading = true);
    final count = await _scheduleController.saveWeekSchedule(_weekShifts);
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã lưu lịch tuần ($count lượt) thành công!'),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    if (_usernameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _fullNameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _selectedStoreId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ các thông tin bắt buộc!'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    final res = await _employeeController.createEmployee(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      roleId: _selectedRoleId,
      storeId: _selectedStoreId!,
      fullName: _fullNameController.text.trim(),
      gender: _selectedGender,
      phone: _phoneController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (res == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tên đăng nhập đã tồn tại trong hệ thống. Vui lòng chọn tên khác.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (res > 0) {
      _usernameController.clear();
      _passwordController.clear();
      _fullNameController.clear();
      _phoneController.clear();
      _loadData();
      _showSuccessDialog('Tạo tài khoản nhân viên thành công.');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Có lỗi xảy ra khi tạo tài khoản!'), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _toggleLock(Map<String, dynamic> emp) async {
    final accountId = emp['AccountID'] as int;
    final currentStatus = emp['Status'] as int;
    final fullName = emp['FullName'] as String;

    if (accountId == widget.employeeId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn không thể tự khóa tài khoản chính mình!'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _isLoading = true);
    await _employeeController.toggleEmployeeStatus(accountId, currentStatus);
    setState(() => _isLoading = false);

    _loadData();
    final action = currentStatus == 1 ? 'Khóa' : 'Mở khóa';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã $action tài khoản của $fullName thành công.'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 50),
        title: const Text('Thành công', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        title: Text(widget.roleId == 1 ? 'Quản Trị Nhân Sự' : 'Quản Lý Store'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(icon: Icon(Icons.people_alt_rounded), text: 'Nhân sự'),
            Tab(
              icon: Icon(widget.roleId == 1 ? Icons.person_add_alt_1_rounded : Icons.calendar_month_rounded),
              text: widget.roleId == 1 ? 'Cấp tài khoản' : 'Xếp ca làm',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEmployeeListTab(),
                widget.roleId == 1 ? _buildCreateAccountTab() : _buildSchedulingTab(),
              ],
            ),
    );
  }

  // ── Tab 1: Employee List ─────────────────────────────────────────────────────
  Widget _buildEmployeeListTab() {
    if (_employees.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.people_outline_rounded, size: 72, color: AppTheme.divider),
          const SizedBox(height: 16),
          Text('Chưa có nhân viên trực thuộc', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.w500)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _employees.length,
      itemBuilder: (context, index) {
        final emp = _employees[index];
        final isLocked = emp['Status'] == 0;
        final isManager = emp['RoleID'] == 2;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isLocked ? AppTheme.error.withAlpha(60) : AppTheme.divider),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              // Avatar
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: isLocked ? const Color(0xFFFFEBEE) : (isManager ? const Color(0xFFE3F2FD) : const Color(0xFFE8F5E9)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isManager ? Icons.supervisor_account_rounded : Icons.person_rounded,
                  color: isLocked ? AppTheme.error : (isManager ? const Color(0xFF1565C0) : AppTheme.primaryLight),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(child: Text(emp['FullName'], style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isLocked ? AppTheme.error.withAlpha(20) : (isManager ? const Color(0xFFE3F2FD) : const Color(0xFFE8F5E9)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isLocked ? 'Đã khóa' : emp['RoleName'],
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: isLocked ? AppTheme.error : (isManager ? const Color(0xFF1565C0) : AppTheme.primaryLight)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text('@${emp['Username']}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                  if (emp['StoreName'] != null) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.store_rounded, size: 11, color: AppTheme.textLight),
                      const SizedBox(width: 3),
                      Text(emp['StoreName'], style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                      const SizedBox(width: 10),
                      const Icon(Icons.phone_rounded, size: 11, color: AppTheme.textLight),
                      const SizedBox(width: 3),
                      Text(emp['Phone'] ?? '-', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                    ]),
                  ],
                ],
              )),
              const SizedBox(width: 8),
              // Actions
              Column(mainAxisSize: MainAxisSize.min, children: [
                if (widget.roleId == 1)
                  _buildIconAction(Icons.edit_rounded, AppTheme.primaryLight, () => _showEditDialog(emp), 'Sửa'),
                const SizedBox(height: 4),
                _buildIconAction(
                  isLocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                  isLocked ? AppTheme.success : AppTheme.error,
                  () => _toggleLock(emp),
                  isLocked ? 'Mở khóa' : 'Khóa',
                ),
              ]),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildIconAction(IconData icon, Color color, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  // ── Tab 2a: Create Account (Owner) ───────────────────────────────────────────
  Widget _buildCreateAccountTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: AppTheme.headerGradient, borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Cấp Tài Khoản Mới', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Tạo tài khoản cho nhân sự', style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),
          // Form
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.divider),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _sectionLabel('Thông tin cá nhân', Icons.badge_rounded),
              const SizedBox(height: 14),
              TextField(controller: _fullNameController, decoration: const InputDecoration(labelText: 'Họ tên nhân viên', prefixIcon: Icon(Icons.person_outline_rounded))),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: _selectedGender,
                decoration: const InputDecoration(labelText: 'Giới tính', prefixIcon: Icon(Icons.wc_rounded)),
                items: const [DropdownMenuItem(value: 1, child: Text('Nam')), DropdownMenuItem(value: 0, child: Text('Nữ'))],
                onChanged: (val) => setState(() => _selectedGender = val ?? 1),
              ),
              const SizedBox(height: 14),
              TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Số điện thoại', prefixIcon: Icon(Icons.phone_outlined))),
              const SizedBox(height: 24),
              _sectionLabel('Phân quyền & cửa hàng', Icons.manage_accounts_rounded),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: _selectedRoleId,
                decoration: const InputDecoration(labelText: 'Vai trò', prefixIcon: Icon(Icons.shield_outlined)),
                items: const [
                  DropdownMenuItem(value: 2, child: Text('Cửa hàng trưởng')),
                  DropdownMenuItem(value: 3, child: Text('Nhân viên')),
                ],
                onChanged: (val) => setState(() => _selectedRoleId = val ?? 3),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: _selectedStoreId,
                decoration: const InputDecoration(labelText: 'Cửa hàng trực thuộc', prefixIcon: Icon(Icons.store_outlined)),
                items: _stores.map((s) => DropdownMenuItem<int>(value: s['StoreID'], child: Text(s['StoreName']))).toList(),
                onChanged: (val) => setState(() => _selectedStoreId = val),
              ),
              const SizedBox(height: 24),
              _sectionLabel('Thông tin đăng nhập', Icons.lock_outline_rounded),
              const SizedBox(height: 14),
              TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Tên đăng nhập (Username)', prefixIcon: Icon(Icons.alternate_email_rounded))),
              const SizedBox(height: 14),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu ban đầu', prefixIcon: Icon(Icons.lock_outline_rounded))),
            ]),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add_rounded, color: Colors.white),
            label: const Text('CẤP TÀI KHOẢN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: _isLoading ? null : _handleCreateAccount,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title, IconData icon) {
    return Row(children: [
      Container(width: 4, height: 16, decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Icon(icon, size: 16, color: AppTheme.primaryLight),
      const SizedBox(width: 6),
      Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary)),
    ]);
  }

  // ── Tab 2b: Scheduling (Manager) ─────────────────────────────────────────────
  static const List<String> _dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  Color _shiftColor(String shift) {
    switch (shift) {
      case 'Sáng': return AppTheme.shiftMorning;
      case 'Chiều': return AppTheme.shiftAfternoon;
      case 'Tối': return AppTheme.shiftEvening;
      default: return AppTheme.shiftOff;
    }
  }

  IconData _shiftIcon(String shift) {
    switch (shift) {
      case 'Sáng': return Icons.wb_sunny_rounded;
      case 'Chiều': return Icons.wb_cloudy_rounded;
      case 'Tối': return Icons.nights_stay_rounded;
      default: return Icons.event_busy_rounded;
    }
  }

  Widget _buildSchedulingTab() {
    final days = _weekDays;
    final weekEnd = days.last;
    final weekLabel = '${_weekStart.day}/${_weekStart.month} – ${weekEnd.day}/${weekEnd.month}/${weekEnd.year}';

    return Column(children: [
      // ── Week nav header ────────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
            tooltip: 'Tuần trước',
            onPressed: () {
              setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));
              _loadSchedulesForWeek();
            },
          ),
          Expanded(child: Column(children: [
            Text('THỜI KHÓA BIỂU', style: GoogleFonts.inter(color: Colors.white60, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
            Text(weekLabel, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          ])),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
            tooltip: 'Tuần sau',
            onPressed: () {
              setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));
              _loadSchedulesForWeek();
            },
          ),
        ]),
      ),

      // ── Timetable grid ─────────────────────────────────────────────────
      Expanded(
        child: _employees.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.calendar_today_outlined, size: 64, color: AppTheme.divider),
                const SizedBox(height: 16),
                Text('Không có nhân viên để xếp lịch', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 15)),
              ]))
            : SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Table(
                      defaultColumnWidth: const IntrinsicColumnWidth(),
                      border: TableBorder(
                        horizontalInside: BorderSide(color: AppTheme.divider, width: 1),
                        verticalInside: BorderSide(color: AppTheme.divider, width: 1),
                        top: BorderSide(color: AppTheme.divider),
                        bottom: BorderSide(color: AppTheme.divider),
                        left: BorderSide(color: AppTheme.divider),
                        right: BorderSide(color: AppTheme.divider),
                      ),
                      children: [
                        // Header row
                        TableRow(
                          decoration: BoxDecoration(color: AppTheme.primary.withAlpha(18)),
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Text('NHÂN VIÊN', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: AppTheme.primaryLight, letterSpacing: 0.5)),
                            ),
                            for (int i = 0; i < 7; i++) _buildDayHeaderCell(days[i], i),
                          ],
                        ),
                        for (final emp in _employees) _buildEmployeeRow(emp, days),
                      ],
                    ),
                  ),
                ),
              ),
      ),

      // ── Save footer ────────────────────────────────────────────────────
      if (_employees.isNotEmpty)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.white,
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 12, offset: const Offset(0, -3))],
          ),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.save_alt_rounded, color: Colors.white),
            label: const Text('LƯU LỊCH CẢ TUẦN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: _isLoading ? null : _saveWeekSchedule,
          ),
        ),
    ]);
  }

  Widget _buildDayHeaderCell(DateTime day, int index) {
    final today = DateTime.now();
    final isToday = day.year == today.year && day.month == today.month && day.day == today.day;
    final isSunday = index == 6;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      alignment: Alignment.center,
      decoration: isToday ? BoxDecoration(color: AppTheme.primaryLight.withAlpha(30)) : null,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_dayLabels[index], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: isSunday ? AppTheme.error : AppTheme.primaryLight)),
        const SizedBox(height: 2),
        Text('${day.day}/${day.month}', style: TextStyle(fontSize: 11, color: isToday ? AppTheme.primaryLight : AppTheme.textSecondary, fontWeight: isToday ? FontWeight.w700 : FontWeight.w400)),
      ]),
    );
  }

  TableRow _buildEmployeeRow(Map<String, dynamic> emp, List<DateTime> days) {
    final empId = emp['EmployeeID'] as int;
    final empShifts = _weekShifts[empId] ?? {};
    return TableRow(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        constraints: const BoxConstraints(minWidth: 120),
        child: Text(emp['FullName'], style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
      ),
      for (final day in days) _buildShiftCell(empId, day, empShifts),
    ]);
  }

  Widget _buildShiftCell(int empId, DateTime day, Map<String, String> empShifts) {
    final dateStr = day.toIso8601String().substring(0, 10);
    final shift = empShifts[dateStr] ?? 'Nghỉ';
    final color = _shiftColor(shift);
    final icon = _shiftIcon(shift);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      constraints: const BoxConstraints(minWidth: 100),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Text(shift == 'Nghỉ' ? 'Nghỉ' : 'Ca $shift', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 4),
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(border: Border.all(color: AppTheme.divider), borderRadius: BorderRadius.circular(6)),
          child: DropdownButton<String>(
            value: shift,
            isExpanded: true,
            isDense: true,
            underline: const SizedBox(),
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textPrimary),
            icon: const Icon(Icons.arrow_drop_down, size: 16),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _weekShifts.putIfAbsent(empId, () => {});
                  _weekShifts[empId]![dateStr] = val;
                });
              }
            },
            items: const [
              DropdownMenuItem(value: 'Nghỉ', child: Text('Nghỉ')),
              DropdownMenuItem(value: 'Sáng', child: Text('Sáng')),
              DropdownMenuItem(value: 'Chiều', child: Text('Chiều')),
              DropdownMenuItem(value: 'Tối', child: Text('Tối')),
            ],
          ),
        ),
      ]),
    );
  }

  void _showEditDialog(Map<String, dynamic> emp) {
    final editFullNameController = TextEditingController(text: emp['FullName']);
    final editPhoneController = TextEditingController(text: emp['Phone']);
    final editUsernameController = TextEditingController(text: emp['Username']);
    final editPasswordController = TextEditingController(text: emp['Password'] ?? '');
    int editGender = emp['Gender'] as int;
    int editRoleId = emp['RoleID'] as int;
    int editStoreId = emp['StoreID'] as int? ?? (_stores.isNotEmpty ? _stores.first['StoreID'] : 1);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Chỉnh Sửa Nhân Sự', style: TextStyle(fontWeight: FontWeight.w800)),
              content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(controller: editFullNameController, decoration: const InputDecoration(labelText: 'Họ tên nhân viên')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: editGender,
                    decoration: const InputDecoration(labelText: 'Giới tính'),
                    items: const [DropdownMenuItem(value: 1, child: Text('Nam')), DropdownMenuItem(value: 0, child: Text('Nữ'))],
                    onChanged: (val) { if (val != null) setDialogState(() => editGender = val); },
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: editPhoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Số điện thoại')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: editRoleId,
                    decoration: const InputDecoration(labelText: 'Vai trò'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Chủ chuỗi')),
                      DropdownMenuItem(value: 2, child: Text('Cửa hàng trưởng')),
                      DropdownMenuItem(value: 3, child: Text('Nhân viên')),
                    ],
                    onChanged: (val) { if (val != null) setDialogState(() => editRoleId = val); },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: editStoreId,
                    decoration: const InputDecoration(labelText: 'Cửa hàng trực thuộc'),
                    items: _stores.map((s) => DropdownMenuItem<int>(value: s['StoreID'], child: Text(s['StoreName']))).toList(),
                    onChanged: (val) { if (val != null) setDialogState(() => editStoreId = val); },
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: editUsernameController, decoration: const InputDecoration(labelText: 'Username')),
                  const SizedBox(height: 12),
                  TextField(controller: editPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                ]),
              ),
              actions: [
                OutlinedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
                ElevatedButton(
                  child: const Text('Cập nhật', style: TextStyle(color: Colors.white)),
                  onPressed: () async {
                    if (editFullNameController.text.isEmpty || editPhoneController.text.isEmpty ||
                        editUsernameController.text.isEmpty || editPasswordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin!')));
                      return;
                    }
                    final res = await _employeeController.updateEmployee(
                      accountId: emp['AccountID'] as int,
                      employeeId: emp['EmployeeID'] as int,
                      username: editUsernameController.text.trim(),
                      password: editPasswordController.text,
                      roleId: editRoleId,
                      storeId: editStoreId,
                      fullName: editFullNameController.text.trim(),
                      gender: editGender,
                      phone: editPhoneController.text.trim(),
                    );
                    if (res == -1) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tên đăng nhập đã tồn tại.'), backgroundColor: AppTheme.error));
                    } else {
                      Navigator.of(ctx).pop();
                      _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công.'), backgroundColor: AppTheme.success));
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
