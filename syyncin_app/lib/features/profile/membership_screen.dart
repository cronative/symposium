import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';

// Design colours (Figma 42) not in AppColors yet.
const _cardLine = Color(0xFFE4E8F1);
const _toggleFill = Color(0xFFF1F3F7);
const _proFill = Color(0xFFF7FAFF);
const _tagBlueFill = Color(0xFFEAF2FE);
const _saveFill = Color(0xFFE3F8F2);
const _saveText = Color(0xFF0A8F6E);
const _featureText = Color(0xFF3D4A6B);

/// Figma 42 / 42b (v3) — Membership Plans, opened from My Profile › Membership.
/// Monthly / Yearly toggle switches the Pro price. Payments aren't live yet,
/// so "Upgrade to Pro" explains that and everyone stays on Free.
class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  bool _yearly = false;

  static const _freeFeatures = [
    '10 connection requests per week',
    'Unlimited chats with connections',
    'Join meetups & host 1 per month',
  ];
  static const _proFeatures = [
    '50 connection requests per week',
    'Advanced professional filters',
    'Save up to 200 professionals',
    'Host 8 meetups per month',
    'Up to 25 participants per meetup',
  ];

  Future<void> _upgrade() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.x4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _CrownBadge(size: 56),
              const SizedBox(height: 14),
              Text(
                'SyyncIn Pro · ${_yearly ? 'Yearly' : 'Monthly'}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              const Text(
                "Payments are launching soon. You'll be able to upgrade right here — until then, enjoy everything in SyyncIn Free.",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Inter', fontSize: 14, height: 20 / 14, color: AppColors.sub),
              ),
              const SizedBox(height: 20),
              PrimaryButton(label: 'Got it', onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const AppTopBar(title: 'Membership Plans'),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.x6, AppSpace.screen, AppSpace.x8),
          children: [
            // ── Hero ─────────────────────────────────────────────
            const Center(child: _CrownBadge(size: 72)),
            const SizedBox(height: 10),
            const Text(
              'Make more meaningful connections.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            const SizedBox(height: 10),
            const Text(
              "Start free. Upgrade when you're ready to grow your professional network.",
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', fontSize: 14, height: 20 / 14, color: AppColors.sub),
            ),
            const SizedBox(height: 16),

            // ── Billing toggle ───────────────────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: _toggleFill, borderRadius: BorderRadius.circular(22)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Segment(label: 'Monthly', selected: !_yearly, onTap: () => setState(() => _yearly = false)),
                    const SizedBox(width: 4),
                    _Segment(
                      label: 'Yearly',
                      selected: _yearly,
                      onTap: () => setState(() => _yearly = true),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: _saveFill, borderRadius: BorderRadius.circular(6)),
                        child: const Text('Save 17%', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: _saveText)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Free ─────────────────────────────────────────────
            _PlanCard(
              name: 'SyyncIn Free',
              tag: 'CURRENT PLAN',
              price: '₹0',
              period: 'forever',
              features: _freeFeatures,
              pro: false,
            ),
            const SizedBox(height: 16),

            // ── Pro ──────────────────────────────────────────────
            _PlanCard(
              name: 'SyyncIn Pro',
              tag: 'MORE NETWORKING POWER',
              price: _yearly ? '₹1,990' : '₹199',
              period: _yearly ? '/year' : '/month',
              note: _yearly ? 'Just ₹166/month · 2 months free' : null,
              features: _proFeatures,
              pro: true,
              cta: PrimaryButton(
                label: _yearly ? 'Upgrade to Pro · Yearly' : 'Upgrade to Pro',
                height: 49,
                radius: 11,
                onPressed: _upgrade,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Core messaging, privacy controls and selfie verification stay free.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, height: 18 / 13, color: AppColors.sub),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(51),
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: _cardLine),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: const Text('Continue with Free'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrownBadge extends StatelessWidget {
  const _CrownBadge({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: _tagBlueFill, shape: BoxShape.circle),
        child: AppIcon(AppIcons.crown, size: size * 34 / 72, color: AppColors.blue),
      );
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.selected, required this.onTap, this.trailing});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: selected ? const [BoxShadow(color: Color(0x140A1740), blurRadius: 3, offset: Offset(0, 1))] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColors.ink : AppColors.sub,
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 6), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.name,
    required this.tag,
    required this.price,
    required this.period,
    required this.features,
    required this.pro,
    this.note,
    this.cta,
  });

  final String name;
  final String tag;
  final String price;
  final String period;
  final String? note;
  final List<String> features;
  final bool pro;
  final Widget? cta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pro ? _proFill : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: pro ? AppColors.blue : _cardLine, width: pro ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name, style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w600, color: pro ? AppColors.blue : AppColors.ink)),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: pro ? _tagBlueFill : _toggleFill, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    tag,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, letterSpacing: 0.4, fontWeight: FontWeight.w600, color: pro ? AppColors.blue : AppColors.sub),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(price, style: const TextStyle(fontFamily: 'Inter', fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(width: 6),
              Text(period, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.sub)),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: 12),
            Text(note!, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: _saveText)),
          ],
          const SizedBox(height: 12),
          for (var i = 0; i < features.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              children: [
                AppIcon(pro ? AppIcons.checkCircle : AppIcons.check, size: 18, color: pro ? AppColors.blue : _saveText),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(features[i], style: const TextStyle(fontFamily: 'Inter', fontSize: 15, height: 22 / 15, color: _featureText)),
                ),
              ],
            ),
          ],
          if (cta != null) ...[const SizedBox(height: 12), cta!],
        ],
      ),
    );
  }
}
