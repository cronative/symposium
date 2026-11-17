/// Typed calls for the screens. One class per area; all go through [ApiClient].
library;

import '../core/network/api_client.dart';
import '../core/session/session.dart';
import 'models.dart';

final _api = ApiClient.instance;

PageResult<T> _page<T>(ApiResponse r, T Function(Map<String, dynamic>) map) {
  final p = r.pagination;
  return PageResult(r.items.map(map).toList(), page: p?.page ?? 1, total: p?.total ?? r.items.length, hasMore: p?.hasMore ?? false, message: r.message);
}

class OtpRequest {
  OtpRequest(Map<String, dynamic> d)
      : requestId = d['requestId'] as String,
        maskedDestination = (d['maskedDestination'] as String?) ?? '',
        resendAfter = (d['resendAfter'] as int?) ?? 30,
        devCode = d['devCode'] as String?;
  final String requestId;
  final String maskedDestination;
  final int resendAfter;

  /// Only in the API's mock mode (never in production) — handy while testing.
  final String? devCode;
}

abstract final class AuthApi {
  static Future<(OtpRequest, String)> requestOtp(String identifier) async {
    final r = await _api.post('/auth/otp/request', body: {'identifier': identifier, 'termsAccepted': true});
    return (OtpRequest(r.data), r.message);
  }

  static Future<(OtpRequest, String)> resendOtp(String requestId) async {
    final r = await _api.post('/auth/otp/resend', body: {'requestId': requestId});
    return (OtpRequest(r.data), r.message);
  }

  /// Verifies the code and stores the session. Returns the onboarding step (7 = done).
  static Future<int> verifyOtp(String requestId, String code) async {
    final r = await _api.post('/auth/otp/verify', body: {'requestId': requestId, 'code': code});
    await Session.instance.saveTokens(r.data);
    return Session.instance.onboardingStep;
  }

  /// GET /me — also refreshes the cached onboarding step.
  static Future<Map<String, dynamic>> me() async {
    final r = await _api.get('/me');
    final step = (r.data['onboarding'] as Map?)?['step'] as int?;
    if (step != null) await Session.instance.setStep(step);
    return r.data;
  }

  static Future<void> logout() async {
    final token = Session.instance.refreshToken;
    if (token != null) {
      try {
        await _api.post('/auth/logout', body: {'refreshToken': token});
      } catch (_) {}
    }
    await Session.instance.clear();
  }
}

/// Options for the Filters screen (GET /discover/filters).
class FilterOptions {
  FilterOptions(Map<String, dynamic> d)
      : professions = _pairs(d['professions'], 'name'),
        interests = _pairs(d['interests'], 'name'),
        experienceLevels = _pairs(d['experienceLevels'], 'label'),
        cities = _pairs(d['cities'], 'name'),
        defaultCityId = (d['defaults'] as Map?)?['cityId'] as int?,
        defaultKm = ((d['distance'] as Map?)?['defaultKm'] as num?)?.toDouble() ?? 25;

  static List<(int, String)> _pairs(Object? v, String key) =>
      ((v as List?) ?? const []).map((e) => ((e as Map)['id'] as int, e[key] as String)).toList();

  final List<(int, String)> professions;
  final List<(int, String)> interests;
  final List<(int, String)> experienceLevels;
  final List<(int, String)> cities;
  final int? defaultCityId;
  final double defaultKm;
}

abstract final class DiscoverApi {
  static FilterOptions? _options;

  static Future<FilterOptions> filterOptions({bool force = false}) async {
    if (_options != null && !force) return _options!;
    return _options = FilterOptions((await _api.get('/discover/filters')).data);
  }

  static Future<PageResult<Person>> discover(Map<String, dynamic> query, {int page = 1, int limit = 20}) async =>
      _page(await _api.get('/discover', query: {...query, 'page': page, 'limit': limit}), Person.fromJson);

