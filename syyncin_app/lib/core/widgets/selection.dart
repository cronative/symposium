import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

const _anim = Duration(milliseconds: 160);

/// Interest chip — 32 h · radius 8. Selected = setup gradient + check.
class SelectChip extends StatelessWidget {
  const SelectChip({super.key, required this.label, required this.selected, required this.onTap});

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
          duration: _anim,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: selected ? null : AppColors.white,
            gradient: selected ? AppGradients.setup : null,
            borderRadius: BorderRadius.circular(8),
            border: selected ? null : Border.all(color: AppColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const AppIcon(AppIcons.check, size: 14, color: AppColors.white),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: selected ? AppText.chip.copyWith(fontWeight: FontWeight.w600, color: AppColors.white) : AppText.chip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grey filled dot used on unselected option cards; blue ring when selected.
class SelectionDot extends StatelessWidget {
  const SelectionDot({super.key, required this.selected, this.size = 14});
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _anim,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.blue : AppColors.line,
        border: selected ? Border.all(color: AppColors.selectedFill, width: size * 0.22) : null,
        boxShadow: selected ? const [BoxShadow(color: AppColors.blue, spreadRadius: 1)] : null,
      ),
    );
  }
}

/// Outline radio (gender list): 20 px, 1.5 px border.
class AppRadio extends StatelessWidget {
  const AppRadio({super.key, required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _anim,
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white,
        border: Border.all(color: selected ? AppColors.blue : AppColors.line, width: 1.5),
      ),
      alignment: Alignment.center,
      child: AnimatedContainer(
        duration: _anim,
        width: selected ? 10 : 0,
        height: selected ? 10 : 0,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.blue),
      ),
    );
  }
}

enum CheckboxLook {
  /// Blue outline + blue tick (availability cards).
  outline,

  /// Navy outline → solid blue with white tick (terms checkbox).
  filled,
}

class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.checked,
    this.size = 14,
    this.look = CheckboxLook.outline,
    this.borderColor = AppColors.sub,
    this.borderWidth = 1.2,
    this.radius = 3,
  });

  final bool checked;
  final double size;
  final CheckboxLook look;
  final Color borderColor;
  final double borderWidth;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final solid = checked && look == CheckboxLook.filled;
    return AnimatedContainer(
      duration: _anim,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: solid ? AppColors.blue : AppColors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: checked ? AppColors.blue : borderColor, width: checked ? 1.6 : borderWidth),
      ),
      alignment: Alignment.center,
      child: checked
          ? AppIcon(AppIcons.check, size: size * 0.8, color: solid ? AppColors.white : AppColors.blue)
          : null,
    );
  }
}

enum OptionIndicator { dot, checkbox }

/// Bordered option tile used in grids (Mindset answers, availability).
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.indicator = OptionIndicator.dot,
    this.height = 46,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final OptionIndicator indicator;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: _anim,
          height: height,
          padding: const EdgeInsets.only(left: 12, right: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.selectedFill : AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? AppColors.blue : AppColors.line, width: selected ? 1.2 : 1),
          ),
          child: Row(
            children: [
              indicator == OptionIndicator.dot
                  ? SelectionDot(selected: selected)
                  : AppCheckbox(checked: selected, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.chip.copyWith(
                    color: selected ? AppColors.blue : AppColors.ink,
                    fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-column grid of [OptionCard]s with 8 px gaps.
class OptionGrid extends StatelessWidget {
  const OptionGrid({
    super.key,
    required this.options,
    required this.isSelected,
    required this.onTap,
    this.indicator = OptionIndicator.dot,
    this.height = 46,
  });

  final List<String> options;
  final bool Function(String) isSelected;
  final ValueChanged<String> onTap;
  final OptionIndicator indicator;
  final double height;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < options.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 8));
      rows.add(Row(
        children: [
          for (var j = i; j < i + 2; j++) ...[
            if (j > i) const SizedBox(width: 8),
            Expanded(
              child: j < options.length
                  ? OptionCard(
                      label: options[j],
                      selected: isSelected(options[j]),
                      onTap: () => onTap(options[j]),
                      indicator: indicator,
                      height: height,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ));
    }
    return Column(children: rows);
  }
}

/// "I'm here to…" card: icon tile + title + description + radio/check.
class ReasonCard extends StatelessWidget {
  const ReasonCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: _anim,
          padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.selectedFill : AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.blue : AppColors.line, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: _anim,
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected ? AppColors.badgeFill : AppColors.inputFill,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: AppIcon(icon, size: 20, color: selected ? AppColors.blue : AppColors.iconBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.cardTitle),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppText.cardBody),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              selected
                  ? const AppIcon(AppIcons.checkCircle, size: 22, color: AppColors.blue)
                  : Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.line),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Equal-width single-select row (In person / Online / Both, distance).
class SegmentedChoice extends StatelessWidget {
  const SegmentedChoice({super.key, required this.options, required this.selectedIndex, required this.onChanged});

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 7),
          Expanded(
            child: Semantics(
              button: true,
              selected: i == selectedIndex,
              label: options[i],
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: _anim,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selectedIndex ? AppColors.selectedFill : AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: i == selectedIndex ? AppColors.blue : AppColors.line,
                      width: i == selectedIndex ? 1.2 : 1,
                    ),
                  ),
                  child: Text(
                    options[i],
                    style: AppText.chip.copyWith(
                      color: i == selectedIndex ? AppColors.blue : AppColors.ink,
                      fontWeight: i == selectedIndex ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Native switch (Cupertino on iOS, Material on Android) in SyyncIn blue.
class AppToggle extends StatelessWidget {
  const AppToggle({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.blue,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// "01" pill used on Mindset questions.
class NumberBadge extends StatelessWidget {
  const NumberBadge(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppColors.badgeFill, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: AppText.badge.copyWith(letterSpacing: 0)),
    );
  }
}
