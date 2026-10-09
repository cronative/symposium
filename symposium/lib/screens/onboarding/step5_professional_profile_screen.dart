import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/info_card.dart';
import '../../widgets/segmented_progress_bar.dart';
import '../../widgets/symposium_header.dart';

class Step5ProfessionalProfileScreen extends StatefulWidget {
  final String initialCompany;
  final String initialRole;
  final String initialLinkedInUrl;
  final Function(String company, String role, String linkedInUrl) onSubmit;
  final VoidCallback onSkip;
  final VoidCallback onBack;

  const Step5ProfessionalProfileScreen({
    super.key,
    required this.initialCompany,
    required this.initialRole,
    required this.initialLinkedInUrl,
    required this.onSubmit,
    required this.onSkip,
    required this.onBack,
  });

  @override
  State<Step5ProfessionalProfileScreen> createState() =>
      _Step5ProfessionalProfileScreenState();
}

class _Step5ProfessionalProfileScreenState
    extends State<Step5ProfessionalProfileScreen> {
  late TextEditingController _companyController;
  late TextEditingController _roleController;
  late TextEditingController _linkedInController;

  @override
  void initState() {
    super.initState();
    _companyController = TextEditingController(
      text: widget.initialCompany.isNotEmpty
          ? widget.initialCompany
          : 'Independent',
    );
    _roleController = TextEditingController(
      text: widget.initialRole.isNotEmpty
          ? widget.initialRole
          : 'Product designer',
    );
    _linkedInController = TextEditingController(
      text: widget.initialLinkedInUrl.isNotEmpty
          ? widget.initialLinkedInUrl
          : 'https://linkedin.com/in/...',
    );
  }

  @override
  void dispose() {
    _companyController.dispose();
    _roleController.dispose();
    _linkedInController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    widget.onSubmit(
      _companyController.text.trim(),
      _roleController.text.trim(),
      _linkedInController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SymposiumHeader(
          onBack: widget.onBack,
          actionText: 'Skip',
          onAction: widget.onSkip,
        ),
        const SegmentedProgressBar(
          sectionName: 'A Little About You',
          currentStep: 4,
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
                  'What keeps\nyou curious?',
                  style: AppTheme.serifTitle.copyWith(
                    fontSize: 32,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  'A little work context can spark a great conversation. This whole step is optional.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),

                // Badge: OPTIONAL · NOT A JOB APPLICATION
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'OPTIONAL · NOT A JOB APPLICATION',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Field 1: Company or organisation
                CustomTextField(
                  label: 'Company or organisation',
                  requirementText: 'Optional',
                  hint: 'e.g. Independent, Studio, or Tech Inc',
                  controller: _companyController,
                ),
                const SizedBox(height: 16),

                // Field 2: Role
                CustomTextField(
                  label: 'Role',
                  requirementText: 'Optional',
                  hint: 'e.g. Product designer',
                  controller: _roleController,
                ),
                const SizedBox(height: 16),

                // Field 3: LinkedIn profile
                CustomTextField(
                  label: 'LinkedIn profile',
                  requirementText: 'Optional',
                  hint: 'https://linkedin.com/in/...',
                  controller: _linkedInController,
                  keyboardType: TextInputType.url,
                  suffix: const Icon(Icons.link_rounded,
                      color: AppColors.primary, size: 20),
                  helperText: 'Add a full profile URL, or leave this blank.',
                ),
                const SizedBox(height: 20),

                // Info Card: You're more than your work
                const InfoCard(
                  icon: Icons.business_center_outlined,
                  title: 'You\'re more than your work',
                  description:
                      'Studying, taking a break or exploring something new? You\'re welcome here. No LinkedIn account is needed.',
                  backgroundColor: AppColors.surfaceWarm,
                  iconColor: AppColors.primary,
                ),
                const SizedBox(height: 32),

                // Save & Continue CTA
                CustomButton(
                  title: 'Save & continue',
                  trailingIcon: const Icon(Icons.arrow_forward,
                      size: 18, color: AppColors.white),
                  onPress: _handleContinue,
                ),
                const SizedBox(height: 14),

                // Skip link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Prefer to leave this for later? ',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onSkip,
                        child: const Text(
                          'Skip this step',
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
