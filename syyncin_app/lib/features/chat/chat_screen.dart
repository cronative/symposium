import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import '../../core/network/api_client.dart';
import '../../core/realtime/realtime_service.dart';
import '../../core/widgets/widgets.dart';
import '../../data/api.dart';
import '../../data/models.dart';

/// Open the chat with a connection (from Inbox, a profile …).
Future<void> openChat(BuildContext context, Person person) =>
    Navigator.of(context).pushNamed(Routes.chat, arguments: ChatArgs(person: person));

/// Either the member (chat is opened / created on the API) or an existing conversation id.
class ChatArgs {
  const ChatArgs({this.person, this.conversationId}) : assert(person != null || conversationId != null);
  final Person? person;
  final int? conversationId;
}

/// 1:1 text chat. Messages arrive live over the socket ([RealtimeService.messages]);
/// sending is optimistic and safe to retry (each message carries a clientId).
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.args});
  final ChatArgs args;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  final _rt = RealtimeService.instance;
  final List<StreamSubscription<dynamic>> _subs = [];

  Chat? _chat;
  Person? _person;

  /// Newest first (the list is reversed so it sticks to the bottom).
  final List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _loadingOlder = false;
  bool _hasMore = false;
  bool _canSend = true;
  int _otherLastReadId = 0;
  ApiException? _error;

  bool _otherTyping = false;
  Timer? _typingClear;
  DateTime? _typingSentAt;
  bool _iAmTyping = false;
  Timer? _readTimer;
  bool _resumed = true;

  @override
  void initState() {
    super.initState();
    _person = widget.args.person;
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScroll);
    _input.addListener(_onInput);
    _subs.add(_rt.messages.listen(_onLiveMessage));
    _subs.add(_rt.reads.listen((e) {
      if (e.$1 == _chat?.id && e.$2 > _otherLastReadId) setState(() => _otherLastReadId = e.$2);
    }));
    _subs.add(_rt.typing.listen((e) {
      if (e.$1 != _chat?.id) return;
      _typingClear?.cancel();
      setState(() => _otherTyping = e.$2);
      if (e.$2) {
        _typingClear = Timer(const Duration(seconds: 6), () {
          if (mounted) setState(() => _otherTyping = false);
        });
      }
    }));
    // Reconnected after being offline → fetch anything we missed.
    _subs.add(_rt.inboxChanges.where((r) => r == 'ready').listen((_) => _catchUp()));
    _open();
  }

  @override
  void dispose() {
    if (_rt.activeChatId == _chat?.id) _rt.activeChatId = null;
    if (_iAmTyping && _chat != null) _rt.sendTyping(_chat!.id, false);
    WidgetsBinding.instance.removeObserver(this);
    for (final s in _subs) {
      s.cancel();
    }
    _typingClear?.cancel();
    _readTimer?.cancel();
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    if (_chat == null) return;
    if (_resumed) {
      _rt.activeChatId = _chat!.id;
      _catchUp();
    } else if (_rt.activeChatId == _chat!.id) {
      _rt.activeChatId = null; // show a notification while the app is in the background
    }
  }

  // ── Loading ──────────────────────────────────────────────────────
  Future<void> _open() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final chat = widget.args.conversationId != null ? await ChatApi.get(widget.args.conversationId!) : await ChatApi.open(widget.args.person!.id);
      final page = await ChatApi.messages(chat.id);
      if (!mounted) return;
      _rt.activeChatId = chat.id;
      setState(() {
        _chat = chat;
        if (chat.user.id != 0) _person = chat.user;
        _messages
          ..clear()
          ..addAll(page.items.reversed);
        _hasMore = page.hasMore;
        _canSend = page.canSend;
        _otherLastReadId = page.otherLastReadId;
        _loading = false;
      });
      _markRead();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  int get _lastServerId {
    for (final m in _messages) {
      if (m.id > 0) return m.id; // newest first
    }
    return 0;
  }

  Future<void> _catchUp() async {
    final chat = _chat;
    if (chat == null) return;
    try {
      final page = await ChatApi.messages(chat.id, after: _lastServerId, limit: 100);
      if (!mounted) return;
      setState(() {
        for (final m in page.items) {
          _insert(m);
        }
        _canSend = page.canSend;
        if (page.otherLastReadId > _otherLastReadId) _otherLastReadId = page.otherLastReadId;
      });
      _markRead();
    } on ApiException catch (_) {}
  }

  void _onScroll() {
    if (!_hasMore || _loadingOlder || _chat == null) return;
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) _loadOlder();
  }

  Future<void> _loadOlder() async {
    if (_messages.isEmpty) return;
    final oldest = _messages.last;
    if (oldest.id <= 0) return;
    setState(() => _loadingOlder = true);
    try {
      final page = await ChatApi.messages(_chat!.id, before: oldest.id);
      if (!mounted) return;
      setState(() {
        _messages.addAll(page.items.reversed.where((m) => !_messages.any((x) => x.id == m.id)));
        _hasMore = page.hasMore;
      });
    } on ApiException catch (_) {
    } finally {
      if (mounted) setState(() => _loadingOlder = false);
    }
  }

  // ── Live events ──────────────────────────────────────────────────
  void _onLiveMessage(ChatEvent e) {
    if (e.conversationId != _chat?.id) return;
    setState(() {
      _insert(e.message);
      if (!e.message.isMine) _otherTyping = false;
    });
    if (!e.message.isMine) _markRead();
  }

  /// Add a server message, replacing its optimistic copy (same clientId) if there is one.
  void _insert(ChatMessage m) {
    if (_messages.any((x) => x.id == m.id && m.id > 0)) return;
    final i = m.clientId == null ? -1 : _messages.indexWhere((x) => x.clientId == m.clientId);
    if (i >= 0) {
      _messages[i] = m;
      return;
    }
    // Keep newest-first order by id (pending ones stay on top).
    final at = _messages.indexWhere((x) => x.id > 0 && x.id < m.id);
    if (at >= 0) {
      _messages.insert(at, m);
    } else {
      _messages.add(m); // first or oldest message
    }
  }

  void _markRead() {
    if (!_resumed || _chat == null) return;
    final hasUnread = _messages.any((m) => !m.isMine && m.id > 0);
    if (!hasUnread) return;
    _readTimer?.cancel();
    _readTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        _rt.setUnreadMessages(await ChatApi.markRead(_chat!.id));
      } on ApiException catch (_) {}
    });
  }

  // ── Typing ───────────────────────────────────────────────────────
  void _onInput() {
    setState(() {}); // send button state
    final chat = _chat;
    if (chat == null || !_canSend) return;
    final has = _input.text.trim().isNotEmpty;
    final now = DateTime.now();
    if (has && (!_iAmTyping || _typingSentAt == null || now.difference(_typingSentAt!) > const Duration(seconds: 3))) {
      _iAmTyping = true;
      _typingSentAt = now;
      _rt.sendTyping(chat.id, true);
    } else if (!has && _iAmTyping) {
      _iAmTyping = false;
      _rt.sendTyping(chat.id, false);
    }
  }

  // ── Sending ──────────────────────────────────────────────────────
  static final _rand = Random();
  String _newClientId() => '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${_rand.nextInt(1 << 30).toRadixString(36)}';

  Future<void> _send() async {
    final chat = _chat;
    final text = _input.text.trim();
    if (chat == null || text.isEmpty || !_canSend) return;
    final local = ChatMessage(id: 0, conversationId: chat.id, senderId: 0, body: text, createdAt: DateTime.now(), isMine: true, clientId: _newClientId(), pending: true);
    _input.clear();
    if (_iAmTyping) {
      _iAmTyping = false;
      _rt.sendTyping(chat.id, false);
    }
    setState(() => _messages.insert(0, local));
    if (_scroll.hasClients) _scroll.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    await _deliver(local);
  }

  Future<void> _deliver(ChatMessage local) async {
    try {
      final saved = await ChatApi.send(local.conversationId, local.body, local.clientId!);
      if (!mounted) return;
      setState(() {
        // The socket echo may already have replaced the local copy.
        final dup = _messages.indexWhere((x) => x.id == saved.id);
        final i = _messages.indexOf(local);
        if (dup >= 0 && i >= 0) {
          _messages.removeAt(i);
        } else if (i >= 0) {
          _messages[i] = saved;
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        local
          ..pending = false
          ..failed = true;
        if (e.code == 'NOT_CONNECTED') _canSend = false;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _retry(ChatMessage m) {
    setState(() {
      m
        ..failed = false
        ..pending = true;
    });
    _deliver(m);
  }

  void _openProfile() {
    final p = _person;
    if (p == null || p.id == 0) return;
    Navigator.of(context).pushNamed(Routes.person, arguments: p.id);
  }

  // ── UI ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final p = _person;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppTopBar(
        titleWidget: GestureDetector(
          onTap: _openProfile,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Avatar(person: p, size: 36),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p?.name ?? 'Chat', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.appBarTitle.copyWith(fontSize: 16)),
                    if (_otherTyping)
                      const Text('typing…', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.blue, fontWeight: FontWeight.w500))
                    else if ((p?.role ?? '').isNotEmpty)
                      Text(p!.role, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.sub)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Expanded(child: _body()),
            if (!_loading && _error == null) (_canSend ? _composer() : _closedNotice()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: AppSpace.screenH,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIcon(AppIcons.info, size: 32, color: AppColors.sub),
              const SizedBox(height: 12),
              Text(_error!.message, textAlign: TextAlign.center, style: AppText.setupSubtitle),
              const SizedBox(height: 16),
              TextButton(onPressed: _open, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Avatar(person: _person, size: 72),
              const SizedBox(height: 14),
              Text('Say hi to ${_person?.firstName ?? 'your connection'} 👋', textAlign: TextAlign.center, style: AppText.cardTitle),
              const SizedBox(height: 6),
              const Text('Start the conversation — introduce yourself or suggest a time to meet.', textAlign: TextAlign.center, style: AppText.setupSubtitle),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, 12, AppSpace.screen, 12),
      itemCount: _messages.length + (_loadingOlder ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _messages.length) {
          return const Padding(padding: EdgeInsets.all(12), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))));
        }
        final m = _messages[i];
        final older = i + 1 < _messages.length ? _messages[i + 1] : null;
        final newer = i > 0 ? _messages[i - 1] : null;
        final newDay = older == null || !_sameDay(older.createdAt, m.createdAt);
        final groupedWithNewer = newer != null && newer.isMine == m.isMine && _sameDay(newer.createdAt, m.createdAt);
        return Column(
          children: [
            if (newDay) _DaySeparator(dayLabel(m.createdAt, relative: true)),
            _Bubble(
              message: m,
              read: m.isMine && m.id > 0 && m.id <= _otherLastReadId,
              tail: !groupedWithNewer,
              onRetry: m.failed ? () => _retry(m) : null,
            ),
            SizedBox(height: groupedWithNewer ? 3 : 10),
          ],
        );
      },
    );
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _composer() {
    final canSend = _input.text.trim().isNotEmpty;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpace.screen, 8, 8, 8),
        decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.divider))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(22)),
                child: TextField(
                  controller: _input,
                  focusNode: _focus,
                  minLines: 1,
                  maxLines: 5,
                  inputFormatters: [LengthLimitingTextInputFormatter(2000)],
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  style: AppText.fieldInput,
                  decoration: const InputDecoration.collapsed(hintText: 'Type a message', hintStyle: AppText.fieldHint),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Semantics(
              button: true,
              label: 'Send',
              child: GestureDetector(
                onTap: canSend ? _send : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: canSend ? AppGradients.setup : null,
                    color: canSend ? null : AppColors.inputFill,
                  ),
                  child: AppIcon(AppIcons.send, size: 20, color: canSend ? AppColors.white : AppColors.placeholder),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _closedNotice() => SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpace.screen),
          decoration: const BoxDecoration(color: AppColors.inputFill, border: Border(top: BorderSide(color: AppColors.divider))),
          child: Text(
            "You're no longer connected with ${_person?.firstName ?? 'this member'}, so you can't send new messages.",
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.sub),
          ),
        ),
      );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.read, required this.tail, this.onRetry});
  final ChatMessage message;
  final bool read;
  final bool tail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final mine = m.isMine;
    final fg = mine ? AppColors.white : AppColors.ink;
    final meta = mine ? AppColors.white.withValues(alpha: 0.85) : AppColors.sub;
    const r = Radius.circular(16);
    const small = Radius.circular(4);
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.76),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      decoration: BoxDecoration(
        gradient: mine && !m.failed ? AppGradients.setup : null,
        color: mine ? (m.failed ? AppColors.error.withValues(alpha: 0.85) : null) : AppColors.inputFill,
        borderRadius: BorderRadius.only(
          topLeft: r,
          topRight: r,
          bottomLeft: mine || !tail ? r : small,
          bottomRight: mine && tail ? small : r,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child: Text(m.body, style: TextStyle(fontFamily: 'Inter', fontSize: 15, height: 1.35, color: fg)),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(clockTime(m.createdAt), style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: meta)),
              if (mine) ...[
                const SizedBox(width: 4),
                Icon(
                  m.failed
                      ? Icons.error_outline_rounded
                      : m.pending
                          ? Icons.schedule_rounded
                          : read
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                  size: 14,
                  color: meta,
                  semanticLabel: m.failed ? 'Not sent' : m.pending ? 'Sending' : read ? 'Seen' : 'Sent',
                ),
              ],
            ],
          ),
        ],
      ),
    );
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(onTap: onRetry, child: bubble),
          if (onRetry != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                onTap: onRetry,
                child: const Text('Not sent · Tap to retry', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500)),
              ),
            ),
        ],
      ),
    );
  }
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(12)),
            child: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.sub)),
          ),
        ),
      );
}

/// Photo, or initials when there's no photo.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.person, required this.size});
  final Person? person;
  final double size;

  @override
  Widget build(BuildContext context) => ChatAvatar(name: person?.name, photoUrl: person?.photoUrl, size: size);
}

/// Round avatar used in chat rows and headers.
class ChatAvatar extends StatelessWidget {
  const ChatAvatar({super.key, required this.name, this.photoUrl, this.size = 48});
  final String? name;
  final String? photoUrl;
  final double size;

  String get _initials => (name ?? 'S').split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.badgeFill, shape: BoxShape.circle),
      child: Text(_initials, style: TextStyle(fontFamily: 'Inter', fontSize: size * 0.34, fontWeight: FontWeight.w600, color: AppColors.blue)),
    );
    final url = photoUrl;
    if (url == null || url.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(url, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback),
    );
  }
}
