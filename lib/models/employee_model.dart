class EmployeeModel {
  final int? employeeId;
  final String fullName;
  final String? dob;
  final int? gender;
  final String? address;
  final String? phone;
  final double? salary;
  final int? storeId;
  final int? accountId;

  EmployeeModel({
    this.employeeId,
    required this.fullName,
    this.dob,
    this.gender,
    this.address,
    this.phone,
    this.salary,
    this.storeId,
    this.accountId,
  });

  Map<String, dynamic> toMap() {
    return {
      'EmployeeID': employeeId,
      'FullName': fullName,
      'DOB': dob,
      'Gender': gender,
      'Address': address,
      'Phone': phone,
      'Salary': salary,
      'StoreID': storeId,
      'AccountID': accountId,
    };
  }

  factory EmployeeModel.fromMap(Map<String, dynamic> map) {
    return EmployeeModel(
      employeeId: map['EmployeeID'] as int?,
      fullName: map['FullName'] as String,
      dob: map['DOB'] as String?,
      gender: map['Gender'] as int?,
      address: map['Address'] as String?,
      phone: map['Phone'] as String?,
      salary: map['Salary'] as double?,
      storeId: map['StoreID'] as int?,
      accountId: map['AccountID'] as int?,
    );
  }
}