import 'package:flutter/material.dart';

/// Centralized Global Color Palette for Symposium
/// Matched exactly to the Figma Editorial Linen & Deep Forest Spruce design.
class AppColors {
  AppColors._();

  // ==========================================
  // 1. BRAND COLORS (Deep Forest Spruce Green)
  // ==========================================
  static const Color primary = Color(0xFF1D4A43); // Deep Spruce Green
  static const Color primaryDark = Color(0xFF143630);
  static const Color primaryLight = Color(0xFF286259);

  // Soft Tint Backgrounds for Icons & Badges
  static const Color primarySoft = Color(0xFFE9F0EC); // Pale Sage Tint
  static const Color primaryBorder = Color(0xFFCCD9D2);

  // ==========================================
  // 2. BACKGROUND & SURFACES (Warm Linen & Cream)
  // ==========================================
  static const Color background = Color(0xFFFBF8F2); // Warm Linen Canvas
  static const Color surface = Color(0xFFFFFFFF); // Pure White Cards & Inputs
  static const Color surfaceWarm = Color(0xFFF3EFE6); // Parchment info cards
  static const Color surfaceElevated = Color(0xFFEDE7DC); // Toggle pill container
  static const Color surfaceBorder = Color(0xFFE5DFD5); // Warm subtle divider/border
  static const Color surfaceBorderLight = Color(0xFFEFE9DE);

  // Avatar placeholder
  static const Color avatarBackground = Color(0xFFE2ECE6); // Sage circle for initials

  // ==========================================
  // 3. STATUS & ACCENTS
  // ==========================================
  static const Color accent = Color(0xFF1D4A43);
  static const Color warning = Color(0xFFB45309);
  static const Color error = Color(0xFFDC2626);
  static const Color errorSoft = Color(0xFFFEE2E2);

  // ==========================================
  // 4. TYPOGRAPHY & TEXT
  // ==========================================
  static const Color textPrimary = Color(0xFF1A332E); // Deep Forest Slate
  static const Color textSecondary = Color(0xFF6B7280); // Slate 500
  static const Color textMuted = Color(0xFF9CA3AF); // Muted grey
  static const Color textLink = Color(0xFF1D4A43); // Forest link

  // ==========================================
  // 5. NEUTRALS & SHADOWS
  // ==========================================
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  static Color get shadowLight => const Color(0xFF1A332E).withValues(alpha: 0.04);
}
