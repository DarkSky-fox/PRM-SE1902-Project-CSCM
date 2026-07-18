import '../services/database_helper.dart';

class AuthRepository {
  Future<Map<String, dynamic>?> login(String username, String password) async {
    return await DatabaseHelper.instance.login(username, password);
  }
}
