import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';
import '../models/person.dart';

/// Round initials avatar on a light-blue disc (Figma: #EDF4FF / brand blue).
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.initials, this.size = 64});
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.badgeFill, shape: BoxShape.circle),
      child: Text(
        initials,
        style: TextStyle(fontFamily: 'Inter', fontSize: size * 0.31, fontWeight: FontWeight.w600, color: AppColors.blue),
      ),
    );
  }
}

/// Grey pill used for interest / skill tags.
class TagPill extends StatelessWidget {
  const TagPill(this.label, {super.key, this.large = false});
  final String label;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: large ? const EdgeInsets.symmetric(horizontal: 14, vertical: 9) : const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(large ? 8 : 6)),
      child: Text(
        label,
        style: TextStyle(fontFamily: 'Inter', fontSize: large ? 14 : 12, fontWeight: FontWeight.w500, color: AppColors.ink),
      ),
    );
  }
}

/// "People near you" card — avatar, role, distance, tags, shared interests, actions.
/// The action button follows `person.connection`: Connect · Requested · Respond · Message (connected).
class PersonCard extends StatelessWidget {
  const PersonCard({
    super.key,
    required this.person,
    required this.onView,
    required this.onConnect,
    required this.onToggleSave,
    required this.onRespond,
    required this.onMessage,
  });

  final Person person;
  final VoidCallback onView;
  final VoidCallback onConnect;
  final VoidCallback onToggleSave;
  final VoidCallback onRespond;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final p = person;
    final link = p.connection;
    const btnH = 44.0;
    final Widget action = switch (link.status) {
      'connected' => PrimaryButton(
          label: 'Message',
          height: btnH,
          radius: 8,
          leading: const AppIcon(AppIcons.chat, size: 16, color: AppColors.white),
          onPressed: onMessage,
        ),
      'pending_sent' => const OutlineActionButton(label: 'Requested', icon: AppIcons.check, height: btnH, muted: true),
      'pending_received' => PrimaryButton(label: 'Respond', height: btnH, radius: 8, onPressed: onRespond),
      _ => p.openToConnect
          ? PrimaryButton(label: 'Connect', height: btnH, radius: 8, onPressed: onConnect)
          : const OutlineActionButton(label: 'Not accepting', height: btnH, muted: true),
    };
    // "Ahmedabad · Flutter · Firebase · iOS" — city, then up to 3 skills (interests if no skills).
    final tags = (p.topSkills.isNotEmpty ? p.topSkills : p.interests).take(3);
    final meta = [if ((p.city ?? '').isNotEmpty) p.city!, ...tags].join(' · ');
    return GestureDetector(
      onTap: onView,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                p.photoUrl == null
                    ? InitialsAvatar(initials: p.initials, size: 56)
                    : ClipOval(
                        child: Image.network(p.photoUrl!, width: 56, height: 56, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => InitialsAvatar(initials: p.initials, size: 56)),
                      ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink),
                            ),
                          ),
                          if (p.verified) ...[
                            const SizedBox(width: 5),
                            const AppIcon(AppIcons.checkCircle, size: 15, color: AppColors.blue),
                          ],
                        ],
                      ),
                      if (p.role.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(p.role, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.sub)),
                      ],
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: AppColors.placeholder)),
                      ],
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: p.isSaved ? 'Remove bookmark' : 'Bookmark',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onToggleSave,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: AppIcon(p.isSaved ? AppIcons.bookmarkFilled : AppIcons.bookmark, size: 19, color: AppColors.blue),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SyyncMatchStrip(match: p.match, name: p.firstName),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: OutlineActionButton(label: 'View Profile', height: btnH, onTap: onView)),
                const SizedBox(width: 10),
                Expanded(child: action),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// White button with a 1 px border (View Profile / Clear filters / Requested).
class OutlineActionButton extends StatelessWidget {
  const OutlineActionButton({super.key, required this.label, this.onTap, this.icon, this.height = 44, this.radius = 8, this.muted = false});

  final String label;
  final VoidCallback? onTap;
  final String? icon;
  final double height;
  final double radius;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = muted ? AppColors.sub : AppColors.ink;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: Pressable(
        onTap: onTap,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[AppIcon(icon!, size: 16, color: color), const SizedBox(width: 6)],
              Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
