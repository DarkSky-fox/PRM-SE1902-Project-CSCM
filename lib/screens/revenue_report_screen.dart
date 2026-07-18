import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../controllers/revenue_controller.dart';

class RevenueReportScreen extends StatefulWidget {
  final int roleId;
  final int? storeId;

  const RevenueReportScreen({
    super.key,
    required this.roleId,
    this.storeId,
  });

  @override
  State<RevenueReportScreen> createState() => _RevenueReportScreenState();
}

class _RevenueReportScreenState extends State<RevenueReportScreen> {
  final _revenueController = RevenueController();
  String _selectedPeriod = 'Day';
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final list = await _revenueController.loadRevenueReport(
      roleId: widget.roleId,
      storeId: widget.storeId,
      selectedPeriod: _selectedPeriod,
    );
    setState(() {
      _reports = list;
      _isLoading = false;
    });
  }

  double _getMaxRevenue() {
    double maxVal = 1.0;
    for (final r in _reports) {
      final val = r['revenue'] as double;
      if (val > maxVal) maxVal = val;
    }
    return maxVal;
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(children: [
      Icon(icon, color: Colors.white, size: 26),
      const SizedBox(height: 8),
      Text(label, style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.roleId == 1 ? 'Doanh Thu Tổng Hợp Toàn Chuỗi' : 'Doanh Thu Cửa Hàng';

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(title: Text(title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── Period selector pill ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Row(
                      children: {'Theo Ngày': 'Day', 'Theo Tháng': 'Month', 'Theo Năm': 'Year'}
                          .entries
                          .map((entry) {
                        final label = entry.key;
                        final value = entry.value;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedPeriod = value);
                              _loadReport();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedPeriod == value ? AppTheme.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: _selectedPeriod == value ? Colors.white : AppTheme.textSecondary,
                                  fontWeight: _selectedPeriod == value ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  if (_reports.isNotEmpty) ...[
                    // ── Summary stats card ────────────────────────────────
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppTheme.headerGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppTheme.buttonShadow,
                      ),
                      child: Row(children: [
                        Expanded(child: _buildStatItem(
                          Icons.payments_rounded,
                          'Tổng doanh thu',
                          AppTheme.formatMoney(_reports.fold(0.0, (s, r) => s + (r['revenue'] as double))),
                        )),
                        Container(width: 1, height: 40, color: Colors.white.withAlpha(40)),
                        Expanded(child: _buildStatItem(
                          Icons.receipt_long_rounded,
                          'Tổng đơn hàng',
                          '${_reports.fold(0, (int s, r) => s + (r['orderCount'] as int))}',
                        )),
                      ]),
                    ),

                    // ── Bar chart ─────────────────────────────────────────
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppTheme.cardShadow,
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(children: [
                            Icon(Icons.bar_chart_rounded, color: AppTheme.primary, size: 20),
                            SizedBox(width: 8),
                            Text('Biểu đồ doanh thu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                          ]),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 160,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: _reports.take(7).toList().reversed.map((r) {
                                final rev = r['revenue'] as double;
                                final maxRev = _getMaxRevenue();
                                final barHeight = maxRev > 0 ? (rev / maxRev) * 110.0 : 4.0;
                                final dateLabel = r['date'].toString();
                                final shortLabel = dateLabel.length >= 2 ? dateLabel.substring(dateLabel.length - 2) : dateLabel;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (rev > 0) Text(
                                          rev >= 1000000 ? '${(rev / 1000000).toStringAsFixed(1)}M' : '${(rev / 1000).toStringAsFixed(0)}K',
                                          style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: double.infinity,
                                          height: barHeight < 4 ? 4 : barHeight,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFF1A6B3C), Color(0xFF00C96B)]),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(shortLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Section header ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 10),
                      child: Row(children: [
                        Container(width: 4, height: 18, decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 10),
                        const Text('Chi tiết số liệu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      ]),
                    ),

                    Expanded(
                      child: ListView.builder(
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          final r = _reports[index];
                          final rev = r['revenue'] as double;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.divider),
                              boxShadow: AppTheme.cardShadowMd,
                            ),
                            child: Row(children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.monetization_on_rounded, color: AppTheme.primary, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r['date'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary)),
                                  const SizedBox(height: 3),
                                  Text('Số đơn: ${r['orderCount']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                ],
                              )),
                              Text(AppTheme.formatMoney(rev), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 15)),
                            ]),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.bar_chart_rounded, size: 72, color: AppTheme.divider),
                          const SizedBox(height: 16),
                          const Text('Chưa có dữ liệu doanh thu', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.w500)),
                          const Text('trong khoảng thời gian này', style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
                        ]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
