import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/widgets/widgets.dart';

/// Web only: shows the whole app inside a phone frame (390 × 844, iPhone 14 / 15)
/// centred on a branded background, so it looks and behaves like the mobile app.
///
/// - Android / iOS builds: [child] is returned untouched (full-screen app).
/// - Web on a narrow window or a phone browser (< 600 px wide): full screen too.
/// - Inside the frame the app sees a phone-sized screen with status-bar and
///   home-indicator safe areas, so navigation, dialogs, bottom sheets and
///   snackbars all stay inside the phone. Mouse drag scrolls like a finger.
class WebPhonePreview extends StatelessWidget {
  const WebPhonePreview({super.key, required this.child});
  final Widget child;

  static const _screen = Size(390, 844);
  static const _bezel = 12.0;
  static const _statusBar = 47.0;
  static const _homeIndicator = 34.0;
  static const _minWindowWidth = 600.0;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (!kIsWeb || mq.size.width < _minWindowWidth) return child;

    final device = Size(_screen.width + _bezel * 2, _screen.height + _bezel * 2);
    // Shrink the phone (never enlarge) so it fits the window with a margin.
    final scale = ((mq.size.height - 48) / device.height).clamp(0.55, 1.0);
    const safe = EdgeInsets.only(top: _statusBar, bottom: _homeIndicator);
    final phoneMq = mq.copyWith(
      size: _screen,
      padding: safe,
      viewPadding: safe,
      viewInsets: EdgeInsets.zero,
      systemGestureInsets: EdgeInsets.zero,
    );
    final showBrand = mq.size.width >= 1100;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF2FF), Color(0xFFF5F8FD), Color(0xFFE4F8F3)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(left: -120, top: -80, child: _Glow(420, AppColors.accentBlue)),
          const Positioned(right: -140, bottom: -120, child: _Glow(480, AppColors.accentTeal)),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showBrand) ...[const _BrandPanel(), SizedBox(width: 96 * scale)],
                SizedBox(
                  width: device.width * scale,
                  height: device.height * scale,
                  child: FittedBox(
                    child: SizedBox.fromSize(
                      size: device,
                      child: _PhoneShell(
                        child: MediaQuery(
                          data: phoneMq,
                          child: ScrollConfiguration(behavior: const _PhoneScrollBehavior(), child: child),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Black bezel, rounded screen, Dynamic Island, status bar and home indicator.
class _PhoneShell extends StatelessWidget {
  const _PhoneShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WebPhonePreview._bezel),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F19),
        borderRadius: BorderRadius.circular(56),
        boxShadow: const [
          BoxShadow(color: Color(0x33062D69), blurRadius: 60, offset: Offset(0, 30)),
          BoxShadow(color: Color(0x1A062D69), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(44),
        child: ColoredBox(
          color: AppColors.white,
          child: Stack(
            children: [
              Positioned.fill(child: child),
              // Status bar + Dynamic Island + home indicator are decoration only.
              const Positioned(left: 0, right: 0, top: 0, child: IgnorePointer(child: _StatusBar())),
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      width: 134,
                      height: 5,
                      decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: WebPhonePreview._statusBar,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 122,
            height: 34,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(34, 6, 28, 0),
            child: Row(
              children: [
                Text('9:41', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111111))),
                Spacer(),
                Icon(Icons.signal_cellular_alt_rounded, size: 17, color: Color(0xFF111111)),
                SizedBox(width: 5),
                Icon(Icons.wifi_rounded, size: 17, color: Color(0xFF111111)),
                SizedBox(width: 5),
                Icon(Icons.battery_full_rounded, size: 19, color: Color(0xFF111111)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandLogo(width: 150, height: 118),
          SizedBox(height: 20),
          Text(
            'Your next connection could be closer than you think.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 26, height: 1.25, fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
          SizedBox(height: 12),
          Text(
            'Mobile preview — the app runs exactly as it does on a phone.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.5, color: AppColors.sub),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow(this.size, this.color);
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.7)),
      );
}

/// Touch-like scrolling with the mouse/trackpad and no desktop scrollbars.
class _PhoneScrollBehavior extends MaterialScrollBehavior {
  const _PhoneScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) => child;
}
