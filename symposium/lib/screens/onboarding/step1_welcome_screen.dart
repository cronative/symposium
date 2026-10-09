import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/onboarding_model.dart';
import '../../widgets/custom_button.dart';

class Step1WelcomeScreen extends StatelessWidget {
  final AuthMode authMode;
  final ValueChanged<AuthMode> onSelectMode;
  final ValueChanged<ContactType> onContinue;

  const Step1WelcomeScreen({
    super.key,
    required this.authMode,
    required this.onSelectMode,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Brand Logo Emblem
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceBorder, width: 1.5),
            ),
            child: const Icon(
              Icons.explore_outlined,
              size: 36,
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'SYMPOSIUM',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Real-World Intent. Verified Neighbors. Curated Experiences.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Auth Mode Toggle (Create Account vs Sign In)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onSelectMode(AuthMode.signup),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: authMode == AuthMode.signup
                            ? AppColors.surfaceElevated
                            : AppColors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Create Account',
                          style: TextStyle(
                            color: authMode == AuthMode.signup
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                            fontWeight: authMode == AuthMode.signup
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onSelectMode(AuthMode.signin),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: authMode == AuthMode.signin
                            ? AppColors.surfaceElevated
                            : AppColors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            color: authMode == AuthMode.signin
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                            fontWeight: authMode == AuthMode.signin
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Value Pillars Highlights
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              children: [
                _buildHighlightItem(
                  icon: Icons.people_alt_outlined,
                  color: AppColors.primaryLight,
                  bgColor: AppColors.primaryGlow,
                  title: 'Know Your Neighbor (KYN)',
                  subtitle:
                      'Connect with nearby verified professionals without exposing exact GPS.',
                ),
                const SizedBox(height: 16),
                _buildHighlightItem(
                  icon: Icons.work_outline,
                  color: AppColors.accent,
                  bgColor: AppColors.accentGlow,
                  title: 'Seek Intent Marketplace',
                  subtitle:
                      'Jobs, gigs, co-founders, and mentorship matched by real-time intent.',
                ),
                const SizedBox(height: 16),
                _buildHighlightItem(
                  icon: Icons.local_activity_outlined,
                  color: AppColors.warning,
                  bgColor: AppColors.warningGlow,
                  title: 'Curated Experiences',
                  subtitle:
                      'Real-world small group dinners, salon talks, and community sessions.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Action Buttons
          CustomButton(
            title: 'Continue with Mobile Number',
            icon: const Icon(Icons.phone_iphone, color: AppColors.white, size: 20),
            onPress: () => onContinue(ContactType.phone),
          ),
          const SizedBox(height: 12),
          CustomButton(
            title: 'Continue with Email',
            variant: ButtonVariant.secondary,
            icon: const Icon(Icons.mail_outline, color: AppColors.textPrimary, size: 20),
            onPress: () => onContinue(ContactType.email),
          ),
          const SizedBox(height: 20),

          // Community Notice
          const Text(
            'By continuing, you agree to Symposium\'s Community Guidelines & Privacy Policy.',
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

  Widget _buildHighlightItem({
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
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
              const SizedBox(height: 2),
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
