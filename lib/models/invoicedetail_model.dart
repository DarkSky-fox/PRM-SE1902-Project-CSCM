class InvoiceDetailModel {
  final int? invoiceDetailId;
  final int? invoiceId;
  final int? productId;
  final int quantity;
  final double salePrice;
  final double discount;

  InvoiceDetailModel({
    this.invoiceDetailId,
    this.invoiceId,
    this.productId,
    required this.quantity,
    required this.salePrice,
    required this.discount,
  });

  Map<String, dynamic> toMap() {
    return {
      'InvoiceDetailID': invoiceDetailId,
      'InvoiceID': invoiceId,
      'ProductID': productId,
      'Quantity': quantity,
      'SalePrice': salePrice,
      'Discount': discount,
    };
  }

  factory InvoiceDetailModel.fromMap(Map<String, dynamic> map) {
    return InvoiceDetailModel(
      invoiceDetailId: map['InvoiceDetailID'] as int?,
      invoiceId: map['InvoiceID'] as int?,
      productId: map['ProductID'] as int?,
      quantity: map['Quantity'] as int,
      salePrice: map['SalePrice'] as double,
      discount: map['Discount'] as double,
    );
  }
}