import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../controllers/store_controller.dart';

class StoreManagementScreen extends StatefulWidget {
  const StoreManagementScreen({super.key});

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen>
    with SingleTickerProviderStateMixin {
  final _controller = StoreController();
  List<Map<String, dynamic>> _stores = [];
  bool _isLoading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _loadStores();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStores() async {
    setState(() => _isLoading = true);
    final data = await _controller.loadStores();
    setState(() {
      _stores = data;
      _isLoading = false;
    });
  }

  // ── FORM DIALOG ─────────────────────────────────────────────────────────────

  void _showStoreForm({Map<String, dynamic>? store}) {
    final isEdit = store != null;
    final nameCtrl = TextEditingController(text: store?['StoreName'] ?? '');
    final addrCtrl = TextEditingController(text: store?['Address'] ?? '');
    final phoneCtrl = TextEditingController(text: store?['Phone'] ?? '');
    final openCtrl = TextEditingController(text: store?['OpenTime'] ?? '07:00');
    final closeCtrl = TextEditingController(text: store?['CloseTime'] ?? '22:00');
    String status = store?['Status'] ?? 'Active';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: EdgeInsets.only(
            top: 4,
            left: 20,
            right: 20,
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
              // Handle bar
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
                isEdit ? 'Sửa thông tin cửa hàng' : 'Thêm cửa hàng mới',
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              Form(
                key: formKey,
                child: Column(
                  children: [
                    _buildFormField(
                      controller: nameCtrl,
                      label: 'Tên cửa hàng',
                      hint: 'VD: Store Quận 1',
                      icon: Icons.store_rounded,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildFormField(
                      controller: addrCtrl,
                      label: 'Địa chỉ',
                      hint: '123 Nguyễn Huệ, Q.1',
                      icon: Icons.location_on_rounded,
                    ),
                    const SizedBox(height: 14),
                    _buildFormField(
                      controller: phoneCtrl,
                      label: 'Số điện thoại',
                      hint: '028xxxxxxxx',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v != null && v.isNotEmpty && v.length < 10) {
                          return 'Số điện thoại phải có ít nhất 10 số';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    // Time row
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimeField(
                            controller: openCtrl,
                            label: 'Giờ mở cửa',
                            icon: Icons.schedule_rounded,
                            onTap: () => _pickTime(ctx, openCtrl),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTimeField(
                            controller: closeCtrl,
                            label: 'Giờ đóng cửa',
                            icon: Icons.schedule_outlined,
                            onTap: () => _pickTime(ctx, closeCtrl),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Status toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.darkElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.circle,
                              color: status == 'Active' ? AppTheme.success : AppTheme.error,
                              size: 12),
                          const SizedBox(width: 10),
                          Text('Trạng thái:',
                              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14)),
                          const Spacer(),
                          Switch(
                            value: status == 'Active',
                            onChanged: (val) =>
                                setModal(() => status = val ? 'Active' : 'Inactive'),
                            activeThumbColor: AppTheme.success,
                          ),
                          Text(
                            status == 'Active' ? 'Hoạt động' : 'Tạm đóng',
                            style: GoogleFonts.inter(
                              color: status == 'Active' ? AppTheme.success : AppTheme.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState?.validate() != true) return;
                          Navigator.pop(ctx);
                          bool ok;
                          if (isEdit) {
                            ok = await _controller.editStore(
                              storeId: store['StoreID'] as int,
                              storeName: nameCtrl.text.trim(),
                              address: addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
                              phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                              openTime: openCtrl.text.trim().isEmpty ? null : openCtrl.text.trim(),
                              closeTime: closeCtrl.text.trim().isEmpty ? null : closeCtrl.text.trim(),
                              status: status,
                            );
                          } else {
                            ok = await _controller.addStore(
                              storeName: nameCtrl.text.trim(),
                              address: addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
                              phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                              openTime: openCtrl.text.trim().isEmpty ? null : openCtrl.text.trim(),
                              closeTime: closeCtrl.text.trim().isEmpty ? null : closeCtrl.text.trim(),
                              status: status,
                            );
                          }
                          await _loadStores();
                          if (mounted) {
                            _showSnack(ok
                                ? (isEdit ? 'Đã cập nhật cửa hàng!' : 'Đã thêm cửa hàng mới!')
                                : 'Có lỗi xảy ra, thử lại!');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          isEdit ? 'Lưu thay đổi' : 'Thêm cửa hàng',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime(BuildContext ctx, TextEditingController ctrl) async {
    final parts = ctrl.text.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '7') ?? 7,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: ctx, initialTime: initial);
    if (picked != null) {
      ctrl.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  void _confirmDelete(Map<String, dynamic> store) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Xóa cửa hàng?',
            style: GoogleFonts.inter(color: AppTheme.textPrimary, fontWeight: FontWeight.w800)),
        content: Text(
          'Bạn có chắc muốn xóa "${store['StoreName']}"?\nHành động này không thể hoàn tác.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await _controller.removeStore(store['StoreID'] as int);
              await _loadStores();
              if (mounted) {
                if (result == 'ok') {
                  _showSnack('Đã xóa cửa hàng!');
                } else if (result == 'has_employees') {
                  _showSnack('Không thể xóa: Cửa hàng còn nhân viên!', isError: true);
                } else if (result == 'has_inventory') {
                  _showSnack('Không thể xóa: Cửa hàng còn hàng tồn kho!', isError: true);
                } else {
                  _showSnack('Xóa thất bại!', isError: true);
                }
              }
            },
            child: Text('Xóa', style: GoogleFonts.inter(color: AppTheme.error, fontWeight: FontWeight.w700)),
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

  // ── BUILD ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text('Quản lý Cửa hàng',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadStores,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeIn,
              child: _stores.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _stores.length,
                      itemBuilder: (context, i) => _buildStoreCard(_stores[i], i),
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStoreForm(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Thêm cửa hàng',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.store_mall_directory_rounded,
              size: 72, color: AppTheme.textSecondary.withAlpha(80)),
          const SizedBox(height: 16),
          Text('Chưa có cửa hàng nào',
              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Nhấn nút + để thêm cửa hàng mới',
              style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store, int index) {
    final isActive = store['Status'] == 'Active';
    final employeeCount = store['EmployeeCount'] as int? ?? 0;
    final openTime = store['OpenTime'] as String?;
    final closeTime = store['CloseTime'] as String?;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.darkBorder),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 0),
              child: Row(
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? AppTheme.primaryGradient
                          : const LinearGradient(colors: [Color(0xFF475569), Color(0xFF334155)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.store_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store['StoreName'] as String,
                          style: GoogleFonts.inter(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        _statusBadge(isActive),
                      ],
                    ),
                  ),
                  // Actions
                  PopupMenuButton<String>(
                    color: AppTheme.darkElevated,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onSelected: (val) async {
                      if (val == 'edit') {
                        _showStoreForm(store: store);
                      } else if (val == 'toggle') {
                        await _controller.toggleStatus(
                          store['StoreID'] as int,
                          store['Status'] as String,
                        );
                        _loadStores();
                      } else if (val == 'delete') {
                        _confirmDelete(store);
                      }
                    },
                    itemBuilder: (_) => [
                      _menuItem('edit', Icons.edit_rounded, 'Chỉnh sửa', AppTheme.info),
                      _menuItem(
                        'toggle',
                        isActive ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
                        isActive ? 'Tạm đóng cửa' : 'Mở lại',
                        isActive ? AppTheme.warning : AppTheme.success,
                      ),
                      _menuItem('delete', Icons.delete_rounded, 'Xóa', AppTheme.error),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.darkElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.more_vert_rounded,
                          color: AppTheme.textSecondary, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            // Info rows
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  if (store['Address'] != null && (store['Address'] as String).isNotEmpty)
                    _infoRow(Icons.location_on_rounded, store['Address'] as String),
                  if (store['Phone'] != null && (store['Phone'] as String).isNotEmpty)
                    _infoRow(Icons.phone_rounded, store['Phone'] as String),
                  if (openTime != null || closeTime != null)
                    _infoRow(
                      Icons.schedule_rounded,
                      '${openTime ?? '--'} – ${closeTime ?? '--'}',
                      color: AppTheme.accent,
                    ),
                  _infoRow(
                    Icons.people_rounded,
                    '$employeeCount nhân viên',
                    color: AppTheme.info,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String val, IconData icon, String label, Color color) {
    return PopupMenuItem<String>(
      value: val,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _statusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.success.withAlpha(30) : AppTheme.error.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isActive ? '● Hoạt động' : '● Tạm đóng',
        style: GoogleFonts.inter(
          color: isActive ? AppTheme.success : AppTheme.error,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: color ?? AppTheme.textSecondary, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: color ?? AppTheme.textSecondary,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }

  Widget _buildTimeField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, size: 20),
          ),
        ),
      ),
    );
  }
}
