import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import 'widgets/pickers.dart';
import '../../data/profile_sync.dart';
import 'widgets/step_save.dart';
import '../../data/meta.dart';

class MindsetQuestion {
  const MindsetQuestion(this.text, this.options);
  final String text;
  final List<String> options;
}

/// Questions come from the API (admin-managed) — see [Meta].
List<MindsetQuestion> get kMindsetQuestions => [
      for (final q in Meta.instance.questions) MindsetQuestion(q.text, q.options.map((o) => o.name).toList()),
    ];

/// Step 4 of 5 — Your mindset (5 single-choice questions).
class MindsetScreen extends StatefulWidget {
  const MindsetScreen({super.key});

  @override
  State<MindsetScreen> createState() => _MindsetScreenState();
}

class _MindsetScreenState extends State<MindsetScreen> {
  final d = SetupDraft.instance;
  bool _saving = false;

  Future<void> _continue() async {
    setState(() => _saving = true);
    final ok = await saveStep(context, ProfileSync.saveMindset);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pushNamed(Routes.community);
  }

  @override
  Widget build(BuildContext context) {
    final answered = d.mindset.length;
    final blocks = <Widget>[];
    for (var q = 0; q < kMindsetQuestions.length; q++) {
      if (q > 0) blocks.add(const DividerLine());
      blocks.add(Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NumberBadge((q + 1).toString().padLeft(2, '0')),
              const SizedBox(width: 10),
              Expanded(child: Text(kMindsetQuestions[q].text, style: AppText.sectionTitle)),
            ],
          ),
          const SizedBox(height: 12),
          OptionGrid(
            options: kMindsetQuestions[q].options,
            isSelected: (o) => d.mindset[q] == o,
            // Tap again to clear — every question is optional.
            onTap: (o) => setState(() => d.mindset[q] == o ? d.mindset.remove(q) : d.mindset[q] = o),
          ),
        ],
      ));
    }

    return SetupScaffold(
      header: const StepHeader(step: 4),
      stickyCta: false,
      gap: 20,
      cta: PrimaryButton(
        label: 'Continue',
        showArrow: true,
        loading: _saving,
        onPressed: _continue,
      ),
      children: [
        const SectionHeading(
          eyebrow: 'Your mindset',
          title: "Let's get to know you better.",
          subtitle: 'Tell us how you think, work and connect, so we can help you find the right people. All questions are optional.',
        ),
        ...blocks,
        Row(
          children: [
            const Expanded(child: Text('Optional · No right or wrong answers.', style: AppText.helper)),
            Text('$answered/${kMindsetQuestions.length} answered', style: AppText.counter.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
