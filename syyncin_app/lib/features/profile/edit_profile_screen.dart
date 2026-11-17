import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/widgets/widgets.dart';
import '../profile_setup/interests_screen.dart' show kInterests, kReasons;
import '../profile_setup/mindset_screen.dart' show kMindsetQuestions;
import '../profile_setup/professional_profile_screen.dart' show kIndustries, kExperience;
import '../../data/meta.dart';
import '../../data/profile_sync.dart';
import '../profile_setup/widgets/pickers.dart';
import '../profile_setup/widgets/step_save.dart';

const kGenders = ['Woman', 'Man', 'Other', 'Prefer not to say'];
const kDistances = ['5 km', '10 km', '25 km', '50+ km'];
const kConnectModes = ['In person', 'Online', 'Both'];
const kAvailability = ['Weekdays', 'Weekends', 'Evenings', 'Flexible'];
const _maxSkills = 5; // same rule as setup + API (rules.maxSkills)
const _maxReasons = 3;
const _minInterests = 3;

enum _EditTab { personal, work, interests, discovery }

const _tabLabels = {
  _EditTab.personal: 'Personal',
  _EditTab.work: 'Work',
  _EditTab.interests: 'Interests',
  _EditTab.discovery: 'Discovery',
};

/// Figma 41a–41d (v3) — Edit Profile. Every field captured during profile
/// setup is editable here. Changes are kept in a local copy and only written
/// to [SetupDraft] + saved via PUT /me/profile on Save (pops `true`);
/// Cancel / back discards them.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final d = SetupDraft.instance;
  _EditTab _tab = _EditTab.personal;
  bool _saving = false;

  // Personal
  late final _name = TextEditingController(text: d.fullName);
  late final _about = TextEditingController(text: d.about);
  late final _linkedIn = TextEditingController(text: d.linkedIn);
  late DateTime? _dob = d.dateOfBirth;
  late String? _gender = d.gender;
  bool _uploading = false;

  // Work
  late final _job = TextEditingController(text: d.jobTitle);
  late final _company = TextEditingController(text: d.company);
  late String? _industry = d.industry;
  late String? _experience = d.experience;
  late final List<String> _skills = d.skills.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  // Interests
  late final Set<String> _interests = {...d.interests};
  late final Set<String> _reasons = {...d.reasons};
  late final Map<int, String> _mindset = {...d.mindset};

  // Discovery
  late String _city = d.city;
  late String _locality = d.locality;
  late int _distance = d.distance;
  late int _connectMode = d.connectMode;
  late final Set<String> _availability = {...d.availability};
  late bool _openToConnect = d.openToConnect;
  late bool _nearby = d.nearbyDiscovery;

  @override
  void dispose() {
    for (final c in [_name, _about, _linkedIn, _job, _company]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────
  Future<void> _pick(String title, List<String> options, String? current, void Function(String) set) async {
    FocusScope.of(context).unfocus();
    final v = await showOptionSheet(context, title: title, options: options, selected: current);
    if (v != null) setState(() => set(v));
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showAppDatePicker(
      context,
      initialDate: _dob ?? DateTime(now.year - 28, now.month, now.day),
      firstDate: DateTime(now.year - 90),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _pickSkills() async {
    FocusScope.of(context).unfocus();
    final v = await showSkillPicker(context, selected: _skills, max: _maxSkills);
    if (v != null) {
      setState(() => _skills
        ..clear()
        ..addAll(v));
    }
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1080, imageQuality: 85);
    if (file == null || !mounted) return;
    setState(() => _uploading = true);
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    await saveStep(context, () async => _snack(await ProfileSync.uploadPhoto(bytes, file.name, file.mimeType ?? 'image/jpeg')));
    if (mounted) setState(() => _uploading = false);
  }

  Future<void> _pickCity() async {
    final cities = Meta.instance.cities.map((c) => c.name).toList();
    if (cities.isEmpty) {
      _snack("Cities couldn't be loaded. Check your connection and try again.");
      await Meta.instance.load(force: true);
      return;
    }
    final v = await showOptionSheet(context, title: 'Your city', options: cities, selected: _city.isEmpty ? null : _city);
    if (v != null && v != _city) setState(() {
      _city = v;
      _locality = '';
    });
  }

  Future<void> _pickLocality() async {
    final cityId = Meta.idOf(Meta.instance.cities, _city);
    if (cityId == null) {
      _snack('Choose your city first.');
      return;
    }
    try {
      final list = (await Meta.instance.localities(cityId)).map((l) => l.name).toList();
      if (!mounted) return;
      if (list.isEmpty) {
        _snack('No localities listed for this city yet — you can leave it empty.');
        return;
      }
      final v = await showOptionSheet(context, title: 'Your locality', options: ['None', ...list], selected: _locality.isEmpty ? 'None' : _locality);
      if (v != null) setState(() => _locality = v == 'None' ? '' : v);
    } catch (_) {
      _snack("Localities couldn't be loaded. Check your connection.");
    }
  }

  void _toggleReason(String r) {
    setState(() {
      if (_reasons.contains(r)) {
        _reasons.remove(r);
      } else if (_reasons.length < _maxReasons) {
        _reasons.add(r);
      } else {
        _snack('Pick up to $_maxReasons reasons.');
      }
    });
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  /// Returns the first tab with a problem, plus the message to show.
  (_EditTab, String)? _validate() {
    if (_name.text.trim().isEmpty) return (_EditTab.personal, 'Please enter your full name.');
    if (_job.text.trim().isEmpty) return (_EditTab.work, 'Please enter your job title.');
    if (_industry == null) return (_EditTab.work, 'Please choose your industry.');
    if (_experience == null) return (_EditTab.work, 'Please choose your years of experience.');
    if (_interests.length < _minInterests) return (_EditTab.interests, 'Choose at least $_minInterests interests.');
    if (_reasons.isEmpty) return (_EditTab.interests, "Pick at least one reason you're here.");
    if (_city.isEmpty) return (_EditTab.discovery, 'Please choose your city.');
    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final problem = _validate();
    if (problem != null) {
      setState(() => _tab = problem.$1);
      _snack(problem.$2);
      return;
    }
    setState(() => _saving = true);
    d
      ..fullName = _name.text.trim()
      ..about = _about.text.trim()
      ..linkedIn = _linkedIn.text.trim()
      ..dateOfBirth = _dob
      ..gender = _gender
      ..jobTitle = _job.text.trim()
      ..company = _company.text.trim()
      ..industry = _industry
      ..experience = _experience
      ..skills = _skills.join(', ')
      ..city = _city
      ..locality = _locality
      ..distance = _distance
      ..connectMode = _connectMode
      ..openToConnect = _openToConnect
      ..nearbyDiscovery = _nearby;
    d.interests
      ..clear()
      ..addAll(_interests);
    d.reasons
      ..clear()
      ..addAll(_reasons);
    d.mindset
      ..clear()
      ..addAll(_mindset);
    d.availability
      ..clear()
      ..addAll(_availability.isEmpty ? {'Flexible'} : _availability);
    String? message;
    final ok = await saveStep(context, () async => message = await ProfileSync.saveAll());
    if (!mounted) return;
    if (!ok) {
      setState(() => _saving = false);
      ProfileSync.load().catchError((_) => 0); // put the shared draft back to what the server has
      return;
    }
    _snack(message ?? 'Profile updated.');
    Navigator.of(context).pop(true);
  }

  // ── Build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppTopBar(
          title: 'Edit Profile',
          actions: [AppBarTextAction(label: 'Save', onPressed: _saving ? null : _save)],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: AppSpace.content,
                  children: [
                    const Text('Keep your profile up to date.', style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink)),
                    const SizedBox(height: 4),
                    const Text('Update the details you added while creating your profile.', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.sub)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        for (final t in _EditTab.values) ...[
                          if (t != _EditTab.personal) const SizedBox(width: 6),
                          Expanded(child: _SegmentButton(label: _tabLabels[t]!, selected: _tab == t, onTap: () => setState(() => _tab = t))),
                        ],
                      ],
                    ),
                    const SizedBox(height: 22),
                    ...switch (_tab) {
                      _EditTab.personal => _personal(),
                      _EditTab.work => _work(),
                      _EditTab.interests => _interestsTab(),
                      _EditTab.discovery => _discovery(),
                    },
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.x3, AppSpace.screen, AppSpace.x3),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
                child: Row(
                  children: [
                    SizedBox(
                      width: 130,
                      child: _OutlineButton(label: 'Cancel', onTap: () => Navigator.of(context).maybePop()),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: PrimaryButton(label: 'Save Changes', height: 52, radius: 10, loading: _saving, onPressed: _save)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Personal ─────────────────────────────────────────────────────
  List<Widget> _personal() {
    final initials = _name.text.trim().split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();
    return [
      Center(
        child: GestureDetector(
          onTap: _uploading ? null : _pickPhoto,
          child: Column(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      alignment: Alignment.center,
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(color: AppColors.badgeFill, shape: BoxShape.circle),
                      child: _uploading
                          ? const CircularProgressIndicator()
                          : d.photoUrl != null
                              ? Image.network(d.photoUrl!, width: 96, height: 96, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Text(initials, style: const TextStyle(fontFamily: 'Inter', fontSize: 30, fontWeight: FontWeight.w600, color: AppColors.blue)))
                              : Text(initials, style: const TextStyle(fontFamily: 'Inter', fontSize: 30, fontWeight: FontWeight.w600, color: AppColors.blue)),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: AppGradients.setup,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 3),
                        ),
                        child: const AppIcon(AppIcons.camera, size: 15, color: AppColors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(d.photoUrl == null ? 'Add photo' : 'Change photo', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.blue)),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      AppTextField(
        label: 'Full name *',
        hint: 'Enter your full name',
        controller: _name,
        textCapitalization: TextCapitalization.words,
        autofillHints: const [AutofillHints.name],
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 18),
      AppTextField(
        label: 'About',
        labelSuffix: '(Optional)',
        hint: 'A line or two about what you do',
        controller: _about,
        textCapitalization: TextCapitalization.sentences,
      ),
      const SizedBox(height: 18),
      AppTextField(
        label: 'Date of birth',
        hint: 'DD / MM / YYYY',
        value: _dob == null ? null : formatDate(_dob!),
        leadingIcon: AppIcons.calendar,
        trailingIcon: AppIcons.chevronDown,
        helper: 'Only visible to you.',
        onTap: _pickDob,
      ),
      const SizedBox(height: 18),
      AppTextField(
        label: 'Gender',
        labelSuffix: '(Optional)',
        hint: 'Select',
        value: _gender,
        trailingIcon: AppIcons.chevronDown,
        onTap: () => _pick('Gender', kGenders, _gender, (v) => _gender = v),
      ),
      const SizedBox(height: 18),
      AppTextField(
        label: 'LinkedIn URL',
        labelSuffix: '(Optional)',
        hint: 'https://linkedin.com/in/username',
        controller: _linkedIn,
        keyboardType: TextInputType.url,
      ),
    ];
  }

  // ── Work ─────────────────────────────────────────────────────────
  List<Widget> _work() => [
        AppTextField(
          label: 'Job title *',
          hint: 'e.g. Product Designer',
          controller: _job,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.jobTitle],
        ),
        const SizedBox(height: 18),
        AppTextField(
          label: 'Industry *',
          hint: 'Select your industry',
          value: _industry,
          trailingIcon: AppIcons.chevronDown,
          onTap: () => _pick('Industry', kIndustries, _industry, (v) => _industry = v),
        ),
        const SizedBox(height: 18),
        AppTextField(
          label: 'Company or organisation',
          labelSuffix: '(Optional)',
          hint: 'Enter company name',
          controller: _company,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.organizationName],
        ),
        const SizedBox(height: 18),
        AppTextField(
          label: 'Years of experience *',
          hint: 'Select',
          value: _experience,
          trailingIcon: AppIcons.chevronDown,
          onTap: () => _pick('Years of experience', kExperience, _experience, (v) => _experience = v),
        ),
        const SizedBox(height: 18),
        FieldLabel('Skills', suffix: '(Up to $_maxSkills)'),
        const SizedBox(height: 10),
        if (_skills.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _skills)
                _RemovableChip(label: s, onRemove: () => setState(() => _skills.remove(s))),
            ],
          ),
          const SizedBox(height: 10),
        ],
        GestureDetector(
          onTap: _pickSkills,
          child: Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.badgeFill, borderRadius: BorderRadius.circular(8)),
            child: Text(
              _skills.isEmpty ? 'Choose skills' : 'Edit skills (${_skills.length}/$_maxSkills)',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.blue),
            ),
          ),
        ),
      ];

  // ── Interests ────────────────────────────────────────────────────
  List<Widget> _interestsTab() {
    final enough = _interests.length >= _minInterests;
    return [
      const _SectionHead('Your interests', 'Choose at least 3 interests. You can change them anytime.'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final i in kInterests)
            _OutlineChip(
              label: i,
              selected: _interests.contains(i),
              showCheck: true,
              onTap: () => setState(() => _interests.contains(i) ? _interests.remove(i) : _interests.add(i)),
            ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Text(
            '${_interests.length} selected',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: enough ? AppColors.blue : AppColors.error),
          ),
          const Spacer(),
          const Text('Minimum 3 required', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.sub)),
        ],
      ),
      const _Divider(),
      const _SectionHead("I'm here to…", 'Pick up to 3 reasons. They shape who we suggest to you.'),
      for (final r in kReasons)
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _toggleReason(r.title),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
                AppCheckbox(checked: _reasons.contains(r.title), size: 20, look: CheckboxLook.filled, radius: 5, borderColor: AppColors.line, borderWidth: 1.5),
                const SizedBox(width: 12),
                Expanded(child: Text(r.title, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppColors.ink))),
              ],
            ),
          ),
        ),
      const _Divider(),
      const _SectionHead('Your mindset', 'Optional · Helps us match you with like-minded people.'),
      for (var q = 0; q < kMindsetQuestions.length; q++) ...[
        if (q > 0) const SizedBox(height: 18),
        Text(
          '${(q + 1).toString().padLeft(2, '0')}  ${kMindsetQuestions[q].text}',
          style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in kMindsetQuestions[q].options)
              _OutlineChip(label: o, selected: _mindset[q] == o, onTap: () => setState(() => _mindset[q] == o ? _mindset.remove(q) : _mindset[q] = o)),
          ],
        ),
      ],
    ];
  }

  // ── Discovery ────────────────────────────────────────────────────
  List<Widget> _discovery() => [
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(AppIcons.pin, size: 20, color: AppColors.blue),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Location & Discovery', style: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  SizedBox(height: 4),
                  Text('Choose where and how professionals can discover you.', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.sub)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        AppTextField(
          label: 'City *',
          hint: 'Select your city',
          value: _city.isEmpty ? null : _city,
          trailingIcon: AppIcons.chevronDown,
          onTap: _pickCity,
        ),
        const SizedBox(height: 18),
        AppTextField(
          label: 'Neighbourhood or locality',
          labelSuffix: '(Optional)',
          hint: _city.isEmpty ? 'Choose your city first' : 'Select your area or locality',
          value: _locality.isEmpty ? null : _locality,
          trailingIcon: AppIcons.chevronDown,
          onTap: _pickLocality,
        ),
        const SizedBox(height: 18),
        const Text('Discovery radius', style: AppText.fieldLabel),
        const SizedBox(height: 10),
        SegmentedChoice(options: kDistances, selectedIndex: _distance, onChanged: (i) => setState(() => _distance = i)),
        const SizedBox(height: 18),
        const Text('How would you like to connect?', style: AppText.fieldLabel),
        const SizedBox(height: 10),
        SegmentedChoice(options: kConnectModes, selectedIndex: _connectMode, onChanged: (i) => setState(() => _connectMode = i)),
        const SizedBox(height: 18),
        const Text('When are you usually available?', style: AppText.fieldLabel),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final a in kAvailability)
              _OutlineChip(
                label: a,
                selected: _availability.contains(a),
                showCheck: true,
                onTap: () => setState(() => _availability.contains(a) ? _availability.remove(a) : _availability.add(a)),
              ),
          ],
        ),
        const _Divider(),
        const _SectionHead('Discovery preferences'),
        _ToggleRow(
          title: 'Open to connect',
          body: "Let other professionals know you're available for new connections.",
          value: _openToConnect,
          onChanged: (v) => setState(() => _openToConnect = v),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.line),
        _ToggleRow(
          title: 'Visible in nearby discovery',
          body: 'Allow your profile to appear in nearby recommendations.',
          value: _nearby,
          onChanged: (v) => setState(() => _nearby = v),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.panelFill, borderRadius: BorderRadius.circular(10)),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(AppIcons.shieldCheck, size: 18, color: AppColors.sub),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your privacy matters', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                    SizedBox(height: 4),
                    Text(
                      'Your exact location and search radius stay private. Others only see your approximate area.',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, height: 17 / 12, color: AppColors.sub),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ];
}

