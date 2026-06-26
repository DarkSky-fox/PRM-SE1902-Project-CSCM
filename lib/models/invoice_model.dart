class InvoiceModel {
  final int? invoiceId;
  final int? storeId;
  final int? customerId;
  final int? employeeId;
  final String invoiceDate;
  final double totalAmount;

  InvoiceModel({
    this.invoiceId,
    this.storeId,
    this.customerId,
    this.employeeId,
    required this.invoiceDate,
    this.totalAmount = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'InvoiceID': invoiceId,
      'StoreID': storeId,
      'CustomerID': customerId,
      'EmployeeID': employeeId,
      'InvoiceDate': invoiceDate,
      'TotalAmount': totalAmount,
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      invoiceId: map['InvoiceID'] as int?,
      storeId: map['StoreID'] as int?,
      customerId: map['CustomerID'] as int?,
      employeeId: map['EmployeeID'] as int?,
      invoiceDate: map['InvoiceDate'] as String,
      totalAmount: map['TotalAmount'] as double? ?? 0.0,
    );
  }
}