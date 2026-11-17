import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import 'widgets/pickers.dart';
import '../../data/profile_sync.dart';
import 'widgets/step_save.dart';
import '../../data/meta.dart';

/// Lists come from the API (admin-managed) — see [Meta].
List<String> get kInterests => Meta.instance.interestNames;

class Reason {
  const Reason(this.icon, this.title, this.subtitle);
  final String icon;
  final String title;
  final String subtitle;
}

const _reasonIcons = {
  'users': AppIcons.users,
  'bulb': AppIcons.bulb,
  'handshake': AppIcons.handshake,
  'graduation': AppIcons.graduation,
  'trend_up': AppIcons.trendUp,
  'coffee': AppIcons.coffee,
};

List<Reason> get kReasons => [
      for (final r in Meta.instance.reasons) Reason(_reasonIcons[r.icon] ?? AppIcons.users, r.name, r.subtitle ?? ''),
    ];

/// Step 3 of 5 — Interests + "I'm here to…" reasons.
/// Continue needs ≥ 3 interests and 1–3 reasons.
class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  final d = SetupDraft.instance;
  static const _minInterests = 3;
  static const _maxReasons = 3;
  bool _saving = false;

  Future<void> _continue() async {
    setState(() => _saving = true);
    final ok = await saveStep(context, ProfileSync.saveInterests);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pushNamed(Routes.mindset);
  }

  void _toggleInterest(String v) => setState(() => d.interests.contains(v) ? d.interests.remove(v) : d.interests.add(v));

  void _toggleReason(String v) {
    setState(() {
      if (d.reasons.contains(v)) {
        d.reasons.remove(v);
      } else if (d.reasons.length < _maxReasons) {
        d.reasons.add(v);
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('You can choose up to 3 reasons.')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final valid = d.interests.length >= _minInterests && d.reasons.isNotEmpty;
    return SetupScaffold(
      header: const StepHeader(step: 3),
      stickyCta: false,
      gap: 20,
      cta: PrimaryButton(
        label: 'Continue',
        showArrow: true,
        enabled: valid,
        loading: _saving,
        onPressed: _continue,
      ),
      children: [
        const SectionHeading(
          eyebrow: 'Your interests',
          title: 'What brings you here?',
          subtitle: 'Choose at least 3 interests to help us find people, events and opportunities relevant to you.',
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitleRow(title: 'Your interests', trailing: '${d.interests.length} selected · Min. $_minInterests'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final i in kInterests)
                  SelectChip(label: i, selected: d.interests.contains(i), onTap: () => _toggleInterest(i)),
              ],
            ),
          ],
        ),
        const DividerLine(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitleRow(
              title: "I'm here to...",
              trailing: '${d.reasons.length} selected',
              helper: 'Choose up to 3 reasons.',
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < kReasons.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              ReasonCard(
                icon: kReasons[i].icon,
                title: kReasons[i].title,
                subtitle: kReasons[i].subtitle,
                selected: d.reasons.contains(kReasons[i].title),
                onTap: () => _toggleReason(kReasons[i].title),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
