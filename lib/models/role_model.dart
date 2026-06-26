class RoleModel {
  final int? roleId;
  final String roleName;

  RoleModel({
    this.roleId,
    required this.roleName,
  });

  Map<String, dynamic> toMap() {
    return {
      'RoleID': roleId,
      'RoleName': roleName,
    };
  }

  factory RoleModel.fromMap(Map<String, dynamic> map) {
    return RoleModel(
      roleId: map['RoleID'] as int?,
      roleName: map['RoleName'] as String,
    );
  }
}