  /// "Show N people" on Filters.
  static Future<int> count(Map<String, dynamic> query) async =>
      (await _api.get('/discover', query: {...query, 'limit': 1})).pagination?.total ?? 0;

  static Future<PersonDetail> person(int id) async => PersonDetail.fromJson((await _api.get('/users/$id')).data);

  static Future<List<String>> icebreakers(int id) async =>
      (((await _api.get('/users/$id/icebreakers')).data['suggestions'] as List?) ?? const []).cast<String>();

  static Future<String> setSaved(int id, bool saved) async =>
      (saved ? await _api.put('/users/$id/save') : await _api.delete('/users/$id/save')).message;
}

abstract final class NetworkApi {
  static Future<(ConnectionRequest, String)> sendRequest(int userId, String message) async {
    final r = await _api.post('/connections/requests', body: {'userId': userId, if (message.trim().isNotEmpty) 'message': message.trim()});
    return (ConnectionRequest.fromJson(r.data), r.message);
  }

  static Future<PageResult<ConnectionRequest>> requests({required bool sent, int page = 1}) async => _page(
        await _api.get('/connections/requests', query: {'direction': sent ? 'sent' : 'received', 'status': 'pending', 'page': page, 'limit': 50}),
        ConnectionRequest.fromJson,
      );

  static Future<String> accept(int requestId) async => (await _api.post('/connections/requests/$requestId/accept')).message;
  static Future<String> decline(int requestId) async => (await _api.post('/connections/requests/$requestId/decline')).message;
  static Future<String> withdraw(int requestId) async => (await _api.delete('/connections/requests/$requestId')).message;

  static Future<PageResult<Person>> connections({String? search, int page = 1}) async =>
      _page(await _api.get('/connections', query: {'search': search, 'page': page, 'limit': 50}), Person.fromJson);

  static Future<String> removeConnection(int userId) async => (await _api.delete('/connections/$userId')).message;

  static Future<InboxSummary> summary() async => InboxSummary.fromJson((await _api.get('/inbox/summary')).data);
}

abstract final class NotificationsApi {
  static Future<(PageResult<AppNotification>, int)> list({int page = 1}) async {
    final r = await _api.get('/notifications', query: {'page': page, 'limit': 30});
    return (_page(r, AppNotification.fromJson), (r.data['unreadCount'] as int?) ?? 0);
  }

  static Future<int> markRead(int id) async => ((await _api.patch('/notifications/$id/read')).data['unreadCount'] as int?) ?? 0;
  static Future<void> markAllRead() => _api.patch('/notifications/read-all');
}

abstract final class ChatApi {
  /// Inbox › Messages. Returns the page and the total unread count.
  static Future<(PageResult<Chat>, int)> list({String? search, int page = 1}) async {
    final r = await _api.get('/chats', query: {'search': search, 'page': page, 'limit': 50});
    return (_page(r, Chat.fromJson), (r.data['totalUnread'] as int?) ?? 0);
  }

  /// Open (or create) the chat with a connection.
  static Future<Chat> open(int userId) async => Chat.fromJson((await _api.post('/chats', body: {'userId': userId})).data);

  static Future<Chat> get(int id) async => Chat.fromJson((await _api.get('/chats/$id')).data);

  static Future<MessagePage> messages(int id, {int? before, int? after, int limit = 30}) async =>
      MessagePage.fromJson((await _api.get('/chats/$id/messages', query: {'before': before, 'after': after, 'limit': limit})).data);

  static Future<ChatMessage> send(int id, String body, String clientId) async =>
      ChatMessage.fromJson((await _api.post('/chats/$id/messages', body: {'body': body, 'clientId': clientId})).data);

  /// Returns the total unread count after marking.
  static Future<int> markRead(int id, {int? messageId}) async =>
      ((await _api.post('/chats/$id/read', body: {if (messageId != null) 'messageId': messageId})).data['totalUnread'] as int?) ?? 0;
}
