import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';

/// Header for Selfie + Verified: tinted square back · "FINAL STEP" badge ·
/// five full 7 px segments (gap 3, radius 4).
class FinalStepHeader extends StatelessWidget {
  const FinalStepHeader({super.key, this.showBack = true});
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 2),
        SizedBox(
          height: 43,
          child: Row(
            children: [
              if (showBack)
                const SquareBackButton(size: 43, fill: AppColors.backFill, iconColor: AppColors.blue)
              else
                const SizedBox(width: 43),
              const Spacer(),
              Container(
                width: 109,
                height: 33,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.badgeFill, borderRadius: BorderRadius.circular(5)),
                child: const Text('FINAL STEP', style: AppText.badge),
              ),
            ],
          ),
        ),
        const SizedBox(height: 17),
        Row(
          children: [
            for (var i = 0; i < 5; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(
                child: Container(
                  height: 7,
                  decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
