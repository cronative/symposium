import 'package:flutter/material.dart';

/// One source of truth for Symposium's UI tokens.
abstract final class AppColors {
  static const primary = Color(0xFFD91D52);
  static const primaryLight = Color(0xFFFFF0F4);
  static const primarySoft = Color(0xFFFDEEF2);
  static const cardBorder = Color(0xFFFFD4DF);
  static const cardBg = Color(0xFFFFF9FA);
  static const inputBg = Color(0xFFF5F5F7);
  static const text = Color(0xFF191923);
  static const secondary = Color(0xFF777784);
  static const muted = Color(0xFF8E8E93);
  static const canvas = Colors.white;
  static const surface = Color(0xFFF7F7F9);
  static const border = Color(0xFFE7E7EC);
  static const divider = Color(0xFFEAEAEA);
  static const error = Color(0xFFC62828);
}

abstract final class AppSpace {
  static const page = 28.0;
  static const fieldHeight = 54.0;
  static const buttonHeight = 54.0;
  static const fieldRadius = 12.0;
  static const buttonRadius = 13.0;
  static const gap = 16.0;
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
    primary: AppColors.primary,
    surface: AppColors.canvas,
    error: AppColors.error,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.canvas,
    // fontFamily: 'Inter',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 29, height: 1.16, fontWeight: FontWeight.w700, color: AppColors.text),
      headlineMedium: TextStyle(fontSize: 25, height: 1.2, fontWeight: FontWeight.w700, color: AppColors.text),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text),
      bodyLarge: TextStyle(fontSize: 15, height: 1.48, color: AppColors.text),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: AppColors.secondary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      hintStyle: const TextStyle(color: AppColors.secondary, fontSize: 14),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpace.fieldRadius), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpace.fieldRadius), borderSide: const BorderSide(color: AppColors.primary, width: 1.6)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpace.fieldRadius), borderSide: const BorderSide(color: AppColors.error)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpace.fieldRadius), borderSide: const BorderSide(color: AppColors.error, width: 1.6)),
    ),
  );
}
