import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/onboarding_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/segmented_progress_bar.dart';
import '../../widgets/symposium_header.dart';

class Step8CompleteSummaryScreen extends StatelessWidget {
  final OnboardingModel model;
  final VoidCallback onEnterKyn;
  final VoidCallback onRestart;

  const Step8CompleteSummaryScreen({
    super.key,
    required this.model,
    required this.onEnterKyn,
    required this.onRestart,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return 'NM';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = model.fullName.isNotEmpty
        ? model.fullName.split(' ').first
        : 'there';

    return Column(
      children: [
        SymposiumHeader(
          showBack: false,
          actionText: 'Help',
          onAction: () {},
        ),
        const SegmentedProgressBar(
          sectionName: 'Welcome to Symposium',
          currentStep: 7,
          totalSteps: 8,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // Headline
                Text(
                  'You\'re ready,\n$firstName.',
                  style: AppTheme.serifTitle.copyWith(
                    fontSize: 34,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  'Your verified profile is setup and ready to discover your neighborhood.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Profile Summary Card (Figma-grade Light Card)
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowLight,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: AppColors.avatarBackground,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(model.fullName),
                                style: AppTheme.serifTitle.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      model.fullName.isNotEmpty
                                          ? model.fullName
                                          : 'Nikunj Maheshwari',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.verified,
                                        color: AppColors.primary, size: 18),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  model.role.isNotEmpty
                                      ? '${model.role} • ${model.company}'
                                      : 'Product designer • Independent',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        color: AppColors.primary, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${model.city} • ${model.age} yrs',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: AppColors.surfaceBorder, height: 1),
                      ),

                      // Intents
                      const Text(
                        'CURRENT INTENT',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: model.currentIntents.map((item) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceWarm,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.flash_on,
                                    color: AppColors.primary, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  item,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Interests
                      const Text(
                        'CORE INTERESTS',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: model.interests.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Discovery Status Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.radar,
                                color: AppColors.primary, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                model.enableKynDiscovery
                                    ? 'KYN Discovery active within ${model.discoveryRadiusKm} km'
                                    : 'Private Mode (Hidden from discovery)',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Enter KYN Button
                CustomButton(
                  title: 'Enter KYN (Know Your Neighbor)',
                  trailingIcon: const Icon(Icons.arrow_forward,
                      size: 18, color: AppColors.white),
                  onPress: onEnterKyn,
                ),
                const SizedBox(height: 10),

                // Re-test flow
                Center(
                  child: TextButton(
                    onPressed: onRestart,
                    child: const Text(
                      'Re-test Onboarding Flow',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
