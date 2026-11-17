import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/network/api_client.dart';
import '../../core/realtime/realtime_service.dart';
import '../../core/widgets/widgets.dart';
import '../../data/api.dart';
import '../../data/profile_sync.dart';

class OtpArgs {
  const OtpArgs({required this.requestId, required this.destination, this.devCode, this.resendAfter = 30});
  final String requestId;
  final String destination;
  final String? devCode;
  final int resendAfter;
}

/// 06 — Verify your account (6-digit OTP) via POST /auth/otp/verify.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.args});
  final OtpArgs args;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpKey = GlobalKey<OtpInputState>();
  Timer? _timer;
  int _seconds = 30;
  String _code = '';
  String? _error;
  String? _info;
  bool _verifying = false;
  late String _requestId = widget.args.requestId;
  late String? _devCode = widget.args.devCode;

  @override
  void initState() {
    super.initState();
    _seconds = widget.args.resendAfter;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = widget.args.resendAfter);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 1) t.cancel();
      if (mounted) setState(() => _seconds = (_seconds - 1).clamp(0, 600));
    });
  }

  Future<void> _resend() async {
    _otpKey.currentState?.clear();
    try {
      final (otp, message) = await AuthApi.resendOtp(_requestId);
      if (!mounted) return;
      setState(() {
        _requestId = otp.requestId;
        _devCode = otp.devCode;
        _error = null;
        _info = message;
      });
      _startTimer();
    } on ApiException catch (e) {
      if (mounted) setState(() {
      _error = e.message;
      _info = null;
    });
    }
  }

  Future<void> _verify() async {
    setState(() => _verifying = true);
    try {
      var step = await AuthApi.verifyOtp(_requestId, _code);
      RealtimeService.instance.start();
      // Pull the saved profile so setup resumes pre-filled at the right step.
      try {
        step = await ProfileSync.load();
      } on ApiException catch (_) {}
      if (!mounted) return;
      // Finished profiles go Home; everyone else continues where they left off.
      Navigator.of(context).pushNamedAndRemoveUntil(ProfileSync.routeForStep(step), (r) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      final left = e.data['remainingAttempts'];
      setState(() {
        _verifying = false;
        _info = null;
        _error = left is int && left > 0 ? '${e.message} ($left attempts left)' : e.message;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dest = widget.args.destination.isEmpty ? 'your phone number or email address' : widget.args.destination;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: FillScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen, vertical: AppSpace.x6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(alignment: Alignment.centerLeft, child: SquareBackButton()),
                const SizedBox(height: 16),
                const Center(child: BrandLogo()),
                const SizedBox(height: 8),
                const Text('Verify your account.', style: AppText.authTitle),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(style: AppText.authBody, children: [
                    const TextSpan(text: 'Enter the 6-digit code we sent to '),
                    TextSpan(text: dest, style: AppText.authBody.copyWith(fontWeight: FontWeight.w600, color: AppColors.navy)),
                    const TextSpan(text: '.'),
                  ]),
                ),
                const SizedBox(height: 24),
                OtpInput(
                  key: _otpKey,
                  hasError: _error != null,
                  onChanged: (v) => setState(() {
                    _code = v;
                    _error = null;
                  }),
                ),
                if (_error != null || _info != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error ?? _info!,
                    style: AppText.legal.copyWith(
                      fontWeight: FontWeight.w500,
                      color: _error != null ? AppColors.error : AppColors.success,
                    ),
                  ),
                ],
                if (_devCode != null) ...[
                  const SizedBox(height: 12),
                  Text('Test mode · your code is $_devCode', style: AppText.legal.copyWith(color: AppColors.sub)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      const Expanded(child: Text("Didn't receive the code?", style: AppText.authBody)),
                      _seconds > 0
                          ? Text(
                              'Resend code in 00:${_seconds.toString().padLeft(2, '0')}',
                              style: AppText.authBody.copyWith(fontWeight: FontWeight.w700),
                            )
                          : GestureDetector(
                              onTap: _resend,
                              child: Text('Resend code', style: AppText.authBody.copyWith(fontWeight: FontWeight.w700, color: AppColors.blue)),
                            ),
                    ],
                  ),
                ),
                const Spacer(),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Verify and continue',
                  variant: ButtonVariant.auth,
                  enabled: _code.length == 6,
                  loading: _verifying,
                  onPressed: _verify,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Your account is protected with one-time verification.',
                  style: AppText.authBody,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
