import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/onboarding_model.dart';
import '../../widgets/custom_button.dart';

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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          // Celebration Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.accentGlow,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accentBorder, width: 2),
            ),
            child: const Icon(Icons.check_circle,
                color: AppColors.accent, size: 44),
          ),
          const SizedBox(height: 16),

          const Text(
            'You\'re All Set!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Your Symposium profile is live and your local neighborhood network is ready to explore.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Profile Summary Card Preview
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceBorder, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                        image: DecorationImage(
                          image: NetworkImage(model.avatarUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                model.fullName.isNotEmpty
                                    ? model.fullName
                                    : 'Member',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.verified,
                                  color: AppColors.accent, size: 18),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            model.role.isNotEmpty
                                ? '${model.role} at ${model.company}'
                                : 'Community Member',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: AppColors.primaryLight, size: 14),
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

                if (model.bio.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    '"${model.bio}"',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                const Divider(color: AppColors.surfaceBorder, height: 28),

                // Intents
                const Text(
                  'CURRENT INTENT',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
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
                        color: AppColors.warningGlow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flash_on,
                              color: AppColors.warning, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            item,
                            style: const TextStyle(
                              color: AppColors.warning,
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
                    letterSpacing: 1.0,
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
                const SizedBox(height: 18),

                // Discovery Status
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        model.enableKynDiscovery
                            ? Icons.radar
                            : Icons.visibility_off,
                        color: model.enableKynDiscovery
                            ? AppColors.accent
                            : AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          model.enableKynDiscovery
                              ? 'KYN Discovery: Active within ${model.discoveryRadiusKm} km'
                              : 'KYN Discovery: Private Mode (Hidden)',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Action Buttons
          CustomButton(
            title: 'Enter KYN (Know Your Neighbor)',
            icon: const Icon(Icons.explore, color: AppColors.white, size: 20),
            onPress: onEnterKyn,
          ),
          const SizedBox(height: 8),
          CustomButton(
            title: 'Re-test Onboarding Flow',
            variant: ButtonVariant.ghost,
            onPress: onRestart,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
