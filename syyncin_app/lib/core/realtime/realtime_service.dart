import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../data/models.dart';
import '../config/env.dart';
import '../network/api_client.dart';
import '../session/session.dart';

/// Live connection to the API while the app is open (Socket.IO).
///
/// - [notifications] emits every new notification (show a banner / local notification).
/// - [inboxChanges] emits a reason whenever Inbox data changed (refresh lists silently).
/// - [unreadCount] and [inbox] drive the bell and the Inbox badge.
/// - [messages] / [reads] / [typing] carry 1:1 chat events; [unreadMessages] is the chat badge.
class RealtimeService extends ChangeNotifier {
  RealtimeService._() {
    // Paused after a rejected token? Reconnect as soon as the API client gets a new one.
    Session.instance.addListener(() {
      final t = Session.instance.accessToken;
      if (_paused && t != null && t != _token) start();
    });
  }
  static final instance = RealtimeService._();

  String? _token; // token the current socket was opened with
  bool _paused = false;

  io.Socket? _socket;
  bool _refreshingToken = false;
  DateTime? _lastRefresh;

  final _notifications = StreamController<AppNotification>.broadcast();
  final _removed = StreamController<List<int>>.broadcast();
  final _inboxChanges = StreamController<String>.broadcast();
  final _messages = StreamController<ChatEvent>.broadcast();
  final _reads = StreamController<(int, int)>.broadcast();
  final _typing = StreamController<(int, bool)>.broadcast();

  Stream<AppNotification> get notifications => _notifications.stream;
  Stream<List<int>> get removedNotifications => _removed.stream;
  Stream<String> get inboxChanges => _inboxChanges.stream;

  /// New chat message (from the other member, or mine sent from another device).
  Stream<ChatEvent> get messages => _messages.stream;

  /// (conversationId, lastReadId) — the other member read my messages up to lastReadId.
  Stream<(int, int)> get reads => _reads.stream;

  /// (conversationId, isTyping) — the other member is typing.
  Stream<(int, bool)> get typing => _typing.stream;

  /// Chat currently open on screen (no banner for it, messages are marked read there).
  int? activeChatId;
  int unreadMessages = 0;

  void sendTyping(int conversationId, bool isTyping) =>
      _socket?.emit('typing', {'conversationId': conversationId, 'isTyping': isTyping});

  void setUnreadMessages(int value) {
    if (value == unreadMessages) return;
    unreadMessages = value;
    notifyListeners();
  }

  bool connected = false;
  int unreadCount = 0;
  InboxSummary inbox = const InboxSummary();

  /// Connect (or reconnect with the current token). Safe to call repeatedly.
  void start() {
    final token = Session.instance.accessToken;
    if (token == null) return;
    _token = token;
    _paused = false;
    _socket?.dispose();
    // forceNew: socket_io_client caches one connection per URL, so without it
    // io() hands back the old socket (still carrying the expired token) and the
    // server keeps answering TOKEN_INVALID → endless /auth/refresh calls.
    final s = io.io(
      Env.apiOrigin,
      io.OptionBuilder()
          .setPath('/socket.io')
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableForceNew()
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(10000)
          .build(),
    );

    s.onConnect((_) {
      connected = true;
      notifyListeners();
    });
    s.onDisconnect((_) {
      connected = false;
      notifyListeners();
    });
    s.onConnectError((err) => _onConnectError(err));

    s.on('ready', (data) {
      final d = _map(data);
      unreadCount = (d['unreadCount'] as int?) ?? 0;
      inbox = InboxSummary.fromJson(_map(d['inbox']));
      unreadMessages = inbox.unreadMessages;
      notifyListeners();
      _inboxChanges.add('ready'); // catch up on anything missed while offline
    });
    s.on('notification', (data) {
      final n = AppNotification.fromJson(_map(data));
      unreadCount += 1;
      notifyListeners();
      _notifications.add(n);
    });
    s.on('notification:removed', (data) {
      final ids = ((_map(data)['ids'] as List?) ?? const []).cast<int>();
      _removed.add(ids);
      _syncUnread();
    });
    s.on('inbox:updated', (data) {
      final d = _map(data);
      inbox = InboxSummary.fromJson(_map(d['inbox']));
      unreadCount = inbox.unreadNotifications;
      unreadMessages = inbox.unreadMessages;
      notifyListeners();
      _inboxChanges.add((d['reason'] as String?) ?? 'updated');
    });

    s.on('message:new', (data) {
      final d = _map(data);
      final e = ChatEvent(
        conversationId: (d['conversationId'] as int?) ?? 0,
        message: ChatMessage.fromJson(_map(d['message'])),
        senderName: _map(d['sender'])['fullName'] as String?,
      );
      unreadMessages = (d['totalUnread'] as int?) ?? unreadMessages;
      notifyListeners();
      _messages.add(e);
    });
    s.on('message:read', (data) {
      final d = _map(data);
      _reads.add(((d['conversationId'] as int?) ?? 0, (d['lastReadId'] as int?) ?? 0));
    });
    s.on('chat:read', (data) {
      setUnreadMessages((_map(data)['totalUnread'] as int?) ?? unreadMessages);
      _inboxChanges.add('chat_read');
    });
    s.on('typing', (data) {
      final d = _map(data);
      _typing.add(((d['conversationId'] as int?) ?? 0, d['isTyping'] == true));
    });

    _socket = s..connect();
  }

  void stop() {
    _paused = false;
    _token = null;
    _socket?.dispose();
    _socket = null;
    connected = false;
    unreadCount = 0;
    unreadMessages = 0;
    activeChatId = null;
    inbox = const InboxSummary();
    notifyListeners();
  }

  /// Local bookkeeping after the user reads notifications on the list screen.
  void setUnread(int value) {
    unreadCount = value;
    notifyListeners();
  }

  Future<void> _onConnectError(dynamic err) async {
    final code = err is Map ? '${err['message']}' : '$err';
    if (code.contains('TOKEN_INVALID') && !_refreshingToken) {
      // Access tokens last 15 min — refresh and reconnect with the new one.
      // At most once a minute, so a server-side problem can never turn into a loop.
      final last = _lastRefresh;
      if (last != null && DateTime.now().difference(last) < const Duration(minutes: 1)) {
        _socket?.dispose(); // stop auto-reconnecting with a token the server rejects
        _socket = null;
        _paused = true; // resumes when the session gets a new token
        connected = false;
        notifyListeners();
        return;
      }
      _lastRefresh = DateTime.now();
      _refreshingToken = true;
      final ok = await ApiClient.instance.refresh();
      _refreshingToken = false;
      if (ok) {
        start();
      } else {
        stop();
        await Session.instance.expire();
      }
    } else if (code.contains('ACCOUNT_BLOCKED')) {
      stop();
      await Session.instance.expire();
    }
  }

  Future<void> _syncUnread() async {
    try {
      final r = await ApiClient.instance.get('/notifications/unread-count');
      setUnread((r.data['unreadCount'] as int?) ?? unreadCount);
    } catch (_) {}
  }

  static Map<String, dynamic> _map(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
}

class ChatEvent {
  const ChatEvent({required this.conversationId, required this.message, this.senderName});
  final int conversationId;
  final ChatMessage message;
  final String? senderName;
}
