import 'package:flutter/material.dart';
import '../../models/store_model.dart';
import '../../services/store_service.dart';

class StoreFormScreen extends StatefulWidget {
  final StoreModel? store;
  const StoreFormScreen({super.key, this.store});

  @override
  State<StoreFormScreen> createState() => _StoreFormScreenState();
}

class _StoreFormScreenState extends State<StoreFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _status = 'Active';
  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;
  final StoreService _service = StoreService();
  bool _isSaving = false;

  bool get _isEditing => widget.store != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameCtrl.text = widget.store!.storeName;
      _addressCtrl.text = widget.store!.address ?? '';
      _phoneCtrl.text = widget.store!.phone ?? '';
      _status = widget.store!.status ?? 'Active';
      _openTime = _parseTime(widget.store!.openTime);
      _closeTime = _parseTime(widget.store!.closeTime);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  /// Parse "HH:mm" string to TimeOfDay
  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    final parts = timeStr.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  /// Format TimeOfDay to "HH:mm"
  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Display string for time (e.g. "07:00 AM")
  String _displayTime(TimeOfDay? t) {
    if (t == null) return 'Chưa đặt';
    return t.format(context);
  }

  Future<void> _pickTime({required bool isOpen}) async {
    final initial = isOpen
        ? (_openTime ?? const TimeOfDay(hour: 7, minute: 0))
        : (_closeTime ?? const TimeOfDay(hour: 22, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF546E7A)),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isOpen) {
          _openTime = picked;
        } else {
          _closeTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final store = StoreModel(
      storeId: widget.store?.storeId,
      storeName: _nameCtrl.text.trim(),
      address:
          _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      phone:
          _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      status: _status,
      openTime: _openTime != null ? _formatTime(_openTime!) : null,
      closeTime: _closeTime != null ? _formatTime(_closeTime!) : null,
    );

    if (_isEditing) {
      await _service.updateStore(store);
    } else {
      await _service.createStore(store);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Cập nhật cửa hàng thành công!'
              : 'Thêm cửa hàng thành công!'),
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
        backgroundColor: const Color(0xFF546E7A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEditing ? 'Chỉnh Sửa Cửa Hàng' : 'Thêm Cửa Hàng',
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
              const SizedBox(height: 16),
              _buildTimeCard(),
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
                  color: const Color(0xFFECEFF1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.store_rounded,
                    color: Color(0xFF607D8B), size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Thông tin cửa hàng',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF212121))),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameCtrl,
            decoration: _input('Tên cửa hàng *', Icons.store_outlined),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Vui lòng nhập tên cửa hàng' : null,
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
          DropdownButtonFormField<String>(
            value: _status,
            decoration: _input('Trạng thái', Icons.toggle_on_outlined),
            items: const [
              DropdownMenuItem(value: 'Active', child: Text('Active')),
              DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
            ],
            onChanged: (v) => setState(() => _status = v ?? 'Active'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard() {
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
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.access_time_rounded,
                    color: Color(0xFFF9A825), size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Giờ hoạt động',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF212121))),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildTimePicker(isOpen: true)),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.grey, size: 20),
              const SizedBox(width: 12),
              Expanded(child: _buildTimePicker(isOpen: false)),
            ],
          ),
          if (_openTime != null &&
              _closeTime != null &&
              !_isValidTimeRange()) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange.shade700, size: 16),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'Lưu ý: Giờ đóng cửa trước giờ mở cửa (có thể là qua đêm)',
                      style: TextStyle(
                          color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isValidTimeRange() {
    if (_openTime == null || _closeTime == null) return true;
    final openMinutes = _openTime!.hour * 60 + _openTime!.minute;
    final closeMinutes = _closeTime!.hour * 60 + _closeTime!.minute;
    return closeMinutes > openMinutes;
  }

  Widget _buildTimePicker({required bool isOpen}) {
    final time = isOpen ? _openTime : _closeTime;
    final label = isOpen ? 'Giờ mở cửa' : 'Giờ đóng cửa';
    final icon = isOpen ? Icons.wb_sunny_rounded : Icons.nightlight_round;
    final color = isOpen ? const Color(0xFFF9A825) : const Color(0xFF5C6BC0);
    final bgColor =
        isOpen ? const Color(0xFFFFFDE7) : const Color(0xFFE8EAF6);

    return GestureDetector(
      onTap: () => _pickTime(isOpen: isOpen),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: time != null ? color : Colors.grey.shade300, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(
              _displayTime(time),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: time != null ? color : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Nhấn để đặt',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF607D8B)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF607D8B), width: 2),
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
          backgroundColor: const Color(0xFF546E7A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                _isEditing ? 'Cập Nhật' : 'Thêm Cửa Hàng',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
