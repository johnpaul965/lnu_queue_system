// lib/shared/theme/app_theme.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: LNUColors.primary,
      primary: LNUColors.primary,
      secondary: LNUColors.secondary,
      surface: LNUColors.surface,
    ),
    scaffoldBackgroundColor: LNUColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: LNUColors.primary,
      foregroundColor: LNUColors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: LNUColors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: LNUColors.primary,
        foregroundColor: LNUColors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LNUColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: LNUColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: LNUColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: LNUColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: LNUColors.yellow),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: LNUColors.yellow, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      color: LNUColors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: LNUColors.darkBlue,
      contentTextStyle: TextStyle(color: LNUColors.white),
    ),
    dividerColor: LNUColors.border,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: LNUColors.black),
      bodySmall: TextStyle(color: LNUColors.textMuted),
    ),
  );
}
