import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../controllers/login_controller.dart';
import 'home_screen.dart';
import 'pos_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _loginController = LoginController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _cardOpacity;
  late Animation<Offset> _cardSlide;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _cardSlide = Tween<Offset>(begin: const Offset(0.0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _loginController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    final user = await _loginController.handleLogin();

    if (user != null) {
      if (user['Status'] == 0) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Tài khoản của bạn đã bị khóa. Vui lòng liên hệ Quản lý hoặc Chủ chuỗi để mở lại.';
        });
        return;
      }

      final username = _loginController.usernameController.text.trim();
      final roleId = user['RoleID'] as int;
      final storeId = user['StoreID'] as int?;
      final employeeId = user['EmployeeID'] as int;
      final fullName = user['FullName'] as String;

      if (roleId == 3) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PosScreen(
              username: username,
              employeeId: employeeId,
              storeId: storeId ?? 1,
              fullName: fullName,
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              username: username,
              roleId: roleId,
              storeId: storeId,
              employeeId: employeeId,
              fullName: fullName,
            ),
          ),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Tên đăng nhập hoặc mật khẩu không chính xác.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.splashGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom),
              child: Stack(
                children: [
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00C96B).withAlpha(8),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -60,
                    left: -60,
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1A6B3C).withAlpha(10),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 60),
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (_, child) => Transform.scale(
                            scale: _logoScale.value,
                            child: child,
                          ),
                          child: _buildLogoSection(),
                        ),
                        const SizedBox(height: 48),
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (_, child) => Opacity(
                            opacity: _cardOpacity.value,
                            child: SlideTransition(
                              position: _cardSlide,
                              child: child,
                            ),
                          ),
                          child: _buildLoginCard(),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Phiên bản 1.0.0',
                          style: TextStyle(
                            color: AppTheme.textOnDarkMuted.withAlpha(120),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E5C3A), Color(0xFF0A3020)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C96B).withAlpha(50),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
            border: Border.all(color: Colors.white.withAlpha(20), width: 2),
          ),
          child: const Icon(Icons.lock_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 20),
        Text(
          'CSCM',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Đăng nhập hệ thống',
          style: GoogleFonts.inter(
            color: AppTheme.textOnDarkMuted,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withAlpha(230),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.darkBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) _buildErrorBanner(),
            if (_errorMessage != null) const SizedBox(height: 20),
            Text(
              'Chào mừng trở lại',
              style: GoogleFonts.inter(
                color: AppTheme.textOnDark,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Nhập thông tin đăng nhập để tiếp tục',
              style: GoogleFonts.inter(
                color: AppTheme.textOnDarkMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _loginController.usernameController,
              style: GoogleFonts.inter(color: AppTheme.textOnDark, fontSize: 15),
              decoration: _darkInputDecoration(
                label: 'Tên đăng nhập',
                hint: 'Nhập username',
                icon: Icons.person_outline_rounded,
              ),
              validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập tên đăng nhập' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _loginController.passwordController,
              obscureText: !_isPasswordVisible,
              style: GoogleFonts.inter(color: AppTheme.textOnDark, fontSize: 15),
              decoration: _darkInputDecoration(
                label: 'Mật khẩu',
                hint: 'Nhập mật khẩu',
                icon: Icons.lock_outline_rounded,
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppTheme.textOnDarkMuted,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
              validator: (v) => v == null || v.length < 6 ? 'Mật khẩu phải có ít nhất 6 ký tự' : null,
            ),
            const SizedBox(height: 28),
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  InputDecoration _darkInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppTheme.textOnDarkMuted, size: 20),
      filled: true,
      fillColor: AppTheme.darkElevated,
      labelStyle: GoogleFonts.inter(color: AppTheme.textOnDarkMuted, fontSize: 14),
      hintStyle: GoogleFonts.inter(
        color: AppTheme.textOnDarkMuted.withAlpha(150),
        fontSize: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.darkBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.error, width: 2),
      ),
      errorStyle: GoogleFonts.inter(color: AppTheme.error, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }

  Widget _buildLoginButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : _handleLogin,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            gradient: _isLoading ? null : AppTheme.primaryGradient,
            color: _isLoading ? AppTheme.darkElevated : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: _isLoading ? [] : AppTheme.buttonShadow,
          ),
          child: Container(
            height: 54,
            alignment: Alignment.center,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    'ĐĂNG NHẬP',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3D1515),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withAlpha(80), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFFF8A80), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.inter(color: const Color(0xFFFF8A80), fontSize: 13, height: 1.4),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: const Icon(Icons.close_rounded, color: Color(0xFFFF8A80), size: 18),
          ),
        ],
      ),
    );
  }
}
