import 'dart:async';

import 'package:dio/dio.dart';

import '../config/env.dart';
import '../session/session.dart';

/// Every API response is `{ status: 1|0, data: {}, message }`.
class ApiResponse {
  ApiResponse(this.data, this.message);

  /// Always an object. Lists live in `data['items']`.
  final Map<String, dynamic> data;
  final String message;

  List<Map<String, dynamic>> get items =>
      ((data['items'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  Pagination? get pagination => data['pagination'] is Map ? Pagination.fromJson(Map<String, dynamic>.from(data['pagination'] as Map)) : null;
}

class Pagination {
  const Pagination({required this.page, required this.limit, required this.total, required this.totalPages});
  factory Pagination.fromJson(Map<String, dynamic> j) =>
      Pagination(page: j['page'] as int, limit: j['limit'] as int, total: j['total'] as int, totalPages: j['totalPages'] as int);
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  bool get hasMore => page < totalPages;
}

/// Failure from the API (`status: 0`) or the network. Show [message]; branch on [code].
class ApiException implements Exception {
  ApiException({required this.code, required this.message, this.statusCode, Map<String, dynamic>? data}) : data = data ?? const {};

  factory ApiException.network() =>
      ApiException(code: 'NETWORK_ERROR', message: "Can't reach SyyncIn right now. Check your connection and try again.");

  final String code;
  final String message;
  final int? statusCode;
  final Map<String, dynamic> data;

  /// Validation errors keyed by field name.
  Map<String, String> get fieldErrors => {
        for (final e in (data['errors'] as List?) ?? const [])
          if (e is Map) '${e['field']}': '${e['message']}',
      };

  @override
  String toString() => message;
}

/// Thin Dio wrapper: adds the bearer token, unwraps the envelope, refreshes once on 401.
class ApiClient {
  ApiClient._();
  static final instance = ApiClient._();

  final _dio = Dio(BaseOptions(
    baseUrl: Env.apiBase,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 25),
    validateStatus: (_) => true, // we read the envelope ourselves
  ));
  Completer<bool>? _refreshing;

  Future<ApiResponse> get(String path, {Map<String, dynamic>? query}) => _send('GET', path, query: query);
  Future<ApiResponse> post(String path, {Object? body}) => _send('POST', path, body: body ?? const {});
  Future<ApiResponse> put(String path, {Object? body}) => _send('PUT', path, body: body ?? const {});
  Future<ApiResponse> patch(String path, {Object? body}) => _send('PATCH', path, body: body ?? const {});
  Future<ApiResponse> delete(String path) => _send('DELETE', path);

  /// Multipart upload of one image (selfie / profile photo).
  Future<ApiResponse> upload(String path, {required String field, required List<int> bytes, required String filename, required String mime}) {
    final parts = mime.split('/');
    return _send('POST', path, formBuilder: () => FormData.fromMap({
          field: MultipartFile.fromBytes(bytes, filename: filename, contentType: DioMediaType(parts.first, parts.length > 1 ? parts[1] : 'jpeg')),
        }));
  }

  Future<ApiResponse> _send(String method, String path, {Map<String, dynamic>? query, Object? body, FormData Function()? formBuilder, bool retry = true}) async {
    final session = Session.instance;
    final q = query == null ? null : (Map<String, dynamic>.from(query)..removeWhere((_, v) => v == null || (v is String && v.isEmpty)));
    Response<dynamic> res;
    try {
      res = await _dio.request<dynamic>(
        path,
        data: formBuilder != null ? formBuilder() : body, // FormData can't be re-sent, so it's rebuilt on retry
        queryParameters: q,
        options: Options(method: method, headers: {if (session.accessToken != null) 'Authorization': 'Bearer ${session.accessToken}'}),
      );
    } on DioException {
      throw ApiException.network();
    }

    final json = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : <String, dynamic>{};
    final isAuthCall = path.startsWith('/auth/');
    if (res.statusCode == 401 && retry && !isAuthCall && session.refreshToken != null) {
      if (await refresh()) return _send(method, path, query: query, body: body, formBuilder: formBuilder, retry: false);
      await session.expire();
    }

    final data = json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : <String, dynamic>{};
    final message = (json['message'] as String?) ?? '';
    if (json['status'] == 1) return ApiResponse(data, message);
    throw ApiException(
      code: (data['code'] as String?) ?? 'UNKNOWN',
      message: message.isNotEmpty ? message : 'Something went wrong. Please try again.',
      statusCode: res.statusCode,
      data: data,
    );
  }

  /// Rotate tokens once, shared by concurrent callers. Returns false if the session is gone.
  Future<bool> refresh() {
    final pending = _refreshing;
    if (pending != null) return pending.future;
    final c = Completer<bool>();
    _refreshing = c;
    () async {
      try {
        final r = await _send('POST', '/auth/refresh', body: {'refreshToken': Session.instance.refreshToken}, retry: false);
        await Session.instance.saveTokens(r.data);
        c.complete(true);
      } catch (_) {
        c.complete(false);
      } finally {
        _refreshing = null;
      }
    }();
    return c.future;
  }
}
