/// Models for the SyyncIn API. Field names follow the API (see /docs).
library;

Map<String, dynamic> _map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
List<Map<String, dynamic>> _list(Object? v) => v is List ? v.map(_map).toList() : <Map<String, dynamic>>[];
List<String> _skillNames(Object? v) =>
    v is List ? v.map((e) => e is Map ? e['name'] as String? : e is String ? e : null).whereType<String>().toList() : const [];
String? _name(Object? v, [String key = 'name']) => v is Map ? v[key] as String? : null;
DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;

/// none · pending_sent · pending_received · connected · self
class LinkState {
  const LinkState(this.status, {this.requestId, this.connectedAt});
  factory LinkState.fromJson(Map<String, dynamic> j) =>
      LinkState((j['status'] as String?) ?? 'none', requestId: j['requestId'] as int?, connectedAt: _date(j['connectedAt']));
  final String status;
  final int? requestId;
  final DateTime? connectedAt;

  bool get isNone => status == 'none';
  bool get isPendingSent => status == 'pending_sent';
  bool get isPendingReceived => status == 'pending_received';
  bool get isConnected => status == 'connected';
}

/// SyyncScore for a member (SyyncMatch, computed on the server — never on the device).
class SyyncMatch {
  const SyyncMatch({required this.score, required this.level, required this.label, this.reasons = const [], this.breakdown = const {}, this.insufficient = false});

  static SyyncMatch? fromJson(Object? v) {
    if (v is! Map) return null;
    final j = Map<String, dynamic>.from(v);
    final score = (j['score'] as num?)?.round();
    if (score == null) return null;
    return SyyncMatch(
      score: score.clamp(0, 100),
      level: (j['level'] as String?) ?? 'low',
      label: (j['label'] as String?) ?? '',
      reasons: ((j['reasons'] as List?) ?? const []).cast<String>(),
      breakdown: _map(j['breakdown']).map((k, v) => MapEntry(k, (v as num).round())),
      insufficient: j['insufficient'] == true,
    );
  }

  final int score;

  /// excellent · strong · potential · low · insufficient
  final String level;

  /// "Strong Match" …
  final String label;
  final List<String> reasons;

  /// Points per factor (adds up to [score]).
  final Map<String, int> breakdown;

  /// Too little profile data for a meaningful score — show "Not enough info", not a number.
  final bool insufficient;
}

/// Member card — KYN, profile header, requests, connections, saved.
class Person {
  Person({
    required this.id,
    required this.name,
    required this.role,
    this.company,
    this.industry,
    this.experience,
    this.city,
    this.locality,
    this.distanceKm,
    this.photoUrl,
    this.verified = false,
    this.openToConnect = true,
    this.interests = const [],
    this.sharedInterests = const [],
    this.isSaved = false,
    this.connection = const LinkState('none'),
    this.connectedAt,
    this.isNew = false,
    this.match,
    this.topSkills = const [],
  });

  factory Person.fromJson(Map<String, dynamic> j) => Person(
        id: j['id'] as int,
        name: (j['fullName'] as String?) ?? 'SyyncIn member',
        role: (j['jobTitle'] as String?) ?? '',
        company: j['company'] as String?,
        industry: _name(j['industry']),
        experience: _name(j['experienceLevel'], 'label'),
        city: _name(j['city']),
        locality: _name(j['locality']),
        distanceKm: (j['distanceKm'] as num?)?.toDouble(),
        photoUrl: j['photoUrl'] as String?,
        verified: j['verified'] == true,
        openToConnect: j['openToConnect'] != false,
        interests: _list(j['interests']).map((e) => e['name'] as String).toList(),
        sharedInterests: ((j['sharedInterests'] as List?) ?? const []).cast<String>(),
        isSaved: j['isSaved'] == true,
        connection: LinkState.fromJson(_map(j['connection'])),
        connectedAt: _date(j['connectedAt']),
        isNew: j['isNew'] == true,
        match: SyyncMatch.fromJson(j['match']),
        topSkills: _skillNames(j['skills']),
      );

