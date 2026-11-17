import 'package:flutter/material.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/home/connect_request_screen.dart';
import '../features/home/home_screen.dart';
import '../features/home/models/person.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/home/person_profile_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/membership_screen.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/onboarding/welcome_screen.dart';
import '../features/profile_setup/basic_profile_screen.dart';
import '../features/profile_setup/community_screen.dart';
import '../features/profile_setup/interests_screen.dart';
import '../features/profile_setup/mindset_screen.dart';
import '../features/profile_setup/professional_profile_screen.dart';
import '../features/profile_setup/selfie_screen.dart';
import '../features/profile_setup/verified_screen.dart';

abstract final class Routes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const otp = '/otp';
  static const basicProfile = '/setup/about-you';
  static const professional = '/setup/work';
  static const interests = '/setup/interests';
  static const mindset = '/setup/mindset';
  static const community = '/setup/community';
  static const selfie = '/setup/selfie';
  static const verified = '/setup/verified';
  static const home = '/home';
  static const person = '/person';
  static const connect = '/connect';
  static const editProfile = '/profile/edit';
  static const notifications = '/notifications';
  static const chat = '/chat';
  static const membership = '/membership';

  static Route<dynamic> onGenerate(RouteSettings s) {
    final Widget page = switch (s.name) {
      splash => const SplashScreen(),
      welcome => const WelcomeScreen(),
      onboarding => const OnboardingScreen(),
      login => const LoginScreen(),
      otp => OtpScreen(args: s.arguments as OtpArgs),
      basicProfile => const BasicProfileScreen(),
      professional => const ProfessionalProfileScreen(),
      interests => const InterestsScreen(),
      mindset => const MindsetScreen(),
      community => const CommunityScreen(),
      selfie => const SelfieScreen(),
      verified => const VerifiedScreen(),
      home => const HomeScreen(),
      person => PersonProfileScreen(userId: s.arguments as int),
      editProfile => const EditProfileScreen(),
      connect => ConnectRequestScreen(person: s.arguments as Person),
      notifications => const NotificationsScreen(),
      chat => ChatScreen(args: s.arguments as ChatArgs),
      membership => const MembershipScreen(),
      _ => const SplashScreen(),
    };
    if (s.name == welcome || s.name == verified) {
      return PageRouteBuilder(
        settings: s,
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      );
    }
    // Screens that pop a result must use a route of the same type, or
    // Navigator.pushNamed<T> fails its cast to Route<T?> and nothing opens.
    return switch (s.name) {
      connect => MaterialPageRoute<String>(settings: s, builder: (_) => page), // pops the "request sent" message
      editProfile => MaterialPageRoute<bool>(settings: s, builder: (_) => page), // pops true when saved
      _ => MaterialPageRoute<dynamic>(settings: s, builder: (_) => page),
    };
  }
}
