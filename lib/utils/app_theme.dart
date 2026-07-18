import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Brand Colors ─────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1A6B3C);
  static const Color primaryDark = Color(0xFF0F4228);
  static const Color primaryLight = Color(0xFF00C96B);
  static const Color accent = Color(0xFFF5A623);
  static const Color accentDark = Color(0xFFD4891A);

  // ─── Dark Theme Surface ────────────────────────────────────────────────────
  static const Color white = Color(0xFF162238); // Dark card background
  static const Color offWhite = Color(0xFF080F1A); // Dark overall scaffold background
  static const Color surfaceLight = Color(0xFF1C2B46); // Slightly lighter container
  static const Color cardBg = Color(0xFF162238);
  static const Color divider = Color(0xFF25354F); // Darker border/divider

  // ─── Dark Mode Specifics (splash / login / others consistent) ─────────────
  static const Color darkBg = Color(0xFF080F1A);
  static const Color darkCard = Color(0xFF162238);
  static const Color darkElevated = Color(0xFF1C2B46);
  static const Color darkBorder = Color(0xFF25354F);

  // ─── Text Colors (Lightened for dark background contrast) ──────────────────
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textLight = Color(0xFF64748B);
  static const Color textOnDark = Color(0xFFF1F5F9);
  static const Color textOnDarkMuted = Color(0xFF94A3B8);

  // ─── Semantic ──────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFFF5252);
  static const Color success = Color(0xFF00C96B);
  static const Color warning = Color(0xFFF5A623);
  static const Color info = Color(0xFF3B82F6);

  // ─── Shift colors (timetable) ──────────────────────────────────────────────
  static const Color shiftMorning = Color(0xFFFF9800);
  static const Color shiftAfternoon = Color(0xFF2196F3);
  static const Color shiftEvening = Color(0xFF7C4DFF);
  static const Color shiftOff = Color(0xFF475569); // Darker grey for off shift

  // ─── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A6B3C), Color(0xFF00C96B)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF080F1A), Color(0xFF162238), Color(0xFF040A12)],
    stops: [0.0, 0.6, 1.0],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF040A12), Color(0xFF0E1A2B), Color(0xFF05170E)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A6B3C), Color(0xFF0F4228)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00C96B), Color(0xFF1A6B3C)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5A623), Color(0xFFD4891A)],
  );

  // ─── Shadows ───────────────────────────────────────────────────────────────
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withAlpha(40),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> cardShadowMd = [
    BoxShadow(
      color: Colors.black.withAlpha(30),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: const Color(0xFF1A6B3C).withAlpha(100),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> glowShadow = [
    BoxShadow(
      color: const Color(0xFF00C96B).withAlpha(80),
      blurRadius: 30,
      offset: const Offset(0, 0),
      spreadRadius: 2,
    ),
  ];

  // ─── Dark ThemeData ────────────────────────────────────────────────────────
  static ThemeData get theme {
    final base = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        surface: offWhite,
      ),
      scaffoldBackgroundColor: offWhite,
      textTheme: base.copyWith(
        displayLarge: base.displayLarge?.copyWith(
          color: textPrimary, fontWeight: FontWeight.w800, letterSpacing: -1.0),
        headlineMedium: base.headlineMedium?.copyWith(
          color: textPrimary, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        titleLarge: base.titleLarge?.copyWith(
          color: textPrimary, fontWeight: FontWeight.w700),
        titleMedium: base.titleMedium?.copyWith(
          color: textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: base.bodyLarge?.copyWith(
          color: textPrimary, fontSize: 15),
        bodyMedium: base.bodyMedium?.copyWith(
          color: textSecondary, fontSize: 14),
        labelSmall: base.labelSmall?.copyWith(
          color: textSecondary, letterSpacing: 0.3),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: offWhite,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withAlpha(40),
        centerTitle: true,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: const BorderSide(color: primaryLight, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: divider, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: divider, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: textLight, fontSize: 15),
        prefixIconColor: textSecondary,
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryLight,
        unselectedLabelColor: textSecondary,
        indicatorColor: primaryLight,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        selectedColor: primary.withAlpha(50),
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: divider),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: divider, width: 1),
        ),
        margin: const EdgeInsets.only(bottom: 12),
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: white,
        titleTextStyle: GoogleFonts.inter(
          color: textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
        contentTextStyle: GoogleFonts.inter(
          color: textSecondary, fontSize: 14, height: 1.5),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primaryLight,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }

  static String formatMoney(num amount) {
    final str = amount.toStringAsFixed(0);
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return '${str.replaceAllMapped(reg, (Match m) => '${m[1]}.')} ₫';
  }
}
