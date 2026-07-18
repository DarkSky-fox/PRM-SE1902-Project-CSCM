import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';

class LoginController {
  final AuthRepository _authRepository = AuthRepository();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
  }

  Future<Map<String, dynamic>?> handleLogin() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;
    return await _authRepository.login(username, password);
  }
}
