import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../controllers/pos_controller.dart';
import '../controllers/schedule_controller.dart';
import 'login_screen.dart';
import 'inventory_ops_screen.dart';

class PosScreen extends StatefulWidget {
  final String username;
  final int employeeId;
  final int storeId;
  final String fullName;

  const PosScreen({
    super.key,
    required this.username,
    required this.employeeId,
    required this.storeId,
    required this.fullName,
  });

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _posController = PosController();
  final _scheduleController = ScheduleController();

  int _currentTab = 0; // 0: Bán hàng (POS), 1: Lịch làm việc, 2: Tiện ích Kho
  List<Map<String, dynamic>> _products = [];
  Map<int, int> _cart = {}; // ProductID -> Quantity
  double _discountPercent = 0.0;
  bool _isLoading = false;

  // Schedule fields - weekly timetable (read-only)
  late DateTime _weekStart;
  List<Map<String, dynamic>> _storeEmployees = [];
  // _weekShifts[employeeId][dateStr] = shift
  Map<int, Map<String, String>> _weekShifts = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
    _weekStart = DateTime(_weekStart.year, _weekStart.month, _weekStart.day);
    _loadProducts();
    _loadSchedules();
  }

  Future<void> _loadProducts() async {
    final list = await _posController.loadStoreProducts(widget.storeId);
    setState(() {
      _products = list;
    });
  }

  List<DateTime> get _weekDays =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  Future<void> _loadSchedules() async {
    final storeId = widget.storeId;
    final emps = await _scheduleController.loadStoreStaffs(storeId);
    final shifts = await _scheduleController.loadSchedulesForWeek(
      storeId: storeId,
      weekDays: _weekDays,
      employees: emps,
    );

    setState(() {
      _storeEmployees = emps;
      _weekShifts = shifts;
    });
  }

  void _addToCart(int productId) {
    setState(() {
      _cart[productId] = (_cart[productId] ?? 0) + 1;
    });
  }

  void _removeFromCart(int productId) {
    setState(() {
      if (_cart.containsKey(productId)) {
        if (_cart[productId] == 1) {
          _cart.remove(productId);
        } else {
          _cart[productId] = _cart[productId]! - 1;
        }
      }
    });
  }

  double _calculateSubtotal() {
    double subtotal = 0.0;
    _cart.forEach((productId, qty) {
      final prod = _products.firstWhere((p) => p['ProductID'] == productId);
      subtotal += (prod['SalePrice'] as double) * qty;
    });
    return subtotal;
  }

  double _calculateTotal() {
    final subtotal = _calculateSubtotal();
    return subtotal * (1 - _discountPercent / 100);
  }

  Future<void> _handleCheckout() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 mặt hàng!'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await _posController.handleCheckout(
      storeId: widget.storeId,
      employeeId: widget.employeeId,
      cart: _cart,
      products: _products,
      discountPercent: _discountPercent,
      totalAmount: _calculateTotal(),
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      setState(() {
        _cart.clear();
        _discountPercent = 0.0;
      });
      _loadProducts();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 50),
          title: const Text('Thành công', style: TextStyle(fontWeight: FontWeight.w800)),
          content: const Text('Lưu hóa đơn thành công. Hàng tồn kho đã được cập nhật.', textAlign: TextAlign.center),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đóng', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giao dịch thất bại! Vui lòng thử lại.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 36),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
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
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
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
        title: Text(
          _currentTab == 0
              ? 'POS Bán Hàng'
              : _currentTab == 1
                  ? 'Lịch Làm Việc'
                  : 'Tiện Ích Kho',
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        selectedItemColor: AppTheme.primary,
        onTap: (index) {
          setState(() {
            _currentTab = index;
          });
          if (index == 0) _loadProducts();
          if (index == 1) _loadSchedules();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale_rounded), label: 'Bán hàng'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Lịch làm'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: 'Tiện ích Kho'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentTab == 0
              ? _buildPosTab()
              : _currentTab == 1
                  ? _buildScheduleTab()
                  : _buildWarehouseTab(),
    );
  }

  Widget _buildPosTab() {
    final isMobile = MediaQuery.of(context).size.width < 750;

    if (isMobile) {
      return Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            child: _products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.divider),
                        const SizedBox(height: 16),
                        Text('Không có sản phẩm nào trong kho.', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final prod = _products[index];
                      final id = prod['ProductID'] as int;
                      final inCart = _cart[id] ?? 0;
                      return _buildProductCard(prod, id, inCart);
                    },
                  ),
          ),
          if (_cart.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.buttonShadow,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showMobileCartBottomSheet,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.shopping_basket_rounded, color: Colors.white),
                          const SizedBox(width: 12),
                          Text(
                            'Giỏ hàng (${_cart.values.fold(0, (sum, q) => sum + q)} món)',
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          const Spacer(),
                          Text(
                            AppTheme.formatMoney(_calculateTotal()),
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // Tablet/Landscape side-by-side view
    return Row(
      children: [
        // Product list area
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.divider),
                        const SizedBox(height: 16),
                        Text('Không có sản phẩm nào trong kho.', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.88,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final prod = _products[index];
                      final id = prod['ProductID'] as int;
                      final inCart = _cart[id] ?? 0;
                      return _buildProductCard(prod, id, inCart);
                    },
                  ),
          ),
        ),
        // Cart panel area
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.white,
              border: const Border(left: BorderSide(color: AppTheme.divider)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart_rounded, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Chi Tiết Giỏ Hàng',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: _cart.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shopping_basket_outlined, size: 48, color: AppTheme.divider),
                              const SizedBox(height: 12),
                              Text('Chưa chọn món nào.', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: _cart.length,
                          itemBuilder: (context, index) {
                            final productId = _cart.keys.elementAt(index);
                            final qty = _cart[productId]!;
                            final prod = _products.firstWhere((p) => p['ProductID'] == productId);
                            return _buildCartListRow(productId, qty, prod, null);
                          },
                        ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.confirmation_num_outlined, color: AppTheme.textSecondary, size: 18),
                      const SizedBox(width: 8),
                      Text('Mã KM: ', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.divider),
                            borderRadius: BorderRadius.circular(8),
                            color: AppTheme.surfaceLight,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<double>(
                              value: _discountPercent,
                              isExpanded: true,
                              style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                              onChanged: (val) {
                                setState(() {
                                  _discountPercent = val ?? 0.0;
                                });
                              },
                              items: const [
                                DropdownMenuItem(value: 0.0, child: Text('Không giảm')),
                                DropdownMenuItem(value: 10.0, child: Text('Giảm 10%')),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tạm tính:', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
                          Text(AppTheme.formatMoney(_calculateSubtotal()), style: GoogleFonts.inter(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Khuyến mãi:', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
                          Text('-${AppTheme.formatMoney(_calculateSubtotal() * (_discountPercent / 100))}', style: GoogleFonts.inter(color: AppTheme.error, fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tổng thanh toán:', style: GoogleFonts.inter(color: AppTheme.textPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
                          Text(
                            AppTheme.formatMoney(_calculateTotal()),
                            style: GoogleFonts.inter(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _handleCheckout,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('XÁC NHẬN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> prod, int id, int inCart) {
    final hasStock = (prod['Quantity'] as int) > 0;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: inCart > 0 ? AppTheme.primary : AppTheme.divider, width: inCart > 0 ? 1.5 : 1.0),
        boxShadow: AppTheme.cardShadowMd,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasStock ? () => _addToCart(id) : null,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: AspectRatio(
                  aspectRatio: 1.5,
                  child: prod['ImageUrl'] != null && prod['ImageUrl'].toString().isNotEmpty
                      ? Image.network(
                          prod['ImageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppTheme.surfaceLight,
                            child: const Icon(Icons.fastfood_rounded, color: AppTheme.textSecondary, size: 28),
                          ),
                        )
                      : Container(
                          color: AppTheme.surfaceLight,
                          child: const Icon(Icons.fastfood_rounded, color: AppTheme.textSecondary, size: 28),
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prod['ProductName'],
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              AppTheme.formatMoney(prod['SalePrice']),
                              style: GoogleFonts.inter(color: AppTheme.primaryLight, fontWeight: FontWeight.w800, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: hasStock ? AppTheme.surfaceLight : const Color(0xFF3D1515),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              hasStock ? 'Còn: ${prod['Quantity']}' : 'Hết hàng',
                              style: GoogleFonts.inter(fontSize: 9, color: hasStock ? AppTheme.textSecondary : AppTheme.error, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      if (inCart > 0) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Đã chọn: $inCart',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                            ),
                          ),
                        )
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartListRow(int productId, int qty, Map<String, dynamic> prod, StateSetter? setSheetState) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(prod['ProductName'], style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        subtitle: Text(AppTheme.formatMoney(prod['SalePrice'] as double), style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded, color: AppTheme.error),
              onPressed: () {
                _removeFromCart(productId);
                if (setSheetState != null) setSheetState(() {});
                setState(() {});
                if (_cart.isEmpty && setSheetState != null) {
                  Navigator.of(context).pop();
                }
              },
              iconSize: 20,
            ),
            Text('$qty', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textPrimary)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.success),
              onPressed: () {
                _addToCart(productId);
                if (setSheetState != null) setSheetState(() {});
                setState(() {});
              },
              iconSize: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 2: Lịch Làm Việc ──────────────
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

  Widget _buildScheduleTab() {
    final days = _weekDays;
    final weekEnd = days.last;
    final weekLabel = '${_weekStart.day}/${_weekStart.month} – ${weekEnd.day}/${weekEnd.month}/${weekEnd.year}';

    return Column(
      children: [
        // Week nav header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
                tooltip: 'Tuần trước',
                onPressed: () {
                  setState(() {
                    _weekStart = _weekStart.subtract(const Duration(days: 7));
                  });
                  _loadSchedules();
                },
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'THỜI KHÓA BIỂU CỬA HÀNG',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      weekLabel,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
                tooltip: 'Tuần sau',
                onPressed: () {
                  setState(() {
                    _weekStart = _weekStart.add(const Duration(days: 7));
                  });
                  _loadSchedules();
                },
              ),
            ],
          ),
        ),

        // Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _legendBadge(Icons.wb_sunny_rounded, AppTheme.shiftMorning, 'Sáng'),
              _legendBadge(Icons.wb_cloudy_rounded, AppTheme.shiftAfternoon, 'Chiều'),
              _legendBadge(Icons.nights_stay_rounded, AppTheme.shiftEvening, 'Tối'),
              _legendBadge(Icons.event_busy_rounded, AppTheme.shiftOff, 'Nghỉ'),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: AppTheme.primary.withAlpha(80)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('Lịch của bạn', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),

        // Timetable
        Expanded(
          child: _storeEmployees.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 64, color: AppTheme.divider),
                      const SizedBox(height: 16),
                      Text('Không có lịch làm nào.', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
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
                          TableRow(
                            decoration: BoxDecoration(color: AppTheme.primary.withAlpha(18)),
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Text(
                                  'NHÂN VIÊN',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    color: AppTheme.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              for (int i = 0; i < 7; i++)
                                _buildDayHeaderCell(days[i], i),
                            ],
                          ),
                          for (final emp in _storeEmployees)
                            _buildReadOnlyRow(emp, days),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _legendBadge(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildDayHeaderCell(DateTime day, int index) {
    final today = DateTime.now();
    final isToday = day.year == today.year && day.month == today.month && day.day == today.day;
    final isSunday = index == 6;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      alignment: Alignment.center,
      decoration: isToday ? BoxDecoration(color: AppTheme.primaryLight.withAlpha(30)) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _dayLabels[index],
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: isSunday ? AppTheme.error : AppTheme.primary),
          ),
          const SizedBox(height: 2),
          Text(
            '${day.day}/${day.month}',
            style: TextStyle(
              fontSize: 11,
              color: isToday ? AppTheme.primary : AppTheme.textSecondary,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildReadOnlyRow(Map<String, dynamic> emp, List<DateTime> days) {
    final empId = emp['EmployeeID'] as int;
    final empShifts = _weekShifts[empId] ?? {};
    final isMe = empId == widget.employeeId;

    return TableRow(
      decoration: isMe ? BoxDecoration(color: AppTheme.primary.withAlpha(20)) : null,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          constraints: const BoxConstraints(minWidth: 130),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMe) ...[
                const Icon(Icons.person_pin_rounded, size: 14, color: AppTheme.primary),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  emp['FullName'],
                  style: GoogleFonts.inter(
                    fontWeight: isMe ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 13,
                    color: isMe ? AppTheme.primary : AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final day in days)
          _buildReadOnlyShiftCell(day, empShifts),
      ],
    );
  }

  Widget _buildReadOnlyShiftCell(DateTime day, Map<String, String> empShifts) {
    final dateStr = day.toIso8601String().substring(0, 10);
    final shift = empShifts[dateStr] ?? 'Nghỉ';
    final color = _shiftColor(shift);
    final icon = _shiftIcon(shift);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      constraints: const BoxConstraints(minWidth: 90),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(50), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 3),
            Text(
              shift == 'Nghỉ' ? 'Nghỉ' : 'Ca $shift',
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 3: Warehouse ──────────────
  Widget _buildWarehouseTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront_rounded, size: 40, color: AppTheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'Tiện Ích Kho Bãi',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Các chức năng luân chuyển và kiểm kê số lượng hàng hóa trong kho của store hiện tại.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.inventory_2_rounded, color: Colors.white),
                label: const Text('XEM DANH SÁCH TỒN KHO', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => InventoryOpsScreen(
                        initialTab: -1,
                        storeId: widget.storeId,
                        employeeId: widget.employeeId,
                        roleId: 3,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
                label: const Text('ĐIỀU CHUYỂN HÀNG HÓA', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => InventoryOpsScreen(
                        initialTab: 1,
                        storeId: widget.storeId,
                        employeeId: widget.employeeId,
                        roleId: 3,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F51B5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.fact_check_rounded, color: Colors.white),
                label: const Text('KIỂM KHO (AUDIT)', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => InventoryOpsScreen(
                        initialTab: 2,
                        storeId: widget.storeId,
                        employeeId: widget.employeeId,
                        roleId: 3,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE040FB),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMobileCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.shopping_basket_rounded, color: AppTheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Chi tiết giỏ hàng',
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(ctx).pop(),
                          )
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: _cart.length,
                          itemBuilder: (context, index) {
                            final productId = _cart.keys.elementAt(index);
                            final qty = _cart[productId]!;
                            final prod = _products.firstWhere((p) => p['ProductID'] == productId);
                            return _buildCartListRow(productId, qty, prod, setSheetState);
                          },
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Text('Khuyến mãi: ', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 36,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.divider),
                                  borderRadius: BorderRadius.circular(8),
                                  color: AppTheme.surfaceLight,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<double>(
                                    value: _discountPercent,
                                    isExpanded: true,
                                    style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                    onChanged: (val) {
                                      setSheetState(() {
                                        _discountPercent = val ?? 0.0;
                                      });
                                      setState(() {});
                                    },
                                    items: const [
                                      DropdownMenuItem(value: 0.0, child: Text('Không giảm')),
                                      DropdownMenuItem(value: 10.0, child: Text('Giảm 10%')),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tạm tính:', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
                          Text(AppTheme.formatMoney(_calculateSubtotal()), style: GoogleFonts.inter(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Giảm giá:', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
                          Text('-${AppTheme.formatMoney(_calculateSubtotal() * (_discountPercent / 100))}', style: GoogleFonts.inter(color: AppTheme.error, fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider()),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tổng thanh toán:', style: GoogleFonts.inter(color: AppTheme.textPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
                          Text(
                            AppTheme.formatMoney(_calculateTotal()),
                            style: GoogleFonts.inter(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _handleCheckout();
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('XÁC NHẬN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      )
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
