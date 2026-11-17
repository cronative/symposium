/// Web / unsupported platforms: no system notifications (the in-app banner is used).
class SystemNotifier {
  static Future<void> init(void Function(String? payload) onTap) async {}
  static Future<void> show({required int id, required String title, required String body, String? payload}) async {}
}
