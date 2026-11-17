import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/network/api_client.dart';
import '../../core/realtime/realtime_service.dart';
import '../../core/widgets/widgets.dart';
import '../../data/api.dart';
import '../chat/chat_screen.dart';
import '../inbox/inbox_tab.dart';
import '../profile/my_profile_tab.dart';
import 'widgets/home_app_bar.dart';
import 'connect_request_screen.dart';
import 'filters_screen.dart';
import 'models/discovery_state.dart';
import 'models/person.dart';
import 'widgets/person_card.dart';

/// App shell after onboarding: bottom tabs KYN · Explore · Meetups · Inbox · Profile.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int get _tab => AppNav.homeTab.value;
  set _tab(int v) => AppNav.homeTab.value = v;

  @override
  void initState() {
    super.initState();
    AppNav.homeTab.addListener(_onTab);
    // The top bar's name + photo come from ProfileSync — MyProfileTab (built
    // up front by the IndexedStack) loads GET /me on start.
  }

  @override
  void dispose() {
    AppNav.homeTab.removeListener(_onTab);
    super.dispose();
  }

  void _onTab() => setState(() {});

  static const _tabs = [
    (AppIcons.compass, 'KYN'),
    (AppIcons.search, 'Explore'),
    (AppIcons.meetups, 'Meetups'),
    (AppIcons.chat, 'Inbox'),
    (AppIcons.user, 'Profile'),
  ];

  /// Centre title of the top bar for each tab.
  static const _titles = ['Discover', 'Explore', 'Meetups', 'Inbox', 'My Profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: HomeAppBar(title: _titles[_tab], onOpenProfile: () => _tab = 4),
      body: IndexedStack(
        index: _tab,
        children: [
          KynTab(onOpenProfileTab: () => _tab = 4),
          _ComingSoon(title: _tabs[1].$2, icon: _tabs[1].$1),
          _ComingSoon(title: _tabs[2].$2, icon: _tabs[2].$1),
          const InboxTab(),
          const MyProfileTab(),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: RealtimeService.instance,
        builder: (context, _) => _BottomTabs(
          items: _tabs,
          index: _tab,
          badgeIndex: RealtimeService.instance.inbox.received > 0 || RealtimeService.instance.unreadMessages > 0 ? 3 : null,
          onTap: (i) => _tab = i,
        ),
      ),
    );
  }
}

class _BottomTabs extends StatelessWidget {
  const _BottomTabs({required this.items, required this.index, required this.onTap, this.badgeIndex});
  final List<(String, String)> items;
  final int index;
  final int? badgeIndex;
  final ValueChanged<int> onTap;

  static const _inactive = Color(0xFF99A3B8);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      // Respects the home indicator / gesture bar; 56 dp bar like the top bar.
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSpace.topBar,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == index,
                    label: items[i].$2,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AppIcon(items[i].$1, size: 22, color: i == index ? AppColors.blue : _inactive),
                              if (badgeIndex == i)
                                Positioned(
                                  right: -2,
                                  top: -1,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.white, width: 1.5),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            items[i].$2,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: i == index ? FontWeight.w600 : FontWeight.w500,
                              color: i == index ? AppColors.blue : _inactive,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _QuickFilter { all, nearby, professionals, similar }

const _quickLabels = {
  _QuickFilter.all: 'All',
  _QuickFilter.nearby: 'Nearby',
  _QuickFilter.professionals: 'Professionals',
  _QuickFilter.similar: 'Similar',
};

/// KYN (Know Your Neighbour) — Figma screen 11, backed by GET /discover.
class KynTab extends StatefulWidget {
  const KynTab({super.key, required this.onOpenProfileTab});
  final VoidCallback onOpenProfileTab;

  @override
  State<KynTab> createState() => _KynTabState();
}

class _KynTabState extends State<KynTab> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  StreamSubscription<String>? _inboxSub;
  Timer? _debounce;

  DiscoveryFilters _filters = DiscoveryFilters.defaults;
  _QuickFilter _quick = _QuickFilter.all;
  String _area = '';

