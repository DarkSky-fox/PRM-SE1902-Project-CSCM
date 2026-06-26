class PurchaseOrderDetailModel {
  final int? purchaseOrderDetailId;
  final int? purchaseOrderId;
  final int? productId;
  final int quantity;
  final double importPrice;
  final String? expiredDate;

  PurchaseOrderDetailModel({
    this.purchaseOrderDetailId,
    this.purchaseOrderId,
    this.productId,
    required this.quantity,
    required this.importPrice,
    this.expiredDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'PurchaseOrderDetailID': purchaseOrderDetailId,
      'PurchaseOrderID': purchaseOrderId,
      'ProductID': productId,
      'Quantity': quantity,
      'ImportPrice': importPrice,
      'ExpiredDate': expiredDate,
    };
  }

  factory PurchaseOrderDetailModel.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderDetailModel(
      purchaseOrderDetailId: map['PurchaseOrderDetailID'] as int?,
      purchaseOrderId: map['PurchaseOrderID'] as int?,
      productId: map['ProductID'] as int?,
      quantity: map['Quantity'] as int,
      importPrice: map['ImportPrice'] as double,
      expiredDate: map['ExpiredDate'] as String?,
    );
  }
}