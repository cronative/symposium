import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import 'widgets/final_step_header.dart';
import 'widgets/pickers.dart';

/// Final step — You're verified.
class VerifiedScreen extends StatelessWidget {
  const VerifiedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpace.screenH,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FinalStepHeader(),
                    const SizedBox(height: 50),
                    const _SuccessBadge(),
                    const SizedBox(height: 26),
                    Text(
                      SetupDraft.instance.verificationStatus == 'verified' ? "You're verified." : 'Selfie submitted.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 27, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    const SizedBox(height: 13),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 11),
                      child: Text(
                        SetupDraft.instance.verificationStatus == 'verified'
                            ? "Your identity check is complete. You're one step closer to building trusted connections on SyyncIn."
                            : "We're reviewing your selfie — this usually doesn't take long. You can start exploring SyyncIn meanwhile.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 14, height: 17 / 14, color: AppColors.sub),
                      ),
                    ),
                    const SizedBox(height: 50),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.panelFill,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: AppColors.panelStroke),
                      ),
                      child: const Column(
                        children: [
                          _Benefit(AppIcons.shieldCheck, 'Identity confirmed'),
                          _BenefitDivider(),
                          _Benefit(AppIcons.userCheck, 'Profile ready'),
                          _BenefitDivider(),
                          _Benefit(AppIcons.users, 'Community guidelines apply'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.x2, AppSpace.screen, AppSpace.x6),
              child: PrimaryButton(
                label: 'Explore SyyncIn',
                height: 52,
                showArrow: true,
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(Routes.home, (r) => false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  @override
  Widget build(BuildContext context) {
    const confetti = [
      (-129.0, 29.0, AppColors.tealBright),
      (109.0, 38.0, AppColors.blue),
      (-115.0, 139.0, AppColors.tealBright),
      (118.0, 154.0, AppColors.blue),
      (-90.0, -13.0, AppColors.tealBright),
      (94.0, -16.0, AppColors.blue),
    ];
    return SizedBox(
      height: 153,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(width: 153, height: 153, decoration: const BoxDecoration(color: AppColors.haloOuter, shape: BoxShape.circle)),
          Positioned(top: 14, child: Container(width: 125, height: 125, decoration: const BoxDecoration(color: AppColors.haloInner, shape: BoxShape.circle))),
          Positioned(
            top: 26,
            child: Container(
              width: 101,
              height: 101,
              decoration: const BoxDecoration(color: AppColors.portraitFill, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const AppIcon(AppIcons.user, size: 46, color: AppColors.portraitIcon),
            ),
          ),
          Positioned(
            top: 105,
            left: 0,
            right: 0,
            child: Align(
              alignment: const Alignment(0.4, 0),
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 3),
                ),
                alignment: Alignment.center,
                child: const AppIcon(AppIcons.check, size: 22, color: AppColors.white),
              ),
            ),
          ),
          for (final c in confetti)
            Positioned(
              top: c.$2,
              left: 0,
              right: 0,
              child: Transform.translate(
                offset: Offset(c.$1, 0),
                child: Center(
                  child: Container(
                    width: 10,
                    height: 16,
                    decoration: BoxDecoration(color: c.$3, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.icon, this.text);
  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Row(
        children: [
          AppIcon(icon, size: 22, color: AppColors.blue),
          const SizedBox(width: 18),
          Expanded(child: Text(text, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.inkSoft))),
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(color: AppColors.successSoft, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const AppIcon(AppIcons.check, size: 13, color: AppColors.white),
          ),
        ],
      ),
    );
  }
}

class _BenefitDivider extends StatelessWidget {
  const _BenefitDivider();
  @override
  Widget build(BuildContext context) => Container(height: 1, color: AppColors.panelStroke);
}
