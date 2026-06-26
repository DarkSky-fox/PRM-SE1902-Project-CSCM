class CustomerModel {
  final int? customerId;
  final String fullName;
  final String? phone;
  final String? email;

  CustomerModel({
    this.customerId,
    required this.fullName,
    this.phone,
    this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'CustomerID': customerId,
      'FullName': fullName,
      'Phone': phone,
      'Email': email,
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      customerId: map['CustomerID'] as int?,
      fullName: map['FullName'] as String,
      phone: map['Phone'] as String?,
      email: map['Email'] as String?,
    );
  }
}