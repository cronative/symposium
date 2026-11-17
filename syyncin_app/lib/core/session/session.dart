import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Signed-in state: tokens + a little of the user, persisted in secure storage.
class Session extends ChangeNotifier {
  Session._();
  static final instance = Session._();

  static const _storage = FlutterSecureStorage();
  static const _kAccess = 'syyncin.access';
  static const _kRefresh = 'syyncin.refresh';
  static const _kUser = 'syyncin.userId';
  static const _kStep = 'syyncin.step';

  String? accessToken;
  String? refreshToken;
  int? userId;
  int onboardingStep = 1;

  bool get isSignedIn => refreshToken != null;
  bool get profileComplete => onboardingStep >= 7;

  /// Called when the session can't be refreshed (e.g. go to Login).
  VoidCallback? onExpired;

  Future<void> restore() async {
    try {
      accessToken = await _storage.read(key: _kAccess);
      refreshToken = await _storage.read(key: _kRefresh);
      userId = int.tryParse(await _storage.read(key: _kUser) ?? '');
      onboardingStep = int.tryParse(await _storage.read(key: _kStep) ?? '') ?? 1;
    } catch (_) {
      // Storage unavailable (tests, some browsers in private mode) → signed out.
      accessToken = refreshToken = null;
    }
  }

  /// Save the `{ accessToken, refreshToken, user }` block returned by verify / refresh.
  Future<void> saveTokens(Map<String, dynamic> d) async {
    accessToken = d['accessToken'] as String?;
    refreshToken = d['refreshToken'] as String?;
    final user = d['user'] is Map ? Map<String, dynamic>.from(d['user'] as Map) : const <String, dynamic>{};
    userId = (user['id'] as int?) ?? userId;
    onboardingStep = (user['onboardingStep'] as int?) ?? onboardingStep;
    await _persist();
    notifyListeners();
  }

  Future<void> setStep(int step) async {
    onboardingStep = step;
    await _persist();
    notifyListeners();
  }

  Future<void> clear() async {
    accessToken = refreshToken = null;
    userId = null;
    onboardingStep = 1;
    try {
      await _storage.deleteAll();
    } catch (_) {}
    notifyListeners();
  }

  /// Refresh failed → clear and let the app send the user to Login.
  Future<void> expire() async {
    await clear();
    onExpired?.call();
  }

  Future<void> _persist() async {
    try {
      await _storage.write(key: _kAccess, value: accessToken);
      await _storage.write(key: _kRefresh, value: refreshToken);
      await _storage.write(key: _kUser, value: userId?.toString());
      await _storage.write(key: _kStep, value: '$onboardingStep');
    } catch (_) {}
  }
}
