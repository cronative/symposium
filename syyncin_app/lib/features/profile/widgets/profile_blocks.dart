import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';

// Building blocks shared by My Profile and other members' profiles.


class ProfileChip extends StatelessWidget {
  const ProfileChip({super.key, required this.label, required this.bg, required this.fg, this.icon});
  final String label;
  final Color bg;
  final Color fg;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[AppIcon(icon!, size: 14, color: fg), const SizedBox(width: 6)],
          Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
        ],
      ),
    );
  }
}

class ProfileSegmentButton extends StatelessWidget {
  const ProfileSegmentButton({super.key, required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? AppGradients.setup : null,
            color: selected ? null : AppColors.inputFill,
            borderRadius: BorderRadius.circular(8),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColors.white : AppColors.sub,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.title, required this.children, this.icon});
  final String title;
  final String? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink))),
              if (icon != null) AppIcon(icon!, size: 18, color: AppColors.placeholder),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class ProfileNavCard extends StatelessWidget {
  const ProfileNavCard({super.key, required this.title, required this.onTap, this.subtitle, this.icon});
  final String title;
  final String? subtitle;
  final String? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
          child: Row(
            children: [
              if (icon != null) ...[AppIcon(icon!, size: 20, color: AppColors.sub), const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: subtitle != null ? 16 : 15,
                        fontWeight: subtitle != null ? FontWeight.w600 : FontWeight.w500,
                        color: AppColors.ink,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.sub)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const AppIcon(AppIcons.chevronRight, size: 18, color: AppColors.placeholder),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileBox extends StatelessWidget {
  const ProfileBox({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

class ProfileBoxTitle extends StatelessWidget {
  const ProfileBoxTitle({super.key, required this.icon, required this.title, this.subtitle});
  final String icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(icon, size: 20, color: AppColors.blue),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink))),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.sub)),
          ],
        ],
      ),
    );
  }
}

/// Light-blue pill (skills) — `outlined` adds the thin blue border used for interests.
class BluePill extends StatelessWidget {
  const BluePill(this.label, {super.key, this.outlined = false});
  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: outlined ? AppColors.selectedFill : AppColors.badgeFill,
        borderRadius: BorderRadius.circular(8),
        border: outlined ? Border.all(color: const Color(0xFFCFE0FA)) : null,
      ),
      child: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.blue)),
    );
  }
}

/// Label ↔ value rows with dividers (Basic Details, Location …).
List<Widget> profileRows(List<(String, String)> rows) => [
      for (var i = 0; i < rows.length; i++) ...[
        if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.line),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rows[i].$1, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.sub)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  rows[i].$2,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
                ),
              ),
            ],
          ),
        ),
      ],
    ];
