import 'package:flutter/material.dart';

/// Centralized Global Color Palette for Symposium
/// Change colors here to update the entire application globally.
class AppColors {
  AppColors._();

  // ==========================================
  // 1. BRAND & ACCENT COLORS
  // ==========================================
  static const Color primary = Color(0xFF6366F1); // Indigo Violet
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  static const Color accent = Color(0xFF10B981); // Emerald Green
  static const Color warning = Color(0xFFF59E0B); // Amber Warning
  static const Color error = Color(0xFFEF4444); // Crimson Error
  static const Color linkedIn = Color(0xFF0A66C2);

  // ==========================================
  // 2. BACKGROUND & SURFACES (Obsidian Luxury Dark)
  // ==========================================
  static const Color background = Color(0xFF0B0F19);
  static const Color surface = Color(0xFF121826);
  static const Color surfaceElevated = Color(0xFF1E2638);
  static const Color surfaceBorder = Color(0xFF2A364F);

  // ==========================================
  // 3. TYPOGRAPHY & TEXT
  // ==========================================
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // ==========================================
  // 4. NEUTRALS
  // ==========================================
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // ==========================================
  // 5. SEMANTIC GLOW & OPACITY HELPERS
  // (Auto-derived from base colors)
  // ==========================================
  static Color get primaryGlow => primary.withValues(alpha: 0.15);
  static Color get primaryGlowStrong => primary.withValues(alpha: 0.25);
  static Color get accentGlow => accent.withValues(alpha: 0.15);
  static Color get accentGlowSoft => accent.withValues(alpha: 0.08);
  static Color get accentBorder => accent.withValues(alpha: 0.25);
  static Color get warningGlow => warning.withValues(alpha: 0.12);
  static Color get errorGlow => error.withValues(alpha: 0.12);
  static Color get errorGlowStrong => error.withValues(alpha: 0.20);
}
