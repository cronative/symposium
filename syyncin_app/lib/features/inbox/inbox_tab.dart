import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/network/api_client.dart';
import '../../core/realtime/realtime_service.dart';
import '../../core/widgets/widgets.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../chat/chat_screen.dart';
import '../home/models/discovery_state.dart';
import '../home/widgets/person_card.dart' show InitialsAvatar, OutlineActionButton;

const _segLabels = {
  InboxSegment.all: 'All',
  InboxSegment.requests: 'Requests',
  InboxSegment.connections: 'Connections',
  InboxSegment.messages: 'Messages',
};

/// Figma 28 / 28b (v3) — Inbox: requests (received / sent) and connections.
/// Data comes from the API and refreshes live via [RealtimeService.inboxChanges].
class InboxTab extends StatefulWidget {
  const InboxTab({super.key});

  @override
  State<InboxTab> createState() => _InboxTabState();
}

class _InboxTabState extends State<InboxTab> {
  final _search = TextEditingController();
  StreamSubscription<String>? _liveSub;
  StreamSubscription<ChatEvent>? _chatSub;
  Timer? _chatReload;

  List<ConnectionRequest> _received = [];
  List<ConnectionRequest> _sent = [];
  List<Person> _connections = [];
  List<Chat> _chats = [];
  bool _loading = true;
  ApiException? _error;
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
    _liveSub = RealtimeService.instance.inboxChanges.listen((_) => _load(silent: true));
    // New chat messages → refresh the Messages list (debounced; bursts become one call).
    _chatSub = RealtimeService.instance.messages.listen((_) {
      _chatReload?.cancel();
      _chatReload = Timer(const Duration(milliseconds: 300), _loadChats);
    });
    // The tab lives in Home's IndexedStack, so refresh whenever it's opened
    // (requests sent from KYN / a profile show up even without a live event).
    AppNav.homeTab.addListener(_onTabChanged);
  }

  static const _inboxTabIndex = 3;
  void _onTabChanged() {
    if (AppNav.homeTab.value == _inboxTabIndex) _load(silent: true);
  }

  @override
  void dispose() {
    AppNav.homeTab.removeListener(_onTabChanged);
    _search.dispose();
    _liveSub?.cancel();
    _chatSub?.cancel();
    _chatReload?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final results = await Future.wait([
        NetworkApi.requests(sent: false),
        NetworkApi.requests(sent: true),
        NetworkApi.connections(),
        ChatApi.list(),
      ]);
      if (!mounted) return;
      final chats = results[3] as (PageResult<Chat>, int);
      RealtimeService.instance.setUnreadMessages(chats.$2);
      setState(() {
        _received = (results[0] as PageResult<ConnectionRequest>).items;
        _sent = (results[1] as PageResult<ConnectionRequest>).items;
        _connections = (results[2] as PageResult<Person>).items;
        _chats = chats.$1.items;
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

  Future<void> _loadChats() async {
    try {
      final (page, unread) = await ChatApi.list();
      RealtimeService.instance.setUnreadMessages(unread);
      if (mounted) setState(() => _chats = page.items);
    } on ApiException catch (_) {}
  }

  bool _matchesChat(Chat c) {
    final q = _search.text.trim().toLowerCase();
    return q.isEmpty || c.user.name.toLowerCase().contains(q) || (c.lastMessage?.body.toLowerCase().contains(q) ?? false);
  }

  Future<void> _openChat(Chat c) async {
    await Navigator.of(context).pushNamed(Routes.chat, arguments: ChatArgs(conversationId: c.id, person: c.user.id == 0 ? null : c.user));
    _loadChats();
  }

  bool _matches(Person p) {
    final q = _search.text.trim().toLowerCase();
    return q.isEmpty || p.name.toLowerCase().contains(q) || p.role.toLowerCase().contains(q);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  /// Run an API action for one request, then refresh.
  Future<void> _act(int id, Future<String> Function() call, {InboxSegment? thenOpen}) async {
    setState(() => _busy.add(id));
    try {
      _snack(await call());
      if (thenOpen != null) AppNav.inboxSegment.value = thenOpen;
      await _load(silent: true);
    } on ApiException catch (e) {
      _snack(e.message);
      await _load(silent: true);
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Future<void> _openProfile(Person p) async {
    await Navigator.of(context).pushNamed(Routes.person, arguments: p.id);
    _load(silent: true);
  }

  Future<void> _message(Person p) async {
    await openChat(context, p);
    _loadChats();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppNav.inboxSegment, AppNav.inboxShowSent]),
      builder: (context, _) {
        final seg = AppNav.inboxSegment.value;
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () => _load(silent: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: AppSpace.content,
                children: [
                  // Title + notifications are in the top bar (HomeAppBar).
                  const Text(
                    'Your connections, all in one place.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 18, height: 24 / 18, fontWeight: FontWeight.w600, color: AppColors.ink),
                  ),
                  const SizedBox(height: 4),
                  const Text('Manage requests, keep conversations going and make plans to connect.', style: AppText.setupSubtitle),
                  const SizedBox(height: 16),
                  if (seg != InboxSegment.connections) ...[
                    _SearchBox(controller: _search, hint: 'Search people or conversations', onChanged: () => setState(() {})),
                    const SizedBox(height: 14),
                  ],
                  _Segments(value: seg, onChanged: (s) => AppNav.inboxSegment.value = s),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Center(child: CircularProgressIndicator()))
                  else if (_error != null)
                    _EmptyState(
                      icon: AppIcons.info,
                      title: _error!.code == 'PROFILE_INCOMPLETE' ? 'Finish your profile first' : "Couldn't load your Inbox",
                      body: _error!.message,
                    )
                  else
                    ...switch (seg) {
                      InboxSegment.all => _allView(),
                      InboxSegment.requests => _requestsView(),
                      InboxSegment.connections => _connectionsView(),
                      InboxSegment.messages => _messagesView(),
                    },
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── All ──────────────────────────────────────────────────────────
  List<Widget> _allView() {
    final received = _received.where((r) => _matches(r.user)).toList();
    final conns = _connections.where(_matches).toList();
    final chats = _chats.where(_matchesChat).take(3).toList();
    final unread = _chats.fold<int>(0, (n, c) => n + c.unreadCount);
    return [
      if (received.isNotEmpty) ...[
        _SectionHeader(title: 'Connection requests', trailing: '${received.length} new', trailingBlue: true),
        const SizedBox(height: 12),
        for (final r in received) ...[_receivedCard(r), const SizedBox(height: 12)],
        const SizedBox(height: 8),
      ],
      if (chats.isNotEmpty) ...[
        _SectionHeader(title: 'Recent messages', trailing: unread > 0 ? '$unread unread' : null, trailingBlue: true),
        const SizedBox(height: 12),
        for (final c in chats) ...[_chatRow(c), const SizedBox(height: 10)],
        if (_chats.length > 3) _LinkButton(label: 'See all messages', onTap: () => AppNav.inboxSegment.value = InboxSegment.messages),
        const SizedBox(height: 16),
      ],
      _SectionHeader(title: 'My Connections', trailing: '${conns.length} connected'),
      const SizedBox(height: 12),
      if (conns.isEmpty)
        const _EmptyState(icon: AppIcons.users, title: 'No connections yet', body: 'Accepted requests will appear here.')
      else
        for (final p in conns) ...[_connectionCard(p), const SizedBox(height: 12)],
    ];
  }

  // ── Requests ─────────────────────────────────────────────────────
  List<Widget> _requestsView() {
    final showSent = AppNav.inboxShowSent.value;
    final received = _received.where((r) => _matches(r.user)).toList();
    final sent = _sent.where((r) => _matches(r.user)).toList();
    return [
      _SubTabs(receivedCount: _received.length, showSent: showSent, onChanged: (v) => AppNav.inboxShowSent.value = v),
      const SizedBox(height: 18),
      if (!showSent) ...[
        _SectionHeader(title: 'Connection requests', trailing: received.isEmpty ? null : '${received.length} new', trailingBlue: true),
        const SizedBox(height: 12),
        if (received.isEmpty)
          const _EmptyState(icon: AppIcons.userPlus, title: "You're all caught up", body: 'New connection requests will show up here instantly.')
        else
          for (final r in received) ...[_receivedCard(r), const SizedBox(height: 12)],
      ] else ...[
        _SectionHeader(title: 'Sent requests', trailing: sent.isEmpty ? null : '${sent.length} pending'),
        const SizedBox(height: 12),
        if (sent.isEmpty)
          const _EmptyState(
            icon: AppIcons.userPlus,
            title: 'No pending requests',
            body: 'Requests you send from KYN or a profile will wait here until they’re accepted.',
          )
        else
          for (final r in sent) ...[_sentCard(r), const SizedBox(height: 12)],
      ],
    ];
  }

  // ── Messages ─────────────────────────────────────────────────────
  List<Widget> _messagesView() {
    final chats = _chats.where(_matchesChat).toList();
    final unread = _chats.fold<int>(0, (n, c) => n + c.unreadCount);
    if (_chats.isEmpty) {
      return [
        _EmptyState(
          icon: AppIcons.chat,
          title: 'No conversations yet',
          body: _connections.isEmpty
              ? 'Once you connect with someone, your chats will show up here.'
              : 'Tap Message on one of your connections to start chatting.',
        ),
        if (_connections.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final p in _connections.take(5)) ...[_connectionCard(p), const SizedBox(height: 12)],
        ],
      ];
    }
    return [
      _SectionHeader(title: 'Messages', trailing: unread > 0 ? '$unread unread' : '${_chats.length} chats', trailingBlue: unread > 0),
      const SizedBox(height: 12),
      if (chats.isEmpty)
        const _EmptyState(icon: AppIcons.search, title: 'No matches', body: 'Try a different name or word.')
      else
        for (final c in chats) ...[_chatRow(c), const SizedBox(height: 10)],
    ];
  }

  Widget _chatRow(Chat c) {
    final last = c.lastMessage;
    final unread = c.unreadCount > 0;
    final preview = last == null ? 'Say hi 👋' : '${last.isMine ? 'You: ' : ''}${last.body.replaceAll('\n', ' ')}';
    final when = c.lastMessageAt ?? last?.createdAt;
    return Semantics(
      button: true,
      label: 'Chat with ${c.user.name}${unread ? ', ${c.unreadCount} unread' : ''}',
      child: Pressable(
        onTap: () => _openChat(c),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: unread ? AppColors.selectedFill : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: unread ? AppColors.accentBlue.withValues(alpha: 0.35) : AppColors.line),
          ),
          child: Row(
            children: [
              ChatAvatar(name: c.user.name, photoUrl: c.user.photoUrl, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: unread ? FontWeight.w700 : FontWeight.w600, color: AppColors.ink),
                          ),
                        ),
                        if (when != null) ...[
                          const SizedBox(width: 8),
                          Text(chatTime(when), style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: unread ? AppColors.blue : AppColors.sub, fontWeight: unread ? FontWeight.w600 : FontWeight.w400)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (last != null && last.isMine) ...[
                          Icon(last.id <= c.otherLastReadId ? Icons.done_all_rounded : Icons.done_rounded, size: 15, color: last.id <= c.otherLastReadId ? AppColors.blue : AppColors.sub),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: unread ? AppColors.ink : AppColors.sub, fontWeight: unread ? FontWeight.w500 : FontWeight.w400),
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            height: 20,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(gradient: AppGradients.setup, borderRadius: BorderRadius.circular(10)),
                            child: Text(c.unreadCount > 99 ? '99+' : '${c.unreadCount}', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.white)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Connections ──────────────────────────────────────────────────
  List<Widget> _connectionsView() {
    final conns = _connections.where(_matches).toList();
    return [
      _SectionHeader(title: 'My Connections', trailing: '${_connections.length} connected', large: true),
      const SizedBox(height: 12),
      _SearchBox(controller: _search, hint: 'Search connections', onChanged: () => setState(() {})),
      const SizedBox(height: 14),
      if (conns.isEmpty)
        _EmptyState(
          icon: AppIcons.users,
          title: _connections.isEmpty ? 'No connections yet' : 'No matches',
          body: _connections.isEmpty ? 'Start by sending a request from KYN.' : 'Try a different name or role.',
        )
      else
        for (final p in conns) ...[_connectionCard(p), const SizedBox(height: 12)],
    ];
  }

  // ── Cards ────────────────────────────────────────────────────────
  Widget _receivedCard(ConnectionRequest r) {
    final busy = _busy.contains(r.id);
    return _Card(
      children: [
        _PersonHeader(person: r.user, trailing: timeAgo(r.createdAt)),
        if ((r.message ?? '').isNotEmpty) ...[const SizedBox(height: 14), _Quote(r.message!)],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: OutlineActionButton(label: 'Decline', onTap: busy ? null : () => _act(r.id, () => NetworkApi.decline(r.id)))),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryButton(
                label: 'Accept',
                height: 44,
                radius: 8,
                loading: busy,
                onPressed: () => _act(r.id, () => NetworkApi.accept(r.id), thenOpen: InboxSegment.connections),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _LinkButton(label: 'View profile', onTap: () => _openProfile(r.user)),
      ],
    );
  }

  Widget _sentCard(ConnectionRequest r) {
    final busy = _busy.contains(r.id);
    return _Card(
      children: [
        _PersonHeader(person: r.user, trailing: 'Sent ${timeAgo(r.createdAt).toLowerCase()}'),
        if ((r.message ?? '').isNotEmpty) ...[const SizedBox(height: 14), _Quote(r.message!)],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: OutlineActionButton(label: busy ? 'Withdrawing…' : 'Withdraw', onTap: busy ? null : () => _act(r.id, () => NetworkApi.withdraw(r.id)))),
            const SizedBox(width: 10),
            const Expanded(child: OutlineActionButton(label: 'Pending', icon: AppIcons.check, muted: true)),
          ],
        ),
        const SizedBox(height: 12),
        _LinkButton(label: 'View profile', onTap: () => _openProfile(r.user)),
      ],
    );
  }

  Widget _connectionCard(Person p) {
    return GestureDetector(
      onTap: () => _openProfile(p),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
        child: Row(
          children: [
            InitialsAvatar(initials: p.initials, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(p.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
                      ),
                      if (p.isNew) ...[const SizedBox(width: 8), const _NewPill()],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(p.role, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.sub)),
                  if ((p.city ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const AppIcon(AppIcons.pin, size: 14, color: AppColors.sub),
                        const SizedBox(width: 6),
                        Text(p.city!, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.sub)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _SmallGradientButton(label: 'Message', icon: AppIcons.chat, onTap: () => _message(p)),
          ],
        ),
      ),
    );
  }
}

// ── Small building blocks ──────────────────────────────────────────

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.hint, required this.onChanged});
  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.line)),
      child: Row(
        children: [
          const AppIcon(AppIcons.search, size: 18, color: AppColors.placeholder),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              textInputAction: TextInputAction.search,
              style: AppText.fieldInput,
              decoration: InputDecoration.collapsed(hintText: hint, hintStyle: AppText.fieldHint),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segments extends StatelessWidget {
  const _Segments({required this.value, required this.onChanged});
  final InboxSegment value;
  final ValueChanged<InboxSegment> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final s in InboxSegment.values) ...[
          if (s != InboxSegment.all) const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              button: true,
              selected: s == value,
              label: _segLabels[s],
              child: GestureDetector(
                onTap: () => onChanged(s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: s == value ? AppGradients.setup : null,
                    color: s == value ? null : AppColors.inputFill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        _segLabels[s]!,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: s == value ? FontWeight.w600 : FontWeight.w500,
                          color: s == value ? AppColors.white : AppColors.sub,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SubTabs extends StatelessWidget {
  const _SubTabs({required this.receivedCount, required this.showSent, required this.onChanged});
  final int receivedCount;
  final bool showSent;
  final ValueChanged<bool> onChanged;

  Widget _tab(String label, bool on, VoidCallback onTap, {int? count}) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: on,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                        color: on ? AppColors.blue : AppColors.sub,
                      ),
                    ),
                    if (count != null && count > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: AppColors.badgeFill, shape: BoxShape.circle),
                        child: Text('$count', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.blue)),
                      ),
                    ],
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: on ? 2 : 1,
                color: on ? AppColors.blue : AppColors.line,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _tab('Received', !showSent, () => onChanged(false), count: receivedCount),
        _tab('Sent', showSent, () => onChanged(true)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing, this.trailingBlue = false, this.large = false});
  final String title;
  final String? trailing;
  final bool trailingBlue;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontFamily: 'Inter', fontSize: large ? 18 : 16, fontWeight: FontWeight.w600, color: AppColors.ink),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: trailingBlue ? FontWeight.w500 : FontWeight.w400,
              color: trailingBlue ? AppColors.blue : AppColors.sub,
            ),
          ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

