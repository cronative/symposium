import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import 'widgets/nearby_visual.dart';
import 'widgets/onboarding_layout.dart';

/// 01b — Welcome · "Your next connection could be closer than you think."
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: OnboardingLayout(
        visual: const NearbyVisual(),
        title: 'Your next connection could be closer than you think.',
        body: 'Meet people nearby, discover shared interests and find opportunities to grow — all in one place.',
        actions: Column(
          children: [
            PrimaryButton(
              label: 'Get started',
              variant: ButtonVariant.auth,
              onPressed: () => Navigator.of(context).pushNamed(Routes.onboarding),
            ),
            const SizedBox(height: 16),
            TextLink(
              height: 20,
              onTap: () => Navigator.of(context).pushNamed(Routes.login),
              child: Text.rich(
                TextSpan(
                  text: 'Already have an account? ',
                  style: AppText.authBody,
                  children: [
                    TextSpan(text: 'Log in', style: AppText.authBody.copyWith(fontWeight: FontWeight.w700, color: AppColors.blue)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
