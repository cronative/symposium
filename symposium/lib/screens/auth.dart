import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../core/routes.dart';
import '../core/onboarding_data.dart';
import '../widgets/common.dart';

// ==========================================
// 01 — Welcome Screen (SyyncIn Design)
// ==========================================
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Stack(
            children: [
              // Subtle ambient pastel blobs
              Positioned(
                top: -30,
                left: -30,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFEAF5FE),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: -60,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFECFBF8),
                  ),
                ),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 18),

                      // SyyncIn Logo + Wordmark + Tagline
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Image.asset(
                          'assets/images/syyncin_logo.png',
                          height: 125,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox(height: 125);
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Value proposition headline
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              height: 1.16,
                              letterSpacing: -0.4,
                            ),
                            children: [
                              TextSpan(
                                text: 'Your People.\n',
                                style: TextStyle(color: Color(0xFF0D1E3A)),
                              ),
                              TextSpan(
                                text: 'Your Opportunities.',
                                style: TextStyle(color: Color(0xFF00BFA5)),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Subtitle
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 28),
                        child: Text(
                          'Discover like-minded people, attend events,\nfind opportunities and grow together.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF5B6E82),
                            height: 1.45,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Hero collage image - full bleed edge-to-edge
                      AspectRatio(
                        aspectRatio: 576 / 344,
                        child: Image.asset(
                          'assets/images/syyncin_hero.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox(height: 240);
                          },
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Pagination indicator dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 18,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0066FF),
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFFCBD5E1),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFFCBD5E1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Get Started gradient pill button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0062FF), Color(0xFF00D494)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00D494).withValues(alpha: 0.38),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: const Color(0xFF0062FF).withValues(alpha: 0.22),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(28),
                              onTap: () => Navigator.pushNamed(context, Routes.login),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text(
                                      'Get Started',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Footer: Already have an account? Sign In
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13.5,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, Routes.login),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: Color(0xFF0062FF),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 02 — Login Screen (Figma 1:1)
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.data});
  final OnboardingData data;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final keyForm = GlobalKey<FormState>();
  final contact = TextEditingController();

  @override
  void dispose() {
    contact.dispose();
    super.dispose();
  }

  void _submit() {
    if (keyForm.currentState!.validate()) {
      widget.data.contact = contact.text.trim();
      Navigator.pushNamed(context, Routes.otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  kToolbarHeight - 20,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Log in or create your Symposium account',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Pink outlined card container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder, width: 1.0),
                    ),
                    child: Form(
                      key: keyForm,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mobile number or email address',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: contact,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v == null || v.trim().length < 5
                                ? 'Enter a valid email address or phone number'
                                : null,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.text,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter phone number or email',
                              hintStyle: const TextStyle(
                                color: Color(0xFF9E9EA7),
                                fontSize: 14,
                              ),
                              fillColor: AppColors.inputBg,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "We'll send a one-time verification code.",
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 20),
                          PrimaryButton(
                            label: 'Continue',
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Divider with "or continue with"
                  Row(
                    children: const [
                      Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'or continue with',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Social Login Buttons: G, Apple, in
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialButton(
                        child: const Text(
                          'G',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        onTap: () {},
                      ),
                      const SizedBox(width: 16),
                      _SocialButton(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: AppColors.text,
                            shape: BoxShape.circle,
                          ),
                        ),
                        onTap: () {},
                      ),
                      const SizedBox(width: 16),
                      _SocialButton(
                        child: const Text(
                          'in',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        onTap: () {},
                      ),
                    ],
                  ),

                  const Spacer(),
                  const SizedBox(height: 20),

                  // Footer disclaimer
                  const Center(
                    child: Text(
                      'By continuing, you agree to our Terms & Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ==========================================
// 03 — OTP Screen (Figma 1:1)
// ==========================================
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.data});
  final OnboardingData data;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _secondsRemaining = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _verify() {
    if (_codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the complete 6-digit code')),
      );
      return;
    }
    Navigator.pushNamed(context, Routes.intro);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Circular back button
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 24,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Enter verification code',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We sent a 6-digit code to your phone or email.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'Edit contact',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // 6-digit OTP boxes display
              GestureDetector(
                onTap: () => _focusNode.requestFocus(),
                child: Stack(
                  children: [
                    // Invisible input capturing user keyboard & paste
                    Opacity(
                      opacity: 0.0,
                      child: SizedBox(
                        height: 52,
                        child: TextField(
                          controller: _codeController,
                          focusNode: _focusNode,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),

                    // Rendered 6 square boxes matching Figma
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        final text = _codeController.text;
                        final hasValue = index < text.length;
                        final isFocused = _focusNode.hasFocus &&
                            (index == text.length || (index == 5 && text.length == 6));

                        return Container(
                          width: 46,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.inputBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isFocused ? AppColors.primary : const Color(0xFFE8E8EE),
                              width: isFocused ? 1.5 : 1.0,
                            ),
                          ),
                          child: Center(
                            child: hasValue
                                ? Text(
                                    text[index],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.text,
                                    ),
                                  )
                                : const Text(
                                    '•',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF9E9EA7),
                                    ),
                                  ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Resend code row with countdown
              Row(
                children: [
                  const Text(
                    "Didn't get the code?",
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.muted,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _secondsRemaining == 0 ? _startTimer : null,
                    child: Text(
                      _secondsRemaining > 0
                          ? 'Resend code in 00:${_secondsRemaining.toString().padLeft(2, '0')}'
                          : 'Resend code',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Verify & Continue Button
              PrimaryButton(
                label: 'Verify & Continue',
                onPressed: _verify,
              ),

              const SizedBox(height: 14),

              // Bottom note
              const Center(
                child: Text(
                  'Your account is protected with secure OTP verification.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
