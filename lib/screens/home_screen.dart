import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../controllers/home_controller.dart';
import 'login_screen.dart';
import 'inventory_ops_screen.dart';
import 'employee_admin_screen.dart';
import 'employee_info_screen.dart';
import 'revenue_report_screen.dart';
import 'store_management_screen.dart';
import 'category_management_screen.dart';
import 'product_management_screen.dart';
import 'supplier_management_screen.dart';
import 'transfer_approval_screen.dart';
import 'invoice_management_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final int roleId;
  final int? storeId;
  final int employeeId;
  final String fullName;

  const HomeScreen({
    super.key,
    required this.username,
    required this.roleId,
    this.storeId,
    required this.employeeId,
    required this.fullName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _homeController = HomeController();
  late AnimationController _animationController;
  late Animation<double> _fadeIn;

  double _todayRevenue = 0.0;
  int _todayOrders = 0;
  int _staffCount = 0;
  bool _isLoading = false;

  List<_DashboardModule> _modules = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _animationController.forward();
    _buildModules();
    _loadStats();
  }

  void _buildModules() {
    _modules.clear();
    if (widget.roleId == 1) {
      _modules.add(_DashboardModule(
        icon: Icons.people_alt_rounded,
        label: 'Quản trị tài khoản',
        subtitle: 'Cấp & khóa tài khoản',
        color: const Color(0xFF3B82F6),
        bgGradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => EmployeeAdminScreen(roleId: 1, employeeId: widget.employeeId),
        )).then((_) => _loadStats()),
      ));
      _modules.add(_DashboardModule(
        icon: Icons.store_mall_directory_rounded,
        label: 'Quản lý Cửa hàng',
        subtitle: 'Thêm, sửa, xóa store',
        color: const Color(0xFF06B6D4),
        bgGradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0284C7)]),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const StoreManagementScreen(),
        )).then((_) => _loadStats()),
      ));
      _modules.add(_DashboardModule(
        icon: Icons.badge_rounded,
        label: 'Thông tin Nhân viên',
        subtitle: 'Xem & sửa hồ sơ',
        color: const Color(0xFF3B82F6),
        bgGradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4338CA)]),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const EmployeeInfoScreen(),
        )),
      ));
      _modules.add(_DashboardModule(
        icon: Icons.category_rounded,
        label: 'Danh mục SP',
        subtitle: 'Thêm, sửa danh mục',
        color: const Color(0xFFF59E0B),
        bgGradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const CategoryManagementScreen(),
        )),
      ));
      _modules.add(_DashboardModule(
        icon: Icons.inventory_2_rounded,
        label: 'Danh sách SP',
        subtitle: 'Quản lý sản phẩm',
        color: const Color(0xFF10B981),
        bgGradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF047857)]),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const ProductManagementScreen(),
        )),
      ));
      _modules.add(_DashboardModule(
        icon: Icons.local_shipping_rounded,
        label: 'Nhà cung cấp',
        subtitle: 'Quản lý đối tác',
        color: const Color(0xFF8B5CF6),
        bgGradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const SupplierManagementScreen(),
        )),
      ));
      _modules.add(_DashboardModule(
        icon: Icons.bar_chart_rounded,
        label: 'Báo cáo chuỗi',
        subtitle: 'Thống kê tổng hợp',
        color: const Color(0xFF8B5CF6),
        bgGradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFF9D174D)]),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => RevenueReportScreen(roleId: 1),
        )),
      ));
      _modules.add(_DashboardModule(
        icon: Icons.receipt_long_rounded,
        label: 'Hóa đơn',
        subtitle: 'Quản lý & Xem lịch sử',
        color: const Color(0xFFEF4444),
        bgGradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFB91C1C)]),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => InvoiceManagementScreen(roleId: 1),
        )),
      ));
    } else {
      _modules.add(_DashboardModule(
        icon: Icons.inventory_2_rounded,
        label: 'Tồn kho',
        subtitle: 'Xem chi tiết kho hiện tại',
        color: const Color(0xFF10B981),
        bgGradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF047857)]),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => InventoryOpsScreen(initialTab: -1, storeId: widget.storeId!, employeeId: widget.employeeId, roleId: 2),
        )).then((_) => _loadStats()),
      ));
      _modules.add(_DashboardModule(
        icon: Icons.move_to_inbox_rounded,
        label: 'Nhập hàng',
        subtitle: 'Nhập hàng vào kho',
        color: const Color(0xFF9C27B0),
        bgGradient: const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF6A1B9A)]),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => InventoryOpsScreen(initialTab: 0, storeId: widget.storeId!, employeeId: widget.employeeId, roleId: 2),
        )).then((_) => _loadStats()),
      ));
      _modules.add(_DashboardModule(
        icon: Icons.approval_rounded,
        label: 'Duyệt chuyển kho',
        subtitle: 'Phê duyệt yêu cầu từ Staff',
        color: const Color(0xFF3B82F6),
        bgGradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TransferApprovalScreen(
            storeId: widget.storeId!,
            employeeId: widget.employeeId,
          ),
        )).then((_) => _loadStats()),
      ));
      _modules.add(_DashboardModule(
        icon: Icons.calendar_month_rounded,
        label: 'Xếp lịch làm',
        subtitle: 'Phân ca cho nhân viên',
        color: const Color(0xFF00BCD4),
        bgGradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF00838F)]),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => EmployeeAdminScreen(roleId: 2, storeId: widget.storeId!, employeeId: widget.employeeId),
        )),
      ));
      _modules.add(_DashboardModule(
        icon: Icons.bar_chart_rounded,
        label: 'Báo cáo doanh thu',
        subtitle: 'Doanh thu của store',
        color: const Color(0xFF8B5CF6),
        bgGradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => RevenueReportScreen(roleId: 2, storeId: widget.storeId!),
        )),
      ));
      _modules.add(_DashboardModule(
        icon: Icons.receipt_long_rounded,
        label: 'Hóa đơn',
        subtitle: 'Quản lý hóa đơn cửa hàng',
        color: const Color(0xFFEF4444),
        bgGradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFB91C1C)]),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => InvoiceManagementScreen(roleId: 2, storeId: widget.storeId),
        )),
      ));
    }
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final data = await _homeController.loadDashboardData(widget.roleId, widget.storeId);
    setState(() {
      _todayRevenue = data['todayRevenue'] as double;
      _todayOrders = data['todayOrdersCount'] as int;
      _staffCount = data['employeeCount'] as int;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => AlertDialog(
        icon: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: const Color(0xFFFEF2F2), shape: BoxShape.circle),
          child: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 28),
        ),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi hệ thống không?'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getTodayDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeIn,
              child: CustomScrollView(
                slivers: [
                  // ── Header ──────────────────────────────────────────────────
                  SliverAppBar(
                    expandedHeight: 200,
                    floating: false,
                    pinned: true,
                    backgroundColor: AppTheme.primary,
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(
                        onPressed: _showLogoutDialog,
                        tooltip: 'Đăng xuất',
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.parallax,
                      background: Container(
                        decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
                        child: Stack(
                          children: [
                            // Subtle circle deco
                            Positioned(top: -30, right: -30, child: Container(
                              width: 160, height: 160,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(8)),
                            )),
                            Positioned(bottom: -20, left: -40, child: Container(
                              width: 120, height: 120,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(5)),
                            )),
                            SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 12, 80, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Row(children: [
                                      Container(
                                        width: 48, height: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.accent.withAlpha(40),
                                          border: Border.all(color: AppTheme.accent.withAlpha(80), width: 2),
                                        ),
                                        child: const Icon(Icons.person_rounded, color: AppTheme.accent, size: 26),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Xin chào! 👋', style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
                                          Text(widget.fullName, style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppTheme.accent.withAlpha(35),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: AppTheme.accent.withAlpha(60), width: 1),
                                            ),
                                            child: Text(
                                              widget.roleId == 1 ? '⚡ Chủ Chuỗi' : '🏪 Cửa Hàng Trưởng',
                                              style: GoogleFonts.inter(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ],
                                      )),
                                    ]),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Stats ────────────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: _buildSummaryStats(),
                    ),
                  ),

                  // ── Section title ────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Row(children: [
                        Container(width: 4, height: 20, decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 10),
                        Text('Chức năng quản lý', style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  ),

                  // ── Module grid ──────────────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildModuleCard(_modules[index], index),
                        childCount: _modules.length,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1.2,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 36)),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.buttonShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.trending_up_rounded, color: AppTheme.accent, size: 18),
            const SizedBox(width: 8),
            Text('Tổng quan hôm nay', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withAlpha(20), borderRadius: BorderRadius.circular(8)),
              child: Text(_getTodayDate(), style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
            ),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            _buildStatItem('Doanh thu', _formatRevenue(_todayRevenue), Icons.payments_rounded),
            _buildStatDivider(),
            _buildStatItem('Đơn hàng', '$_todayOrders', Icons.receipt_long_rounded),
            _buildStatDivider(),
            _buildStatItem('Nhân sự', '$_staffCount', Icons.people_rounded),
          ]),
        ],
      ),
    );
  }

  String _formatRevenue(double rev) {
    return AppTheme.formatMoney(rev);
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(child: Column(children: [
      Icon(icon, color: AppTheme.accent, size: 22),
      const SizedBox(height: 6),
      Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 2),
      Text(label, style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
    ]));
  }

  Widget _buildStatDivider() => Container(width: 1, height: 44, color: Colors.white.withAlpha(30));

  Widget _buildModuleCard(_DashboardModule module, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + index * 70),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: module.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.divider),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: module.bgGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(module.icon, color: Colors.white, size: 22),
                ),
                const Spacer(),
                Text(module.label, style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(module.subtitle, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 10, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardModule {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final LinearGradient bgGradient;
  final VoidCallback onTap;

  const _DashboardModule({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.bgGradient,
    required this.onTap,
  });
}
