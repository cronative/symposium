import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/onboarding_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/symposium_header.dart';

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
  ContactType _contactType = ContactType.email;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController =
      TextEditingController(text: 'nikunj.maheshwari@example.com');
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

    Future.delayed(const Duration(milliseconds: 500), () {
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
    return Column(
      children: [
        SymposiumHeader(
          onBack: widget.onBack,
          actionText: 'Help',
          onAction: () {},
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // Title
                Text(
                  'Welcome back.',
                  style: AppTheme.serifTitle.copyWith(
                    fontSize: 32,
                    height: 1.2,
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
                const SizedBox(height: 24),

                // Toggle Pills
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
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (_contactType == ContactType.email) ...[
                  CustomTextField(
                    label: 'Registered email address',
                    requirementText: 'Required',
                    hint: 'nikunj.maheshwari@example.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    suffix: const Icon(Icons.mail_outline_rounded,
                        color: AppColors.primary, size: 20),
                    errorText: _errorText,
                    onChanged: (_) => setState(() => _errorText = null),
                  ),
                ] else ...[
                  CustomTextField(
                    label: 'Registered mobile number',
                    requirementText: 'Required',
                    hint: '+91 98765 43210',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    suffix: const Icon(Icons.phone_iphone_outlined,
                        color: AppColors.primary, size: 20),
                    errorText: _errorText,
                    onChanged: (_) => setState(() => _errorText = null),
                  ),
                ],
                const SizedBox(height: 32),

                CustomButton(
                  title: 'Sign In with OTP',
                  trailingIcon: const Icon(Icons.arrow_forward,
                      size: 18, color: AppColors.white),
                  loading: _isLoading,
                  onPress: _handleSignIn,
                ),
                const SizedBox(height: 20),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Don\'t have an account yet? ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onGoToSignUp,
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
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
