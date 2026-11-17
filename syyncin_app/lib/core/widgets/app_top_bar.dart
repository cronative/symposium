import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../icons/app_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// The one top navigation bar used across the app (native [AppBar]).
///
/// - 56 dp toolbar (status bar excluded), white, title always centred so
///   right-side actions never shift it.
/// - Very subtle bottom divider ([AppColors.divider]) plus an extremely light
///   shadow that only appears once content scrolls underneath.
/// - Back button only when the route can pop (secondary screens). Main tabs pass
///   `showBack: false`.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.leadingWidth,
    this.actions = const [],
    this.showBack = true,
    this.onBack,
  });

  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final double? leadingWidth;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;

  static const _dividerHeight = 1.0;

  @override
  Size get preferredSize => const Size.fromHeight(AppSpace.topBar + _dividerHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = showBack && (ModalRoute.of(context)?.canPop ?? false);
    final lead = leading ?? (canPop ? AppBackButton(onPressed: onBack) : null);
    return AppBar(
      toolbarHeight: AppSpace.topBar,
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1.5,
      shadowColor: AppColors.barShadow,
      systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      automaticallyImplyLeading: false,
      centerTitle: true,
      titleSpacing: 0,
      leading: lead,
      leadingWidth: leadingWidth ?? (lead == null ? 0 : AppSpace.touch + AppSpace.x2),
      title: titleWidget ??
          (title == null
              ? null
              : Text(title!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.appBarTitle)),
      actions: [...actions, const SizedBox(width: AppSpace.x2)],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(_dividerHeight),
        child: Divider(height: _dividerHeight, thickness: _dividerHeight, color: AppColors.divider),
      ),
    );
  }
}

/// Platform back control: chevron on iOS, arrow on Android. 48 dp touch target.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ios = defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;
    return Padding(
      padding: const EdgeInsets.only(left: AppSpace.x1),
      child: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
        icon: AppIcon(ios ? AppIcons.chevronLeft : AppIcons.back, size: ios ? 24 : 22, color: AppColors.ink),
      ),
    );
  }
}

/// Text action on the right of the top bar ("Save", "Reset", "Mark all read").
class AppBarTextAction extends StatelessWidget {
  const AppBarTextAction({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.blue,
        disabledForegroundColor: AppColors.placeholder,
        minimumSize: const Size(AppSpace.touch, AppSpace.touch),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x2),
        textStyle: AppText.appBarAction,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }
}

/// Icon action on the right of the top bar. 48 dp touch target.
class AppBarIconAction extends StatelessWidget {
  const AppBarIconAction({super.key, required this.icon, required this.tooltip, required this.onPressed, this.color = AppColors.ink});
  final String icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: AppIcon(icon, size: 22, color: color),
    );
  }
}
