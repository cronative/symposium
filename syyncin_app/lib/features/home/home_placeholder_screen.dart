import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../profile_setup/widgets/pickers.dart';

/// Placeholder until the KYN Home screen is built (next sprint).
class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = SetupDraft.instance;
    final name = d.fullName.isEmpty ? 'there' : d.fullName.split(' ').first;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Center(child: BrandLogo(width: 128, height: 100)),
              const SizedBox(height: 24),
              Text('Welcome, $name!', style: AppText.setupTitle, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Your profile is set up. KYN Home comes next.\n'
                '${d.interests.length} interests · ${d.reasons.length} goals · ${d.city.isEmpty ? 'no city' : d.city}',
                style: AppText.setupSubtitle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
