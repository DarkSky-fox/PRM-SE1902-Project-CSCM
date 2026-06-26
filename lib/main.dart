import 'package:flutter/material.dart';
import 'screens/manager_menu_screen.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const CSCMApp());
}

class CSCMApp extends StatelessWidget {
  const CSCMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CSCM - Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const ManagerMenuScreen(),
      title: 'CSCM - Quản lý chuỗi cửa hàng tiện lợi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}
