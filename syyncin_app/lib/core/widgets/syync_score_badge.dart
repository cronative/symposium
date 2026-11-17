import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../icons/app_icons.dart';
import '../theme/app_colors.dart';
import 'buttons.dart';

/// SyyncScore brand colour (#0868E8) and the light panel behind it.
const _brand = Color(0xFF0868E8);
const _panel = Color(0xFFEFF5FE);
const _iconBox = Color(0xFFF1F4F9);
const _muted = Color(0xFF6577AB);
const _mutedLine = Color(0xFFE1E7F2);
const _track = Color(0xFFDCE7FA);
const _privacy = Color(0xFF0A8F6E);

/// Factors shown in the "How is your match calculated?" list (KYN strategy).
const _factors = [
  ('skills', AppIcons.briefcase, 'Skills & Expertise', 'We compare professional skills and expertise to identify areas of similarity or useful collaboration.'),
  ('intent', AppIcons.target, 'Connection Goals', 'We look at whether your networking, mentoring or collaboration goals are compatible.'),
  ('interests', AppIcons.heart, 'Shared Interests', 'We identify common professional topics and interests that could help start a conversation.'),
  ('location', AppIcons.pin, 'Location', 'We consider city and preferred discovery distance without revealing exact locations.'),
  ('professional', AppIcons.building, 'Professional Relevance', 'We consider related job roles, industries and professional experience.'),
];

String _scoreText(SyyncMatch? m, {bool loading = false, bool error = false}) {
  if (loading) return 'Calculating…';
  if (error || m == null) return 'Unavailable';
  if (m.insufficient) return 'Not enough info';
  return '${m.score}% Match';
}

bool _hasScore(SyyncMatch? m) => m != null && !m.insufficient;

String _semantics(SyyncMatch? m, {bool loading = false, bool error = false}) {
  if (loading) return 'Calculating SyyncMatch score';
  if (error || m == null) return 'SyyncMatch score unavailable';
  if (m.insufficient) return 'SyyncMatch: not enough profile information yet';
  return 'SyyncMatch ${m.score} percent, ${m.label}${m.reasons.isEmpty ? '' : '. ${m.reasons.join(', ')}'}';
}

/// KYN card / profile strip: 👥 SyyncMatch ······ 92% Match ⓘ — tap for the explanation sheet.
class SyyncMatchStrip extends StatelessWidget {
  const SyyncMatchStrip({super.key, required this.match, this.name, this.loading = false, this.error = false});

  final SyyncMatch? match;

  /// The other member's first name ("Your compatibility with Rahul").
  final String? name;
  final bool loading;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scored = _hasScore(match) && !loading && !error;
    final fg = scored && match!.level != 'low' ? _brand : _muted;
    return Semantics(
      button: !loading,
      label: '${_semantics(match, loading: loading, error: error)}. Tap for details.',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: loading ? null : () => showSyyncScoreInfo(context, match, name: name),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(5)),
          child: Row(
            children: [
              const AppIcon(AppIcons.users, size: 18, color: _brand),
              const SizedBox(width: 10),
              const Text('SyyncMatch', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink)),
              const Spacer(),
              if (loading) ...[
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.6, color: _muted)),
                const SizedBox(width: 8),
              ],
              Text(_scoreText(match, loading: loading, error: error),
                  style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w500, color: fg)),
              if (!loading) ...[
                const SizedBox(width: 8),
                Icon(Icons.info_outline_rounded, size: 19, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact pill — "82% Match · Strong Match" (Seek results, lists). Same states as the strip.
class SyyncScoreBadge extends StatelessWidget {
  const SyyncScoreBadge({super.key, required this.match, this.name, this.loading = false, this.error = false, this.showInfo = false, this.showLevel = true});

  final SyyncMatch? match;
  final String? name;
  final bool loading;
  final bool error;
  final bool showInfo;
  final bool showLevel;

  @override
  Widget build(BuildContext context) {
    final m = match;
    final scored = _hasScore(m) && !loading && !error;
    final strong = scored && m!.level != 'low';
    final text = scored && showLevel && m!.label.isNotEmpty ? '${m.score}% Match · ${m.label}' : _scoreText(m, loading: loading, error: error);
    final fg = strong ? _brand : _muted;
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: strong ? _panel : AppColors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: strong ? _brand.withValues(alpha: 0.3) : _mutedLine),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: fg))),
          if (showInfo && !loading) ...[const SizedBox(width: 4), Icon(Icons.info_outline_rounded, size: 14, color: fg)],
        ],
      ),
    );
    return Semantics(
      label: _semantics(m, loading: loading, error: error),
      button: showInfo && !loading,
      excludeSemantics: true,
      child: showInfo && !loading ? GestureDetector(onTap: () => showSyyncScoreInfo(context, m, name: name), child: badge) : badge,
    );
  }
}

