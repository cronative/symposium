import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app_keys.dart';
import 'app/routes.dart';
import 'app/web_phone_preview.dart';
import 'core/notifications/notifier.dart';
import 'core/realtime/realtime_service.dart';
import 'core/session/session.dart';
import 'core/theme/app_theme.dart';
import 'features/profile_setup/widgets/pickers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Live notifications (banner in foreground, system notification on Android/iOS in background).
  Notifier.instance.init();
  // Refresh token gone / account blocked → back to Login.
  Session.instance.onExpired = () {
    RealtimeService.instance.stop();
    SetupDraft.instance.reset();
    navigatorKey.currentState?.pushNamedAndRemoveUntil(Routes.login, (r) => false);
    messengerKey.currentState?.showSnackBar(const SnackBar(content: Text('Your session has ended. Please sign in again.')));
  };
  runApp(const SyyncInApp());
}

class SyyncInApp extends StatelessWidget {
  const SyyncInApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SyyncIn',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      theme: AppTheme.light,
      scrollBehavior: const _AppScrollBehavior(),
      initialRoute: Routes.splash,
      onGenerateRoute: Routes.onGenerate,
      builder: (context, child) => DefaultTextHeightBehavior(
        // Matches Figma: extra line-height is split evenly above/below glyphs.
        textHeightBehavior: const TextHeightBehavior(leadingDistribution: TextLeadingDistribution.even),
        child: MediaQuery(
          // Pixel-matched to Figma at 100 %; allow a little OS font scaling for accessibility.
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.15),
            ),
          ),
          // Web on a wide window: show the app inside a phone frame. Android / iOS: full screen.
          child: WebPhonePreview(child: child!),
        ),
      ),
    );
  }
}

/// Lets lists be dragged with a mouse / trackpad too (Flutter web blocks that by default),
/// so pull-to-refresh and swiping work in the browser preview like on a phone.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.unknown,
      };
}
