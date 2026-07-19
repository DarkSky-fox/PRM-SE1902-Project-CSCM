import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../controllers/inventory_ops_controller.dart';

class InventoryOpsScreen extends StatefulWidget {
  final int initialTab; // 0: Nhập hàng (PO), 1: Chuyển kho, 2: Kiểm kho
  final int storeId;
  final int employeeId;
  final int roleId;

  const InventoryOpsScreen({
    super.key,
    required this.initialTab,
    required this.storeId,
    required this.employeeId,
    required this.roleId,
  });

  @override
  State<InventoryOpsScreen> createState() => _InventoryOpsScreenState();
}

class _InventoryOpsScreenState extends State<InventoryOpsScreen>
    with SingleTickerProviderStateMixin {
  final _inventoryOpsController = InventoryOpsController();
  late TabController _tabController;
  List<Map<String, dynamic>> _inventory = [];
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _otherStores = [];

  int? _selectedImportProductId;
  final _importQtyController = TextEditingController();
  final _importPriceController = TextEditingController();

  int? _selectedTransferProductId;
  int? _selectedTargetStoreId;
  final _transferQtyController = TextEditingController();

  int? _selectedAuditProductId;
  final _auditActualQtyController = TextEditingController();

  bool _isLoading = false;

  // Search & sorting for inventory list tab
  String _searchQuery = '';
  String _sortBy = 'name';

  @override
  void initState() {
    super.initState();
    int tabCount = widget.roleId == 2 ? 4 : 2;
    int initialIndex;
    if (widget.roleId == 2) {
      // For manager:
      // initialTab: 0 -> Nhập kho (Tab index 1)
      // initialTab: 1 -> Chuyển kho (Tab index 2)
      // initialTab: 2 -> Kiểm kho (Tab index 3)
      // Tab index 0 is the new Tồn kho tab.
      initialIndex = (widget.initialTab >= 0 && widget.initialTab <= 2)
          ? widget.initialTab + 1
          : 0;
    } else {
      // For staff:
      // initialTab: 1 -> Chuyển kho (Tab index 0)
      // initialTab: 2 -> Kiểm kho (Tab index 1)
      initialIndex = widget.initialTab == 1 ? 0 : 1;
    }

    _tabController = TabController(length: tabCount, vsync: this, initialIndex: initialIndex);
    _loadData();
  }

  Future<void> _loadData() async {
    final inv = await _inventoryOpsController.loadInventory(widget.storeId);
    final prods = await _inventoryOpsController.loadProducts();
    final stores = await _inventoryOpsController.loadStores();

    setState(() {
      _inventory = inv;
      _allProducts = prods;
      _otherStores = stores.where((s) => s['StoreID'] != widget.storeId).toList();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importQtyController.dispose();
    _importPriceController.dispose();
    _transferQtyController.dispose();
    _auditActualQtyController.dispose();
    super.dispose();
  }

  Future<void> _handleImport() async {
    if (_selectedImportProductId == null ||
        _importQtyController.text.isEmpty ||
        _importPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin nhập kho!'), backgroundColor: AppTheme.error),
      );
      return;
    }

    final qty = int.tryParse(_importQtyController.text) ?? 0;
    final price = double.tryParse(_importPriceController.text) ?? 0.0;

    if (qty <= 0 || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số lượng và đơn giá phải lớn hơn 0!'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await _inventoryOpsController.handleImport(
      employeeId: widget.employeeId,
      storeId: widget.storeId,
      productId: _selectedImportProductId!,
      quantity: qty,
      importPrice: price,
    );

    setState(() => _isLoading = false);

    if (success) {
      _importQtyController.clear();
      _importPriceController.clear();
      setState(() => _selectedImportProductId = null);
      _loadData();
      _showSuccessDialog('Nhập hàng thành công. Kho của bạn đã được cộng thêm.');
    } else {
      _showErrorSnackBar('Lỗi hệ thống khi nhập hàng!');
    }
  }

  Future<void> _handleTransfer() async {
    if (_selectedTransferProductId == null ||
        _selectedTargetStoreId == null ||
        _transferQtyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin chuyển kho!'), backgroundColor: AppTheme.error),
      );
      return;
    }

    final qty = int.tryParse(_transferQtyController.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số lượng chuyển phải lớn hơn 0!'), backgroundColor: AppTheme.error),
      );
      return;
    }

    final sourceItem = _inventory.firstWhere(
      (item) => item['ProductID'] == _selectedTransferProductId,
      orElse: () => {},
    );

    if (sourceItem.isEmpty || (sourceItem['Quantity'] as int) < qty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số lượng hàng tồn kho nguồn không đủ để thực hiện chuyển.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await _inventoryOpsController.handleTransfer(
      fromStoreId: widget.storeId,
      toStoreId: _selectedTargetStoreId!,
      productId: _selectedTransferProductId!,
      quantity: qty,
    );

    setState(() => _isLoading = false);

    if (success) {
      _transferQtyController.clear();
      setState(() {
        _selectedTransferProductId = null;
        _selectedTargetStoreId = null;
      });
      _loadData();
      _showSuccessDialog('Đã thực hiện chuyển hàng thành công.');
    } else {
      _showErrorSnackBar('Lỗi hệ thống khi chuyển kho!');
    }
  }

  Future<void> _handleAudit() async {
    if (_selectedAuditProductId == null || _auditActualQtyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập sản phẩm và số lượng thực tế!'), backgroundColor: AppTheme.error),
      );
      return;
    }

    final qty = int.tryParse(_auditActualQtyController.text) ?? -1;
    if (qty < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số lượng thực tế không hợp lệ!'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await _inventoryOpsController.handleAudit(
      storeId: widget.storeId,
      productId: _selectedAuditProductId!,
      actualQty: qty,
    );

    setState(() => _isLoading = false);

    if (success) {
      _auditActualQtyController.clear();
      setState(() => _selectedAuditProductId = null);
      _loadData();
      _showSuccessDialog('Đã cập nhật số lượng tồn kho thực tế thành công.');
    } else {
      _showErrorSnackBar('Lỗi hệ thống khi kiểm kho!');
    }
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  Widget _buildInventoryTab() {
    final filteredList = _inventory.where((item) {
      final name = (item['ProductName'] ?? '').toString().toLowerCase();
      final category = (item['CategoryName'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || category.contains(query);
    }).toList();

    if (_sortBy == 'name') {
      filteredList.sort((a, b) => (a['ProductName'] ?? '').compareTo(b['ProductName'] ?? ''));
    } else if (_sortBy == 'qty_asc') {
      filteredList.sort((a, b) => (a['Quantity'] as int).compareTo(b['Quantity'] as int));
    } else if (_sortBy == 'qty_desc') {
      filteredList.sort((a, b) => (b['Quantity'] as int).compareTo(a['Quantity'] as int));
    } else if (_sortBy == 'price_asc') {
      filteredList.sort((a, b) => (a['SalePrice'] as num).compareTo(b['SalePrice'] as num));
    } else if (_sortBy == 'price_desc') {
      filteredList.sort((a, b) => (b['SalePrice'] as num).compareTo(a['SalePrice'] as num));
    }

    int totalItems = filteredList.length;
    int totalQty = filteredList.fold<int>(0, (sum, item) => sum + (item['Quantity'] as int));

    return Column(
      children: [
        // Search & Filter header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Tìm sản phẩm hoặc danh mục...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.divider, width: 1.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    dropdownColor: AppTheme.white,
                    icon: const Icon(Icons.sort_rounded, color: AppTheme.accent),
                    items: const [
                      DropdownMenuItem(value: 'name', child: Text('Tên A-Z')),
                      DropdownMenuItem(value: 'qty_desc', child: Text('Tồn kho giảm')),
                      DropdownMenuItem(value: 'qty_asc', child: Text('Tồn kho tăng')),
                      DropdownMenuItem(value: 'price_desc', child: Text('Giá giảm')),
                      DropdownMenuItem(value: 'price_asc', child: Text('Giá tăng')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _sortBy = val);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Summary stats bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng số mặt hàng: $totalItems',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Text(
                'Tổng số lượng: $totalQty',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: filteredList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.textLight),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty ? 'Không tìm thấy sản phẩm phù hợp' : 'Kho hàng trống',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    final String name = item['ProductName'] ?? '';
                    final String category = item['CategoryName'] ?? '';
                    final int qty = item['Quantity'] ?? 0;
                    final double price = (item['SalePrice'] as num?)?.toDouble() ?? 0.0;
                    final int productId = item['ProductID'] ?? 0;

                    // Warning color for low stock
                    final isLowStock = qty <= 5;

                    return Card(
                      color: AppTheme.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: isLowStock ? AppTheme.warning.withAlpha(100) : AppTheme.divider,
                          width: isLowStock ? 1.5 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppTheme.surfaceLight,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          category,
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      AppTheme.formatMoney(price),
                                      style: const TextStyle(
                                        color: AppTheme.accent,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (isLowStock)
                                          const Padding(
                                            padding: EdgeInsets.only(right: 4),
                                            child: Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 16),
                                          ),
                                        Text(
                                          'Tồn: $qty',
                                          style: TextStyle(
                                            color: isLowStock ? AppTheme.warning : AppTheme.success,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: AppTheme.divider),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedImportProductId = productId;
                                    });
                                    _tabController.animateTo(1); // Switch to Nhập Kho
                                  },
                                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 16, color: Colors.white),
                                  label: const Text('Nhập kho'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedTransferProductId = productId;
                                    });
                                    _tabController.animateTo(2); // Switch to Chuyển Kho
                                  },
                                  icon: const Icon(Icons.swap_horiz_rounded, size: 16, color: Colors.white),
                                  label: const Text('Chuyển kho'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Tab> tabs = [];
    if (widget.roleId == 2) {
      tabs.add(const Tab(icon: Icon(Icons.inventory_2_rounded), text: 'Tồn kho'));
      tabs.add(const Tab(icon: Icon(Icons.move_to_inbox_rounded), text: 'Nhập kho'));
    }
    tabs.add(const Tab(icon: Icon(Icons.swap_horiz_rounded), text: 'Chuyển kho'));
    tabs.add(const Tab(icon: Icon(Icons.fact_check_rounded), text: 'Kiểm kho'));

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        title: const Text('Quản Lý Kho Hàng'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: widget.roleId == 2,
          tabAlignment: widget.roleId == 2 ? TabAlignment.start : null,
          tabs: tabs,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: widget.roleId == 2
                  ? [
                      _buildInventoryTab(),
                      _buildImportTab(),
                      _buildTransferTab(),
                      _buildAuditTab(),
                    ]
                  : [
                      _buildTransferTab(),
                      _buildAuditTab(),
                    ],
            ),
    );
  }

  Widget _buildTabLayout({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> formFields,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.headerGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12)),
                ],
              )),
            ]),
          ),
          const SizedBox(height: 20),
          // Form container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.divider),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: formFields,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: onPressed,
            child: Text(buttonText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildImportTab() {
    return _buildTabLayout(
      icon: Icons.move_to_inbox_rounded,
      title: 'Nhập Hàng Vào Kho',
      subtitle: 'Tạo phiếu nhập từ nhà cung cấp',
      buttonText: 'XÁC NHẬN NHẬP KHO',
      onPressed: _handleImport,
      formFields: [
        DropdownButtonFormField<int>(
          value: _selectedImportProductId,
          decoration: const InputDecoration(labelText: 'Chọn sản phẩm'),
          items: _allProducts.map((p) => DropdownMenuItem<int>(
            value: p['ProductID'],
            child: Text(p['ProductName']),
          )).toList(),
          onChanged: (val) => setState(() => _selectedImportProductId = val),
        ),
        const SizedBox(height: 16),
        TextField(controller: _importQtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số lượng nhập')),
        const SizedBox(height: 16),
        TextField(controller: _importPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Giá nhập (VNĐ)')),
      ],
    );
  }

  Widget _buildTransferTab() {
    return _buildTabLayout(
      icon: Icons.swap_horiz_rounded,
      title: 'Điều Chuyển Hàng Hóa',
      subtitle: 'Chuyển hàng sang cửa hàng khác',
      buttonText: 'XÁC NHẬN CHUYỂN KHO',
      onPressed: _handleTransfer,
      formFields: [
        DropdownButtonFormField<int>(
          value: _selectedTransferProductId,
          decoration: const InputDecoration(labelText: 'Sản phẩm chuyển'),
          items: _inventory.map((p) => DropdownMenuItem<int>(
            value: p['ProductID'],
            child: Text('${p['ProductName']} (Còn: ${p['Quantity']})'),
          )).toList(),
          onChanged: (val) => setState(() => _selectedTransferProductId = val),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          value: _selectedTargetStoreId,
          decoration: const InputDecoration(labelText: 'Cửa hàng nhận'),
          items: _otherStores.map((s) => DropdownMenuItem<int>(
            value: s['StoreID'],
            child: Text(s['StoreName']),
          )).toList(),
          onChanged: (val) => setState(() => _selectedTargetStoreId = val),
        ),
        const SizedBox(height: 16),
        TextField(controller: _transferQtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số lượng chuyển')),
      ],
    );
  }

  Widget _buildAuditTab() {
    return _buildTabLayout(
      icon: Icons.fact_check_rounded,
      title: 'Kiểm Kê Tồn Kho',
      subtitle: 'Cập nhật số lượng thực tế',
      buttonText: 'CẬP NHẬT TỒN KHO',
      onPressed: _handleAudit,
      formFields: [
        DropdownButtonFormField<int>(
          value: _selectedAuditProductId,
          decoration: const InputDecoration(labelText: 'Chọn sản phẩm'),
          items: _inventory.map((p) => DropdownMenuItem<int>(
            value: p['ProductID'],
            child: Text('${p['ProductName']} (Hệ thống: ${p['Quantity']})'),
          )).toList(),
          onChanged: (val) => setState(() => _selectedAuditProductId = val),
        ),
        const SizedBox(height: 16),
        TextField(controller: _auditActualQtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số lượng thực tế đếm được')),
      ],
    );
  }
}
