import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import '../../core/network/api_client.dart';
import '../../core/realtime/realtime_service.dart';
import '../../core/session/session.dart';
import '../../core/widgets/widgets.dart';
import '../../data/profile_sync.dart';

/// 01 — Splash: navy → teal gradient, logo card (radius 28, soft shadow),
/// light tagline. After ≥ 1.5 s routes to Home, profile setup or Welcome.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  /// Signed in → GET /me decides Home vs. profile setup; otherwise Welcome.
  Future<void> _route() async {
    final minDelay = Future<void>.delayed(const Duration(milliseconds: 1500));
    String next = Routes.welcome;
    final session = Session.instance;
    await session.restore();
    if (session.isSignedIn) {
      try {
        // Refreshes the token if needed, caches the step and pre-fills the profile.
        next = ProfileSync.routeForStep(await ProfileSync.load());
      } on ApiException catch (e) {
        // Offline: use what we know; anything else (expired, blocked) → start again.
        next = e.code == 'NETWORK_ERROR' && session.isSignedIn
            ? ProfileSync.routeForStep(session.onboardingStep)
            : Routes.welcome;
      }
      if (session.isSignedIn) RealtimeService.instance.start();
    }
    await minDelay;
    if (mounted) Navigator.of(context).pushReplacementNamed(next);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark, // white splash → dark status-bar icons
      child: const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: BrandLogo(width: 205, height: 160, radius: 28),
        ),
      ),
    );
  }
}
