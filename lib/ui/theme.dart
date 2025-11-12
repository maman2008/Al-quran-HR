import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color islamicGreen = Color(0xFF10B981); // brand primary
  static const Color islamicGold = Color(0xFFD4AF37); // aksen emas
  static const Color bgLightStart = Color(0xFFF0FEF4); // latar gradien awal
  static const Color bgLightEnd = Color(0xFFFFFFFF); // latar gradien akhir

  static const Color islamicGreenDark = Color(0xFF059669); // for gradients

  static ThemeData light() {
    final base = ThemeData.light();
    final colorScheme = ColorScheme.fromSeed(
      seedColor: islamicGreen,
      brightness: Brightness.light,
      primary: islamicGreen,
      secondary: islamicGold,
    );
    return base.copyWith(
      colorScheme: colorScheme.copyWith(
        surface: Colors.white,
        surfaceContainerHighest: const Color(0xFFF3F6F4),
        onSurface: const Color(0xFF101413),
        outlineVariant: const Color(0xFFCFD8D3),
      ),
      scaffoldBackgroundColor: Colors.white,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: const Color(0xFF1B2B26),
        displayColor: const Color(0xFF1B2B26),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: islamicGreen,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: islamicGreen, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: islamicGreen,
        unselectedItemColor: Color(0xFF6B7280),
        showUnselectedLabels: true,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Color(0x1F10B981),
        iconTheme: WidgetStatePropertyAll(IconThemeData(color: islamicGreen)),
        labelTextStyle: WidgetStatePropertyAll(TextStyle(color: islamicGreen, fontWeight: FontWeight.w600)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark();
    final cs = ColorScheme.fromSeed(
      seedColor: islamicGreen,
      brightness: Brightness.dark,
    );
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0C1210),
      colorScheme: cs.copyWith(
        primary: const Color(0xFF78D2A5),
        onPrimary: const Color(0xFF0C1210),
        secondary: islamicGold,
        surface: const Color(0xFF121816),
        surfaceContainerHighest: const Color(0xFF17201D),
        onSurface: const Color(0xFFE6F1EC),
        onSurfaceVariant: const Color(0xFFA3B2AA),
        outlineVariant: const Color(0xFF2A3430),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: const Color(0xFFE6F1EC),
        displayColor: const Color(0xFFE6F1EC),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF17201D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF121816),
        selectedItemColor: Color(0xFF78D2A5),
        unselectedItemColor: Color(0xFFA3B2AA),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xFF121816),
        indicatorColor: Color(0x334ADE80),
        iconTheme: WidgetStatePropertyAll(IconThemeData(color: Color(0xFF78D2A5))),
        labelTextStyle: WidgetStatePropertyAll(TextStyle(color: Color(0xFF78D2A5), fontWeight: FontWeight.w600)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF161D1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      useMaterial3: true,
    );
  }

  static const List<Color> primaryGradient = [islamicGreen, islamicGreenDark];
}
