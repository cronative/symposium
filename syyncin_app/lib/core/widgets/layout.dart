import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'buttons.dart';

/// Image from assets/images with a brand-gradient placeholder until the
/// file is exported from Figma (see assets/images/README.md).
class AssetBox extends StatelessWidget {
  const AssetBox(
    this.path, {
    super.key,
    required this.width,
    required this.height,
    this.radius = 0,
    this.border,
    this.shadow,
    this.fit = BoxFit.cover,
    this.placeholderLabel,
  });

  final String path;
  final double width;
  final double height;
  final double radius;
  final BoxBorder? border;
  final List<BoxShadow>? shadow;
  final BoxFit fit;
  final String? placeholderLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: shadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          path,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => Container(
            decoration: const BoxDecoration(gradient: AppGradients.welcomeVisual),
            alignment: Alignment.center,
            child: Text(
              placeholderLabel ?? path.split('/').last,
              style: AppText.helper.copyWith(color: AppColors.navy, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// SyyncIn logo (exported from Figma as assets/images/logo.png).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.width = 205, this.height = 160, this.radius = 0, this.shadow});
  final double width;
  final double height;
  final double radius;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) => AssetBox(
        'assets/images/logo.png',
        width: width,
        height: height,
        radius: radius,
        shadow: shadow,
        fit: BoxFit.contain,
        placeholderLabel: 'SyyncIn',
      );
}

/// "MEET • CONNECT • GROW" with blue / teal dots.
class Tagline extends StatelessWidget {
  const Tagline({super.key, this.monoColor, this.wideSpacing = true});

  /// When set (splash), the whole line uses this colour.
  final Color? monoColor;
  final bool wideSpacing;

  @override
  Widget build(BuildContext context) {
    final base = AppText.tagline.copyWith(color: monoColor ?? AppColors.taglineGrey);
    final gap = wideSpacing ? '  ' : ' ';
    return Text.rich(
      TextSpan(style: base, children: [
        TextSpan(text: 'MEET$gap'),
        TextSpan(text: '•', style: base.copyWith(color: monoColor ?? AppColors.taglineDotBlue)),
        TextSpan(text: '${gap}CONNECT$gap'),
        TextSpan(text: '•', style: base.copyWith(color: monoColor ?? AppColors.taglineDotTeal)),
        TextSpan(text: '${gap}GROW'),
      ]),
      textAlign: TextAlign.center,
    );
  }
}

/// Eyebrow · title · subtitle block used at the top of every setup step.
class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, this.eyebrow, required this.title, this.subtitle, this.titleStyle});

  final String? eyebrow;
  final String title;
  final String? subtitle;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (eyebrow != null) ...[
          Text(eyebrow!.toUpperCase(), style: AppText.setupEyebrow),
          const SizedBox(height: 6),
        ],
        Text(title, style: titleStyle ?? AppText.setupTitle),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: AppText.setupSubtitle),
        ],
      ],
    );
  }
}

class DividerLine extends StatelessWidget {
  const DividerLine({super.key});
  @override
  Widget build(BuildContext context) => Container(height: 1, color: AppColors.line);
}

/// Title row with a dynamic counter on the right ("Your interests · 0 selected").
class SectionTitleRow extends StatelessWidget {
  const SectionTitleRow({super.key, required this.title, required this.trailing, this.helper});
  final String title;
  final String trailing;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: AppText.sectionTitle)),
            Text(trailing, style: AppText.counter),
          ],
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(helper!, style: AppText.helper.copyWith(height: null)),
        ],
      ],
    );
  }
}

enum StepHeaderStyle {
  /// ← · "STEP 2 OF 5" · five 4 px segments (steps 2–5).
  segmented,

  /// ← · centred title · "1 of 5" · single bar (step 1 "About you").
  titled,
}

/// Header shared by all profile-setup steps.
/// Geometry from Figma: back icon 12 px under the safe area, progress 16 px
/// below it, content 20 px below progress.
class StepHeader extends StatelessWidget {
  const StepHeader({
    super.key,
    required this.step,
    this.total = 5,
    this.style = StepHeaderStyle.segmented,
    this.title,
    this.onBack,
  });

  final int step;
  final int total;
  final StepHeaderStyle style;
  final String? title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final titled = style == StepHeaderStyle.titled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        SizedBox(
          height: 22,
          child: Row(
            children: [
              ArrowBackButton(onTap: onBack),
              Expanded(
                child: titled && title != null
                    ? Text(title!.toUpperCase(), textAlign: TextAlign.center, style: AppText.screenTitle)
                    : const SizedBox.shrink(),
              ),
              SizedBox(
                width: titled ? 44 : null,
                child: Text(
                  titled ? '$step of $total' : 'STEP $step OF $total',
                  textAlign: TextAlign.right,
                  style: titled ? AppText.stepCount.copyWith(fontWeight: FontWeight.w400, letterSpacing: 0) : AppText.stepCount,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        titled ? _SingleBar(step: step, total: total) : _Segments(step: step, total: total),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _Segments extends StatelessWidget {
  const _Segments({required this.step, required this.total});
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 7),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i < step ? AppColors.blue : AppColors.segment,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SingleBar extends StatelessWidget {
  const _SingleBar({required this.step, required this.total});
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      decoration: BoxDecoration(color: AppColors.segment, borderRadius: BorderRadius.circular(2)),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: step / total,
        child: Container(
          decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(2)),
        ),
      ),
    );
  }
}

/// Scroll view whose child is at least as tall as the viewport, so
/// `MainAxisAlignment.spaceBetween` layouts match Figma on tall phones and
/// still scroll on small ones.
class FillScrollView extends StatelessWidget {
  const FillScrollView({super.key, required this.child, this.padding = EdgeInsets.zero});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight - padding.vertical),
          child: IntrinsicHeight(child: child),
        ),
      ),
    );
  }
}

/// Scaffold for profile-setup steps.
/// [stickyCta] = CTA pinned 16 px above the screen bottom (steps 1–2);
/// otherwise it sits at the end of the scrolling content (steps 3–5).
class SetupScaffold extends StatelessWidget {
  const SetupScaffold({
    super.key,
    required this.header,
    required this.children,
    required this.cta,
    this.stickyCta = true,
    this.gap = 16,
  });

  final StepHeader header;
  final List<Widget> children;
  final Widget cta;
  final bool stickyCta;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) spaced.add(SizedBox(height: gap));
      spaced.add(children[i]);
    }
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen), child: header),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, stickyCta ? AppSpace.x4 : AppSpace.x8 + MediaQuery.paddingOf(context).bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...spaced,
                      if (!stickyCta) ...[SizedBox(height: gap), cta],
                    ],
                  ),
                ),
              ),
              if (stickyCta) Padding(padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.x2, AppSpace.screen, AppSpace.x4), child: cta),
            ],
          ),
        ),
      ),
    );
  }
}
