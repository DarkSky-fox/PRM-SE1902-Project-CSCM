import 'package:flutter/material.dart';
import '../../models/employee_model.dart';
import '../../models/store_model.dart';
import '../../services/employee_service.dart';

class EmployeeFormScreen extends StatefulWidget {
  final EmployeeModel? employee;
  final List<StoreModel> stores;

  const EmployeeFormScreen({
    super.key,
    this.employee,
    required this.stores,
  });

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();

  int? _selectedGender; // 1 = Nam, 0 = Nữ
  int? _selectedStoreId;
  DateTime? _selectedDob;

  final EmployeeService _service = EmployeeService();
  bool _isSaving = false;

  bool get _isEditing => widget.employee != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.employee!;
      _nameCtrl.text = e.fullName;
      _phoneCtrl.text = e.phone ?? '';
      _addressCtrl.text = e.address ?? '';
      _salaryCtrl.text = e.salary != null ? e.salary!.toStringAsFixed(0) : '';
      _selectedGender = e.gender;
      _selectedStoreId = e.storeId;
      if (e.dob != null) {
        _dobCtrl.text = e.dob!;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _salaryCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(1995),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF0097A7)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobCtrl.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final employee = EmployeeModel(
      employeeId: widget.employee?.employeeId,
      fullName: _nameCtrl.text.trim(),
      dob: _selectedDob != null
          ? '${_selectedDob!.year}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}'
          : widget.employee?.dob,
      gender: _selectedGender,
      address:
          _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      salary: _salaryCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_salaryCtrl.text.trim()),
      storeId: _selectedStoreId,
      accountId: widget.employee?.accountId,
    );

    if (_isEditing) {
      await _service.updateEmployee(employee);
    } else {
      await _service.createEmployee(employee);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Cập nhật nhân viên thành công!'
              : 'Thêm nhân viên thành công!'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0097A7),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEditing ? 'Chỉnh Sửa Nhân Viên' : 'Thêm Nhân Viên',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildFormCard(),
              const SizedBox(height: 24),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_rounded,
                    color: Color(0xFF0097A7), size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Thông tin nhân viên',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF212121))),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameCtrl,
            decoration: _input('Họ và tên *', Icons.person_outline),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Vui lòng nhập họ tên' : null,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            value: _selectedGender,
            decoration: _input('Giới tính', Icons.wc_outlined),
            hint: const Text('Chọn giới tính'),
            items: const [
              DropdownMenuItem(value: 1, child: Text('Nam')),
              DropdownMenuItem(value: 0, child: Text('Nữ')),
            ],
            onChanged: (v) => setState(() => _selectedGender = v),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _dobCtrl,
            decoration: _input('Ngày sinh', Icons.cake_outlined).copyWith(
              suffixIcon: const Icon(Icons.calendar_today_outlined,
                  color: Color(0xFF0097A7)),
            ),
            readOnly: true,
            onTap: _pickDate,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phoneCtrl,
            decoration: _input('Số điện thoại', Icons.phone_outlined),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _addressCtrl,
            decoration: _input('Địa chỉ', Icons.location_on_outlined),
            maxLines: 2,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _salaryCtrl,
            decoration: _input('Lương (VND)', Icons.payments_outlined),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v != null && v.trim().isNotEmpty) {
                if (double.tryParse(v.trim()) == null) {
                  return 'Lương phải là số hợp lệ';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            value: _selectedStoreId,
            decoration: _input('Cửa hàng', Icons.store_outlined),
            hint: const Text('Chọn cửa hàng'),
            items: widget.stores
                .map((s) => DropdownMenuItem(
                      value: s.storeId,
                      child: Text(s.storeName),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedStoreId = v),
          ),
        ],
      ),
    );
  }

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF0097A7)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0097A7), width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0097A7),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                _isEditing ? 'Cập Nhật' : 'Thêm Nhân Viên',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
