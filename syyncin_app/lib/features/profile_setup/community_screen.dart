import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import 'widgets/pickers.dart';
import '../../data/profile_sync.dart';
import 'widgets/step_save.dart';
import '../../data/meta.dart';

/// Step 5 of 5 — Your community (location & connection preferences).
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final d = SetupDraft.instance;

  static const _modes = ['In person', 'Online', 'Both'];
  static const _distances = ['5 km', '10 km', '25 km', '50+ km'];
  static const _availability = ['Weekdays', 'Weekends', 'Evenings', 'Flexible'];

  /// City from the admin-managed list (GET /meta/cities).
  Future<void> _pickCity() async {
    final cities = Meta.instance.cities.map((c) => c.name).toList();
    if (cities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cities couldn't be loaded. Check your connection.")));
      await Meta.instance.load(force: true);
      return;
    }
    final v = await showOptionSheet(context, title: 'Your city', options: cities, selected: d.city.isEmpty ? null : d.city);
    if (v != null && v != d.city) setState(() {
      d.city = v;
      d.locality = '';
    });
  }

  /// Locality of the chosen city (GET /meta/localities).
  Future<void> _pickLocality() async {
    final cityId = Meta.idOf(Meta.instance.cities, d.city);
    if (cityId == null) return;
    try {
      final list = (await Meta.instance.localities(cityId)).map((l) => l.name).toList();
      if (!mounted) return;
      if (list.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No localities listed for this city yet — you can skip this.')));
        return;
      }
      final v = await showOptionSheet(context, title: 'Your locality', options: ['Skip', ...list], selected: d.locality.isEmpty ? 'Skip' : d.locality);
      if (v != null) setState(() => d.locality = v == 'Skip' ? '' : v);
    } catch (_) {}
  }

  bool _saving = false;

  Future<void> _continue() async {
    setState(() => _saving = true);
    final ok = await saveStep(context, ProfileSync.saveCommunity);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pushNamed(Routes.selfie);
  }

  Widget _question(String label, Widget child) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Text(label, style: AppText.fieldLabel), const SizedBox(height: 10), child],
      );

  @override
  Widget build(BuildContext context) {
    return SetupScaffold(
      header: const StepHeader(step: 5),
      stickyCta: false,
      gap: 18,
      cta: PrimaryButton(
        label: 'Continue',
        showArrow: true,
        enabled: d.city.trim().isNotEmpty,
        loading: _saving,
        onPressed: _continue,
      ),
      children: [
        const SectionHeading(
          eyebrow: 'Your community',
          title: 'Who would you like to meet?',
          subtitle: 'Set your location and connection preferences to make discovery more relevant.',
        ),
        AppTextField(
          label: 'City *',
          hint: 'Select your city',
          value: d.city.isEmpty ? null : d.city,
          trailingIcon: AppIcons.chevronDown,
          labelGap: 8,
          onTap: _pickCity,
        ),
        AppTextField(
          label: 'Neighbourhood or locality (optional)',
          hint: d.city.isEmpty ? 'Choose your city first' : 'Select your area or locality',
          value: d.locality.isEmpty ? null : d.locality,
          trailingIcon: AppIcons.chevronDown,
          labelGap: 8,
          onTap: _pickLocality,
        ),
        const DividerLine(),
        _question(
          'How would you like to connect?',
          SegmentedChoice(options: _modes, selectedIndex: d.connectMode, onChanged: (i) => setState(() => d.connectMode = i)),
        ),
        _question(
          'Preferred discovery distance',
          SegmentedChoice(options: _distances, selectedIndex: d.distance, onChanged: (i) => setState(() => d.distance = i)),
        ),
        _question(
          'When are you usually available?',
          OptionGrid(
            options: _availability,
            indicator: OptionIndicator.checkbox,
            isSelected: d.availability.contains,
            onTap: (o) => setState(() => d.availability.contains(o) ? d.availability.remove(o) : d.availability.add(o)),
          ),
        ),
        const DividerLine(),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nearby discovery', style: AppText.fieldLabel),
                  const SizedBox(height: 4),
                  Text('Let nearby professionals discover your profile.', style: AppText.helper.copyWith(height: null)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AppToggle(value: d.nearbyDiscovery, onChanged: (v) => setState(() => d.nearbyDiscovery = v)),
          ],
        ),
        const Text('You can update these preferences anytime.', style: AppText.helper, textAlign: TextAlign.center),
      ],
    );
  }
}