  final List<Person> _people = [];
  int _page = 1;
  int _total = 0;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) _loadMore();
    });
    // Someone accepted / sent a request → refresh card states quietly.
    _inboxSub = RealtimeService.instance.inboxChanges.listen((r) {
      if (r != 'ready') _load(silent: true);
    });
    _loadArea();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    _inboxSub?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  Map<String, dynamic> get _query => {..._filters.toQuery(), 'quick': _quick.name, 'search': _search.text.trim()};

  Future<void> _loadArea() async {
    try {
      final me = await AuthApi.me();
      final c = (me['community'] as Map?) ?? const {};
      final city = (c['city'] as Map?)?['name'] as String?;
      final loc = (c['locality'] as Map?)?['name'] as String?;
      if (mounted) setState(() => _area = [loc, city].whereType<String>().join(', '));
    } catch (_) {}
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final r = await DiscoverApi.discover(_query);
      if (!mounted) return;
      setState(() {
        _people
          ..clear()
          ..addAll(r.items);
        _page = 1;
        _total = r.total;
        _hasMore = r.hasMore;
        _error = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore || _loading) return;
    setState(() => _loadingMore = true);
    try {
      final r = await DiscoverApi.discover(_query, page: _page + 1);
      if (!mounted) return;
      setState(() {
        _people.addAll(r.items);
        _page += 1;
        _hasMore = r.hasMore;
      });
    } catch (_) {
      // keep what we have; the next scroll retries
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _openFilters() async {
    FocusScope.of(context).unfocus();
    final result = await Navigator.of(context).push<DiscoveryFilters>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => FiltersScreen(initial: _filters)),
    );
    if (result != null) {
      setState(() => _filters = result);
      _load();
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _openPerson(Person p) async {
    await Navigator.of(context).pushNamed(Routes.person, arguments: p.id);
    _load(silent: true); // profile actions may have changed bookmark / request state
  }

  Future<void> _connect(Person p) async {
    await openConnectFlow(context, p);
    _load(silent: true);
  }

  Future<void> _toggleSave(Person p) async {
    final next = !p.isSaved;
    setState(() => p.isSaved = next);
    try {
      _snack(await DiscoverApi.setSaved(p.id, next));
    } on ApiException catch (e) {
      setState(() => p.isSaved = !next);
      _snack(e.message);
    }
  }

  void _clearAll() {
    setState(() {
      _filters = DiscoveryFilters.defaults;
      _quick = _QuickFilter.all;
      _search.clear();
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          // Silent: keep the cards on screen while the spinner shows (no full-page loader).
          onRefresh: () => Future.wait([_load(silent: true), _loadArea()]),
          child: ListView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.x5, AppSpace.screen, AppSpace.x6),
            children: [
              // App name, notifications and profile live in the top bar (HomeAppBar).
              const Text('Your next connection starts here.', style: AppText.setupTitle),
              const SizedBox(height: 6),
              const Text('Discover professionals, neighbours and like-minded people around you.', style: AppText.setupSubtitle),
              const SizedBox(height: 16),

              // ── Location ───────────────────────────────────────────
              GestureDetector(
                onTap: () => _snack('Change your area in My Profile › Edit › Discovery.'),
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.only(left: 16, right: 14),
                  decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const AppIcon(AppIcons.pin, size: 20, color: AppColors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _area.isEmpty ? 'Your area' : _area,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink),
                        ),
                      ),
                      const AppIcon(AppIcons.chevronDown, size: 20, color: AppColors.sub),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Search + filters ───────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.line)),
                      child: TextField(
                        controller: _search,
                        onChanged: _onSearch,
                        textInputAction: TextInputAction.search,
                        style: AppText.fieldInput,
                        decoration: const InputDecoration.collapsed(hintText: 'Search by name, role or interest', hintStyle: AppText.fieldHint),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Semantics(
                    button: true,
                    label: 'Filters',
                    child: GestureDetector(
                      onTap: _openFilters,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _filters.activeCount > 0 ? AppColors.blue : AppColors.line),
                            ),
                            child: AppIcon(AppIcons.sliders, size: 20, color: _filters.activeCount > 0 ? AppColors.blue : AppColors.ink),
                          ),
                          if (_filters.activeCount > 0)
                            Positioned(
                              right: -5,
                              top: -5,
                              child: Container(
                                width: 18,
                                height: 18,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(gradient: AppGradients.setup, shape: BoxShape.circle),
                                child: Text(
                                  '${_filters.activeCount}',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Quick filter chips ─────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final q in _QuickFilter.values) ...[
                      if (q != _QuickFilter.all) const SizedBox(width: 8),
                      _QuickChip(
                        label: _quickLabels[q]!,
                        selected: _quick == q,
                        onTap: () {
                          setState(() => _quick = q);
                          _load();
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── People ─────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _loading ? 'People near you' : 'People near you · $_total',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink),
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearAll,
                    child: const Row(
                      children: [
                        Text('See all', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.blue)),
                        SizedBox(width: 4),
                        AppIcon(AppIcons.arrowRight, size: 14, color: AppColors.blue),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Center(child: CircularProgressIndicator()))
              else if (_error != null)
                _EmptyResults(
                  title: _error!.code == 'PROFILE_INCOMPLETE' ? 'Finish your profile first' : "Couldn't load people",
                  body: _error!.message,
                  action: 'Try again',
                  onAction: _load,
                )
              else if (_people.isEmpty)
                _EmptyResults(
                  title: 'No matches just yet.',
                  body: 'Try widening your search or adjusting your filters to discover more people.',
                  action: 'Clear filters',
                  onAction: _clearAll,
                )
              else ...[
                for (var i = 0; i < _people.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  PersonCard(
                    person: _people[i],
                    onView: () => _openPerson(_people[i]),
                    onConnect: () => _connect(_people[i]),
                    onToggleSave: () => _toggleSave(_people[i]),
                    onRespond: () => AppNav.openInbox(InboxSegment.requests),
                    onMessage: () => openChat(context, _people[i]),
                  ),
                ],
                if (_loadingMore) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Bell with unread badge → Notifications screen.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RealtimeService.instance,
      builder: (context, _) {
        final n = RealtimeService.instance.unreadCount;
        return Semantics(
          button: true,
          label: n > 0 ? 'Notifications, $n unread' : 'Notifications',
          child: Pressable(
            onTap: () => Navigator.of(context).pushNamed(Routes.notifications),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 48 dp touch target around a 24 px icon.
                const Padding(padding: EdgeInsets.all(12), child: AppIcon(AppIcons.bell, size: 24, color: AppColors.ink)),
                if (n > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18),
                      height: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(9), border: Border.all(color: AppColors.white, width: 1.5)),
                      child: Text(n > 9 ? '9+' : '$n', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.white)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.selected, required this.onTap});
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
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? AppGradients.setup : null,
            color: selected ? null : AppColors.inputFill,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColors.white : AppColors.sub,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.title, required this.body, required this.action, required this.onAction});
  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(color: AppColors.panelFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
      child: Column(
        children: [
          const AppIcon(AppIcons.search, size: 32, color: AppColors.sub),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: AppText.sectionTitle),
          const SizedBox(height: 6),
          Text(body, textAlign: TextAlign.center, style: AppText.helper),
          const SizedBox(height: 16),
          SizedBox(width: 160, child: PrimaryButton(label: action, height: 44, radius: 8, onPressed: onAction)),
        ],
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title, required this.icon});
  final String title;
  final String icon;

  @override
  Widget build(BuildContext context) {
    // Pull to refresh works here too (nothing to reload yet — keeps every tab consistent).
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => Future<void>.delayed(const Duration(milliseconds: 600)),
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: Center(
                child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.badgeFill, shape: BoxShape.circle),
              child: AppIcon(icon, size: 30, color: AppColors.blue),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppText.setupTitle),
            const SizedBox(height: 6),
            const Text('Coming in the next sprint.', style: AppText.setupSubtitle),
          ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
