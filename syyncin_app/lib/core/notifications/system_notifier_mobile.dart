import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android / iOS system notifications (shown when the app is in the background
/// but the live connection is still open). Push (FCM) will reuse this later.
class SystemNotifier {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const _channel = AndroidNotificationDetails(
    'connections',
    'Connections',
    channelDescription: 'Connection requests and accepted requests',
    importance: Importance.high,
    priority: Priority.high,
  );

  static Future<void> init(void Function(String? payload) onTap) async {
    final supported = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
    if (!supported || _ready) return;
    try {
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (r) => onTap(r.payload),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (e) {
      debugPrint('Local notifications unavailable: $e');
    }
  }

  static Future<void> show({required int id, required String title, required String body, String? payload}) async {
    if (!_ready) return;
    await _plugin.show(id, title, body, const NotificationDetails(android: _channel, iOS: DarwinNotificationDetails()), payload: payload);
  }
}
