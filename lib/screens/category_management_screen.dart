import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../controllers/category_controller.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = CategoryController();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  // Category icon palette
  static const List<IconData> _catIcons = [
    Icons.local_drink_rounded,
    Icons.fastfood_rounded,
    Icons.cookie_rounded,
    Icons.shopping_basket_rounded,
    Icons.spa_rounded,
    Icons.lunch_dining_rounded,
    Icons.icecream_rounded,
    Icons.coffee_rounded,
  ];

  static const List<Color> _catColors = [
    Color(0xFF3B82F6),
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
    Color(0xFF84CC16),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _loadCategories();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final data = await _ctrl.loadCategories();
    setState(() {
      _categories = data;
      _isLoading = false;
    });
  }

  void _showCategoryForm({Map<String, dynamic>? cat}) {
    final isEdit = cat != null;
    final nameCtrl = TextEditingController(text: cat?['CategoryName'] ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isEdit ? 'Sửa danh mục' : 'Thêm danh mục',
          style: GoogleFonts.inter(color: AppTheme.textPrimary, fontWeight: FontWeight.w800),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameCtrl,
            autofocus: true,
            style: GoogleFonts.inter(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Tên danh mục',
              hintText: 'VD: Đồ uống',
              prefixIcon: Icon(Icons.category_rounded, size: 20),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên danh mục' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              bool ok;
              if (isEdit) {
                ok = await _ctrl.editCategory(cat['CategoryID'] as int, nameCtrl.text);
              } else {
                ok = await _ctrl.addCategory(nameCtrl.text);
              }
              await _loadCategories();
              if (mounted) {
                _showSnack(ok
                    ? (isEdit ? 'Đã cập nhật danh mục!' : 'Đã thêm danh mục!')
                    : 'Có lỗi xảy ra!');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: Text(isEdit ? 'Lưu' : 'Thêm',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> cat) {
    final count = cat['ProductCount'] as int? ?? 0;
    if (count > 0) {
      _showSnack('Không thể xóa: Còn $count sản phẩm thuộc danh mục này!', isError: true);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Xóa danh mục?',
            style: GoogleFonts.inter(color: AppTheme.textPrimary, fontWeight: FontWeight.w800)),
        content: Text('Xóa "${cat['CategoryName']}"?',
            style: GoogleFonts.inter(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await _ctrl.removeCategory(cat['CategoryID'] as int);
              await _loadCategories();
              if (mounted) {
                _showSnack(result == 'ok' ? 'Đã xóa danh mục!' : 'Xóa thất bại!',
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
        title: Text('Quản lý Danh mục',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeIn,
              child: _categories.isEmpty
                  ? _buildEmpty()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: _categories.length,
                        itemBuilder: (context, i) => _buildCategoryCard(_categories[i], i),
                      ),
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryForm(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Thêm danh mục',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.category_rounded, size: 72, color: AppTheme.textSecondary.withAlpha(80)),
          const SizedBox(height: 16),
          Text('Chưa có danh mục nào',
              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat, int index) {
    final color = _catColors[index % _catColors.length];
    final icon = _catIcons[index % _catIcons.length];
    final count = cat['ProductCount'] as int? ?? 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.scale(scale: 0.9 + 0.1 * v, child: child),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.darkBorder),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _showCategoryForm(cat: cat),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: color.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _confirmDelete(cat),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.delete_outline_rounded,
                              color: AppTheme.textLight, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    cat['CategoryName'] as String,
                    style: GoogleFonts.inter(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count sản phẩm',
                    style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
