import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class Step4BasicProfileScreen extends StatefulWidget {
  final String initialFullName;
  final String initialCity;
  final String initialAge;
  final String initialBio;
  final String initialAvatarUrl;
  final Function(
    String fullName,
    String city,
    String age,
    String bio,
    String avatarUrl,
  ) onSubmit;
  final VoidCallback onBack;

  const Step4BasicProfileScreen({
    super.key,
    required this.initialFullName,
    required this.initialCity,
    required this.initialAge,
    required this.initialBio,
    required this.initialAvatarUrl,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  State<Step4BasicProfileScreen> createState() => _Step4BasicProfileScreenState();
}

class _Step4BasicProfileScreenState extends State<Step4BasicProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _cityController;
  late TextEditingController _ageController;
  late TextEditingController _bioController;
  late String _avatarUrl;

  final List<String> _popularCities = [
    'Mumbai',
    'Bengaluru',
    'Delhi NCR',
    'Pune',
    'Hyderabad',
  ];

  final List<String> _avatarPresets = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&h=200&fit=crop&crop=face',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop&crop=face',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200&h=200&fit=crop&crop=face',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&h=200&fit=crop&crop=face',
  ];

  String? _nameError;
  String? _cityError;
  String? _ageError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialFullName);
    _cityController = TextEditingController(text: widget.initialCity);
    _ageController = TextEditingController(text: widget.initialAge);
    _bioController = TextEditingController(text: widget.initialBio);
    _avatarUrl = widget.initialAvatarUrl.isNotEmpty
        ? widget.initialAvatarUrl
        : _avatarPresets.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    setState(() {
      _nameError = null;
      _cityError = null;
      _ageError = null;
    });

    bool hasError = false;

    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = 'Full name is required.');
      hasError = true;
    }

    if (_cityController.text.trim().isEmpty) {
      setState(() => _cityError = 'City is required for neighborhood discovery.');
      hasError = true;
    }

    final ageStr = _ageController.text.trim();
    if (ageStr.isEmpty) {
      setState(() => _ageError = 'Age is required (18+).');
      hasError = true;
    } else {
      final ageNum = int.tryParse(ageStr);
      if (ageNum == null || ageNum < 18 || ageNum > 100) {
        setState(() => _ageError = 'You must be at least 18 years old.');
        hasError = true;
      }
    }

    if (hasError) return;

    widget.onSubmit(
      _nameController.text.trim(),
      _cityController.text.trim(),
      _ageController.text.trim(),
      _bioController.text.trim(),
      _avatarUrl,
    );
  }

  void _cycleAvatar() {
    final curIndex = _avatarPresets.indexOf(_avatarUrl);
    final nextIndex = (curIndex + 1) % _avatarPresets.length;
    setState(() => _avatarUrl = _avatarPresets[nextIndex]);
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
              child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Basic Profile Setup',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Introduce yourself to your neighborhood peers and future collaborators.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),

          // Avatar Selector (Figma-grade Light Mode)
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        image: DecorationImage(
                          image: NetworkImage(_avatarUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _cycleAvatar,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.surface, width: 2.5),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: AppColors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tap camera icon to switch avatar',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Full Name
          CustomTextField(
            label: 'Full Name *',
            hint: 'e.g. Nikunj Maheshwari',
            controller: _nameController,
            errorText: _nameError,
            prefix: const Icon(Icons.person_outline, color: AppColors.textMuted),
            onChanged: (_) => setState(() => _nameError = null),
          ),
          const SizedBox(height: 16),

          // City and Age Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 12,
                child: CustomTextField(
                  label: 'City *',
                  hint: 'e.g. Mumbai',
                  controller: _cityController,
                  errorText: _cityError,
                  prefix: const Icon(Icons.location_on_outlined,
                      color: AppColors.textMuted),
                  onChanged: (_) => setState(() => _cityError = null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 8,
                child: CustomTextField(
                  label: 'Age (18+) *',
                  hint: '26',
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                  errorText: _ageError,
                  onChanged: (_) => setState(() => _ageError = null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Popular City Quick Select Pills (Clean Light Styling)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularCities.map((city) {
              final isSelected = _cityController.text.trim().toLowerCase() ==
                  city.toLowerCase();
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _cityController.text = city;
                    _cityError = null;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primarySoft
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
                    city,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Bio Input
          CustomTextField(
            label: 'Short Bio (Optional)',
            hint: 'Building tech, exploring design and hosting dinners.',
            controller: _bioController,
            maxLines: 3,
          ),
          const SizedBox(height: 32),

          CustomButton(
            title: 'Save & Continue',
            onPress: _handleContinue,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
