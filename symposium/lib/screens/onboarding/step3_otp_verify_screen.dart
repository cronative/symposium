import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_button.dart';

class Step3OtpVerifyScreen extends StatefulWidget {
  final String contactValue;
  final ValueChanged<String> onVerifySuccess;
  final VoidCallback onBack;
  final VoidCallback onResendOtp;

  const Step3OtpVerifyScreen({
    super.key,
    required this.contactValue,
    required this.onVerifySuccess,
    required this.onBack,
    required this.onResendOtp,
  });

  @override
  State<Step3OtpVerifyScreen> createState() => _Step3OtpVerifyScreenState();
}

class _Step3OtpVerifyScreenState extends State<Step3OtpVerifyScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

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

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isLoading = false);
        if (code == '000000') {
          setState(() => _errorText = 'Incorrect OTP. Try 123456 or resend code.');
        } else {
          widget.onVerifySuccess(code);
        }
      }
    });
  }

  void _handleResend() {
    if (_timerSeconds == 0) {
      for (var c in _controllers) {
        c.clear();
      }
      setState(() => _errorText = null);
      _startCountdown();
      widget.onResendOtp();
    }
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

          const Text(
            'Enter Verification Code',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              children: [
                const TextSpan(text: 'A 6-digit code was sent to '),
                TextSpan(
                  text: widget.contactValue,
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 6 Digit Cells
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              final bool isFilled = _controllers[index].text.isNotEmpty;
              return Container(
                width: 46,
                height: 56,
                decoration: BoxDecoration(
                  color: isFilled ? AppColors.surfaceElevated : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _errorText != null
                        ? AppColors.error
                        : isFilled
                            ? AppColors.primary
                            : AppColors.surfaceBorder,
                    width: 1.5,
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
          const SizedBox(height: 20),

          // Error Message Banner
          if (_errorText != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorGlow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorText!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Resend Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Didn\'t receive the code? ',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              GestureDetector(
                onTap: _handleResend,
                child: Text(
                  _timerSeconds > 0 ? 'Resend in ${_timerSeconds}s' : 'Resend Code',
                  style: TextStyle(
                    color: _timerSeconds > 0
                        ? AppColors.textMuted
                        : AppColors.primaryLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tip Hint Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    color: AppColors.primaryLight, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tip: Enter any 6 digits (e.g. 1 2 3 4 5 6) to proceed in this demo.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          CustomButton(
            title: 'Verify & Continue',
            loading: _isLoading,
            onPress: _verifyCode,
          ),
        ],
      ),
    );
  }
}
