import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_button.dart';

class Step7PrivacyDiscoveryScreen extends StatefulWidget {
  final bool initialEnableKynDiscovery;
  final int initialDiscoveryRadiusKm;
  final bool initialIsProfilePrivate;
  final Function(
    bool enableKynDiscovery,
    int discoveryRadiusKm,
    bool isProfilePrivate,
  ) onSubmit;
  final VoidCallback onBack;

  const Step7PrivacyDiscoveryScreen({
    super.key,
    required this.initialEnableKynDiscovery,
    required this.initialDiscoveryRadiusKm,
    required this.initialIsProfilePrivate,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  State<Step7PrivacyDiscoveryScreen> createState() =>
      _Step7PrivacyDiscoveryScreenState();
}

class _Step7PrivacyDiscoveryScreenState
    extends State<Step7PrivacyDiscoveryScreen> {
  late bool _enableKynDiscovery;
  late int _discoveryRadiusKm;
  late bool _isProfilePrivate;

  final List<int> _radiusOptions = [2, 5, 10, 20];

  @override
  void initState() {
    super.initState();
    _enableKynDiscovery = widget.initialEnableKynDiscovery;
    _discoveryRadiusKm = widget.initialDiscoveryRadiusKm;
    _isProfilePrivate = widget.initialIsProfilePrivate;
  }

  void _handleContinue() {
    widget.onSubmit(
      _enableKynDiscovery,
      _discoveryRadiusKm,
      _isProfilePrivate,
    );
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
              child: const Icon(Icons.arrow_back,
                  color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Privacy & Discovery',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Control how and when you appear to others nearby. You are always in control of your visibility.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),

          // Main KYN Toggle Card (Figma-grade Light Card)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.near_me_outlined,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Know Your Neighbor (KYN)',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Allow verified peers in your area to discover your profile.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _enableKynDiscovery,
                      activeThumbColor: AppColors.white,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          _enableKynDiscovery = val;
                          if (val) _isProfilePrivate = false;
                        });
                      },
                    ),
                  ],
                ),
                if (_enableKynDiscovery) ...[
                  const Divider(color: AppColors.surfaceBorder, height: 28),
                  const Text(
                    'Discovery Radius',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: _radiusOptions.map((km) {
                      final isSelected = _discoveryRadiusKm == km;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _discoveryRadiusKm = km),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.surfaceBorder,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$km km',
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Zero-GPS Assurance Card (Light Emerald Accent Card)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accentBorder),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined,
                    color: AppColors.accent, size: 24),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zero Exact-GPS Exposure',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Symposium never reveals your apartment or precise street coordinates. Only general vicinity (e.g. "Bandra West • 2 km away") is displayed.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Incognito / Private Mode Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.errorSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.visibility_off_outlined,
                      color: AppColors.error, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Private / Incognito Mode',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Only people you contact or invite to meetings will see your profile.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isProfilePrivate,
                  activeThumbColor: AppColors.white,
                  activeTrackColor: AppColors.error,
                  onChanged: (val) {
                    setState(() {
                      _isProfilePrivate = val;
                      if (val) _enableKynDiscovery = false;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          CustomButton(
            title: 'Complete Profile',
            onPress: _handleContinue,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