  final int id;
  final String name;
  final String role;
  final String? company;
  final String? industry;
  final String? experience;
  final String? city;
  final String? locality;
  final double? distanceKm;
  final String? photoUrl;
  final bool verified;
  final bool openToConnect;
  final List<String> interests;
  final List<String> sharedInterests;
  bool isSaved;
  LinkState connection;
  final DateTime? connectedAt;
  final bool isNew;
  final SyyncMatch? match;

  /// Skill names (cards send strings; the profile sends {id, name}).
  final List<String> topSkills;

  String get firstName => name.split(RegExp(r'\s+')).first;
  String get initials => name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();
  String get experienceLabel => experience ?? '';
  String get cityLabel => [locality, city].whereType<String>().join(', ');
  String get distanceLabel => distanceKm == null ? '' : '${distanceKm!.toStringAsFixed(1)} km away';
  String get placeLine => [city, if (distanceKm != null) distanceLabel].whereType<String>().join(' · ');
}

/// Full Professional Profile (GET /users/:id).
class PersonDetail extends Person {
  PersonDetail.fromJson(Map<String, dynamic> j)
      : about = j['about'] as String?,
        skills = _list(j['skills']).map((e) => e['name'] as String).toList(),
        intent = _list(j['intent']).map((e) => e['title'] as String).toList(),
        connectMode = _map(j['connectionPreferences'])['connectMode'] as String?,
        availability = ((_map(j['connectionPreferences'])['availability'] as List?) ?? const []).cast<String>(),
        linkedinUrl = j['linkedinUrl'] as String?,
        super(
          id: j['id'] as int,
          name: (j['fullName'] as String?) ?? 'SyyncIn member',
          role: (j['jobTitle'] as String?) ?? '',
          company: j['company'] as String?,
          industry: _name(j['industry']),
          experience: _name(j['experienceLevel'], 'label'),
          city: _name(j['city']),
          locality: _name(j['locality']),
          distanceKm: (j['distanceKm'] as num?)?.toDouble(),
          photoUrl: j['photoUrl'] as String?,
          verified: j['verified'] == true,
          openToConnect: j['openToConnect'] != false,
          interests: _list(j['interests']).map((e) => e['name'] as String).toList(),
          sharedInterests: ((j['sharedInterests'] as List?) ?? const []).cast<String>(),
          isSaved: j['isSaved'] == true,
          connection: LinkState.fromJson(_map(j['connection'])),
          match: SyyncMatch.fromJson(j['match']),
          topSkills: _skillNames(j['skills']),
        );

  final String? about;
  final List<String> skills;
  final List<String> intent;
  final String? connectMode;
  final List<String> availability;
  final String? linkedinUrl;

  static const _modes = {'in_person': 'In person', 'online': 'Online', 'both': 'Both'};
  String get connectModeLabel => _modes[connectMode] ?? '—';
  String get availabilityLabel =>
      availability.isEmpty ? '—' : availability.map((a) => a[0].toUpperCase() + a.substring(1)).join(', ');
}

class ConnectionRequest {
  ConnectionRequest.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        direction = (j['direction'] as String?) ?? 'received',
        status = (j['status'] as String?) ?? 'pending',
        message = j['message'] as String?,
        createdAt = _date(j['createdAt']) ?? DateTime.now(),
        user = Person.fromJson(_map(j['user']));

  final int id;
  final String direction;
  final String status;
  final String? message;
  final DateTime createdAt;
  final Person user;
}

class AppNotification {
  AppNotification.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        type = j['type'] as String,
        title = j['title'] as String,
        body = j['body'] as String,
        data = _map(j['data']),
        actorName = _map(j['actor'])['fullName'] as String?,
        isRead = j['isRead'] == true,
        createdAt = _date(j['createdAt']) ?? DateTime.now();

  final int id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String? actorName;
  bool isRead;
  final DateTime createdAt;

