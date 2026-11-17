import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import 'widgets/pickers.dart';
import '../../data/profile_sync.dart';
import 'widgets/step_save.dart';
import 'package:image_picker/image_picker.dart';

/// Step 1 of 5 — About you.
class BasicProfileScreen extends StatefulWidget {
  const BasicProfileScreen({super.key});

  @override
  State<BasicProfileScreen> createState() => _BasicProfileScreenState();
}

class _BasicProfileScreenState extends State<BasicProfileScreen> {
  final d = SetupDraft.instance;
  late final _name = TextEditingController(text: d.fullName);
  late final _linkedin = TextEditingController(text: d.linkedIn);

  static const _genders = ['Woman', 'Man', 'Other', 'Prefer not to say'];

  @override
  void dispose() {
    _name.dispose();
    _linkedin.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showAppDatePicker(
      context,
      initialDate: d.dateOfBirth ?? DateTime(now.year - 28, now.month, now.day),
      firstDate: DateTime(now.year - 90),
      lastDate: now,
    );
    if (picked != null) setState(() => d.dateOfBirth = picked);
  }

  bool _saving = false;

  Future<void> _continue() async {
    d
      ..fullName = _name.text.trim()
      ..linkedIn = _linkedin.text.trim();
    setState(() => _saving = true);
    final ok = await saveStep(context, ProfileSync.saveBasic);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pushNamed(Routes.professional);
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1080, imageQuality: 85);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    final ok = await saveStep(context, () async {
      final msg = await ProfileSync.uploadPhoto(bytes, file.name, file.mimeType ?? 'image/jpeg');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    });
    if (ok && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SetupScaffold(
      header: const StepHeader(step: 1, style: StepHeaderStyle.titled, title: 'About you'),
      gap: 14,
      cta: PrimaryButton(
        label: 'Continue',
        showArrow: true,
        enabled: _name.text.trim().isNotEmpty,
        loading: _saving,
        onPressed: _continue,
      ),
      children: [
        const SectionHeading(
          title: "Let's put a face to your name.",
          subtitle: 'Add a few details so people can recognise you and get to know you.',
          titleStyle: AppText.setupTitleSmall,
        ),
        Center(
          child: GestureDetector(
            onTap: _pickPhoto,
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(color: AppColors.selectedFill, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const AppIcon(AppIcons.camera, size: 24, color: AppColors.iconBlue),
                ),
                const SizedBox(height: 10),
                Text(d.photoUrl == null ? 'Add a profile photo' : 'Photo added · tap to change', style: AppText.fieldLabel.copyWith(fontWeight: FontWeight.w600)),
                Text('Optional', style: AppText.helper.copyWith(height: 18 / 12)),
              ],
            ),
          ),
        ),
        AppTextField(
          label: 'Full name *',
          hint: 'Enter your full name',
          controller: _name,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          onChanged: (_) => setState(() {}),
        ),
        AppTextField(
          label: 'Date of birth',
          hint: 'DD / MM / YYYY',
          value: d.dateOfBirth == null ? null : formatDate(d.dateOfBirth!),
          leadingIcon: AppIcons.calendar,
          trailingIcon: AppIcons.chevronDown,
          helper: 'Optional unless required by the approved age policy.',
          onTap: _pickDob,
        ),
        AppTextField(
          label: 'LinkedIn URL',
          labelSuffix: '(Optional)',
          hint: 'https://linkedin.com/in/username',
          controller: _linkedin,
          keyboardType: TextInputType.url,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FieldLabel('Gender', suffix: '(Optional)'),
            const SizedBox(height: 8),
            for (final g in _genders)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => d.gender = g),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      AppRadio(selected: d.gender == g),
                      const SizedBox(width: 12),
                      Text(g, style: AppText.fieldInput.copyWith(fontSize: 15)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
