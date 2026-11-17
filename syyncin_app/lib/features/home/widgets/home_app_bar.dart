import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';
import '../../../data/profile_sync.dart';
import '../../profile_setup/widgets/pickers.dart';
import '../home_screen.dart' show NotificationBell;

/// Fixed top navigation bar shared by every tab of Home (native [AppBar]):
/// app name on the left, the tab's title centred, notifications + your
/// photo (or initials) on the right — tapping the photo opens My Profile.
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key, required this.title, required this.onOpenProfile});
  final String title;
  final VoidCallback onOpenProfile;

  @override
  Size get preferredSize => const AppTopBar().preferredSize;

  @override
  Widget build(BuildContext context) {
    return AppTopBar(
      showBack: false, // main tab — never a back arrow
      leadingWidth: 104,
      leading: const Padding(
        padding: EdgeInsets.only(left: AppSpace.screen),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.blue),
              children: [TextSpan(text: 'Syync'), TextSpan(text: 'In', style: TextStyle(color: AppColors.tealBright))],
            ),
            maxLines: 1,
          ),
        ),
      ),
      title: title,
      actions: [
        const NotificationBell(),
        _ProfileButton(onTap: onOpenProfile),
        // Avatar sits 7 px inside its 48 px box: 1 + 8 (AppTopBar) + 7 = 16 px visual edge.
        const SizedBox(width: 1),
      ],
    );
  }
}

/// Your profile photo, or your initials when there's no photo yet.
class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.onTap});
  final VoidCallback onTap;

  static const _size = 34.0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ProfileSync.changes,
      builder: (context, _, __) {
        final d = SetupDraft.instance;
        final initials = d.fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();
        final fallback = Container(
          width: _size,
          height: _size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.badgeFill, shape: BoxShape.circle),
          child: initials.isEmpty
              ? const AppIcon(AppIcons.user, size: 18, color: AppColors.blue)
              : Text(initials, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.blue)),
        );
        return Semantics(
          button: true,
          label: 'My profile',
          child: Pressable(
            onTap: onTap,
            child: SizedBox(
              // 48 dp touch target around the 34 px avatar.
              width: AppSpace.touch,
              height: AppSpace.touch,
              child: Center(
                child: d.photoUrl == null
                    ? fallback
                    : ClipOval(
                        child: Image.network(d.photoUrl!, width: _size, height: _size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
