import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class Step5ProfessionalProfileScreen extends StatefulWidget {
  final String initialCompany;
  final String initialRole;
  final String initialIndustry;
  final String initialLinkedInUrl;
  final Function(
    String company,
    String role,
    String industry,
    String linkedInUrl,
  ) onSubmit;
  final VoidCallback onSkip;
  final VoidCallback onBack;

  const Step5ProfessionalProfileScreen({
    super.key,
    required this.initialCompany,
    required this.initialRole,
    required this.initialIndustry,
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
  late String _selectedIndustry;

  final List<String> _industries = [
    'Technology & AI',
    'Design & Creative',
    'Venture & Startups',
    'Product Management',
    'Finance & FinTech',
    'Media & Content',
  ];

  String? _linkedInError;

  @override
  void initState() {
    super.initState();
    _companyController = TextEditingController(text: widget.initialCompany);
    _roleController = TextEditingController(text: widget.initialRole);
    _linkedInController =
        TextEditingController(text: widget.initialLinkedInUrl);
    _selectedIndustry = widget.initialIndustry.isNotEmpty
        ? widget.initialIndustry
        : _industries.first;
  }

  @override
  void dispose() {
    _companyController.dispose();
    _roleController.dispose();
    _linkedInController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    setState(() => _linkedInError = null);

    final url = _linkedInController.text.trim();
    if (url.isNotEmpty && !url.toLowerCase().contains('linkedin.com')) {
      setState(() => _linkedInError =
          'Please enter a valid LinkedIn URL (e.g. linkedin.com/in/username).');
      return;
    }

    widget.onSubmit(
      _companyController.text.trim(),
      _roleController.text.trim(),
      _selectedIndustry,
      _linkedInController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar with back and skip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowLight,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: AppColors.textPrimary),
                ),
              ),
              GestureDetector(
                onTap: widget.onSkip,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(
                    'Skip for now',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text(
            'Professional Background',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Helps verify your credibility and matches you with relevant opportunities on Seek & KYN.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),

          // Inputs
          CustomTextField(
            label: 'Current Company / Organization',
            hint: 'e.g. Google, Stripe, or Stealth Startup',
            controller: _companyController,
            prefix: const Icon(Icons.business_outlined,
                color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),

          CustomTextField(
            label: 'Job Role / Title',
            hint: 'e.g. Lead Engineer, Product Designer, Founder',
            controller: _roleController,
            prefix: const Icon(Icons.work_outline, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),

          const Text(
            'Industry / Domain',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 10),

          // Industry selection chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _industries.map((item) {
              final isSelected = _selectedIndustry == item;
              return GestureDetector(
                onTap: () => setState(() => _selectedIndustry = item),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primarySoft
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceBorder,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // LinkedIn Input
          CustomTextField(
            label: 'LinkedIn Profile URL (Recommended)',
            hint: 'https://linkedin.com/in/username',
            controller: _linkedInController,
            errorText: _linkedInError,
            keyboardType: TextInputType.url,
            prefix: const Icon(Icons.link, color: AppColors.linkedIn),
            onChanged: (_) => setState(() => _linkedInError = null),
          ),
          const SizedBox(height: 16),

          // Verified Badge Note Card (Clean Light Styling)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.verified, color: AppColors.accent, size: 24),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verified Member Status',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Profiles with verified professional links get a Verified badge and 3x more connection responses.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          CustomButton(
            title: 'Continue',
            onPress: _handleContinue,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
