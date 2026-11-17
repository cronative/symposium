import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/widgets.dart';
import '../../data/api.dart';
import '../chat/chat_screen.dart';
import '../profile/widgets/profile_blocks.dart';
import 'connect_request_screen.dart';
import 'models/discovery_state.dart';
import 'models/person.dart';
import 'widgets/person_card.dart';

enum _Tab { overview, professional, interests }

const _tabLabels = {_Tab.overview: 'Overview', _Tab.professional: 'Professional', _Tab.interests: 'Interests'};

/// Another member's profile (GET /users/:id) — same layout as My Profile:
/// hero, then Overview · Professional · Interests tabs, with the connect / message action pinned below.
class PersonProfileScreen extends StatefulWidget {
  const PersonProfileScreen({super.key, required this.userId});
  final int userId;

  @override
  State<PersonProfileScreen> createState() => _PersonProfileScreenState();
}

class _PersonProfileScreenState extends State<PersonProfileScreen> {
  PersonDetail? _p;
  ApiException? _error;
  bool _busy = false;
  _Tab _tab = _Tab.overview;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await DiscoverApi.person(widget.userId);
      if (mounted) setState(() {
      _p = p;
      _error = null;
    });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _toggleSave() async {
    final p = _p!;
    final next = !p.isSaved;
    setState(() => p.isSaved = next);
    try {
      _snack(await DiscoverApi.setSaved(p.id, next));
    } on ApiException catch (e) {
      setState(() => p.isSaved = !next);
      _snack(e.message);
    }
  }

  Future<void> _connect() async {
    await openConnectFlow(context, _p!);
    _load();
  }

