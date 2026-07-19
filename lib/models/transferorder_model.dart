class TransferOrderModel {
  final int? transferId;
  final int? fromStoreId;
  final int? toStoreId;
  final int? productId;
  final int quantity;
  final String transferDate;
  final int? requestedByEmployeeId;
  final String status;
  final int? reviewedByEmployeeId;
  final String? reviewedAt;

  TransferOrderModel({
    this.transferId,
    this.fromStoreId,
    this.toStoreId,
    this.productId,
    required this.quantity,
    required this.transferDate,
    this.requestedByEmployeeId,
    this.status = 'Pending',
    this.reviewedByEmployeeId,
    this.reviewedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'TransferID': transferId,
      'FromStoreID': fromStoreId,
      'ToStoreID': toStoreId,
      'ProductID': productId,
      'Quantity': quantity,
      'TransferDate': transferDate,
      'RequestedByEmployeeID': requestedByEmployeeId,
      'Status': status,
      'ReviewedByEmployeeID': reviewedByEmployeeId,
      'ReviewedAt': reviewedAt,
    };
  }

  factory TransferOrderModel.fromMap(Map<String, dynamic> map) {
    return TransferOrderModel(
      transferId: map['TransferID'] as int?,
      fromStoreId: map['FromStoreID'] as int?,
      toStoreId: map['ToStoreID'] as int?,
      productId: map['ProductID'] as int?,
      quantity: map['Quantity'] as int,
      transferDate: map['TransferDate'] as String,
      requestedByEmployeeId: map['RequestedByEmployeeID'] as int?,
      status: (map['Status'] as String?) ?? 'Pending',
      reviewedByEmployeeId: map['ReviewedByEmployeeID'] as int?,
      reviewedAt: map['ReviewedAt'] as String?,
    );
  }
}
