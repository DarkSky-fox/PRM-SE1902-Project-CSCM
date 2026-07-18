import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _pulseController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.5)),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _pulseScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 2100));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.splashGradient),
        child: Stack(
          children: [
            // ── Decorative circles ────────────────────────────────────────────
            Positioned(
              top: -60, right: -60,
              child: Container(
                width: 260, height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00C96B).withAlpha(8),
                ),
              ),
            ),
            Positioned(
              bottom: -100, left: -80,
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A6B3C).withAlpha(12),
                ),
              ),
            ),
            Positioned(
              top: 180, left: -120,
              child: Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF5A623).withAlpha(6),
                ),
              ),
            ),

            // ── Main content ──────────────────────────────────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: Listenable.merge([_logoController, _pulseController]),
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(scale: _logoScale.value, child: child),
                      );
                    },
                    child: _buildLogoWidget(),
                  ),
                  const SizedBox(height: 40),
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _textOpacity.value,
                        child: SlideTransition(position: _textSlide, child: child),
                      );
                    },
                    child: _buildTextContent(),
                  ),
                  const SizedBox(height: 80),
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) => Opacity(opacity: _textOpacity.value, child: child),
                    child: _buildLoadingIndicator(),
                  ),
                ],
              ),
            ),

            // ── Version ───────────────────────────────────────────────────────
            Positioned(
              bottom: 40, left: 0, right: 0,
              child: AnimatedBuilder(
                animation: _textController,
                builder: (context, child) => Opacity(opacity: _textOpacity.value, child: child),
                child: const Text(
                  'Phiên bản 1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white30, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoWidget() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: _pulseScale.value,
              child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00C96B).withAlpha(12),
                ),
              ),
            ),
            Transform.scale(
              scale: _pulseScale.value,
              child: Container(
                width: 145, height: 145,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00C96B).withAlpha(20),
                ),
              ),
            ),
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E5C3A), Color(0xFF0D3522)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C96B).withAlpha(50),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
                border: Border.all(color: Colors.white.withAlpha(25), width: 2),
              ),
              child: const Icon(
                Icons.store_mall_directory_rounded,
                color: Colors.white,
                size: 56,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextContent() {
    return Column(
      children: [
        Text(
          'CSCM',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 52,
            fontWeight: FontWeight.w900,
            letterSpacing: 10,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 40, height: 2, color: AppTheme.primaryLight.withAlpha(153)),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 8, height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryLight.withAlpha(178)),
            ),
            Container(width: 40, height: 2, color: AppTheme.primaryLight.withAlpha(153)),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Hệ thống quản lý',
          style: GoogleFonts.inter(color: AppTheme.textOnDarkMuted, fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 1.5),
        ),
        const SizedBox(height: 4),
        Text(
          'Chuỗi Cửa Hàng Tiện Lợi',
          style: GoogleFonts.inter(color: AppTheme.accent, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.2),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        SizedBox(
          width: 36, height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight.withAlpha(200)),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Đang khởi động...', style: TextStyle(color: Colors.white54, fontSize: 13)),
      ],
    );
  }
}
