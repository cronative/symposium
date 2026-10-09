import 'package:flutter/material.dart';

/// Centralized Global Color Palette for Symposium (PREMIUM LIGHT THEME)
/// Sabhi colors yahan se control hote hain. Kisi bhi color ko change karne par
/// pure application mein instantly reflect hoga.
class AppColors {
  AppColors._();

  // ==========================================
  // 1. BRAND COLORS (Luxury Indigo)
  // ==========================================
  static const Color primary = Color(0xFF4F46E5); // Rich Indigo
  static const Color primaryLight = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF3730A3);

  // Soft Tint Backgrounds for Icons & Chips
  static const Color primarySoft = Color(0xFFEEF2FF); // Indigo 50
  static const Color primaryBorder = Color(0xFFC7D2FE);

  // ==========================================
  // 2. STATUS & ACCENT COLORS
  // ==========================================
  static const Color accent = Color(0xFF059669); // Emerald Success
  static const Color accentSoft = Color(0xFFECFDF5); // Emerald 50
  static const Color accentBorder = Color(0xFFA7F3D0);

  static const Color warning = Color(0xFFD97706); // Amber
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color error = Color(0xFFDC2626); // Crimson Error
  static const Color errorSoft = Color(0xFFFEF2F2);
  static const Color errorBorder = Color(0xFFFECACA);

  static const Color linkedIn = Color(0xFF0A66C2);
  static const Color linkedInSoft = Color(0xFFE8F3FC);

  // ==========================================
  // 3. BACKGROUND & SURFACES (Clean Light Mode)
  // ==========================================
  static const Color background = Color(0xFFF8FAFC); // Slate 50 crisp canvas
  static const Color surface = Color(0xFFFFFFFF); // Pure white cards
  static const Color surfaceElevated = Color(0xFFF1F5F9); // Slate 100 for tabs & inputs
  static const Color surfaceBorder = Color(0xFFE2E8F0); // Slate 200 clean borders
  static const Color surfaceBorderLight = Color(0xFFF1F5F9);

  // ==========================================
  // 4. TYPOGRAPHY & TEXT
  // ==========================================
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900 (High-contrast luxury)
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  // ==========================================
  // 5. NEUTRALS & SHADOWS
  // ==========================================
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  static Color get shadowLight => const Color(0xFF0F172A).withValues(alpha: 0.05);
  static Color get shadowMedium => const Color(0xFF0F172A).withValues(alpha: 0.08);

  // Dynamic opacity helper
  static Color withOpacity(Color color, double opacity) =>
      color.withValues(alpha: opacity);
}
