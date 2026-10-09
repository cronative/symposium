import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/onboarding_model.dart';
import '../../widgets/custom_button.dart';

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
      'role': 'Product Architect',
      'company': 'HyperScale Labs',
      'distance': '1.2 km away',
      'area': 'Pali Hill, Bandra',
      'mutuals': 4,
      'avatar':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop&crop=face',
      'intent': 'Open for Coffee & Co-working',
      'verified': true,
    },
    {
      'id': '2',
      'name': 'Pooja Mehta',
      'role': 'Editorial Designer & Writer',
      'company': 'Independent Studio',
      'distance': '2.1 km away',
      'area': 'Khar West',
      'mutuals': 7,
      'avatar':
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&h=200&fit=crop&crop=face',
      'intent': 'Hosting Weekend Book Salon',
      'verified': true,
    },
    {
      'id': '3',
      'name': 'Vikram Singhania',
      'role': 'Founder & Marathoner',
      'company': 'Terra Studio',
      'distance': '3.4 km away',
      'area': 'Juhu Tara Road',
      'mutuals': 3,
      'avatar':
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&h=200&fit=crop&crop=face',
      'intent': 'Morning Bandstand Runs & Coffee',
      'verified': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '✳',
                style: TextStyle(
                  fontSize: 22,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'symposium',
                style: AppTheme.wordmark,
              ),
              GestureDetector(
                onTap: onRestartOnboarding,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.avatarBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      'NM',
                      style: AppTheme.serifTitle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: AppColors.primary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${userData.city} • Within ${userData.discoveryRadiusKm} km',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Know Your Neighbor',
                  style: AppTheme.serifTitle.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),

                // Radar Active Banner (Pale Sage)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.radar, color: AppColors.primary, size: 22),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KYN Radar Active',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
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
                const SizedBox(height: 22),

                // Section Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'CURATED NEARBY (3)',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'Radius: ${userData.discoveryRadiusKm} km',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Member Cards
                ..._nearbyPeople.map((person) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: AppColors.surfaceBorder, width: 1.2),
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
                            CircleAvatar(
                              radius: 26,
                              backgroundImage: NetworkImage(person['avatar']),
                            ),
                            const SizedBox(width: 14),
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
                                            color: AppColors.primary, size: 16),
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
                            color: AppColors.surfaceWarm,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            person['intent'],
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        const Divider(color: AppColors.surfaceBorder, height: 1),
                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: ElevatedButton.icon(
                            onPressed: () => _showIntroModal(
                              context,
                              person['name'],
                              person['area'],
                              person['intent'],
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.chat_bubble_outline_rounded,
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

                // Finish card
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: AppColors.primary, size: 28),
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
                        'All screens matched 1:1 to the Figma Linen & Deep Forest Spruce designs.',
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
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Re-test Onboarding Flow',
                          style: TextStyle(
                            color: AppColors.primary,
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
          ),
        ),
      ],
    );
  }

  void _showIntroModal(
    BuildContext context,
    String name,
    String area,
    String intent,
  ) {
    final noteController = TextEditingController(
      text:
          'Hey $name! Saw you\'re nearby in $area ($intent). Would love to connect over coffee!',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 20,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Say Hello to $name',
                  style: AppTheme.serifTitle.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nearby in $area • $intent',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: TextField(
                    controller: noteController,
                    maxLines: 3,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Write a warm neighborhood greeting...',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Symposium keeps all conversations respectful and neighborly.',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 18),
                CustomButton(
                  title: 'Send Intro Note',
                  trailingIcon: const Icon(Icons.send_rounded,
                      size: 16, color: AppColors.white),
                  onPress: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Intro note sent to $name!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
