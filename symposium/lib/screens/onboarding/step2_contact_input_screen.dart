import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/onboarding_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class Step2ContactInputScreen extends StatefulWidget {
  final AuthMode authMode;
  final ContactType contactType;
  final ValueChanged<ContactType> onChangeContactType;
  final Function(String countryCode, String phone, String email) onSubmitContact;
  final VoidCallback onBack;

  const Step2ContactInputScreen({
    super.key,
    required this.authMode,
    required this.contactType,
    required this.onChangeContactType,
    required this.onSubmitContact,
    required this.onBack,
  });

  @override
  State<Step2ContactInputScreen> createState() => _Step2ContactInputScreenState();
}

class _Step2ContactInputScreenState extends State<Step2ContactInputScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final String _countryCode = '+91';
  String? _errorText;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleSendCode() {
    setState(() => _errorText = null);

    if (widget.contactType == ContactType.phone) {
      final text = _phoneController.text.trim();
      if (text.length < 10) {
        setState(() => _errorText = 'Please enter a valid 10-digit mobile number.');
        return;
      }
    } else {
      final email = _emailController.text.trim();
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!emailRegex.hasMatch(email)) {
        setState(() => _errorText = 'Please enter a valid email address.');
        return;
      }
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isLoading = false);
        widget.onSubmitContact(
          _countryCode,
          _phoneController.text.trim(),
          _emailController.text.trim(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Text(
            widget.authMode == AuthMode.signup
                ? 'Verify your identity'
                : 'Welcome back',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We will send a one-time verification code (OTP) to authenticate your account.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Method Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _errorText = null);
                      widget.onChangeContactType(ContactType.phone);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: widget.contactType == ContactType.phone
                            ? AppColors.surfaceElevated
                            : AppColors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phone_iphone,
                            size: 16,
                            color: widget.contactType == ContactType.phone
                                ? AppColors.white
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mobile Number',
                            style: TextStyle(
                              color: widget.contactType == ContactType.phone
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _errorText = null);
                      widget.onChangeContactType(ContactType.email);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: widget.contactType == ContactType.email
                            ? AppColors.surfaceElevated
                            : AppColors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mail_outline,
                            size: 16,
                            color: widget.contactType == ContactType.email
                                ? AppColors.white
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Email Address',
                            style: TextStyle(
                              color: widget.contactType == ContactType.email
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Inputs
          if (widget.contactType == ContactType.phone) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 52,
                  margin: const EdgeInsets.only(top: 25),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.surfaceBorder, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Text('🇮🇳', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        _countryCode,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomTextField(
                    label: 'Mobile Number',
                    hint: '98765 43210',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    errorText: _errorText,
                    onChanged: (_) => setState(() => _errorText = null),
                  ),
                ),
              ],
            ),
          ] else ...[
            CustomTextField(
              label: 'Email Address',
              hint: 'you@company.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              errorText: _errorText,
              prefix: const Icon(Icons.mail_outline, color: AppColors.textMuted),
              onChanged: (_) => setState(() => _errorText = null),
            ),
          ],
          const SizedBox(height: 16),

          // Privacy Assurance Note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accentGlowSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentBorder),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppColors.accent, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your contact details are strictly encrypted and never revealed publicly without explicit consent.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          CustomButton(
            title: 'Get Verification Code',
            loading: _isLoading,
            onPress: _handleSendCode,
          ),
        ],
      ),
    );
  }
}
