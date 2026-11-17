import 'package:flutter/material.dart';

/// Every colour below is sampled from the SyyncIn Figma file
/// (page "SyyncIn · V3 · MoM 17 Oct updates"). Do not hand-tweak values —
/// change them in Figma first, then mirror them here.
abstract final class AppColors {
  // Brand
  static const blue = Color(0xFF0668E8);
  static const tealDeep = Color(0xFF008F78); // gradient end on onboarding/auth
  static const tealBright = Color(0xFF00CFAE); // gradient end on profile setup
  static const navy = Color(0xFF062D69); // onboarding & auth headings
  static const ink = Color(0xFF0A1741); // profile setup headings & labels
  static const inkSoft = Color(0xFF101B43);

  // Text
  static const grey = Color(0xFF606B7D); // onboarding & auth body
  static const sub = Color(0xFF6577AB); // profile setup body / helper
  static const placeholder = Color(0xFF7B8BB5); // profile setup placeholders
  static const authPlaceholder = Color(0xFF667085);
  static const iconBlue = Color(0xFF1645A4);
  static const taglineGrey = Color(0xFF546375);
  static const taglineDotBlue = Color(0xFF0061FF);
  static const taglineDotTeal = Color(0xFF00BFA8);

  // Surfaces & lines
  static const white = Color(0xFFFFFFFF);
  static const line = Color(0xFFE1E7F2);
  static const divider = Color(0xFFE8EDF4); // top-bar bottom divider (very subtle)
  static const segment = Color(0xFFE9EDF6);
  static const inputFill = Color(0xFFF4F6FB);
  static const selectedFill = Color(0xFFF0F6FD);
  static const badgeFill = Color(0xFFEDF4FF);
  static const backFill = Color(0xFFF3F6FC);
  static const otpBackFill = Color(0xFFF7F7F9);
  static const dotInactive = Color(0xFFD0D4D8);
  static const socialStroke = Color(0xFF6F88A3);
  static const accentBlue = Color(0xFFD5EAFE);
  static const accentTeal = Color(0xFFE1FAF8);
  static const cardStroke = Color(0xFFE1F8F3);

  // Feedback
  static const error = Color(0xFFD62B2B);
  static const success = Color(0xFF00BE9C);
  static const successSoft = Color(0xFF00BDA0);
  static const warning = Color(0xFFD98C0D);
  static const warningFill = Color(0xFFFFF5E8);

  // Selfie / verified
  static const cameraBg = Color(0xFFD8DFE8);
  static const cameraPortrait = Color(0xFFAEBECF);
  static const cameraGuide = Color(0xFFE9F2FF);
  static const cameraFace = Color(0xFFD5DFEC);
  static const cameraOverlay = Color(0xFF0D1C43);
  static const tipFill = Color(0xFFF3F7FE);
  static const tipStroke = Color(0xFFE5ECFA);
  static const panelFill = Color(0xFFF8FAFE);
  static const panelStroke = Color(0xFFE5EAF4);
  static const haloOuter = Color(0xFFE6F9F4);
  static const haloInner = Color(0xFFCFF6EA);
  static const portraitFill = Color(0xFFDCE8F3);
  static const portraitIcon = Color(0xFF355B83);

  // Splash
  static const splashMid = Color(0xFF054D9E);
  static const splashTagline = Color(0xFFD9EDFF);

  // Welcome illustration
  static const chipOrange = Color(0xFFFAA84D);
  static const chipPurple = Color(0xFF8C66F2);
  static const chipGreen = Color(0xFF33BF99);
  static const visualStart = Color(0xFFEBF2FF);
  static const visualEnd = Color(0xFFE5F7F2);

  // Shadows (alpha baked in to avoid deprecated withOpacity calls)
  static const shadowNavy12 = Color(0x1F062D69);
  static const shadowBlue35 = Color(0x590668E8);
  static const shadowBlack25 = Color(0x40000000);
  static const barShadow = Color(0x14062D69); // top bar elevation while content scrolls under it
}

abstract final class AppGradients {
  /// Buttons on onboarding & auth screens.
  static const auth = LinearGradient(colors: [AppColors.blue, AppColors.tealDeep]);

  /// Buttons, chips and toggles on profile setup screens.
  static const setup = LinearGradient(colors: [AppColors.blue, AppColors.tealBright]);

  static const splash = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.navy, AppColors.splashMid, AppColors.tealDeep],
    stops: [0, 0.6, 1],
  );

  static const welcomeVisual = LinearGradient(colors: [AppColors.visualStart, AppColors.visualEnd]);
}