  /// 'inbox.requests.received' | 'inbox.connections'
  String? get screen => data['screen'] as String?;
  String get actorInitials =>
      (actorName ?? 'S').split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();
}

class InboxSummary {
  const InboxSummary({this.received = 0, this.sent = 0, this.connections = 0, this.newConnections = 0, this.unreadNotifications = 0, this.unreadMessages = 0});
  factory InboxSummary.fromJson(Map<String, dynamic> j) => InboxSummary(
        received: (_map(j['requests'])['received'] as int?) ?? 0,
        sent: (_map(j['requests'])['sent'] as int?) ?? 0,
        connections: (_map(j['connections'])['total'] as int?) ?? 0,
        newConnections: (_map(j['connections'])['new'] as int?) ?? 0,
        unreadNotifications: (_map(j['notifications'])['unread'] as int?) ?? 0,
        unreadMessages: (_map(j['messages'])['unread'] as int?) ?? 0,
      );
  final int received;
  final int sent;
  final int connections;
  final int newConnections;
  final int unreadNotifications;
  final int unreadMessages;
}

/// One chat message. [pending] / [failed] are local states while sending.
class ChatMessage {
  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    required this.isMine,
    this.clientId,
    this.pending = false,
    this.failed = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as int,
        conversationId: j['conversationId'] as int,
        senderId: j['senderId'] as int,
        body: (j['body'] as String?) ?? '',
        clientId: j['clientId'] as String?,
        createdAt: _date(j['createdAt']) ?? DateTime.now(),
        isMine: j['isMine'] == true,
      );

  /// Server id (0 while [pending]).
  int id;
  final int conversationId;
  final int senderId;
  final String body;
  final String? clientId;
  DateTime createdAt;
  final bool isMine;
  bool pending;
  bool failed;
}

/// Inbox › Messages row / chat header (GET /chats).
class Chat {
  Chat.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        user = Person.fromJson(_map(j['user'])..putIfAbsent('id', () => 0)),
        lastMessage = j['lastMessage'] is Map ? ChatMessage.fromJson(_map(j['lastMessage'])) : null,
        lastMessageAt = _date(j['lastMessageAt']),
        unreadCount = (j['unreadCount'] as int?) ?? 0,
        otherLastReadId = (j['otherLastReadId'] as int?) ?? 0,
        canSend = j['canSend'] == true;

  final int id;
  final Person user;
  final ChatMessage? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final int otherLastReadId;
  final bool canSend;
}

/// GET /chats/:id/messages
class MessagePage {
  MessagePage.fromJson(Map<String, dynamic> j)
      : items = _list(j['items']).map(ChatMessage.fromJson).toList(),
        hasMore = j['hasMore'] == true,
        otherLastReadId = (j['otherLastReadId'] as int?) ?? 0,
        canSend = j['canSend'] != false;
  final List<ChatMessage> items;
  final bool hasMore;
  final int otherLastReadId;
  final bool canSend;
}

/// One page of a list endpoint.
class PageResult<T> {
  const PageResult(this.items, {this.page = 1, this.total = 0, this.hasMore = false, this.message = ''});
  final List<T> items;
  final int page;
  final int total;
  final bool hasMore;
  final String message;
}

/// "Just now", "5m ago", "3h ago", "2d ago".
String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inHours < 1) return '${d.inMinutes}m ago';
  if (d.inDays < 1) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}

/// "14:05" · "Yesterday" · "Mon" · "12 Oct" — chat list times.
String chatTime(DateTime t) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return clockTime(t);
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][t.weekday - 1];
  return dayLabel(t);
}

/// "9:05 AM"
String clockTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
}

/// "Today" · "Yesterday" · "12 Oct" · "12 Oct 2025" — date separators in a chat.
String dayLabel(DateTime t, {bool relative = false}) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final now = DateTime.now();
  if (relative) {
    final diff = DateTime(now.year, now.month, now.day).difference(DateTime(t.year, t.month, t.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
  }
  return '${t.day} ${months[t.month - 1]}${t.year == now.year ? '' : ' ${t.year}'}';
}
