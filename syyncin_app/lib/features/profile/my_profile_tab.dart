import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/network/api_client.dart';
import '../../core/realtime/realtime_service.dart';
import '../../core/widgets/widgets.dart';
import '../../data/api.dart';
import '../../data/profile_sync.dart';
import '../home/widgets/person_card.dart' show InitialsAvatar;
import '../profile_setup/widgets/pickers.dart';
import 'widgets/profile_blocks.dart';

const _distances = ['5 km', '10 km', '25 km', '50+ km'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

enum _ProfileTab { overview, professional, preferences }

const _tabLabels = {
  _ProfileTab.overview: 'Overview',
  _ProfileTab.professional: 'Professional',
  _ProfileTab.preferences: 'Preferences',
};

/// Figma 40 (v3) — My Profile. Loads GET /me into [SetupDraft] on open
/// (pull down to refresh); toggles save via PATCH /me/settings.
class MyProfileTab extends StatefulWidget {
  const MyProfileTab({super.key});

  @override
  State<MyProfileTab> createState() => _MyProfileTabState();
}

class _MyProfileTabState extends State<MyProfileTab> {
  final d = SetupDraft.instance;
  _ProfileTab _tab = _ProfileTab.overview;

  String _or(String? v, [String fallback = '—']) => (v == null || v.trim().isEmpty) ? fallback : v.trim();

  String get _name => _or(d.fullName, 'Your name');
  String get _role => _or(d.jobTitle, '');
  String get _city => _or(d.city);
  String get _location => [d.locality, d.city].where((s) => s.trim().isNotEmpty).join(', ');
  String get _experience => _or(d.experience, '');
  String get _initials => _name.split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();

  String get _dob {
    final b = d.dateOfBirth;
    if (b == null) return '—';
    return '${b.day} ${_months[b.month - 1]} ${b.year}';
  }

  List<String> get _skills => d.skills.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  List<String> get _interests => d.interests.toList();
  List<String> get _reasons => d.reasons.toList();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  /// Pull the latest profile from the server (GET /me).
  Future<void> _refresh() async {
    try {
      await ProfileSync.load();
      if (mounted) setState(() {});
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _edit() async {
    final saved = await Navigator.of(context).pushNamed<bool>(Routes.editProfile);
    if (mounted) setState(() {}); // Edit Profile already showed the server's message
    if (saved != true) _refresh();
  }

  Future<void> _toggle({bool? openToConnect, bool? nearbyDiscovery}) async {
    final before = (d.openToConnect, d.nearbyDiscovery);
    setState(() {
      if (openToConnect != null) d.openToConnect = openToConnect;
      if (nearbyDiscovery != null) d.nearbyDiscovery = nearbyDiscovery;
    });
    try {
      _snack(await ProfileSync.saveSettings(openToConnect: openToConnect, nearbyDiscovery: nearbyDiscovery));
    } on ApiException catch (e) {
      setState(() {
        d.openToConnect = before.$1;
        d.nearbyDiscovery = before.$2;
      });
      _snack(e.message);
    }
  }

  (String, String?, Color, Color) get _verification => switch (d.verificationStatus) {
        'verified' => ('Verified', AppIcons.shieldCheck, AppColors.selectedFill, AppColors.blue),
        'pending' => ('Verification pending', AppIcons.shield, AppColors.warningFill, AppColors.warning),
        'rejected' => ('Verification failed', AppIcons.shield, AppColors.warningFill, AppColors.error),
        _ => ('Not verified', AppIcons.shield, AppColors.warningFill, AppColors.warning),
      };

  void _soon(String what) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$what is coming in the next sprint')));

  @override
  Widget build(BuildContext context) {
    final v = _verification;
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.x3, AppSpace.screen, AppSpace.x6),
        children: [
          // Title is in the top bar (HomeAppBar); Edit sits above the hero.
          Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              button: true,
              label: 'Edit profile',
              child: GestureDetector(
                onTap: _edit,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon(AppIcons.pencil, size: 18, color: AppColors.blue),
                      SizedBox(width: 6),
                      Text('Edit', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.blue)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // ── Hero ───────────────────────────────────────────────
          Center(
            child: d.photoUrl == null
                ? InitialsAvatar(initials: _initials, size: 104)
                : ClipOval(
                    child: Image.network(d.photoUrl!, width: 104, height: 104, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => InitialsAvatar(initials: _initials, size: 104)),
                  ),
          ),
          const SizedBox(height: 16),
          Text(_name, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 6),
          Text(_role, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppColors.sub)),
          if (_location.isNotEmpty) const SizedBox(height: 8),
          if (_location.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppIcon(AppIcons.pin, size: 15, color: AppColors.sub),
              const SizedBox(width: 6),
              Flexible(child: Text(_location, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.sub))),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_experience.isNotEmpty) ProfileChip(label: '$_experience experience', bg: AppColors.inputFill, fg: AppColors.sub),
              ProfileChip(label: v.$1, icon: v.$2, bg: v.$3, fg: v.$4),
            ],
          ),
          const SizedBox(height: 20),

          // ── Tabs ───────────────────────────────────────────────
          Row(
            children: [
              for (final t in _ProfileTab.values) ...[
                if (t != _ProfileTab.overview) const SizedBox(width: 8),
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
                  _ProfileTab.overview => _overview(),
                  _ProfileTab.professional => _professional(),
                  _ProfileTab.preferences => _preferences(),
                },
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  // ── Overview ───────────────────────────────────────────────────────
  List<Widget> _overview() => [
        ProfileCard(
          title: 'About Me',
          icon: AppIcons.user,
          children: [
            Text(
              d.about.trim().isEmpty ? 'Add a line about yourself from Edit profile.' : d.about.trim(),
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, height: 21 / 14, color: AppColors.sub),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ProfileCard(
          title: 'Basic Details',
          icon: AppIcons.lock,
          children: [
            ...profileRows([
              ('Full name', _name),
              ('Date of birth', _dob),
              ('Gender', _or(d.gender)),
              ('LinkedIn', _or(d.linkedIn)),
            ]),
            const SizedBox(height: 8),
            const Row(
              children: [
                AppIcon(AppIcons.info, size: 14, color: AppColors.placeholder),
                SizedBox(width: 6),
                Expanded(child: Text('DOB and gender are private account details.', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.placeholder))),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        ProfileNavCard(
          title: 'Professional Details',
          subtitle: 'Role, industry, company, experience and skills',
          onTap: () => setState(() => _tab = _ProfileTab.professional),
        ),
        const SizedBox(height: 12),
        ProfileNavCard(
          title: 'Interests & Discovery',
          subtitle: 'Interests, intent, location and privacy',
          onTap: () => setState(() => _tab = _ProfileTab.preferences),
        ),
        const SizedBox(height: 12),
        ProfileNavCard(title: 'Membership', subtitle: 'SyyncIn Free · See Pro plans', icon: AppIcons.crown, onTap: () => Navigator.of(context).pushNamed(Routes.membership)),
        const SizedBox(height: 12),
        ProfileNavCard(title: 'Settings & Safety', icon: AppIcons.settings, onTap: () => _soon('Settings & Safety')),
        const SizedBox(height: 12),
        ProfileNavCard(title: 'Log out', icon: AppIcons.back, onTap: _logout),
      ];

  Future<void> _logout() async {
    final ok = await showAppConfirm(
      context,
      title: 'Log out?',
      message: 'You will need a new verification code to sign in again.',
      confirmLabel: 'Log out',
      destructive: true,
    );
    if (!ok || !mounted) return;
    RealtimeService.instance.stop();
    await AuthApi.logout();
    SetupDraft.instance.reset();
    if (mounted) Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (r) => false);
  }

  // ── Professional ───────────────────────────────────────────────────
  List<Widget> _professional() {
    final fields = [
      ('Job Title', _or(d.jobTitle)),
      ('Industry', _or(d.industry)),
      ('Company / Organisation', _or(d.company)),
      ('Years of Experience', _or(d.experience)),
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
          if (_skills.isEmpty) const Text('No skills added yet.', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.sub)),
          Wrap(spacing: 10, runSpacing: 10, children: [for (final s in _skills) BluePill(s)]),
        ],
      ),
    ];
  }

  // ── Preferences ────────────────────────────────────────────────────
  List<Widget> _preferences() => [
        ProfileBox(
          children: [
            const ProfileBoxTitle(icon: AppIcons.heart, title: 'My Interests', subtitle: "Topics you're interested in exploring."),
            Wrap(spacing: 10, runSpacing: 10, children: [for (final s in _interests) BluePill(s, outlined: true)]),
          ],
        ),
        const SizedBox(height: 14),
        ProfileBox(
          children: [
            const ProfileBoxTitle(icon: AppIcons.users, title: 'Connection Intent', subtitle: "What you're looking for on SyyncIn."),
            for (final r in _reasons)
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
            const ProfileBoxTitle(icon: AppIcons.pin, title: 'Location & Discovery'),
            ...profileRows([
              ('City', _city),
              ('Locality', _or(d.locality)),
              ('Search radius', _distances[d.distance.clamp(0, _distances.length - 1)]),
            ]),
            const Divider(height: 1, thickness: 1, color: AppColors.line),
            _ToggleRow(
              title: 'Open to connect',
              status: d.openToConnect ? 'Enabled' : 'Paused',
              value: d.openToConnect,
              onChanged: (v) => _toggle(openToConnect: v),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.line),
            _ToggleRow(
              title: 'Nearby discovery',
              status: d.nearbyDiscovery ? 'Visible' : 'Hidden',
              value: d.nearbyDiscovery,
              onChanged: (v) => _toggle(nearbyDiscovery: v),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.panelFill, borderRadius: BorderRadius.circular(8)),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIcon(AppIcons.shieldCheck, size: 16, color: AppColors.sub),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your exact location and search radius remain private. Only an approximate area is shown to others.',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, height: 17 / 12, color: AppColors.sub),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ];
}

// Shared profile blocks live in widgets/profile_blocks.dart.

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.title, required this.status, required this.value, required this.onChanged});
  final String title;
  final String status;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(status, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.sub)),
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
