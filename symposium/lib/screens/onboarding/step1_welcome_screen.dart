import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_button.dart';

class Step1WelcomeScreen extends StatelessWidget {
  final VoidCallback onGoToSignUp;
  final VoidCallback onGoToSignIn;

  const Step1WelcomeScreen({
    super.key,
    required this.onGoToSignUp,
    required this.onGoToSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Brand Emblem Card
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.primaryBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.explore_rounded,
              size: 38,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),

          // App Title & Tagline
          const Text(
            'SYMPOSIUM',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: 2.2,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Real-World Intent. Verified Neighbors. Curated Experiences.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.45,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Value Pillars Feature Cards (Figma-grade Light Cards)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildPillarItem(
                  icon: Icons.people_alt_outlined,
                  color: AppColors.primary,
                  bgColor: AppColors.primarySoft,
                  title: 'Know Your Neighbor (KYN)',
                  subtitle:
                      'Discover nearby verified professionals without exposing your exact GPS.',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(color: AppColors.surfaceBorder, height: 1),
                ),
                _buildPillarItem(
                  icon: Icons.work_outline_rounded,
                  color: AppColors.accent,
                  bgColor: AppColors.accentSoft,
                  title: 'Seek Marketplace',
                  subtitle:
                      'Gigs, co-founders, hiring, and mentorship matched by active intent.',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(color: AppColors.surfaceBorder, height: 1),
                ),
                _buildPillarItem(
                  icon: Icons.event_available_outlined,
                  color: AppColors.warning,
                  bgColor: AppColors.warningSoft,
                  title: 'Curated Real-World Events',
                  subtitle:
                      'Intimate small group dinners, salon talks, and community sessions.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Primary Actions: Distinct Sign Up vs Sign In
          CustomButton(
            title: 'Create Account',
            onPress: onGoToSignUp,
          ),
          const SizedBox(height: 12),
          CustomButton(
            title: 'Sign In to Existing Account',
            variant: ButtonVariant.secondary,
            onPress: onGoToSignIn,
          ),
          const SizedBox(height: 20),

          // Community & Terms Footer
          const Text(
            'By continuing, you agree to Symposium\'s Community Standards & Privacy Policy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPillarItem({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
