class ProductModel {
  final int? productId;
  final String productName;
  final int? categoryId;
  final int? supplierId;
  final String? description;

  ProductModel({
    this.productId,
    required this.productName,
    this.categoryId,
    this.supplierId,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'ProductID': productId,
      'ProductName': productName,
      'CategoryID': categoryId,
      'SupplierID': supplierId,
      'Description': description,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      productId: map['ProductID'] as int?,
      productName: map['ProductName'] as String,
      categoryId: map['CategoryID'] as int?,
      supplierId: map['SupplierID'] as int?,
      description: map['Description'] as String?,
    );
  }
}