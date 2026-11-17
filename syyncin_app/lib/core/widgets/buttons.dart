import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'adaptive.dart';

enum ButtonVariant {
  /// Onboarding & auth: 56 h · radius 5 · blue → deep teal · Inter Bold 16.
  auth,

  /// Profile setup: 55 h · radius 11 · blue → bright teal · Inter Semi Bold 16.
  setup,
}

/// Gradient primary CTA. Disabled state = same gradient at 40 % opacity (as in Figma).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.setup,
    this.enabled = true,
    this.showArrow = false,
    this.leading,
    this.height,
    this.radius,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool enabled;
  final bool showArrow;
  final Widget? leading;
  final double? height;
  final double? radius;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isAuth = variant == ButtonVariant.auth;
    final active = enabled && !loading && onPressed != null;
    return Semantics(
      button: true,
      enabled: active,
      label: label,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1 : 0.4,
        child: Pressable(
          onTap: active ? onPressed : null,
          pressedOpacity: 0.8,
          child: Container(
            height: height ?? (isAuth ? 56 : 52),
            decoration: BoxDecoration(
              gradient: isAuth ? AppGradients.auth : AppGradients.setup,
              borderRadius: BorderRadius.circular(radius ?? (isAuth ? 5 : 11)),
            ),
            alignment: Alignment.center,
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.white),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (leading != null) ...[leading!, const SizedBox(width: 10)],
                      Text(label, style: isAuth ? AppText.authButton : AppText.setupButton),
                      if (showArrow) ...[
                        const SizedBox(width: 8),
                        const AppIcon(AppIcons.arrowRight, size: 18, color: AppColors.white),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// 48×48 outlined square used for Google / LinkedIn / Apple sign-in.
class SocialButton extends StatelessWidget {
  const SocialButton({super.key, required this.svg, required this.onTap, required this.semanticLabel});

  final String svg;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Pressable(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppColors.socialStroke, width: 1.5),
          ),
          alignment: Alignment.center,
          child: BrandSvg(svg),
        ),
      ),
    );
  }
}

/// Square tinted back button (OTP, Selfie, Verified).
class SquareBackButton extends StatelessWidget {
  const SquareBackButton({
    super.key,
    this.size = 48,
    this.fill = AppColors.otpBackFill,
    this.iconColor = AppColors.navy,
    this.onTap,
  });

  final double size;
  final Color fill;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: Pressable(
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(5)),
          alignment: Alignment.center,
          child: AppIcon(AppIcons.chevronLeft, size: 22, color: iconColor),
        ),
      ),
    );
  }
}

/// Plain arrow back used in the profile-setup header (22 px, 44 px hit area).
class ArrowBackButton extends StatelessWidget {
  const ArrowBackButton({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: Pressable(
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Align(
            alignment: Alignment.centerLeft,
            child: AppIcon(AppIcons.back, size: 22, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}
