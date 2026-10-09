import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/onboarding_model.dart';
import '../../widgets/custom_button.dart';

class KynHomePreviewScreen extends StatefulWidget {
  final OnboardingModel userData;
  final VoidCallback onRestartOnboarding;

  const KynHomePreviewScreen({
    super.key,
    required this.userData,
    required this.onRestartOnboarding,
  });

  @override
  State<KynHomePreviewScreen> createState() => _KynHomePreviewScreenState();
}

class _KynHomePreviewScreenState extends State<KynHomePreviewScreen> {
  int _currentTabIndex = 0;
  String _selectedRadius = '5 km';
  bool _filterSharedInterests = true;
  bool _filtersActive = false;
  late String _currentCity;

  @override
  void initState() {
    super.initState();
    _currentCity = widget.userData.city.isNotEmpty
        ? widget.userData.city
        : 'Mumbai';
  }

  void _showCityPicker() {
    final cities = [
      'Mumbai',
      'Bengaluru',
      'Delhi NCR',
      'Pune',
      'Hyderabad',
      'Chennai',
      'Kolkata',
      'Ahmedabad',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select neighborhood city',
                style: AppTheme.serifTitle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Divider(color: AppColors.surfaceBorder),
              ...cities.map((city) {
                return ListTile(
                  title: Text(
                    city,
                    style: TextStyle(
                      color: _currentCity == city
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: _currentCity == city
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  trailing: _currentCity == city
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _currentCity = city);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showManageDiscoveryModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                  'Discovery Settings',
                  style: AppTheme.serifTitle.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Control your presence in Know Your Neighbor (KYN).',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Discovery Status',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            'Active',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Radius: 5 km • Approximate area only. Exact GPS coordinates are never recorded or shared.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  title: 'Done',
                  onPress: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showIntroModal({
    required String name,
    required String role,
    required String org,
    required String intent,
    required bool isSayHi,
  }) {
    final controller = TextEditingController(
      text: isSayHi
          ? 'Hi $name! Noticed we\'re both nearby in $_currentCity. Would love to say hello and connect.'
          : 'Hi $name! I saw you\'re looking for a collaborator. I\'d love to request an introduction.',
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
                  isSayHi ? 'Say Hi to $name' : 'Request Intro to $name',
                  style: AppTheme.serifTitle.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  '$role • $org • $intent',
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
                    controller: controller,
                    maxLines: 3,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Write a warm neighborhood note...',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Chat opens only after your request is accepted.',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 18),
                CustomButton(
                  title: isSayHi ? 'Send Hello' : 'Send Request',
                  trailingIcon: const Icon(Icons.send_rounded,
                      size: 16, color: AppColors.white),
                  onPress: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isSayHi
                              ? 'Your greeting was sent to $name!'
                              : 'Introduction request sent to $name!',
                        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top App Bar: Asterisk | symposium DEMO | Initials Avatar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        '✳',
                        style: TextStyle(
                          fontSize: 20,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'symposium',
                        style: AppTheme.wordmark.copyWith(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: const Text(
                          'DEMO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: widget.onRestartOnboarding,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.avatarBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'JS',
                          style: AppTheme.serifTitle.copyWith(
                            fontSize: 13,
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

            // Main Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),

                    // Title & Subtitle
                    Text(
                      'Know your neighbor.',
                      style: AppTheme.serifTitle.copyWith(
                        fontSize: 28,
                        height: 1.15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Good connections start close to home.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // City Dropdown & Discovery on Manage Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: _showCityPicker,
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                _currentCity,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 18, color: AppColors.textPrimary),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _showManageDiscoveryModal,
                          child: Row(
                            children: [
                              const Icon(Icons.circle,
                                  size: 7, color: AppColors.primary),
                              const SizedBox(width: 5),
                              const Text(
                                'Discovery on ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const Text(
                                'Manage',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Filter Pills Row
                    Row(
                      children: [
                        // Pill 1: 5 km
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRadius =
                                  _selectedRadius == '5 km' ? '10 km' : '5 km';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.near_me_outlined,
                                    size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  _selectedRadius,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Pill 2: Shared interests
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _filterSharedInterests = !_filterSharedInterests;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: _filterSharedInterests
                                  ? AppColors.surface
                                  : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.surfaceBorder,
                              ),
                            ),
                            child: Text(
                              'Shared interests',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _filterSharedInterests
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Pill 3: Filters
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _filtersActive = !_filtersActive;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: _filtersActive
                                  ? AppColors.primarySoft
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _filtersActive
                                    ? AppColors.primary
                                    : AppColors.surfaceBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.tune_rounded,
                                    size: 14,
                                    color: _filtersActive
                                        ? AppColors.primary
                                        : AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  'Filters',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _filtersActive
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Privacy Assurance Microcopy
                    const Row(
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 13, color: AppColors.textMuted),
                        SizedBox(width: 6),
                        Text(
                          'Selected city only. Your exact location stays private.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Section 1: Your kind of people
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your kind of people',
                              style: AppTheme.serifTitle.copyWith(
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              '24 people around your selected area',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const Row(
                          children: [
                            Text(
                              'See all',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward,
                                size: 13, color: AppColors.primary),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Two Cards Row (Maya Rao & Arjun Shah)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card 1: Maya Rao
                        Expanded(
                          child: _buildNeighborCard(
                            name: 'Maya Rao',
                            role: 'Product designer',
                            org: 'Independent',
                            tags: 'Design • Hiking',
                            intent: 'Open to creative collaboration',
                            mutualCount: 3,
                            imageUrl:
                                'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&auto=format&fit=crop&q=80',
                            isPrimaryAction: true,
                            actionLabel: 'Say Hi',
                            actionIcon: Icons.chat_bubble_outline_rounded,
                            onAction: () => _showIntroModal(
                              name: 'Maya Rao',
                              role: 'Product designer',
                              org: 'Independent',
                              intent: 'Open to creative collaboration',
                              isSayHi: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Card 2: Arjun Shah
                        Expanded(
                          child: _buildNeighborCard(
                            name: 'Arjun Shah',
                            role: 'Founder',
                            org: 'Goodground',
                            tags: 'Startups • Coffee',
                            intent: 'Looking for a co-founder',
                            mutualCount: 2,
                            imageUrl:
                                'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80',
                            isPrimaryAction: false,
                            actionLabel: 'Request Intro',
                            actionIcon: Icons.north_east_rounded,
                            onAction: () => _showIntroModal(
                              name: 'Arjun Shah',
                              role: 'Founder',
                              org: 'Goodground',
                              intent: 'Looking for a co-founder',
                              isSayHi: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Chat disclaimer
                    const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 12, color: AppColors.textMuted),
                          SizedBox(width: 6),
                          Text(
                            'Chat opens only after your request is accepted.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),

                    // Section 2: Better together (Experiences)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Better together',
                          style: AppTheme.serifTitle.copyWith(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Row(
                          children: [
                            Text(
                              'Experiences',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward,
                                size: 13, color: AppColors.primary),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Experience Card: Coffee & good conversation
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.surfaceBorder,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=400&auto=format&fit=crop&q=80',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 100,
                                height: 100,
                                color: AppColors.surfaceWarm,
                                child: const Icon(Icons.people_outline,
                                    color: AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'THIS WEEKEND • SMALL GROUP',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Coffee & good\nconversation',
                                  style: AppTheme.serifTitle.copyWith(
                                    fontSize: 15,
                                    height: 1.2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Sat, 19 Oct • 10:00 am',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  '6 of 8 spots filled • Free',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Row(
                                  children: [
                                    Text(
                                      'View & apply',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward,
                                        size: 11, color: AppColors.primary),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 3: SEEK • OPPORTUNITIES Promo Card (Spruce Green)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'SEEK • OPPORTUNITIES',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFC4D8D2),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Premium preview',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFC4D8D2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Find your next chapter.',
                            style: AppTheme.serifTitle.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Jobs, freelance, mentors & co-founders.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFC4D8D2),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Explore preview',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward,
                                      size: 13, color: AppColors.white),
                                ],
                              ),
                              Text(
                                'Upgrade',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFC4D8D2),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 4: Calendar & Private Notes
                    Row(
                      children: [
                        // Calendar Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceWarm,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.surfaceBorder,
                              ),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(Icons.calendar_today_outlined,
                                        size: 18, color: AppColors.textPrimary),
                                    Icon(Icons.north_east_rounded,
                                        size: 14,
                                        color: AppColors.textSecondary),
                                  ],
                                ),
                                SizedBox(height: 14),
                                Text(
                                  'Calendar',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Meetings & invites',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Private Notes Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceWarm,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.surfaceBorder,
                              ),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(Icons.edit_note_rounded,
                                        size: 20, color: AppColors.textPrimary),
                                    Icon(Icons.north_east_rounded,
                                        size: 14,
                                        color: AppColors.textSecondary),
                                  ],
                                ),
                                SizedBox(height: 14),
                                Text(
                                  'Private notes',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Remember & follow up',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Section 5: Help & Safety
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.surfaceBorder,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 20, color: AppColors.primary),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Help & Safety',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 1),
                                Text(
                                  'Report a concern • Support • Local emergency help',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              size: 18, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Sample Disclaimer
                    const Center(
                      child: Text(
                        'Sample people and experiences for this product demo.',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Re-test Onboarding Flow button
                    Center(
                      child: TextButton.icon(
                        onPressed: widget.onRestartOnboarding,
                        icon: const Icon(Icons.refresh_rounded,
                            size: 14, color: AppColors.primary),
                        label: const Text(
                          'Re-test Onboarding Flow',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Fixed Bottom Navigation Bar matching Figma
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.surfaceBorder, width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Tab 1: KYN (Active)
                      _buildNavTab(
                        index: 0,
                        icon: Icons.people_outline_rounded,
                        activeIcon: Icons.people_alt_rounded,
                        label: 'KYN',
                        hasBadge: false,
                      ),
                      // Tab 2: Experiences
                      _buildNavTab(
                        index: 1,
                        icon: Icons.auto_awesome_outlined,
                        activeIcon: Icons.auto_awesome,
                        label: 'Experiences',
                        hasBadge: false,
                      ),
                      // Tab 3: Seek
                      _buildNavTab(
                        index: 2,
                        icon: Icons.business_center_outlined,
                        activeIcon: Icons.business_center,
                        label: 'Seek',
                        hasBadge: false,
                      ),
                      // Tab 4: Inbox (with badge 3)
                      _buildNavTab(
                        index: 3,
                        icon: Icons.mail_outline_rounded,
                        activeIcon: Icons.mail_rounded,
                        label: 'Inbox',
                        hasBadge: true,
                        badgeText: '3',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTab({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool hasBadge,
    String? badgeText,
  }) {
    final isSelected = _currentTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTabIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: isSelected
                    ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
                    : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primarySoft
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              if (hasBadge && badgeText != null)
                Positioned(
                  top: -2,
                  right: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Center(
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeighborCard({
    required String name,
    required String role,
    required String org,
    required String tags,
    required String intent,
    required int mutualCount,
    required String imageUrl,
    required bool isPrimaryAction,
    required String actionLabel,
    required IconData actionIcon,
    required VoidCallback onAction,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceBorder,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo with Verified Pill Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.network(
                  imageUrl,
                  height: 135,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 135,
                    color: AppColors.surfaceWarm,
                    child: const Center(
                      child: Icon(Icons.person,
                          size: 36, color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 10, color: AppColors.primary),
                      SizedBox(width: 3),
                      Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Card Body
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  role,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  org,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tags,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),

                // HERE TO Pill Container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HERE TO',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        intent,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Mutual connections
                Row(
                  children: [
                    const Icon(Icons.people_outline,
                        size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '$mutualCount mutual connections',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Action Button (Solid Green or Outline)
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: isPrimaryAction
                      ? ElevatedButton.icon(
                          onPressed: onAction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            padding: EdgeInsets.zero,
                          ),
                          icon: Icon(actionIcon,
                              size: 13, color: AppColors.white),
                          label: Text(
                            actionLabel,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: onAction,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.primary,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          icon: Icon(actionIcon,
                              size: 13, color: AppColors.primary),
                          label: Text(
                            actionLabel,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
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
