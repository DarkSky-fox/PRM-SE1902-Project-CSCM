import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../controllers/product_controller.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = ProductController();

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _filtered = [];

  bool _isLoading = false;
  int? _filterCategoryId;
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
    final products = await _ctrl.loadProducts();
    final cats = await _ctrl.loadCategories();
    final sups = await _ctrl.loadSuppliers();
    setState(() {
      _products = products;
      _categories = cats;
      _suppliers = sups;
      _isLoading = false;
      _applyFilter();
    });
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _products.where((p) {
        final matchCat = _filterCategoryId == null || p['CategoryID'] == _filterCategoryId;
        final matchSearch =
            q.isEmpty || (p['ProductName'] as String? ?? '').toLowerCase().contains(q);
        return matchCat && matchSearch;
      }).toList();
    });
  }

  void _showProductForm({Map<String, dynamic>? product}) {
    final isEdit = product != null;
    final nameCtrl = TextEditingController(text: product?['ProductName'] ?? '');
    final descCtrl = TextEditingController(text: product?['Description'] ?? '');
    final imgCtrl = TextEditingController(text: product?['ImageUrl'] ?? '');
    int? categoryId = product?['CategoryID'] as int?;
    int? supplierId = product?['SupplierID'] as int?;
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
                Text(
                  isEdit ? 'Sửa sản phẩm' : 'Thêm sản phẩm mới',
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 20),
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      _field(nameCtrl, 'Tên sản phẩm *', Icons.inventory_2_rounded,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên sản phẩm' : null),
                      const SizedBox(height: 12),
                      // Category dropdown
                      DropdownButtonFormField<int?>(
                        value: categoryId,
                        dropdownColor: AppTheme.darkElevated,
                        decoration: const InputDecoration(
                          labelText: 'Danh mục *',
                          prefixIcon: Icon(Icons.category_rounded, size: 20),
                        ),
                        validator: (v) => v == null ? 'Vui lòng chọn danh mục' : null,
                        items: _categories
                            .map((c) => DropdownMenuItem<int?>(
                                  value: c['CategoryID'] as int,
                                  child: Text(c['CategoryName'] as String,
                                      style: GoogleFonts.inter(
                                          color: AppTheme.textPrimary, fontSize: 14)),
                                ))
                            .toList(),
                        onChanged: (v) => setModal(() => categoryId = v),
                        style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      // Supplier dropdown
                      DropdownButtonFormField<int?>(
                        value: supplierId,
                        dropdownColor: AppTheme.darkElevated,
                        decoration: const InputDecoration(
                          labelText: 'Nhà cung cấp',
                          prefixIcon: Icon(Icons.local_shipping_rounded, size: 20),
                        ),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text('-- Không chọn --',
                                style: GoogleFonts.inter(
                                    color: AppTheme.textSecondary, fontSize: 14)),
                          ),
                          ..._suppliers.map((s) => DropdownMenuItem<int?>(
                                value: s['SupplierID'] as int,
                                child: Text(s['SupplierName'] as String,
                                    style: GoogleFonts.inter(
                                        color: AppTheme.textPrimary, fontSize: 14)),
                              )),
                        ],
                        onChanged: (v) => setModal(() => supplierId = v),
                        style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      _field(descCtrl, 'Mô tả sản phẩm', Icons.notes_rounded,
                          maxLines: 2),
                      const SizedBox(height: 12),
                      _field(imgCtrl, 'URL hình ảnh', Icons.image_rounded),
                      // Image preview
                      if (imgCtrl.text.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            imgCtrl.text,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 80,
                              color: AppTheme.darkElevated,
                              child: const Icon(Icons.broken_image_rounded,
                                  color: AppTheme.textSecondary),
                            ),
                          ),
                        ),
                      ],
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
                              ok = await _ctrl.editProduct(
                                productId: product['ProductID'] as int,
                                productName: nameCtrl.text.trim(),
                                categoryId: categoryId,
                                supplierId: supplierId,
                                description: descCtrl.text.trim().isEmpty
                                    ? null
                                    : descCtrl.text.trim(),
                                imageUrl: imgCtrl.text.trim().isEmpty
                                    ? null
                                    : imgCtrl.text.trim(),
                              );
                            } else {
                              ok = await _ctrl.addProduct(
                                productName: nameCtrl.text.trim(),
                                categoryId: categoryId,
                                supplierId: supplierId,
                                description: descCtrl.text.trim().isEmpty
                                    ? null
                                    : descCtrl.text.trim(),
                                imageUrl: imgCtrl.text.trim().isEmpty
                                    ? null
                                    : imgCtrl.text.trim(),
                              );
                            }
                            await _loadData();
                            if (mounted) {
                              _showSnack(ok
                                  ? (isEdit ? 'Đã cập nhật sản phẩm!' : 'Đã thêm sản phẩm!')
                                  : 'Có lỗi xảy ra!');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            isEdit ? 'Lưu thay đổi' : 'Thêm sản phẩm',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700),
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
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Xóa sản phẩm?',
            style: GoogleFonts.inter(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w800)),
        content: Text(
          'Bạn có chắc muốn xóa "${product['ProductName']}"?',
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
              final result = await _ctrl.removeProduct(product['ProductID'] as int);
              await _loadData();
              if (mounted) {
                if (result == 'ok') {
                  _showSnack('Đã xóa sản phẩm!');
                } else if (result == 'has_inventory') {
                  _showSnack('Không thể xóa: Sản phẩm còn tồn kho!', isError: true);
                } else {
                  _showSnack('Xóa thất bại!', isError: true);
                }
              }
            },
            child: Text('Xóa',
                style: GoogleFonts.inter(
                    color: AppTheme.error, fontWeight: FontWeight.w700)),
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
        title: Text('Quản lý Sản phẩm',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            color: AppTheme.darkCard,
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  style: GoogleFonts.inter(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Tìm sản phẩm...',
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
                      _catChip('Tất cả', null),
                      ..._categories.map((c) =>
                          _catChip(c['CategoryName'] as String, c['CategoryID'] as int)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(children: [
              Text('${_filtered.length} sản phẩm',
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
                            child: Text('Không có sản phẩm',
                                style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: _filtered.length,
                            itemBuilder: (context, i) =>
                                _buildProductCard(_filtered[i], i),
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductForm(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Thêm sản phẩm',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _catChip(String label, int? catId) {
    final selected = _filterCategoryId == catId;
    return GestureDetector(
      onTap: () {
        setState(() => _filterCategoryId = catId);
        _applyFilter();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.darkElevated,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: selected ? AppTheme.primaryLight : AppTheme.darkBorder),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
              color: selected ? Colors.white : AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            )),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    final imgUrl = product['ImageUrl'] as String?;
    final catName = product['CategoryName'] as String? ?? 'N/A';
    final supName = product['SupplierName'] as String? ?? 'N/A';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 280 + index * 40),
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
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius:
                  const BorderRadius.only(topLeft: Radius.circular(18), bottomLeft: Radius.circular(18)),
              child: imgUrl != null && imgUrl.isNotEmpty
                  ? Image.network(
                      imgUrl,
                      width: 80, height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgPlaceholder(),
                    )
                  : _imgPlaceholder(),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['ProductName'] as String,
                        style: GoogleFonts.inter(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.category_rounded, size: 12, color: AppTheme.info),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(catName,
                            style: GoogleFonts.inter(color: AppTheme.info, fontSize: 11),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                    Row(children: [
                      Icon(Icons.local_shipping_rounded,
                          size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(supName,
                            style: GoogleFonts.inter(
                                color: AppTheme.textSecondary, fontSize: 11),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            // Actions
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.edit_rounded, color: AppTheme.info, size: 20),
                  onPressed: () => _showProductForm(product: product),
                ),
                IconButton(
                  icon: Icon(Icons.delete_rounded, color: AppTheme.error, size: 20),
                  onPressed: () => _confirmDelete(product),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      width: 80, height: 80,
      color: AppTheme.darkElevated,
      child: Icon(Icons.image_rounded, color: AppTheme.textLight, size: 32),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }
}
