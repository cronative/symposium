import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/info_card.dart';
import '../../widgets/segmented_progress_bar.dart';
import '../../widgets/symposium_header.dart';

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
    return Column(
      children: [
        SymposiumHeader(
          onBack: widget.onBack,
          actionText: 'Help',
          onAction: () {},
        ),
        const SegmentedProgressBar(
          sectionName: 'Privacy & Control',
          currentStep: 6,
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
                  'Your visibility,\nyour terms.',
                  style: AppTheme.serifTitle.copyWith(
                    fontSize: 32,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  'Control how you appear in Know Your Neighbor (KYN) discovery. You are always in control.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // KYN Discovery Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
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
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(color: AppColors.surfaceBorder, height: 1),
                        ),
                        const Text(
                          'Discovery radius',
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
                                onTap: () =>
                                    setState(() => _discoveryRadiusKm = km),
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(10),
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

                // Zero Exact-GPS Note
                const InfoCard(
                  icon: Icons.shield_outlined,
                  title: 'Zero Exact-GPS Exposure',
                  description:
                      'Symposium never reveals your apartment or precise street coordinates. Only general vicinity (e.g. "Bandra West • 2 km away") is displayed.',
                  backgroundColor: AppColors.primarySoft,
                  iconColor: AppColors.primary,
                ),
                const SizedBox(height: 16),

                // Private / Incognito Mode Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.visibility_off_outlined,
                            color: AppColors.textSecondary, size: 22),
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
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isProfilePrivate,
                        activeThumbColor: AppColors.white,
                        activeTrackColor: AppColors.primary,
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
                const SizedBox(height: 32),

                CustomButton(
                  title: 'Save & continue',
                  trailingIcon: const Icon(Icons.arrow_forward,
                      size: 18, color: AppColors.white),
                  onPress: _handleContinue,
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
