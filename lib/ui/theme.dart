import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color pastelGreen = Color(0xFFDDE9C7); // hijau pastel lembut
  static const Color darkGreenText = Color(0xFF1B5E20); // hijau gelap teks

  static ThemeData light() {
    final base = ThemeData.light();
    final colorScheme = ColorScheme.fromSeed(
      seedColor: pastelGreen,
      brightness: Brightness.light,
      primary: darkGreenText,
    );
    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.white,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: darkGreenText,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white.withOpacity(0.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark();
    final cs = ColorScheme.fromSeed(
      seedColor: pastelGreen,
      brightness: Brightness.dark,
    );
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0B0F0E),
      colorScheme: cs.copyWith(
        primary: const Color(0xFF98E29B),
        onPrimary: const Color(0xFF0B0F0E),
        secondary: const Color(0xFF72C58B),
        surface: const Color(0xFF111514),
        surfaceContainerHighest: const Color(0xFF171B1A),
        onSurface: const Color(0xFFE7F2E3),
        onSurfaceVariant: const Color(0xFFAAB7A6),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: const Color(0xFFE7F2E3),
        displayColor: const Color(0xFFE7F2E3),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF171B1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1A1F1D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      useMaterial3: true,
    );
  }
}
