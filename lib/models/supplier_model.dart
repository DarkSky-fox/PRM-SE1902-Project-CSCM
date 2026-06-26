class SupplierModel {
  final int? supplierId;
  final String supplierName;
  final String? address;
  final String? email;
  final String? phone;

  SupplierModel({
    this.supplierId,
    required this.supplierName,
    this.address,
    this.email,
    this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'SupplierID': supplierId,
      'SupplierName': supplierName,
      'Address': address,
      'Email': email,
      'Phone': phone,
    };
  }

  factory SupplierModel.fromMap(Map<String, dynamic> map) {
    return SupplierModel(
      supplierId: map['SupplierID'] as int?,
      supplierName: map['SupplierName'] as String,
      address: map['Address'] as String?,
      email: map['Email'] as String?,
      phone: map['Phone'] as String?,
    );
  }
}