  Future<void> _accept() async {
    final requestId = _p!.connection.requestId;
    if (requestId == null) return;
    setState(() => _busy = true);
    try {
      _snack(await NetworkApi.accept(requestId));
      await _load();
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _cta(PersonDetail p) {
    return switch (p.connection.status) {
      'connected' => PrimaryButton(
          label: 'Message',
          leading: const AppIcon(AppIcons.chat, size: 20, color: AppColors.white),
          onPressed: () => openChat(context, p),
        ),
      'pending_sent' => OutlineActionButton(
          label: 'Request sent · View in Inbox',
          icon: AppIcons.check,
          height: 56,
          radius: 11,
          muted: true,
          onTap: () {
            AppNav.openInbox(InboxSegment.requests, sent: true);
            Navigator.of(context).popUntil((r) => r.isFirst || r.settings.name == '/home');
          },
        ),
      'pending_received' => PrimaryButton(label: 'Accept Request', loading: _busy, onPressed: _accept),
      _ => p.openToConnect
          ? PrimaryButton(
              label: 'Send Connection Request',
              leading: const AppIcon(AppIcons.userPlus, size: 20, color: AppColors.white),
              onPressed: _connect,
            )
          : const OutlineActionButton(label: 'Not accepting new connections', height: 56, radius: 11, muted: true),
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppTopBar(
        title: 'Professional Profile',
        actions: [
          if (p != null)
            AppBarIconAction(
              icon: p.isSaved ? AppIcons.bookmarkFilled : AppIcons.bookmark,
              tooltip: p.isSaved ? 'Remove bookmark' : 'Bookmark',
              color: AppColors.blue,
              onPressed: _toggleSave,
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: p == null
                  ? Center(
                      child: _error == null
                          ? const CircularProgressIndicator()
                          : Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_error!.message, textAlign: TextAlign.center, style: AppText.setupSubtitle),
                                  const SizedBox(height: 16),
                                  SizedBox(width: 160, child: PrimaryButton(label: 'Try again', height: 44, radius: 8, onPressed: _load)),
                                ],
                              ),
                            ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.x5, AppSpace.screen, AppSpace.x4),
                        children: [
                          ..._hero(p),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              for (final t in _Tab.values) ...[
                                if (t != _Tab.overview) const SizedBox(width: 8),
                                Expanded(child: ProfileSegmentButton(label: _tabLabels[t]!, selected: _tab == t, onTap: () => setState(() => _tab = t))),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: KeyedSubtree(
                              key: ValueKey(_tab),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: switch (_tab) {
                                  _Tab.overview => _overview(p),
                                  _Tab.professional => _professional(p),
                                  _Tab.interests => _interests(p),
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            if (p != null) Padding(padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.x2, AppSpace.screen, AppSpace.x4), child: _cta(p)),
          ],
        ),
      ),
    );
  }

  static String _or(String? v) => (v == null || v.trim().isEmpty) ? '—' : v.trim();

  // ── Hero ───────────────────────────────────────────────────────────
  List<Widget> _hero(PersonDetail p) => [
        Center(
          child: p.photoUrl == null
              ? InitialsAvatar(initials: p.initials, size: 104)
              : ClipOval(
                  child: Image.network(p.photoUrl!, width: 104, height: 104, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => InitialsAvatar(initials: p.initials, size: 104)),
                ),
        ),
        const SizedBox(height: 16),
        Text(p.name, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
        if (p.role.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            [p.role, if ((p.company ?? '').isNotEmpty) p.company!].join(' · '),
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppColors.sub),
          ),
        ],
        if (p.placeLine.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppIcon(AppIcons.pin, size: 15, color: AppColors.sub),
              const SizedBox(width: 6),
              Flexible(child: Text(p.placeLine, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.sub))),
            ],
          ),
        ],
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            if (p.experienceLabel.isNotEmpty) ProfileChip(label: '${p.experienceLabel} experience', bg: AppColors.inputFill, fg: AppColors.sub),
            if (p.verified) const ProfileChip(label: 'Verified', icon: AppIcons.shieldCheck, bg: AppColors.selectedFill, fg: AppColors.blue),
            if (p.connection.isConnected) const ProfileChip(label: 'Connected', icon: AppIcons.check, bg: AppColors.successSoft, fg: AppColors.success),
          ],
        ),
        if (p.match != null) ...[
          const SizedBox(height: 12),
          SyyncMatchStrip(match: p.match, name: p.firstName),
          if (p.match!.reasons.isNotEmpty) ...[
            const SizedBox(height: 8),
            SyyncReasons(match: p.match, maxLines: 2, center: true),
          ],
        ],
      ];

  // ── Overview ───────────────────────────────────────────────────────
  List<Widget> _overview(PersonDetail p) => [
        ProfileCard(
          title: 'About ${p.firstName}',
          icon: AppIcons.user,
          children: [
            Text(
              (p.about ?? '').trim().isEmpty ? "${p.firstName} hasn't added an introduction yet." : p.about!.trim(),
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, height: 21 / 14, color: AppColors.sub),
            ),
          ],
        ),
        if (p.sharedInterests.isNotEmpty) ...[
          const SizedBox(height: 14),
          ProfileCard(
            title: 'You have in common',
            icon: AppIcons.heart,
            children: [
              Wrap(spacing: 10, runSpacing: 10, children: [for (final s in p.sharedInterests) BluePill(s, outlined: true)]),
            ],
          ),
        ],
        const SizedBox(height: 14),
        ProfileCard(
          title: 'Basic Details',
          icon: AppIcons.user,
          children: [
            ...profileRows([
              ('Full name', p.name),
              ('Location', _or(p.cityLabel)),
              ('LinkedIn', p.linkedinUrl ?? (p.connection.isConnected ? '—' : 'Visible after you connect')),
            ]),
          ],
        ),
        const SizedBox(height: 14),
        ProfileNavCard(
          title: 'Professional Details',
          subtitle: 'Role, industry, company, experience and skills',
          onTap: () => setState(() => _tab = _Tab.professional),
        ),
        const SizedBox(height: 12),
        ProfileNavCard(
          title: 'Interests & Preferences',
          subtitle: 'Interests, intent and how they like to connect',
          onTap: () => setState(() => _tab = _Tab.interests),
        ),
      ];

  // ── Professional ───────────────────────────────────────────────────
  List<Widget> _professional(PersonDetail p) {
    final fields = [
      ('Job Title', _or(p.role)),
      ('Industry', _or(p.industry)),
      ('Company / Organisation', _or(p.company)),
      ('Years of Experience', _or(p.experience)),
    ];
    return [
      const Row(
        children: [
          AppIcon(AppIcons.briefcase, size: 20, color: AppColors.blue),
          SizedBox(width: 10),
          Text('Professional Details', style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink)),
        ],
      ),
      const SizedBox(height: 12),
      ProfileBox(
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.line),
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 14, bottom: i == fields.length - 1 ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fields[i].$1, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.sub)),
                  const SizedBox(height: 6),
                  Text(fields[i].$2, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ink)),
                ],
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 14),
      ProfileBox(
        children: [
          const Text('Skills', style: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink)),
          const SizedBox(height: 14),
          if (p.skills.isEmpty) const Text('No skills added yet.', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.sub)),
          Wrap(spacing: 10, runSpacing: 10, children: [for (final s in p.skills) BluePill(s)]),
        ],
      ),
    ];
  }

  // ── Interests & preferences ────────────────────────────────────────
  List<Widget> _interests(PersonDetail p) => [
        ProfileBox(
          children: [
            ProfileBoxTitle(icon: AppIcons.heart, title: 'Interests', subtitle: 'Topics ${p.firstName} is interested in exploring.'),
            if (p.interests.isEmpty) const Text('No interests added yet.', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.sub)),
            Wrap(spacing: 10, runSpacing: 10, children: [for (final s in p.interests) BluePill(s, outlined: true)]),
            if (p.sharedInterests.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('You both like ${p.sharedInterests.join(', ')}', style: AppText.helper),
            ],
          ],
        ),
        const SizedBox(height: 14),
        ProfileBox(
          children: [
            ProfileBoxTitle(icon: AppIcons.users, title: 'Connection Intent', subtitle: 'What ${p.firstName} is looking for on SyyncIn.'),
            if (p.intent.isEmpty) const Text('Not shared yet.', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.sub)),
            for (final r in p.intent)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const AppIcon(AppIcons.checkCircle, size: 18, color: AppColors.blue),
                    const SizedBox(width: 10),
                    Expanded(child: Text(r, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppColors.ink))),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        ProfileBox(
          children: [
            const ProfileBoxTitle(icon: AppIcons.pin, title: 'Connection Preferences'),
            ...profileRows([
              ('Connection mode', p.connectModeLabel),
              ('Availability', p.availabilityLabel),
              ('Area', _or(p.cityLabel)),
              if (p.distanceKm != null) ('Distance', p.distanceLabel),
            ]),
          ],
        ),
      ];
}
