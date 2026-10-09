import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum ButtonVariant { primary, secondary, outline, ghost }

class CustomButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPress;
  final ButtonVariant variant;
  final bool loading;
  final Widget? icon;
  final double? width;
  final double height;

  const CustomButton({
    super.key,
    required this.title,
    required this.onPress,
    this.variant = ButtonVariant.primary,
    this.loading = false,
    this.icon,
    this.width,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case ButtonVariant.secondary:
        bgColor = AppColors.surfaceElevated;
        textColor = AppColors.textPrimary;
        borderSide = const BorderSide(color: AppColors.surfaceBorder, width: 1);
        break;
      case ButtonVariant.outline:
        bgColor = AppColors.transparent;
        textColor = AppColors.primaryLight;
        borderSide = const BorderSide(color: AppColors.primary, width: 1.5);
        break;
      case ButtonVariant.ghost:
        bgColor = AppColors.transparent;
        textColor = AppColors.textSecondary;
        break;
      case ButtonVariant.primary:
        bgColor = AppColors.primary;
        textColor = AppColors.white;
        break;
    }

    final bool isDisabled = onPress == null || loading;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPress,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          disabledBackgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.5),
          disabledForegroundColor: AppColors.textMuted,
          elevation: variant == ButtonVariant.primary ? 4 : 0,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: borderSide,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    variant == ButtonVariant.outline
                        ? AppColors.primaryLight
                        : AppColors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 10),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDisabled ? AppColors.textMuted : textColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
