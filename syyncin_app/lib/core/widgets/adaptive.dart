import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

bool get isCupertinoPlatform => defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;

/// Date picker that feels native: wheel in a bottom sheet on iOS, Material
/// calendar dialog on Android/web. Returns null when dismissed.
Future<DateTime?> showAppDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  FocusScope.of(context).unfocus();
  if (!isCupertinoPlatform) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.15)),
        ),
        child: child!,
      ),
    );
  }
  var picked = initialDate;
  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (sheet) => Container(
      color: AppColors.white,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 48,
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.x4),
                    onPressed: () => Navigator.of(sheet).pop(),
                    child: Text('Cancel', style: AppText.appBarAction.copyWith(color: AppColors.sub, fontWeight: FontWeight.w500)),
                  ),
                  const Spacer(),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.x4),
                    onPressed: () => Navigator.of(sheet).pop(picked),
                    child: const Text('Done', style: AppText.appBarAction),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 216,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initialDate,
                minimumDate: firstDate,
                maximumDate: lastDate,
                onDateTimeChanged: (d) => picked = d,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Native confirm dialog (Cupertino on iOS, Material elsewhere). True = confirmed.
Future<bool> showAppConfirm(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final ok = await showAdaptiveDialog<bool>(
    context: context,
    builder: (c) => AlertDialog.adaptive(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        _dialogAction(c, cancelLabel, false, isDefault: true),
        _dialogAction(c, confirmLabel, true, destructive: destructive),
      ],
    ),
  );
  return ok ?? false;
}

Widget _dialogAction(BuildContext c, String label, bool value, {bool destructive = false, bool isDefault = false}) {
  if (isCupertinoPlatform) {
    return CupertinoDialogAction(
      isDefaultAction: isDefault,
      isDestructiveAction: destructive,
      onPressed: () => Navigator.of(c).pop(value),
      child: Text(label),
    );
  }
  return TextButton(
    onPressed: () => Navigator.of(c).pop(value),
    style: TextButton.styleFrom(foregroundColor: destructive ? AppColors.error : AppColors.blue),
    child: Text(label),
  );
}

/// Touch feedback for custom (non-Material) buttons: dims while pressed.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, required this.onTap, this.pressedOpacity = 0.6});
  final Widget child;
  final VoidCallback? onTap;
  final double pressedOpacity;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      child: AnimatedOpacity(
        duration: Duration(milliseconds: _down ? 60 : 160),
        opacity: _down ? widget.pressedOpacity : 1,
        child: widget.child,
      ),
    );
  }
}
