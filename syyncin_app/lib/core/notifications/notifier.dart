import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_keys.dart';
import '../../app/routes.dart';
import '../../data/models.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/home/models/discovery_state.dart';
import '../realtime/realtime_service.dart';
import '../theme/app_colors.dart';
import 'system_notifier_stub.dart' if (dart.library.io) 'system_notifier_mobile.dart';

/// Shows live notifications:
/// - app in the foreground → in-app banner (all platforms, incl. web)
/// - app in the background → system notification (Android / iOS)
/// Tapping either opens the right Inbox section.
class Notifier with WidgetsBindingObserver {
  Notifier._();
  static final instance = Notifier._();

  StreamSubscription<AppNotification>? _sub;
  StreamSubscription<ChatEvent>? _chatSub;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;
  OverlayEntry? _banner;
  Timer? _hideTimer;

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    await SystemNotifier.init(openScreen);
    _sub ??= RealtimeService.instance.notifications.listen(_onNotification);
    _chatSub ??= RealtimeService.instance.messages.listen(_onChatMessage);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _lifecycle = state;

  void _onNotification(AppNotification n) {
    if (_lifecycle == AppLifecycleState.resumed) {
      _showBanner(n);
    } else {
      SystemNotifier.show(id: n.id, title: n.title, body: n.body, payload: n.screen);
    }
  }

  /// A chat message from someone else, unless that chat is open on screen.
  void _onChatMessage(ChatEvent e) {
    if (e.message.isMine || RealtimeService.instance.activeChatId == e.conversationId) return;
    final n = AppNotification.fromJson({
      'id': -e.message.id, // keeps chat banners apart from notification ids
      'type': 'chat.message',
      'title': e.senderName ?? 'New message',
      'body': e.message.body,
      'data': {'screen': 'chat:${e.conversationId}'},
      'actor': {'fullName': e.senderName},
    });
    _onNotification(n);
  }

  /// Navigate for a notification's `data.screen`.
  static void openScreen(String? screen) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    if (screen != null && screen.startsWith('chat:')) {
      final id = int.tryParse(screen.substring(5));
      if (id == null) return;
      nav.popUntil((r) => r.settings.name == Routes.home || r.isFirst);
      AppNav.openInbox(InboxSegment.messages);
      nav.pushNamed(Routes.chat, arguments: ChatArgs(conversationId: id));
      return;
    }
    if (screen == 'inbox.connections') {
      AppNav.openInbox(InboxSegment.connections);
    } else {
      AppNav.openInbox(InboxSegment.requests);
    }
    nav.popUntil((r) => r.settings.name == Routes.home || r.isFirst);
  }

  void _showBanner(AppNotification n) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    _hide();
    _banner = OverlayEntry(
      builder: (_) => _Banner(
        notification: n,
        onTap: () {
          _hide();
          openScreen(n.screen);
        },
        onDismiss: _hide,
      ),
    );
    overlay.insert(_banner!);
    _hideTimer = Timer(const Duration(seconds: 5), _hide);
  }

  void _hide() {
    _hideTimer?.cancel();
    _banner?.remove();
    _banner = null;
  }
}

class _Banner extends StatefulWidget {
  const _Banner({required this.notification, required this.onTap, required this.onDismiss});
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 260))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    return Positioned(
      left: 12,
      right: 12,
      top: MediaQuery.of(context).padding.top + 8,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, -1.2), end: Offset.zero).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic)),
        child: Dismissible(
          key: ValueKey(n.id),
          direction: DismissDirection.up,
          onDismissed: (_) => widget.onDismiss(),
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line),
                  boxShadow: const [BoxShadow(color: AppColors.shadowNavy12, blurRadius: 24, offset: Offset(0, 8))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.badgeFill, shape: BoxShape.circle),
                      child: Text(n.actorInitials, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.blue)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(n.title, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                          const SizedBox(height: 2),
                          Text(
                            n.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, height: 18 / 13, color: AppColors.sub),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('View', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.blue)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
