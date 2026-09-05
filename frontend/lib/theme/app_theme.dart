import 'package:flutter/material.dart';

class AppTheme {
  static const Color navy = Color(0xFF111A24);
  static const Color charcoal = Color(0xFF1D2733);
  static const Color accent = Color(0xFF32D5A4);
  static const Color amber = Color(0xFFF2A33A);
  static const Color page = Color(0xFFBAECFF);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
      primary: const Color(0xFF19735F),
      secondary: amber,
      surface: Colors.white,
    );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: page,
      useMaterial3: true,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: navy,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: navy,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: navy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: navy,
          side: BorderSide(color: navy.withValues(alpha: 0.2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
