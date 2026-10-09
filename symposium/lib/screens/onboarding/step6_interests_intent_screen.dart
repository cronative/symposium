import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/segmented_progress_bar.dart';
import '../../widgets/symposium_header.dart';

class Step6InterestsIntentScreen extends StatefulWidget {
  final List<String> initialIntents;
  final List<String> initialInterests;
  final Function(List<String> intents, List<String> interests) onSubmit;
  final VoidCallback onBack;

  const Step6InterestsIntentScreen({
    super.key,
    required this.initialIntents,
    required this.initialInterests,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  State<Step6InterestsIntentScreen> createState() =>
      _Step6InterestsIntentScreenState();
}

class _Step6InterestsIntentScreenState
    extends State<Step6InterestsIntentScreen> {
  late List<String> _selectedIntents;
  late List<String> _selectedInterests;
  String? _errorText;

  final List<Map<String, dynamic>> _intentOptions = [
    {
      'id': 'neighbors',
      'label': 'Meeting thoughtful minds in my neighborhood',
      'icon': Icons.people_outline_rounded,
    },
    {
      'id': 'coffee',
      'label': 'Coffee chats, walks & casual catch-ups',
      'icon': Icons.local_cafe_outlined,
    },
    {
      'id': 'salon_dinners',
      'label': 'Salon dinners, book talks & gatherings',
      'icon': Icons.restaurant_outlined,
    },
    {
      'id': 'collaborate',
      'label': 'Collaborations, projects & co-founding',
      'icon': Icons.hub_outlined,
    },
    {
      'id': 'coworking',
      'label': 'Coworking sessions & sharing local tips',
      'icon': Icons.laptop_mac_outlined,
    },
    {
      'id': 'activities',
      'label': 'Weekend runs, cycling & outdoor activities',
      'icon': Icons.directions_run_outlined,
    },
  ];

  final List<String> _interestTags = [
    'Technology & AI',
    'Product & Design',
    'Books & Philosophy',
    'Specialty Coffee',
    'Architecture & Urbanism',
    'Running & Fitness',
    'Culinary & Dining',
    'Cinema & Visual Arts',
    'Startups & Ideas',
    'Dogs & Pets',
    'Mindfulness & Meditation',
    'Writing & Literature',
    'Music & Vinyl',
  ];

  @override
  void initState() {
    super.initState();
    _selectedIntents = List.from(widget.initialIntents);
    _selectedInterests = List.from(widget.initialInterests);
  }

  void _toggleIntent(String id) {
    setState(() {
      _errorText = null;
      if (_selectedIntents.contains(id)) {
        _selectedIntents.remove(id);
      } else {
        _selectedIntents.add(id);
      }
    });
  }

  void _toggleInterest(String tag) {
    setState(() {
      _errorText = null;
      if (_selectedInterests.contains(tag)) {
        _selectedInterests.remove(tag);
      } else {
        _selectedInterests.add(tag);
      }
    });
  }

  void _handleContinue() {
    if (_selectedIntents.isEmpty) {
      setState(() => _errorText = 'Please select at least 1 current intent.');
      return;
    }
    if (_selectedInterests.length < 3) {
      setState(() => _errorText =
          'Please select at least 3 topics (${_selectedInterests.length} selected).');
      return;
    }

    widget.onSubmit(_selectedIntents, _selectedInterests);
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
          sectionName: 'Curating Your Feed',
          currentStep: 5,
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
                  'What brings you\nto Symposium?',
                  style: AppTheme.serifTitle.copyWith(
                    fontSize: 32,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  'Select what you\'re open to right now. You can change this anytime.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Section 1: Intent
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Primary intent right now *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      'Select any',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Intent Cards
                Column(
                  children: _intentOptions.map((item) {
                    final isSelected = _selectedIntents.contains(item['id']);
                    return GestureDetector(
                      onTap: () => _toggleIntent(item['id']),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primarySoft
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surfaceBorder,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              size: 20,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['label'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.surfaceBorder,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Section 2: Topics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select at least 3 topics of interest *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '(${_selectedInterests.length} selected)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _interestTags.map((tag) {
                    final isSelected = _selectedInterests.contains(tag);
                    return GestureDetector(
                      onTap: () => _toggleInterest(tag),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surfaceBorder,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.white
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                if (_errorText != null) ...[
                  Text(
                    _errorText!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 24),

                // CTA
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
