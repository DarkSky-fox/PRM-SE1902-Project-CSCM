class InventoryModel {
  final int? inventoryId;
  final int? storeId;
  final int? productId;
  final int quantity;
  final double salePrice;
  final String? expiredDate;

  InventoryModel({
    this.inventoryId,
    this.storeId,
    this.productId,
    required this.quantity,
    required this.salePrice,
    this.expiredDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'InventoryID': inventoryId,
      'StoreID': storeId,
      'ProductID': productId,
      'Quantity': quantity,
      'SalePrice': salePrice,
      'ExpiredDate': expiredDate,
    };
  }

  factory InventoryModel.fromMap(Map<String, dynamic> map) {
    return InventoryModel(
      inventoryId: map['InventoryID'] as int?,
      storeId: map['StoreID'] as int?,
      productId: map['ProductID'] as int?,
      quantity: map['Quantity'] as int,
      salePrice: map['SalePrice'] as double,
      expiredDate: map['ExpiredDate'] as String?,
    );
  }
}