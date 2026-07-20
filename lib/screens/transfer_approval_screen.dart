import 'package:flutter/material.dart';
import '../controllers/inventory_ops_controller.dart';
import '../utils/app_theme.dart';

class TransferApprovalScreen extends StatefulWidget {
  final int storeId;
  final int employeeId;

  const TransferApprovalScreen({
    super.key,
    required this.storeId,
    required this.employeeId,
  });

  @override
  State<TransferApprovalScreen> createState() => _TransferApprovalScreenState();
}

class _TransferApprovalScreenState extends State<TransferApprovalScreen> {
  final _controller = InventoryOpsController();
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _isLoading = true);
    try {
      final requests = await _controller.loadManagerTransferRequests(
        widget.storeId,
      );
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Không thể tải danh sách yêu cầu chuyển kho.', isError: true);
    }
  }

  Future<void> _confirmReview(
    Map<String, dynamic> request, {
    required bool approve,
  }) async {
    final productName = request['ProductName'] as String? ?? 'Sản phẩm';
    final quantity = request['Quantity'] as int? ?? 0;
    final targetStore = request['ToStoreName'] as String? ?? 'cửa hàng đích';
    final action = approve ? 'phê duyệt' : 'từ chối';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          approve ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: approve ? AppTheme.success : AppTheme.error,
          size: 48,
        ),
        title: Text('${approve ? 'Phê duyệt' : 'Từ chối'} yêu cầu?'),
        content: Text(
          'Bạn có chắc muốn $action yêu cầu chuyển $quantity $productName sang $targetStore?',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              approve ? 'Phê duyệt' : 'Từ chối',
              style: TextStyle(
                color: approve ? AppTheme.success : AppTheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    final result = await _controller.reviewTransferRequest(
      transferId: request['TransferID'] as int,
      managerEmployeeId: widget.employeeId,
      approve: approve,
    );
    if (!mounted) return;
    await _loadRequests(showLoading: false);
    if (!mounted) return;

    switch (result) {
      case 'approved':
        _showSnack('Đã phê duyệt và cập nhật tồn kho hai cửa hàng.');
        break;
      case 'rejected':
        _showSnack('Đã từ chối yêu cầu chuyển kho.');
        break;
      case 'insufficient_stock':
        _showSnack(
          'Kho nguồn không còn đủ hàng để phê duyệt yêu cầu này.',
          isError: true,
        );
        break;
      case 'already_processed':
        _showSnack('Yêu cầu đã được xử lý trước đó.', isError: true);
        break;
      case 'unauthorized':
        _showSnack(
          'Bạn không có quyền duyệt yêu cầu của cửa hàng này.',
          isError: true,
        );
        break;
      default:
        _showSnack('Không thể xử lý yêu cầu. Vui lòng thử lại.', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return AppTheme.success;
      case 'Rejected':
        return AppTheme.error;
      default:
        return AppTheme.warning;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Approved':
        return 'Đã duyệt';
      case 'Rejected':
        return 'Đã từ chối';
      default:
        return 'Chờ duyệt';
    }
  }

  String _formatDate(Object? value) {
    final raw = value?.toString() ?? '';
    if (raw.isEmpty) return '--';
    final normalized = raw.replaceFirst('T', ' ');
    return normalized.length >= 16 ? normalized.substring(0, 16) : normalized;
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['Status'] as String? ?? 'Pending';
    final quantity = request['Quantity'] as int? ?? 0;
    final available = request['AvailableQuantity'] as int? ?? 0;
    final isPending = status == 'Pending';
    final hasEnoughStock = available >= quantity;
    final statusColor = _statusColor(status);

    return Card(
      color: AppTheme.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: statusColor.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request['ProductName'] as String? ?? 'Sản phẩm',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(24),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Nhân viên tạo: ${request['RequestedByName'] ?? 'Không xác định'}'),
            const SizedBox(height: 5),
            Text('Cửa hàng nhận: ${request['ToStoreName'] ?? '--'}'),
            const SizedBox(height: 5),
            Text('Số lượng chuyển: $quantity'),
            const SizedBox(height: 5),
            Text(
              'Tồn kho nguồn hiện tại: $available',
              style: TextStyle(
                color: hasEnoughStock ? AppTheme.textSecondary : AppTheme.error,
                fontWeight: hasEnoughStock ? FontWeight.w400 : FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Ngày tạo: ${_formatDate(request['TransferDate'])}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            if (!isPending && request['ReviewedByName'] != null) ...[
              const SizedBox(height: 5),
              Text(
                'Người xử lý: ${request['ReviewedByName']}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
            if (isPending) ...[
              const Divider(height: 28),
              if (!hasEnoughStock)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Không đủ tồn kho để phê duyệt. Hãy nhập thêm hàng hoặc từ chối yêu cầu.',
                    style: TextStyle(color: AppTheme.error, fontSize: 12),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmReview(request, approve: false),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Từ chối'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: hasEnoughStock
                          ? () => _confirmReview(request, approve: true)
                          : null,
                      icon: const Icon(Icons.check_rounded, color: Colors.white),
                      label: const Text(
                        'Phê duyệt',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _requests
        .where((request) => request['Status'] == 'Pending')
        .length;

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        title: const Text('Duyệt Chuyển Kho'),
        actions: [
          IconButton(
            onPressed: _loadRequests,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRequests,
              child: _requests.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 180),
                        Icon(
                          Icons.inbox_rounded,
                          size: 72,
                          color: AppTheme.textLight,
                        ),
                        SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Chưa có yêu cầu chuyển kho',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _requests.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Text(
                              '$pendingCount yêu cầu đang chờ phê duyệt',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return _buildRequestCard(_requests[index - 1]);
                      },
                    ),
            ),
    );
  }
}
