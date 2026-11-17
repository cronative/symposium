import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';

/// Shared frame for Welcome + the three onboarding slides.
/// Figma: content padding 24/24/48/24, space-between [top group · copy · actions],
/// soft brand ellipses peeking behind the status bar.
class OnboardingLayout extends StatelessWidget {
  const OnboardingLayout({
    super.key,
    required this.visual,
    required this.title,
    required this.body,
    required this.actions,
    this.eyebrow,
  });

  final Widget visual;
  final String? eyebrow;
  final String title;
  final String body;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned(left: -125, top: -158, child: _Ellipse(221, 250, AppColors.accentBlue)),
        const Positioned(left: 323, top: 99, child: _Ellipse(167, 224, AppColors.accentTeal)),
        SafeArea(
          bottom: false,
          child: Container(
            color: AppColors.white,
            child: FillScrollView(
              padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.x6, AppSpace.screen, AppSpace.x8 + AppSpace.x4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const BrandLogo(width: 128, height: 100),
                      const SizedBox(height: 16),
                      visual,
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        if (eyebrow != null) ...[
                          Text(eyebrow!, style: AppText.onboardingEyebrow, textAlign: TextAlign.center),
                          const SizedBox(height: 10),
                        ],
                        Text(title, style: AppText.authTitle, textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        Text(body, style: AppText.authBody, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  actions,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Ellipse extends StatelessWidget {
  const _Ellipse(this.w, this.h, this.color);
  final double w;
  final double h;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: w, height: h, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.all(Radius.elliptical(w / 2, h / 2))));
}

/// Pagination dots: active 25×9 blue, inactive 9×9 #D0D4D8, 8 px gap.
class PageDots extends StatelessWidget {
  const PageDots({super.key, required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: i == index ? 25 : 9,
            height: 9,
            decoration: BoxDecoration(
              color: i == index ? AppColors.blue : AppColors.dotInactive,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ],
    );
  }
}

/// Tappable centred text link (Skip / Log in).
class TextLink extends StatelessWidget {
  const TextLink({super.key, required this.child, required this.onTap, this.height = 32});
  final Widget child;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(height: height, child: Center(child: child)),
      );
}
