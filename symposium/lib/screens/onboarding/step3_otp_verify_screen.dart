import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/info_card.dart';
import '../../widgets/segmented_progress_bar.dart';
import '../../widgets/symposium_header.dart';

class Step3OtpVerifyScreen extends StatefulWidget {
  final String contactValue;
  final ValueChanged<String> onVerifySuccess;
  final VoidCallback onBack;
  final VoidCallback onChangeContact;
  final VoidCallback onResendOtp;

  const Step3OtpVerifyScreen({
    super.key,
    required this.contactValue,
    required this.onVerifySuccess,
    required this.onBack,
    required this.onChangeContact,
    required this.onResendOtp,
  });

  @override
  State<Step3OtpVerifyScreen> createState() => _Step3OtpVerifyScreenState();
}

class _Step3OtpVerifyScreenState extends State<Step3OtpVerifyScreen> {
  final List<TextEditingController> _controllers = [
    TextEditingController(text: '4'),
    TextEditingController(text: '8'),
    TextEditingController(text: '2'),
    TextEditingController(text: '9'),
    TextEditingController(text: '1'),
    TextEditingController(text: '6'),
  ];
  final List<FocusNode> _focusNodes = List.generate(6, (i) => FocusNode());

  int _timerSeconds = 45;
  Timer? _timer;
  String? _errorText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _timerSeconds = 45);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _handleDigitChanged(String value, int index) {
    setState(() => _errorText = null);
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyCode();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  void _verifyCode() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 6) {
      setState(() => _errorText = 'Please enter all 6 digits of the code.');
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoading = false);
        if (code == '000000') {
          setState(() => _errorText = 'Incorrect OTP code. Try again or request a new code.');
        } else {
          widget.onVerifySuccess(code);
        }
      }
    });
  }

  void _handleResend() {
    for (var c in _controllers) {
      c.clear();
    }
    setState(() => _errorText = null);
    _startCountdown();
    widget.onResendOtp();
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
          currentStep: 2,
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
                  'A small check.\nA fresh start.',
                  style: AppTheme.serifTitle.copyWith(
                    fontSize: 32,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  'Enter the 6-digit code we sent to your email.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                // Contact display & change link
                Text(
                  widget.contactValue.isNotEmpty
                      ? widget.contactValue
                      : 'nikunj.maheshwari@example.com',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: widget.onChangeContact,
                  child: const Text(
                    'Change email address',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Verification code label
                const Text(
                  'Verification code',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),

                // 6 Boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    final isFilled = _controllers[index].text.isNotEmpty;
                    return Container(
                      width: 48,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _errorText != null
                              ? AppColors.error
                              : isFilled
                                  ? AppColors.primary
                                  : AppColors.surfaceBorder,
                          width: 1.3,
                        ),
                      ),
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                        ),
                        onChanged: (val) => _handleDigitChanged(val, index),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),

                const Text(
                  'Codes are valid for 10 minutes. Use the newest code if you\'ve requested more than one.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Resend row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Didn\'t get the code?',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    GestureDetector(
                      onTap: _handleResend,
                      child: Text(
                        _timerSeconds > 0
                            ? 'Resend code (${_timerSeconds}s)'
                            : 'Resend code',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Warm Info Card
                const InfoCard(
                  icon: Icons.refresh_rounded,
                  title: 'A code that won\'t work?',
                  description:
                      'Check for typos and try again. If the code is expired, resend it. Look in spam if the email hasn\'t arrived.',
                  backgroundColor: AppColors.surfaceWarm,
                ),
                const SizedBox(height: 16),

                // Support Link
                const Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Still stuck? Contact support',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // CTA
                CustomButton(
                  title: 'Verify & continue',
                  trailingIcon: const Icon(Icons.arrow_forward,
                      size: 18, color: AppColors.white),
                  loading: _isLoading,
                  onPress: _verifyCode,
                ),
                const SizedBox(height: 12),

                const Center(
                  child: Text(
                    'Verification keeps our community more human.',
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
