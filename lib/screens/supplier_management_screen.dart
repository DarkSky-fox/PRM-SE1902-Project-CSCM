import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../controllers/supplier_controller.dart';

class SupplierManagementScreen extends StatefulWidget {
  const SupplierManagementScreen({super.key});

  @override
  State<SupplierManagementScreen> createState() => _SupplierManagementScreenState();
}

class _SupplierManagementScreenState extends State<SupplierManagementScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = SupplierController();
  List<Map<String, dynamic>> _suppliers = [];
  bool _isLoading = false;
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];

  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _loadSuppliers();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoading = true);
    final data = await _ctrl.loadSuppliers();
    setState(() {
      _suppliers = data;
      _isLoading = false;
      _applyFilter();
    });
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _suppliers.where((s) {
        return q.isEmpty ||
            (s['SupplierName'] as String? ?? '').toLowerCase().contains(q) ||
            (s['Phone'] as String? ?? '').contains(q);
      }).toList();
    });
  }

  void _showSupplierForm({Map<String, dynamic>? supplier}) {
    final isEdit = supplier != null;
    final nameCtrl = TextEditingController(text: supplier?['SupplierName'] ?? '');
    final addrCtrl = TextEditingController(text: supplier?['Address'] ?? '');
    final emailCtrl = TextEditingController(text: supplier?['Email'] ?? '');
    final phoneCtrl = TextEditingController(text: supplier?['Phone'] ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          top: 4, left: 20, right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
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
            Text(
              isEdit ? 'Sửa nhà cung cấp' : 'Thêm nhà cung cấp',
              style: GoogleFonts.inter(
                color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            Form(
              key: formKey,
              child: Column(
                children: [
                  _field(nameCtrl, 'Tên nhà cung cấp *', Icons.business_rounded,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên' : null),
                  const SizedBox(height: 12),
                  _field(addrCtrl, 'Địa chỉ', Icons.location_on_rounded),
                  const SizedBox(height: 12),
                  _field(emailCtrl, 'Email', Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v != null && v.isNotEmpty) {
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!emailRegex.hasMatch(v)) return 'Email không hợp lệ';
                        }
                        return null;
                      }),
                  const SizedBox(height: 12),
                  _field(phoneCtrl, 'Số điện thoại', Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v != null && v.isNotEmpty && v.length < 10) {
                          return 'SĐT phải có ít nhất 10 số';
                        }
                        return null;
                      }),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        Navigator.pop(ctx);
                        bool ok;
                        if (isEdit) {
                          ok = await _ctrl.editSupplier(
                            supplierId: supplier['SupplierID'] as int,
                            supplierName: nameCtrl.text.trim(),
                            address: addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
                            email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                            phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                          );
                        } else {
                          ok = await _ctrl.addSupplier(
                            supplierName: nameCtrl.text.trim(),
                            address: addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
                            email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                            phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                          );
                        }
                        await _loadSuppliers();
                        if (mounted) {
                          _showSnack(ok
                              ? (isEdit ? 'Đã cập nhật nhà cung cấp!' : 'Đã thêm nhà cung cấp!')
                              : 'Có lỗi xảy ra!');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        isEdit ? 'Lưu thay đổi' : 'Thêm nhà cung cấp',
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> supplier) {
    final count = supplier['ProductCount'] as int? ?? 0;
    if (count > 0) {
      _showSnack('Không thể xóa: Còn $count sản phẩm từ nhà cung cấp này!', isError: true);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Xóa nhà cung cấp?',
            style: GoogleFonts.inter(color: AppTheme.textPrimary, fontWeight: FontWeight.w800)),
        content: Text('Xóa "${supplier['SupplierName']}"?',
            style: GoogleFonts.inter(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await _ctrl.removeSupplier(supplier['SupplierID'] as int);
              await _loadSuppliers();
              if (mounted) {
                _showSnack(result == 'ok' ? 'Đã xóa nhà cung cấp!' : 'Xóa thất bại!',
                    isError: result != 'ok');
              }
            },
            child: Text('Xóa',
                style: GoogleFonts.inter(color: AppTheme.error, fontWeight: FontWeight.w700)),
          ),
        ],
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
        title: Text('Quản lý Nhà cung cấp',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            color: AppTheme.darkCard,
            child: TextField(
              controller: _searchCtrl,
              style: GoogleFonts.inter(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Tìm nhà cung cấp...',
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(children: [
              Text('${_filtered.length} nhà cung cấp',
                  style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
            ]),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FadeTransition(
                    opacity: _fadeIn,
                    child: _filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.local_shipping_rounded,
                                    size: 72,
                                    color: AppTheme.textSecondary.withAlpha(80)),
                                const SizedBox(height: 16),
                                Text('Không có nhà cung cấp',
                                    style: GoogleFonts.inter(
                                        color: AppTheme.textSecondary, fontSize: 16)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: _filtered.length,
                            itemBuilder: (context, i) =>
                                _buildSupplierCard(_filtered[i], i),
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSupplierForm(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Thêm nhà cung cấp',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildSupplierCard(Map<String, dynamic> supplier, int index) {
    final count = supplier['ProductCount'] as int? ?? 0;
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_shipping_rounded,
                    color: Color(0xFF8B5CF6), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier['SupplierName'] as String,
                      style: GoogleFonts.inter(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (supplier['Phone'] != null &&
                        (supplier['Phone'] as String).isNotEmpty)
                      _infoRow(Icons.phone_rounded, supplier['Phone'] as String),
                    if (supplier['Email'] != null &&
                        (supplier['Email'] as String).isNotEmpty)
                      _infoRow(Icons.email_rounded, supplier['Email'] as String),
                    if (supplier['Address'] != null &&
                        (supplier['Address'] as String).isNotEmpty)
                      _infoRow(Icons.location_on_rounded, supplier['Address'] as String),
                    _infoRow(Icons.inventory_2_rounded, '$count sản phẩm',
                        color: const Color(0xFF8B5CF6)),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_rounded, color: AppTheme.info, size: 20),
                    onPressed: () => _showSupplierForm(supplier: supplier),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_rounded, color: AppTheme.error, size: 20),
                    onPressed: () => _confirmDelete(supplier),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color ?? AppTheme.textSecondary),
          const SizedBox(width: 6),
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
