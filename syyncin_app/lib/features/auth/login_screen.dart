import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/widgets.dart';
import '../../data/api.dart';
import 'otp_screen.dart';

/// 05 — Log in or create account.
/// Continue is enabled once a phone/email is entered. Tapping it accepts the
/// Terms of Service and Privacy Policy (legal line shown right above the button).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _contact = TextEditingController();
  bool _sending = false;

  bool get _canContinue => _contact.text.trim().length >= 5;

  @override
  void dispose() {
    _contact.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    try {
      final (otp, _) = await AuthApi.requestOtp(_contact.text.trim());
      if (!mounted) return;
      Navigator.of(context).pushNamed(
        Routes.otp,
        arguments: OtpArgs(requestId: otp.requestId, destination: otp.maskedDestination, devCode: otp.devCode, resendAfter: otp.resendAfter),
      );
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _social() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Social sign-in is coming soon. Please continue with your phone or email.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle = AppText.legal.copyWith(fontWeight: FontWeight.w600, color: AppColors.blue);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: FillScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen, vertical: AppSpace.x6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: BrandLogo()),
                const SizedBox(height: 16),
                const Text("Let's get you connected.", style: AppText.authTitle, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                const Text(
                  'Enter your phone number or email address to create your account or sign in.',
                  style: AppText.authBody,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: AuthTextField(
                    label: 'Phone number or email address',
                    hint: 'Enter phone number or email',
                    helper: "We'll send you a one-time code to verify your account.",
                    controller: _contact,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Text.rich(
                  TextSpan(style: AppText.legal, children: [
                    const TextSpan(text: 'By continuing, you agree to our '),
                    TextSpan(text: 'Terms of Service', style: linkStyle),
                    const TextSpan(text: ' and '),
                    TextSpan(text: 'Privacy Policy', style: linkStyle),
                    const TextSpan(text: '.'),
                  ]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Continue',
                  variant: ButtonVariant.auth,
                  enabled: _canContinue,
                  loading: _sending,
                  onPressed: _continue,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Container(height: 2, decoration: BoxDecoration(color: AppColors.dotInactive, borderRadius: BorderRadius.circular(5)))),
                    const SizedBox(width: 16),
                    const Text('or continue with', style: AppText.authBody),
                    const SizedBox(width: 16),
                    Expanded(child: Container(height: 2, decoration: BoxDecoration(color: AppColors.dotInactive, borderRadius: BorderRadius.circular(5)))),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SocialButton(svg: AppIcons.google, semanticLabel: 'Continue with Google', onTap: _social),
                    const SizedBox(width: 16),
                    SocialButton(svg: AppIcons.linkedin, semanticLabel: 'Continue with LinkedIn', onTap: _social),
                    const SizedBox(width: 16),
                    SocialButton(svg: AppIcons.apple, semanticLabel: 'Continue with Apple', onTap: _social),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "+919812345210" → "+91 98•••••210", "nikunj@gmail.com" → "ni•••@gmail.com".
String maskDestination(String raw) {
  if (raw.contains('@')) {
    final parts = raw.split('@');
    final name = parts.first;
    final keep = name.length <= 2 ? name : name.substring(0, 2);
    return '$keep•••@${parts.last}';
  }
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length < 6) return raw;
  final local = digits.length > 10 ? digits.substring(digits.length - 10) : digits;
  final cc = digits.length > 10 ? '+${digits.substring(0, digits.length - 10)} ' : '+91 ';
  return '$cc${local.substring(0, 2)}•••••${local.substring(local.length - 3)}';
}