// ── Building blocks ────────────────────────────────────────────────────

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? AppGradients.setup : null,
            color: selected ? null : AppColors.inputFill,
            borderRadius: BorderRadius.circular(8),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColors.white : AppColors.sub,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead(this.title, [this.subtitle]);
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, height: 18 / 13, color: AppColors.sub)),
          ],
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1, thickness: 1, color: AppColors.line));
}

/// Outline chip — selected = light-blue fill + blue border (+ optional tick).
class _OutlineChip extends StatelessWidget {
  const _OutlineChip({required this.label, required this.selected, required this.onTap, this.showCheck = false});
  final String label;
  final bool selected;
  final bool showCheck;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.selectedFill : AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? AppColors.blue : AppColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showCheck && selected) ...[const AppIcon(AppIcons.check, size: 14, color: AppColors.blue), const SizedBox(width: 6)],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                  color: selected ? AppColors.blue : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemovableChip extends StatelessWidget {
  const _RemovableChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.only(left: 12, right: 6),
      decoration: BoxDecoration(color: AppColors.badgeFill, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.blue)),
          Semantics(
            button: true,
            label: 'Remove $label',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onRemove,
              child: const Padding(padding: EdgeInsets.all(6), child: AppIcon(AppIcons.close, size: 14, color: AppColors.blue)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.title, required this.body, required this.value, required this.onChanged});
  final String title;
  final String body;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, height: 18 / 13, color: AppColors.sub)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.line)),
          child: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
        ),
      ),
    );
  }
}
