import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/notifications/notifier.dart';
import '../../core/realtime/realtime_service.dart';
import '../../core/widgets/widgets.dart';
import '../../data/api.dart';
import '../../data/models.dart';

/// Bell → list of notifications (GET /notifications). New ones appear live.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<AppNotification> _items = [];
  bool _loading = true;
  String? _error;
  final _subs = <StreamSubscription<dynamic>>[];

  @override
  void initState() {
    super.initState();
    _load();
    final rt = RealtimeService.instance;
    _subs
      ..add(rt.notifications.listen((n) => setState(() => _items.insert(0, n))))
      ..add(rt.removedNotifications.listen((ids) => setState(() => _items.removeWhere((n) => ids.contains(n.id)))));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final (page, unread) = await NotificationsApi.list();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _loading = false;
        _error = null;
      });
      RealtimeService.instance.setUnread(unread);
    } on ApiException catch (e) {
      if (mounted) setState(() {
      _loading = false;
      _error = e.message;
    });
    }
  }

  Future<void> _open(AppNotification n) async {
    if (!n.isRead) {
      setState(() => n.isRead = true);
      try {
        RealtimeService.instance.setUnread(await NotificationsApi.markRead(n.id));
      } catch (_) {}
    }
    Notifier.openScreen(n.screen);
  }

  Future<void> _readAll() async {
    try {
      await NotificationsApi.markAllRead();
      setState(() {
        for (final n in _items) {
          n.isRead = true;
        }
      });
      RealtimeService.instance.setUnread(0);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _items.any((n) => !n.isRead);
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppTopBar(
        title: 'Notifications',
        actions: [if (hasUnread) AppBarTextAction(label: 'Mark all read', onPressed: _readAll)],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : (_error != null || _items.isEmpty)
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(32),
                            children: [
                              const SizedBox(height: 60),
                              const Center(child: AppIcon(AppIcons.bell, size: 36, color: AppColors.sub)),
                              const SizedBox(height: 12),
                              Text(_error ?? "You're all caught up.", textAlign: TextAlign.center, style: AppText.sectionTitle),
                              const SizedBox(height: 6),
                              const Text('Connection requests and replies will show up here.', textAlign: TextAlign.center, style: AppText.helper),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1, color: AppColors.line, indent: 24, endIndent: 24),
                            itemBuilder: (_, i) => _Tile(n: _items[i], onTap: () => _open(_items[i])),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.n, required this.onTap});
  final AppNotification n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: n.isRead ? null : AppColors.selectedFill,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen, vertical: AppSpace.x3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.badgeFill, shape: BoxShape.circle),
              child: Text(n.actorInitials, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.blue)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title, style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w600, color: AppColors.ink)),
                  const SizedBox(height: 3),
                  Text(n.body, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, height: 18 / 13, color: AppColors.sub)),
                  const SizedBox(height: 6),
                  Text(timeAgo(n.createdAt), style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.placeholder)),
                ],
              ),
            ),
            if (!n.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 8, top: 6),
                decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
