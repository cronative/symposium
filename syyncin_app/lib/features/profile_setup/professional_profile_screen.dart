import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import '../../data/meta.dart';
import '../../data/profile_sync.dart';
import 'widgets/pickers.dart';
import 'widgets/step_save.dart';

/// Lists come from the API (admin-managed) — see [Meta].
List<String> get kIndustries => Meta.instance.industryNames;
List<String> get kExperience => Meta.instance.experienceNames;

/// Step 2 of 5 — Your work.
class ProfessionalProfileScreen extends StatefulWidget {
  const ProfessionalProfileScreen({super.key});

  @override
  State<ProfessionalProfileScreen> createState() => _ProfessionalProfileScreenState();
}

class _ProfessionalProfileScreenState extends State<ProfessionalProfileScreen> {
  final d = SetupDraft.instance;
  late final _job = TextEditingController(text: d.jobTitle);
  late final _company = TextEditingController(text: d.company);
  bool _saving = false;

  bool get _valid => _job.text.trim().isNotEmpty && d.industry != null && d.experience != null;

  @override
  void dispose() {
    _job.dispose();
    _company.dispose();
    super.dispose();
  }

  Future<void> _pick(String title, List<String> options, String? current, void Function(String) set) async {
    FocusScope.of(context).unfocus();
    final v = await showOptionSheet(context, title: title, options: options, selected: current);
    if (v != null) setState(() => set(v));
  }

  List<String> get _skillList => d.skills.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  Future<void> _pickSkills() async {
    FocusScope.of(context).unfocus();
    final picked = await showSkillPicker(context, selected: _skillList);
    if (picked != null) setState(() => d.skills = picked.join(', '));
  }

  Future<void> _continue() async {
    d
      ..jobTitle = _job.text.trim()
      ..company = _company.text.trim();
    setState(() => _saving = true);
    final ok = await saveStep(context, ProfileSync.saveWork);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pushNamed(Routes.interests);
  }

  @override
  Widget build(BuildContext context) {
    return SetupScaffold(
      header: const StepHeader(step: 2),
      cta: PrimaryButton(label: 'Continue', showArrow: true, enabled: _valid, loading: _saving, onPressed: _continue),
      children: [
        const SectionHeading(
          eyebrow: 'Your work',
          title: 'What do you do?',
          subtitle: 'Help people discover you through your work, experience and skills.',
        ),
        AppTextField(
          label: 'Job title *',
          hint: 'e.g. Product Designer',
          controller: _job,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.jobTitle],
          onChanged: (_) => setState(() {}),
        ),
        AppTextField(
          label: 'Industry *',
          hint: 'Select your industry',
          value: d.industry,
          trailingIcon: AppIcons.chevronDown,
          onTap: () => _pick('Industry', kIndustries, d.industry, (v) => d.industry = v),
        ),
        AppTextField(
          label: 'Company or organisation',
          labelSuffix: '(Optional)',
          hint: 'Enter company name',
          controller: _company,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.organizationName],
        ),
        AppTextField(
          label: 'Years of experience *',
          hint: 'Select experience level',
          value: d.experience,
          trailingIcon: AppIcons.chevronDown,
          onTap: () => _pick('Years of experience', kExperience, d.experience, (v) => d.experience = v),
        ),
        AppTextField(
          label: 'Skills',
          labelSuffix: '(Optional)',
          hint: 'Search and add skills',
          value: d.skills.isEmpty ? null : d.skills,
          trailingIcon: AppIcons.chevronDown,
          onTap: _pickSkills,
          helper: 'Choose up to 5 skills that describe your expertise.',
        ),
      ],
    );
  }
}
