import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/symposium_header.dart';

class Step1WelcomeScreen extends StatelessWidget {
  final VoidCallback onSignUpMobile;
  final VoidCallback onSignUpEmail;
  final VoidCallback onLogIn;

  const Step1WelcomeScreen({
    super.key,
    required this.onSignUpMobile,
    required this.onSignUpEmail,
    required this.onLogIn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Header: Asterisk | symposium | Help
        SymposiumHeader(
          showBack: false,
          actionText: 'Help',
          onAction: () {},
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // Headline (Serif)
                Text(
                  'Find your people.\nFeel at home.',
                  style: AppTheme.serifTitle.copyWith(
                    fontSize: 34,
                    height: 1.15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle
                const Text(
                  'A little about you. A world of good connections, close to home.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),

                // Hero Image Card
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=900&auto=format&fit=crop&q=80',
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 250,
                        color: AppColors.surfaceWarm,
                        child: const Center(
                          child: Icon(Icons.people_outline,
                              size: 48, color: AppColors.primary),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // Caption under photo: Good company starts with hello. | KYN
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Good company starts with hello.',
                      style: AppTheme.serifTitle.copyWith(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Text(
                      'KYN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Button 1: Sign up with mobile 📱
                CustomButton(
                  title: 'Sign up with mobile',
                  variant: ButtonVariant.outline,
                  trailingIcon: const Icon(Icons.phone_iphone_outlined,
                      size: 18, color: AppColors.primary),
                  onPress: onSignUpMobile,
                ),
                const SizedBox(height: 16),

                // Reassurance copy
                const Text(
                  'About 3 minutes. Your profile stays private until you choose to be discovered.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'By signing up, you agree to our Terms of use and Privacy policy.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Button 2: Sign up with email ➔ (Primary)
                CustomButton(
                  title: 'Sign up with email',
                  variant: ButtonVariant.primary,
                  trailingIcon: const Icon(Icons.arrow_forward,
                      size: 18, color: AppColors.white),
                  onPress: onSignUpEmail,
                ),
                const SizedBox(height: 16),

                // Footer: Already have an account? Log in
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: onLogIn,
                        child: const Text(
                          'Log in',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
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
