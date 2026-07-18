import 'package:flutter/material.dart';
import '../../models/store_model.dart';
import '../../services/store_service.dart';
import 'store_form_screen.dart';

class StoreListScreen extends StatefulWidget {
  const StoreListScreen({super.key});

  @override
  State<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends State<StoreListScreen> {
  final StoreService _service = StoreService();
  List<StoreModel> _stores = [];
  List<StoreModel> _filtered = [];
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _service.getAllStores();
    setState(() {
      _stores = data;
      _filtered = data;
      _isLoading = false;
    });
  }

  void _onSearch(String query) {
    setState(() {
      _filtered = _stores
          .where((s) =>
              s.storeName.toLowerCase().contains(query.toLowerCase()) ||
              (s.address ?? '').toLowerCase().contains(query.toLowerCase()) ||
              (s.phone ?? '').contains(query))
          .toList();
    });
  }

  Future<void> _delete(StoreModel store) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa cửa hàng "${store.storeName}" không?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _service.deleteStore(store.storeId!);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa "${store.storeName}"'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatHours(String? open, String? close) {
    if (open != null && close != null) return '$open – $close';
    if (open != null) return 'Mở: $open';
    if (close != null) return 'Đóng: $close';
    return '';
  }

  Future<void> _openForm({StoreModel? store}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => StoreFormScreen(store: store)),
    );
    if (result == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? _buildEmptyState()
                    : _buildList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFF607D8B),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm mới',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF546E7A),
      foregroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quản Lý Cửa Hàng',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          Text('${_filtered.length} cửa hàng',
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFF546E7A),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _onSearch,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Tìm theo tên, địa chỉ, SĐT...',
          hintStyle: const TextStyle(color: Colors.white60),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  onPressed: () {
                    _searchCtrl.clear();
                    _onSearch('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filtered.length,
      itemBuilder: (ctx, i) => _buildCard(_filtered[i]),
    );
  }

  Widget _buildCard(StoreModel store) {
    final isActive = (store.status ?? '').toLowerCase() == 'active';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFECEFF1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.store_rounded,
                  color: Color(0xFF607D8B), size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(store.storeName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF212121))),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isActive
                                  ? Colors.green.shade300
                                  : Colors.grey.shade300),
                        ),
                        child: Text(
                          store.status ?? 'N/A',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                  if (store.phone != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.phone_outlined,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(store.phone!,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 13)),
                    ]),
                  ],
                  if (store.address != null) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(store.address!,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ],
                  if (store.openTime != null || store.closeTime != null) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.access_time_rounded,
                          size: 13, color: Color(0xFFF9A825)),
                      const SizedBox(width: 4),
                      Text(
                        _formatHours(store.openTime, store.closeTime),
                        style: const TextStyle(
                            color: Color(0xFFF9A825),
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon:
                      const Icon(Icons.edit_outlined, color: Color(0xFF607D8B)),
                  onPressed: () => _openForm(store: store),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _delete(store),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchCtrl.text.isNotEmpty
                ? 'Không tìm thấy cửa hàng nào'
                : 'Chưa có cửa hàng nào',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
