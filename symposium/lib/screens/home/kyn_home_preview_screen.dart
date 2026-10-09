import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/onboarding_model.dart';

class KynHomePreviewScreen extends StatelessWidget {
  final OnboardingModel userData;
  final VoidCallback onRestartOnboarding;

  const KynHomePreviewScreen({
    super.key,
    required this.userData,
    required this.onRestartOnboarding,
  });

  static final List<Map<String, dynamic>> _nearbyPeople = [
    {
      'id': '1',
      'name': 'Aarav Sharma',
      'role': 'AI Research Engineer',
      'company': 'HyperScale AI',
      'distance': '1.2 km away',
      'area': 'Bandra West',
      'mutuals': 4,
      'avatar':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop&crop=face',
      'intent': 'Looking for Co-founder',
      'verified': true,
    },
    {
      'id': '2',
      'name': 'Pooja Mehta',
      'role': 'Principal Designer',
      'company': 'Studio Craft',
      'distance': '2.5 km away',
      'area': 'Khar West',
      'mutuals': 7,
      'avatar':
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&h=200&fit=crop&crop=face',
      'intent': 'Hosting Design Dinners',
      'verified': true,
    },
    {
      'id': '3',
      'name': 'Vikram Patel',
      'role': 'Angel Investor / VP',
      'company': 'Nexus Ventures',
      'distance': '3.1 km away',
      'area': 'Juhu',
      'mutuals': 2,
      'avatar':
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&h=200&fit=crop&crop=face',
      'intent': 'Mentorship & Angel Checks',
      'verified': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: AppColors.primaryLight, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${userData.city} • Within ${userData.discoveryRadiusKm} km',
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Know Your Neighbor',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onRestartOnboarding,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(userData.avatarUrl),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Radar Active Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accentGlowSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.accentBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accentGlow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.radar,
                      color: AppColors.accent, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KYN Radar Active',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Showing verified members nearby. Your exact GPS is hidden.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CURATED NEARBY (${_nearbyPeople.length})',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                'Radius: ${userData.discoveryRadiusKm} km',
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cards List
          ..._nearbyPeople.map((person) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundImage: NetworkImage(person['avatar']),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  person['name'],
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (person['verified'] == true) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified,
                                      color: AppColors.accent, size: 16),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${person['role']} • ${person['company']}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '📍 ${person['area']} (${person['distance']}) • ${person['mutuals']} mutuals',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Intent Chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warningGlow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: AppColors.warning, size: 12),
                        const SizedBox(width: 5),
                        Text(
                          person['intent'],
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Divider(color: AppColors.surfaceBorder, height: 1),
                  const SizedBox(height: 12),

                  // Say Hi Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.chat_bubble_outline,
                          size: 16, color: AppColors.white),
                      label: const Text(
                        'Say Hi / Request Intro',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Finish / Re-test Box
          Container(
            margin: const EdgeInsets.only(top: 16, bottom: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: AppColors.accent, size: 28),
                const SizedBox(height: 8),
                const Text(
                  '01 · Onboarding Flow Completed',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'All 8 onboarding steps with validation, state management, and centralized global colors are running in Flutter.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: onRestartOnboarding,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.surfaceBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Re-test Onboarding Flow',
                    style: TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
