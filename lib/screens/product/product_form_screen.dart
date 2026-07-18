import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../models/supplier_model.dart';
import '../../services/product_service.dart';

class ProductFormScreen extends StatefulWidget {
  final Map<String, dynamic>? productData;
  final List<CategoryModel> categories;
  final List<SupplierModel> suppliers;

  const ProductFormScreen({
    super.key,
    this.productData,
    required this.categories,
    required this.suppliers,
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int? _selectedCategoryId;
  int? _selectedSupplierId;
  final ProductService _service = ProductService();
  bool _isSaving = false;

  bool get _isEditing => widget.productData != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameCtrl.text = widget.productData!['ProductName'] as String? ?? '';
      _descCtrl.text = widget.productData!['Description'] as String? ?? '';
      _selectedCategoryId = widget.productData!['CategoryID'] as int?;
      _selectedSupplierId = widget.productData!['SupplierID'] as int?;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final product = ProductModel(
      productId: widget.productData?['ProductID'] as int?,
      productName: _nameCtrl.text.trim(),
      categoryId: _selectedCategoryId,
      supplierId: _selectedSupplierId,
      description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    );

    if (_isEditing) {
      await _service.updateProduct(product);
    } else {
      await _service.createProduct(product);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Cập nhật sản phẩm thành công!'
              : 'Thêm sản phẩm thành công!'),
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
        backgroundColor: const Color(0xFF388E3C),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEditing ? 'Chỉnh Sửa Sản Phẩm' : 'Thêm Sản Phẩm',
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
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2_outlined,
                    color: Color(0xFF4CAF50), size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Thông tin sản phẩm',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF212121))),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameCtrl,
            decoration: _input('Tên sản phẩm *', Icons.label_outline),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Vui lòng nhập tên sản phẩm' : null,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            value: _selectedCategoryId,
            decoration: _input('Danh mục', Icons.category_outlined),
            hint: const Text('Chọn danh mục'),
            items: widget.categories
                .map((c) => DropdownMenuItem(
                      value: c.categoryId,
                      child: Text(c.categoryName),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedCategoryId = v),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            value: _selectedSupplierId,
            decoration: _input('Nhà cung cấp', Icons.local_shipping_outlined),
            hint: const Text('Chọn nhà cung cấp'),
            items: widget.suppliers
                .map((s) => DropdownMenuItem(
                      value: s.supplierId,
                      child: Text(s.supplierName),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedSupplierId = v),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _descCtrl,
            decoration: _input('Mô tả', Icons.notes_outlined),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF4CAF50)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
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
          backgroundColor: const Color(0xFF388E3C),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                _isEditing ? 'Cập Nhật' : 'Thêm Sản Phẩm',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