/// "Shared Skills · Compatible Goals · Same City".
class SyyncReasons extends StatelessWidget {
  const SyyncReasons({super.key, required this.match, this.maxLines = 1, this.center = false});
  final SyyncMatch? match;
  final int maxLines;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final m = match;
    if (!_hasScore(m) || m!.reasons.isEmpty) return const SizedBox.shrink();
    return Text(
      m.reasons.join(' · '),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: _muted),
    );
  }
}

/// SyyncMatch explanation sheet (opened from the ⓘ).
Future<void> showSyyncScoreInfo(BuildContext context, SyyncMatch? m, {String? name}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.white,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (context) => _InfoSheet(match: m, name: name),
  );
}

class _InfoSheet extends StatefulWidget {
  const _InfoSheet({required this.match, this.name});
  final SyyncMatch? match;
  final String? name;

  @override
  State<_InfoSheet> createState() => _InfoSheetState();
}

class _InfoSheetState extends State<_InfoSheet> {
  bool _open = true;

  static const _body = TextStyle(fontFamily: 'Inter', fontSize: 14, height: 21 / 14, color: Color(0xFF3D4A6B));
  static const _small = TextStyle(fontFamily: 'Inter', fontSize: 13, height: 19 / 13, color: _muted);

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final who = (widget.name ?? '').trim().isEmpty ? 'this professional' : widget.name!.trim();
    final scored = _hasScore(m);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ─────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(8)),
                  child: const AppIcon(AppIcons.users, size: 22, color: _brand),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SyyncMatch', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      SizedBox(height: 2),
                      Text('Smarter professional connections', style: _small),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const AppIcon(AppIcons.close, size: 20, color: _muted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'SyyncMatch helps you discover professionals whose skills, interests and networking goals align with yours, making professional discovery more relevant.',
              style: _body,
            ),
            const SizedBox(height: 16),

            // ── Your compatibility ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('YOUR COMPATIBILITY WITH ${who.toUpperCase()}',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, letterSpacing: 0.4, fontWeight: FontWeight.w500, color: _muted)),
                  const SizedBox(height: 8),
                  if (scored) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text('${m!.score}% Match',
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w700, color: _brand)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(m.label, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: _brand)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: m.score / 100, minHeight: 8, backgroundColor: _track, color: _brand),
                    ),
                    if (m.reasons.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final r in m.reasons)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(5), border: Border.all(color: _brand.withValues(alpha: 0.25))),
                              child: Text(r, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: _brand)),
                            ),
                        ],
                      ),
                    ],
                  ] else
                    Text(
                      m == null
                          ? 'A match score isn’t available right now.'
                          : 'There isn’t enough profile information yet to calculate a fair score. Scores appear once skills, goals, interests and location are filled in.',
                      style: _body,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── How it's calculated ────────────────────────────
            const Text('How is your match calculated?', style: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 12),
            for (final (key, icon, title, text) in _factors)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: _iconBox, borderRadius: BorderRadius.circular(8)),
                      child: AppIcon(icon, size: 20, color: _brand),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink))),
                              if (scored && m!.breakdown.containsKey(key))
                                Text('+${m.breakdown[key]}', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: _brand)),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(text, style: _small),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // ── What does the percentage mean? ─────────────────
            Container(
              decoration: BoxDecoration(color: const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _open = !_open),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text('What does the percentage mean?', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
                          ),
                          AnimatedRotation(
                            turns: _open ? 0.5 : 0,
                            duration: const Duration(milliseconds: 160),
                            child: const AppIcon(AppIcons.chevronDown, size: 20, color: _muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_open)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Your SyyncMatch percentage shows how closely another professional's profile aligns with your skills, interests, goals and discovery preferences.",
                            style: _body,
                          ),
                          const SizedBox(height: 10),
                          Text.rich(
                            TextSpan(style: _body, children: [
                              const TextSpan(text: 'For example, a '),
                              TextSpan(text: '${scored ? m!.score : 92}% Match', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                              TextSpan(
                                text: ' means you have ${scored && m!.score < 70 ? 'some' : 'a high'} estimated level of professional compatibility with ${scored ? who : 'that person'}. '
                                    'You may share relevant skills, have compatible connection goals or work in related fields.',
                              ),
                            ]),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'A higher score suggests stronger alignment, but it does not mean the person will necessarily accept your request or that a successful connection is guaranteed.',
                            style: _body,
                          ),
                          const SizedBox(height: 10),
                          const Text('85+ Excellent · 70+ Strong · 50+ Potential · below 50 Low. Pro membership never changes a score.', style: _small),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIcon(AppIcons.shieldCheck, size: 18, color: _privacy),
                SizedBox(width: 8),
                Expanded(child: Text('Your private information and exact location are not shown to other professionals.', style: _small)),
              ],
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Got it', onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}
