import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/segmented_progress_bar.dart';
import '../../widgets/symposium_header.dart';

class Step4BasicProfileScreen extends StatefulWidget {
  final String initialFullName;
  final String initialCity;
  final DateTime? initialBirthDate;
  final Function(
    String fullName,
    String city,
    DateTime? birthDate,
    int? calculatedAge,
  ) onSubmit;
  final VoidCallback onBack;

  const Step4BasicProfileScreen({
    super.key,
    required this.initialFullName,
    required this.initialCity,
    this.initialBirthDate,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  State<Step4BasicProfileScreen> createState() =>
      _Step4BasicProfileScreenState();
}

class _Step4BasicProfileScreenState extends State<Step4BasicProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _cityController;
  late TextEditingController _birthDateController;
  DateTime? _selectedBirthDate;

  final List<String> _cities = [
    'Bengaluru',
    'Mumbai',
    'Delhi NCR',
    'Pune',
    'Hyderabad',
    'Chennai',
    'Kolkata',
    'Ahmedabad',
  ];

  String? _nameError;
  String? _cityError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialFullName.isNotEmpty
          ? widget.initialFullName
          : 'Nisha Mehta',
    );
    _cityController = TextEditingController(
      text: widget.initialCity.isNotEmpty ? widget.initialCity : 'Bengaluru',
    );
    _selectedBirthDate = widget.initialBirthDate ?? DateTime(1996, 5, 14);
    _birthDateController = TextEditingController(
      text: _formatDate(_selectedBirthDate),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  int? _calculateAge(DateTime? date) {
    if (date == null) return null;
    final now = DateTime.now();
    int age = now.year - date.year;
    if (now.month < date.month ||
        (now.month == date.month && now.day < date.day)) {
      age--;
    }
    return age;
  }

  Future<void> _showDatePickerModal() async {
    final DateTime initial = _selectedBirthDate ?? DateTime(1996, 5, 14);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      helpText: 'Select your date of birth',
      cancelText: 'Cancel',
      confirmText: 'Done',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = _formatDate(picked);
      });
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return 'NM';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  void _showCityPicker() {
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
                'Select your city',
                style: AppTheme.serifTitle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Divider(color: AppColors.surfaceBorder),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _cities.length,
                  itemBuilder: (context, index) {
                    final city = _cities[index];
                    return ListTile(
                      title: Text(
                        city,
                        style: TextStyle(
                          color: _cityController.text == city
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight: _cityController.text == city
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      trailing: _cityController.text == city
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () {
                        setState(() {
                          _cityController.text = city;
                          _cityError = null;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleContinue() {
    setState(() {
      _nameError = null;
      _cityError = null;
    });

    bool hasError = false;

    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = 'Full name is required.');
      hasError = true;
    }

    if (_cityController.text.trim().isEmpty) {
      setState(() => _cityError = 'City is required.');
      hasError = true;
    }

    if (hasError) return;

    widget.onSubmit(
      _nameController.text.trim(),
      _cityController.text.trim(),
      _selectedBirthDate,
      _calculateAge(_selectedBirthDate),
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
          sectionName: 'A Little About You',
          currentStep: 3,
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
                  'Put a name\nto your hello.',
                  style: AppTheme.serifTitle.copyWith(
                    fontSize: 32,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  'Start with the essentials. You can add more or make changes later.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Avatar Upload Row
                Row(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: AppColors.avatarBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(_nameController.text),
                          style: AppTheme.serifTitle.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.camera_alt_outlined,
                                  size: 18, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Add a photo · Optional',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'No photo yet? Your initials work too.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Field 1: Full name
                CustomTextField(
                  label: 'Full name',
                  requirementText: 'Required',
                  hint: 'e.g. Nisha Mehta',
                  controller: _nameController,
                  errorText: _nameError,
                  onChanged: (val) => setState(() => _nameError = null),
                ),
                const SizedBox(height: 16),

                // Field 2: City
                GestureDetector(
                  onTap: _showCityPicker,
                  child: AbsorbPointer(
                    child: CustomTextField(
                      label: 'City',
                      requirementText: 'Required',
                      hint: 'Select your city',
                      controller: _cityController,
                      suffix: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primary, size: 22),
                      helperText:
                          'Choose manually. No location permission needed.',
                      errorText: _cityError,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Field 3: Birthdate (with automatic age calculation)
                GestureDetector(
                  onTap: _showDatePickerModal,
                  child: AbsorbPointer(
                    child: CustomTextField(
                      label: 'Birthdate',
                      requirementText: 'Optional',
                      hint: 'Select birthdate',
                      controller: _birthDateController,
                      suffix: const Icon(Icons.calendar_today_outlined,
                          color: AppColors.primary, size: 20),
                      helperText: _selectedBirthDate != null
                          ? 'Calculated age: ${_calculateAge(_selectedBirthDate)} years · Kept private on your profile.'
                          : 'Your age is calculated automatically and kept private.',
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Privacy Note
                const Text(
                  'Only your name and city can appear in discovery. Your age stays private.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                // Submit CTA
                CustomButton(
                  title: 'Save & continue',
                  trailingIcon: const Icon(Icons.arrow_forward,
                      size: 18, color: AppColors.white),
                  onPress: _handleContinue,
                ),
                const SizedBox(height: 12),

                const Center(
                  child: Text(
                    'Name and selected city are needed to continue.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
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
