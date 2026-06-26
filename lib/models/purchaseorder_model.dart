class PurchaseOrderModel {
  final int? purchaseOrderId;
  final int? supplierId;
  final int? employeeId;
  final String orderDate;

  PurchaseOrderModel({
    this.purchaseOrderId,
    this.supplierId,
    this.employeeId,
    required this.orderDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'PurchaseOrderID': purchaseOrderId,
      'SupplierID': supplierId,
      'EmployeeID': employeeId,
      'OrderDate': orderDate,
    };
  }

  factory PurchaseOrderModel.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderModel(
      purchaseOrderId: map['PurchaseOrderID'] as int?,
      supplierId: map['SupplierID'] as int?,
      employeeId: map['EmployeeID'] as int?,
      orderDate: map['OrderDate'] as String,
    );
  }
}