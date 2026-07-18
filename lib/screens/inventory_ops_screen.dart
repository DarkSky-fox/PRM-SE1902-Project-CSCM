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

  @override
  void initState() {
    super.initState();
    int tabCount = widget.roleId == 2 ? 3 : 2;
    int initialIndex = widget.roleId == 2
        ? widget.initialTab
        : (widget.initialTab == 0 ? 0 : widget.initialTab - 1);

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

  @override
  Widget build(BuildContext context) {
    final List<Tab> tabs = [];
    if (widget.roleId == 2) {
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
                  ? [_buildImportTab(), _buildTransferTab(), _buildAuditTab()]
                  : [_buildTransferTab(), _buildAuditTab()],
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
