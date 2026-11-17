import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import 'widgets/onboarding_layout.dart';

class _Slide {
  const _Slide(this.image, this.title, this.body);
  final String image;
  final String title;
  final String body;
}

const _slides = [
  _Slide(
    'assets/images/onboarding_meet.png',
    'Good connections start close to home.',
    'Discover professionals and neighbours around you, find common ground, and turn everyday encounters into meaningful connections.',
  ),
  _Slide(
    'assets/images/onboarding_connect.png',
    'Go beyond the introduction.',
    'Explore shared interests, start conversations and build relationships that extend beyond a profile.',
  ),
  _Slide(
    'assets/images/onboarding_grow.png',
    'Turn connections into possibilities.',
    'Discover events, explore career opportunities and meet people who can help you take your next step.',
  ),
];

/// 02–04 — Onboarding · MEET / CONNECT / GROW (swipeable).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pager = PageController();
  int _index = 0;

  void _next() {
    if (_index == _slides.length - 1) {
      _toLogin();
    } else {
      _pager.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _toLogin() => Navigator.of(context).pushNamed(Routes.login);

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: PageView.builder(
        controller: _pager,
        itemCount: _slides.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) {
          final s = _slides[i];
          final last = i == _slides.length - 1;
          return OnboardingLayout(
            visual: AssetBox(
              s.image,
              width: 323,
              height: 270,
              radius: 5,
              border: Border.all(color: AppColors.cardStroke),
            ),
            eyebrow: 'STEP ${i + 1} OF ${_slides.length}',
            title: s.title,
            body: s.body,
            actions: Column(
              children: [
                PageDots(count: _slides.length, index: _index),
                const SizedBox(height: 16),
                PrimaryButton(label: last ? 'Get started' : 'Next', variant: ButtonVariant.auth, onPressed: _next),
                const SizedBox(height: 16),
                TextLink(onTap: _toLogin, child: const Text('Skip', style: AppText.authBody)),
              ],
            ),
          );
        },
      ),
    );
  }
}
