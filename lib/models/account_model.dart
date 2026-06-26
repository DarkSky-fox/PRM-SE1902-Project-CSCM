class AccountModel {
  final int? accountId;
  final String username;
  final String password;
  final int? roleId;
  final int status; // 1: Active, 0: Inactive

  AccountModel({
    this.accountId,
    required this.username,
    required this.password,
    this.roleId,
    this.status = 1,
  });

  // Chuyển từ Object sang Map để chèn vào SQLite
  Map<String, dynamic> toMap() {
    return {
      'AccountID': accountId,
      'Username': username,
      'Password': password,
      'RoleID': roleId,
      'Status': status,
    };
  }

  // Chuyển từ Map của SQLite thành Object Dart
  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      accountId: map['AccountID'] as int?,
      username: map['Username'] as String,
      password: map['Password'] as String,
      roleId: map['RoleID'] as int?,
      status: map['Status'] as int? ?? 1,
    );
  }
}