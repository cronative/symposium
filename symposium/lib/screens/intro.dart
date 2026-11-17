import 'package:flutter/material.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class KynIntroScreen extends StatefulWidget {
  const KynIntroScreen({super.key});
  @override
  State<KynIntroScreen> createState() => _KynIntroScreenState();
}
class _KynIntroScreenState extends State<KynIntroScreen> {
  final page = PageController();
  int current = 0;
  static const slides = [
    ('Meet your neighbours.', 'Discover people who live around you — and turn familiar streets into meaningful connections.', 'assets/images/symposium_kyn_1.jpg'),
    ('Find your kind of people.', 'Connect with neighbours who share your interests, profession and favourite activities.', 'assets/images/symposium_kyn_2.jpg'),
    ('From nearby to real friendships.', "Say hello, start a conversation and meet for coffee when you're both ready.", 'assets/images/symposium_kyn_3.jpg'),
  ];
  @override
  void dispose() { page.dispose(); super.dispose(); }
  void next() { if (current == 2) { Navigator.pushNamed(context, Routes.basic); } else { page.nextPage(duration: const Duration(milliseconds: 270), curve: Curves.easeInOut); } }
  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpace.page), child: Column(children: [
    const SizedBox(height: 14),
    Row(children: [const Text('SYMPOSIUM  /  KYN', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, letterSpacing: 1, fontSize: 12)), const Spacer(), TextAction(label: 'Skip', onPressed: () => Navigator.pushNamed(context, Routes.basic))]),
    const SizedBox(height: 24),
    Expanded(child: PageView.builder(controller: page, itemCount: slides.length, onPageChanged: (index) => setState(() => current = index), itemBuilder: (context, index) {
      final slide = slides[index];
      return Column(children: [
        Expanded(flex: 6, child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.asset(slide.$3, fit: BoxFit.cover, width: double.infinity, height: double.infinity))),
        const SizedBox(height: 37),
        Text(slide.$1, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 16),
        Text(slide.$2, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(flex: 2),
      ]);
    })),
    Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => Container(width: i == current ? 24 : 7, height: 7, margin: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(color: i == current ? AppColors.primary : AppColors.border, borderRadius: BorderRadius.circular(9))))),
    const SizedBox(height: 24),
    PrimaryButton(label: current == 2 ? 'Get Started' : 'Continue', onPressed: next),
    const SizedBox(height: 16),
  ]))));
}
