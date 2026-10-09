import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_button.dart';

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
      'id': 'hiring',
      'label': 'Hiring Talent',
      'icon': Icons.person_add_alt_1_outlined,
    },
    {
      'id': 'jobs',
      'label': 'Seeking Opportunities / Jobs',
      'icon': Icons.work_outline,
    },
    {
      'id': 'cofounder',
      'label': 'Finding a Co-Founder',
      'icon': Icons.hub_outlined,
    },
    {
      'id': 'freelance',
      'label': 'Freelance & Consulting Gigs',
      'icon': Icons.laptop_chromebook_outlined,
    },
    {
      'id': 'investing',
      'label': 'Angel Investing / Raising',
      'icon': Icons.trending_up,
    },
    {
      'id': 'friends',
      'label': 'Making Quality Local Friends',
      'icon': Icons.chat_bubble_outline,
    },
    {
      'id': 'experiences',
      'label': 'Attending Dinners & Events',
      'icon': Icons.restaurant_outlined,
    },
  ];

  final List<String> _interestTags = [
    'Artificial Intelligence',
    'Product Design',
    'Venture Capital',
    'SaaS & B2B',
    'Health & Longevity',
    'Deep Tech',
    'Architecture & Cities',
    'Electronic Music',
    'Podcasting',
    'Philosophy & Books',
    'Running / Fitness',
    'Culinary & Wine',
    'Fintech',
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              child: const Icon(Icons.arrow_back,
                  color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Intent & Interests',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Symposium matches you based on real-time intent, not passive swiping.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Primary Intent Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'What is your intent right now? *',
                style: TextStyle(
                  fontSize: 14,
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
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.surfaceElevated
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceBorder,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          size: 18,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item['label'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: isSelected
                            ? AppColors.primaryLight
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

          // Topic Interests Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select at least 3 topics *',
                style: TextStyle(
                  fontSize: 14,
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

          // Tag Pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _interestTags.map((tag) {
              final isSelected = _selectedInterests.contains(tag);
              return GestureDetector(
                onTap: () => _toggleInterest(tag),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryLight
                          : AppColors.surfaceBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tag,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.white
                              : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.check,
                            size: 14, color: AppColors.white),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          if (_errorText != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorGlow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 18),
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
          const SizedBox(height: 24),

          CustomButton(
            title: 'Continue',
            onPress: _handleContinue,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
