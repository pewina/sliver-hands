import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF172A3A);
  static const cream = Color(0xFFFFFBF5);
  static const saffron = Color(0xFFF29D38);
  static const teal = Color(0xFF057B77);
  static const green = Color(0xFF207A4D);
  static const rose = Color(0xFFC5495F);
  static const mist = Color(0xFFEAF3F0);
}

abstract final class AppTheme {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      primary: AppColors.teal,
      secondary: AppColors.saffron,
      surface: Colors.white,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.ink),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
      bodyLarge: TextStyle(fontSize: 17, height: 1.4, color: AppColors.ink),
      bodyMedium: TextStyle(fontSize: 15, height: 1.35, color: AppColors.ink),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 56),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
  );
}