class _PersonHeader extends StatelessWidget {
  const _PersonHeader({required this.person, required this.trailing, this.showDistance = false});
  final Person person;
  final String trailing;
  final bool showDistance;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InitialsAvatar(initials: person.initials, size: 56),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(person.name, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
              const SizedBox(height: 4),
              Text(person.role, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.sub)),
              const SizedBox(height: 4),
              Text(
                person.placeLine.isEmpty ? 'SyyncIn member' : person.placeLine,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.sub),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(trailing, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.placeholder)),
      ],
    );
  }
}

class _Quote extends StatelessWidget {
  const _Quote(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.panelFill, borderRadius: BorderRadius.circular(8)),
      child: Text('“$text”', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, height: 18 / 13, color: AppColors.ink)),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.blue)),
              const SizedBox(width: 4),
              const AppIcon(AppIcons.chevronRight, size: 14, color: AppColors.blue),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewPill extends StatelessWidget {
  const _NewPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.haloOuter, borderRadius: BorderRadius.circular(6)),
      child: const Text('New', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success)),
    );
  }
}

class _SmallGradientButton extends StatelessWidget {
  const _SmallGradientButton({required this.label, required this.icon, required this.onTap});
  final String label;
  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(gradient: AppGradients.setup, borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(icon, size: 16, color: AppColors.white),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.body});
  final String icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(color: AppColors.panelFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
      child: Column(
        children: [
          AppIcon(icon, size: 30, color: AppColors.sub),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: AppText.sectionTitle),
          const SizedBox(height: 6),
          Text(body, textAlign: TextAlign.center, style: AppText.helper),
        ],
      ),
    );
  }
}
