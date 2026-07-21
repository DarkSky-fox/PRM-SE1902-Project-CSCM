import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../controllers/invoice_controller.dart';

class InvoiceManagementScreen extends StatefulWidget {
  final int roleId; // 1: Chủ chuỗi, 2: Cửa hàng trưởng, 3: Nhân viên
  final int? storeId;

  const InvoiceManagementScreen({
    super.key,
    required this.roleId,
    this.storeId,
  });

  @override
  State<InvoiceManagementScreen> createState() => _InvoiceManagementScreenState();
}

class _InvoiceManagementScreenState extends State<InvoiceManagementScreen> {
  final _controller = InvoiceController();
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final storeIdToLoad = widget.roleId == 1 ? null : widget.storeId;
    final list = await _controller.loadInvoices(storeIdToLoad);
    setState(() {
      _invoices = list;
      _isLoading = false;
    });
  }

  void _showInvoiceDetails(int invoiceId, String invoiceLabel) async {
    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));
    final details = await _controller.loadInvoiceDetails(invoiceId);
    if (!mounted) return;
    Navigator.of(context).pop(); // dismiss loading

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
            Text('Chi tiết hóa đơn $invoiceLabel', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const Divider(height: 30),
            Expanded(
              child: details.isEmpty
                ? const Center(child: Text('Không có chi tiết'))
                : ListView.builder(
                    itemCount: details.length,
                    itemBuilder: (context, index) {
                      final item = details[index];
                      final name = item['ProductName'] ?? 'Unknown';
                      final qty = item['Quantity'] ?? 0;
                      final price = item['UnitPrice'] ?? 0.0;
                      final discount = item['DiscountAmount'] ?? 0.0;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.surfaceLight,
                          child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryLight),
                        ),
                        title: Text('$name', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                        subtitle: Text('SL: $qty x ${AppTheme.formatMoney(price)}'),
                        trailing: Text(AppTheme.formatMoney((qty * price) - discount), style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppTheme.accent)),
                      );
                    },
                  ),
            )
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        title: const Text('Lịch Sử Hóa Đơn'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invoices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long_rounded, size: 80, color: AppTheme.divider),
                      const SizedBox(height: 16),
                      Text('Chưa có hóa đơn nào.', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _invoices.length,
                  itemBuilder: (context, index) {
                    final inv = _invoices[index];
                    final invId = inv['InvoiceID'] as int;
                    final total = inv['TotalAmount'] as double;
                    final date = inv['InvoiceDate'] as String;
                    final storeName = inv['StoreName'] as String?;
                    final empName = inv['EmployeeName'] as String?;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: AppTheme.white,
                      child: InkWell(
                        onTap: () => _showInvoiceDetails(invId, '#$invId'),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Hóa đơn #$invId', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.primary)),
                                  Text(AppTheme.formatMoney(total), style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.accent)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(_formatDate(date), style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
                                ],
                              ),
                              if (storeName != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.store_rounded, size: 14, color: AppTheme.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(storeName, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
                                  ],
                                ),
                              ],
                              if (empName != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.person_rounded, size: 14, color: AppTheme.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(empName, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
                                  ],
                                ),
                              ]
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
