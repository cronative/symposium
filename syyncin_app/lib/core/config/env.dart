/// Where the app finds the SyyncIn API.
///
/// The server address lives here, so every `flutter run` / `flutter build` uses
/// it without any extra flag. Change [serverUrl] when the API moves (e.g. to
/// https://api.syyncin.app) — that's the only place to edit.
///
/// To test against the API on your Mac instead, override it for that run only:
///   flutter run -d chrome --dart-define=API_URL=http://localhost:4000
///   flutter run --dart-define=API_URL=http://10.0.2.2:4000          (Android emulator)
///   flutter run --dart-define=API_URL=http://192.168.1.20:4000      (real phone → Mac's Wi-Fi IP)
abstract final class Env {
  /// The live SyyncIn server (VPS). No trailing slash, no /api/v1.
  static const serverUrl = 'https://api.syyncin.trustiqlabs.com';

  static const _fromDefine = String.fromEnvironment('API_URL');

  static String get apiOrigin => (_fromDefine.isNotEmpty ? _fromDefine : serverUrl).replaceAll(RegExp(r'/+$'), '');

  static String get apiBase => '$apiOrigin/api/v1';
}
