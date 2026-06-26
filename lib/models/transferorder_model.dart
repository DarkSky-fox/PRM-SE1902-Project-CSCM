class TransferOrderModel {
  final int? transferId;
  final int? fromStoreId;
  final int? toStoreId;
  final int? productId;
  final int quantity;
  final String transferDate;

  TransferOrderModel({
    this.transferId,
    this.fromStoreId,
    this.toStoreId,
    this.productId,
    required this.quantity,
    required this.transferDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'TransferID': transferId,
      'FromStoreID': fromStoreId,
      'ToStoreID': toStoreId,
      'ProductID': productId,
      'Quantity': quantity,
      'TransferDate': transferDate,
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
    );
  }
}