import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static TextStyle get serifTitle => GoogleFonts.lora(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
      );

  static TextStyle get wordmark => GoogleFonts.lora(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
        fontSize: 21,
        letterSpacing: -0.3,
      );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        surface: AppColors.surface,
        onPrimary: AppColors.white,
        onSurface: AppColors.textPrimary,
      ),
      dividerColor: AppColors.surfaceBorder,
      cardColor: AppColors.surface,
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme.copyWith(
          displayLarge: serifTitle.copyWith(fontSize: 34, height: 1.15),
          displayMedium: serifTitle.copyWith(fontSize: 28, height: 1.2),
          titleLarge: serifTitle.copyWith(fontSize: 22, height: 1.25),
          bodyLarge: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.45,
          ),
          bodySmall: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
