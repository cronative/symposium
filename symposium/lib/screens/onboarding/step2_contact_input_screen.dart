import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/onboarding_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/info_card.dart';
import '../../widgets/segmented_progress_bar.dart';
import '../../widgets/symposium_header.dart';

class Step2ContactInputScreen extends StatefulWidget {
  final ContactType initialContactType;
  final Function(ContactType type, String phone, String email) onSubmitContact;
  final VoidCallback onBack;

  const Step2ContactInputScreen({
    super.key,
    this.initialContactType = ContactType.email,
    required this.onSubmitContact,
    required this.onBack,
  });

  @override
  State<Step2ContactInputScreen> createState() =>
      _Step2ContactInputScreenState();
}

class _Step2ContactInputScreenState extends State<Step2ContactInputScreen> {
  late ContactType _contactType;
  final TextEditingController _emailController =
      TextEditingController(text: 'nisha.mehta@example.com');
  final TextEditingController _phoneController = TextEditingController();
  String? _errorText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _contactType = widget.initialContactType;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSendCode() {
    setState(() => _errorText = null);

    if (_contactType == ContactType.email) {
      final email = _emailController.text.trim();
      final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!regex.hasMatch(email)) {
        setState(() => _errorText = 'Please enter a valid email address.');
        return;
      }
    } else {
      final phone = _phoneController.text.trim();
      if (phone.length < 10) {
        setState(() => _errorText = 'Please enter a valid mobile number.');
        return;
      }
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoading = false);
        widget.onSubmitContact(
          _contactType,
          _phoneController.text.trim(),
          _emailController.text.trim(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SymposiumHeader(
          onBack: widget.onBack,
          actionText: 'Help',
          onAction: () {},
        ),
        const SegmentedProgressBar(
          sectionName: 'Your Account',
          currentStep: 1,
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
                  'Start with a hello.',
                  style: AppTheme.serifTitle.copyWith(
                    fontSize: 32,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  'Choose how you\'d like to sign in. We\'ll send a code to make sure it\'s really you.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),

                // Segmented Toggle Pills (Mobile vs Email)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _errorText = null;
                              _contactType = ContactType.phone;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _contactType == ContactType.phone
                                  ? AppColors.surface
                                  : AppColors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _contactType == ContactType.phone
                                  ? [
                                      BoxShadow(
                                        color: AppColors.shadowLight,
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Mobile',
                                style: TextStyle(
                                  color: _contactType == ContactType.phone
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _errorText = null;
                              _contactType = ContactType.email;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _contactType == ContactType.email
                                  ? AppColors.surface
                                  : AppColors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _contactType == ContactType.email
                                  ? [
                                      BoxShadow(
                                        color: AppColors.shadowLight,
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Email',
                                style: TextStyle(
                                  color: _contactType == ContactType.email
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
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

                // Field
                if (_contactType == ContactType.email) ...[
                  CustomTextField(
                    label: 'Email address',
                    requirementText: 'Required',
                    hint: 'nisha.mehta@example.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    suffix: const Icon(Icons.mail_outline_rounded,
                        color: AppColors.primary, size: 20),
                    errorText: _errorText,
                    onChanged: (_) => setState(() => _errorText = null),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use an address you can access now.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Using mobile instead? Include your country code, for example +91, before your number.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ] else ...[
                  CustomTextField(
                    label: 'Mobile number',
                    requirementText: 'Required',
                    hint: '+91 98765 43210',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    suffix: const Icon(Icons.phone_iphone_outlined,
                        color: AppColors.primary, size: 20),
                    errorText: _errorText,
                    onChanged: (_) => setState(() => _errorText = null),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Include your country code, for example +91.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Info Card (Pale sage box)
                const InfoCard(
                  icon: Icons.lock_outline_rounded,
                  title: 'Only for your account',
                  description:
                      'Your email or mobile number is never shown to other members. We\'ll use it for verification and account recovery.',
                  backgroundColor: AppColors.primarySoft,
                  iconColor: AppColors.primary,
                ),
                const SizedBox(height: 22),

                // "Not receiving messages?" note
                const Text(
                  'Not receiving messages?',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Check your email spelling or mobile format before sending. You can change it on the next step.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                // Submit CTA
                CustomButton(
                  title: 'Send verification code',
                  trailingIcon: const Icon(Icons.arrow_forward,
                      size: 18, color: AppColors.white),
                  loading: _isLoading,
                  onPress: _handleSendCode,
                ),
                const SizedBox(height: 12),

                const Center(
                  child: Text(
                    'No password to remember.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
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
