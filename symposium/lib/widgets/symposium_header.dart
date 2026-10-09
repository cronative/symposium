import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

class SymposiumHeader extends StatelessWidget {
  final VoidCallback? onBack;
  final bool showBack;
  final String? actionText;
  final VoidCallback? onAction;

  const SymposiumHeader({
    super.key,
    this.onBack,
    this.showBack = true,
    this.actionText = 'Help',
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Back button or decorative asterisk
          SizedBox(
            width: 44,
            height: 44,
            child: showBack && onBack != null
                ? IconButton(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.primary, size: 22),
                    onPressed: onBack,
                  )
                : const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '✳',
                      style: TextStyle(
                        fontSize: 22,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
          ),

          // Center: symposium serif wordmark
          Text(
            'symposium',
            style: AppTheme.wordmark,
          ),

          // Right: Action text (Help / Skip)
          SizedBox(
            width: 44,
            height: 44,
            child: actionText != null
                ? Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: onAction,
                      child: Text(
                        actionText!,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
