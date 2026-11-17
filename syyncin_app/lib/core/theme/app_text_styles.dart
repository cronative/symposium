import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Type scale taken from Figma. `height` = Figma line-height ÷ font-size.
abstract final class AppText {
  static const _f = 'Inter';

  // ── Navigation ──────────────────────────────────────────────────────
  static const appBarTitle = TextStyle(fontFamily: _f, fontSize: 17, height: 22 / 17, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const appBarAction = TextStyle(fontFamily: _f, fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.blue);

  // ── Onboarding & auth ───────────────────────────────────────────────
  static const authTitle = TextStyle(fontFamily: _f, fontSize: 24, height: 32 / 24, fontWeight: FontWeight.w700, color: AppColors.navy);
  static const authBody = TextStyle(fontFamily: _f, fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w400, color: AppColors.grey);
  static const authLabel = TextStyle(fontFamily: _f, fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w700, color: AppColors.navy);
  static const authInput = TextStyle(fontFamily: _f, fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w400, color: AppColors.navy);
  static const authButton = TextStyle(fontFamily: _f, fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w700, color: AppColors.white);
  static const onboardingEyebrow = TextStyle(fontFamily: _f, fontSize: 12, height: 1.4, letterSpacing: 1.5, fontWeight: FontWeight.w600, color: AppColors.blue);
  static const tagline = TextStyle(fontFamily: _f, fontSize: 12, height: 16 / 12, letterSpacing: 2, fontWeight: FontWeight.w400, color: AppColors.taglineGrey);
  static const legal = TextStyle(fontFamily: _f, fontSize: 13, height: 16 / 13, fontWeight: FontWeight.w400, color: AppColors.grey);
  static const otpDigit = TextStyle(fontFamily: _f, fontSize: 24, height: 32 / 24, fontWeight: FontWeight.w700, color: AppColors.navy);

  // ── Profile setup ───────────────────────────────────────────────────
  static const setupEyebrow = TextStyle(fontFamily: _f, fontSize: 12, letterSpacing: 0.8, fontWeight: FontWeight.w600, color: AppColors.blue);
  static const setupTitle = TextStyle(fontFamily: _f, fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w700, color: AppColors.ink);
  static const setupTitleSmall = TextStyle(fontFamily: _f, fontSize: 20, height: 26 / 20, fontWeight: FontWeight.w700, color: AppColors.ink);
  static const setupSubtitle = TextStyle(fontFamily: _f, fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w400, color: AppColors.sub);
  static const stepCount = TextStyle(fontFamily: _f, fontSize: 12, letterSpacing: 0.6, fontWeight: FontWeight.w500, color: AppColors.sub);
  static const screenTitle = TextStyle(fontFamily: _f, fontSize: 14, letterSpacing: 0.6, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const fieldLabel = TextStyle(fontFamily: _f, fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink);
  static const fieldInput = TextStyle(fontFamily: _f, fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.ink);
  static const fieldHint = TextStyle(fontFamily: _f, fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.placeholder);
  static const helper = TextStyle(fontFamily: _f, fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w400, color: AppColors.sub);
  static const sectionTitle = TextStyle(fontFamily: _f, fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const counter = TextStyle(fontFamily: _f, fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.blue);
  static const chip = TextStyle(fontFamily: _f, fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.ink);
  static const cardTitle = TextStyle(fontFamily: _f, fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink);
  static const cardBody = TextStyle(fontFamily: _f, fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.sub);
  static const setupButton = TextStyle(fontFamily: _f, fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.white);
  static const badge = TextStyle(fontFamily: _f, fontSize: 11, letterSpacing: 0.5, fontWeight: FontWeight.w600, color: AppColors.blue);
}
