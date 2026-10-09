import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/onboarding_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class SignInScreen extends StatefulWidget {
  final Function(ContactType type, String phone, String email) onSubmitSignIn;
  final VoidCallback onGoToSignUp;
  final VoidCallback onBack;

  const SignInScreen({
    super.key,
    required this.onSubmitSignIn,
    required this.onGoToSignUp,
    required this.onBack,
  });

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  ContactType _contactType = ContactType.phone;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _errorText;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleSignIn() {
    setState(() => _errorText = null);

    if (_contactType == ContactType.phone) {
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
        widget.onSubmitSignIn(
          _contactType,
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
          // Back button
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
              child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 24),

          // Title & Greeting
          const Text(
            'Welcome back',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign in to access your verified network, scheduled experiences, and messages.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),

          // Login Type Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceBorder),
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
                        borderRadius: BorderRadius.circular(8),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phone_iphone,
                            size: 16,
                            color: _contactType == ContactType.phone
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mobile Number',
                            style: TextStyle(
                              color: _contactType == ContactType.phone
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
                        borderRadius: BorderRadius.circular(8),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mail_outline,
                            size: 16,
                            color: _contactType == ContactType.email
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Email Address',
                            style: TextStyle(
                              color: _contactType == ContactType.email
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

          // Input Field
          if (_contactType == ContactType.phone) ...[
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
                    border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowLight,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Text('🇮🇳', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 6),
                      Text(
                        '+91',
                        style: TextStyle(
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
                    label: 'Registered Mobile Number',
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
              label: 'Registered Email Address',
              hint: 'you@company.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              errorText: _errorText,
              prefix: const Icon(Icons.mail_outline, color: AppColors.textMuted),
              onChanged: (_) => setState(() => _errorText = null),
            ),
          ],
          const SizedBox(height: 32),

          CustomButton(
            title: 'Sign In with OTP',
            loading: _isLoading,
            onPress: _handleSignIn,
          ),
          const SizedBox(height: 24),

          // Switch to Sign Up
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Don\'t have an account yet? ',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                GestureDetector(
                  onTap: widget.onGoToSignUp,
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
