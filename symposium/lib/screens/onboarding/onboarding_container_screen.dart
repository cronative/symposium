import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/onboarding_model.dart';

import 'step1_welcome_screen.dart';
import 'sign_in_screen.dart';
import 'step2_contact_input_screen.dart';
import 'step3_otp_verify_screen.dart';
import 'step4_basic_profile_screen.dart';
import 'step5_professional_profile_screen.dart';
import 'step6_interests_intent_screen.dart';
import 'step7_privacy_discovery_screen.dart';
import 'step8_complete_summary_screen.dart';
import '../home/kyn_home_preview_screen.dart';

enum OnboardingStep {
  welcome,
  signIn,
  contact,
  otp,
  basicProfile,
  professionalProfile,
  interestsIntent,
  privacySettings,
  complete,
  kynHome,
}

class OnboardingContainerScreen extends StatefulWidget {
  const OnboardingContainerScreen({super.key});

  @override
  State<OnboardingContainerScreen> createState() =>
      _OnboardingContainerScreenState();
}

class _OnboardingContainerScreenState extends State<OnboardingContainerScreen> {
  OnboardingStep _currentStep = OnboardingStep.welcome;
  final OnboardingModel _model = OnboardingModel(
    fullName: 'Nisha Mehta',
    city: 'Bengaluru',
    age: '29',
    company: 'Independent',
    role: 'Product designer',
    linkedInUrl: 'https://linkedin.com/in/...',
  );

  void _restart() {
    setState(() {
      _currentStep = OnboardingStep.welcome;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          child: _buildCurrentScreen(),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentStep) {
      case OnboardingStep.welcome:
        return Step1WelcomeScreen(
          key: const ValueKey('welcome'),
          onSignUpMobile: () {
            setState(() {
              _model.authMode = AuthMode.signup;
              _model.contactType = ContactType.phone;
              _currentStep = OnboardingStep.contact;
            });
          },
          onSignUpEmail: () {
            setState(() {
              _model.authMode = AuthMode.signup;
              _model.contactType = ContactType.email;
              _currentStep = OnboardingStep.contact;
            });
          },
          onLogIn: () {
            setState(() {
              _model.authMode = AuthMode.signin;
              _currentStep = OnboardingStep.signIn;
            });
          },
        );

      case OnboardingStep.signIn:
        return SignInScreen(
          key: const ValueKey('signIn'),
          onSubmitSignIn: (type, phone, email) {
            setState(() {
              _model.authMode = AuthMode.signin;
              _model.contactType = type;
              _model.phoneNumber = phone;
              _model.email = email;
              _currentStep = OnboardingStep.otp;
            });
          },
          onGoToSignUp: () {
            setState(() {
              _model.authMode = AuthMode.signup;
              _currentStep = OnboardingStep.contact;
            });
          },
          onBack: () => setState(() => _currentStep = OnboardingStep.welcome),
        );

      case OnboardingStep.contact:
        return Step2ContactInputScreen(
          key: const ValueKey('contact'),
          initialContactType: _model.contactType,
          onSubmitContact: (type, phone, email) {
            setState(() {
              _model.contactType = type;
              _model.phoneNumber = phone;
              _model.email = email;
              _currentStep = OnboardingStep.otp;
            });
          },
          onBack: () => setState(() => _currentStep = OnboardingStep.welcome),
        );

      case OnboardingStep.otp:
        final contactValue = _model.contactType == ContactType.phone
            ? '${_model.countryCode} ${_model.phoneNumber}'
            : (_model.email.isNotEmpty ? _model.email : 'nisha.mehta@example.com');
        return Step3OtpVerifyScreen(
          key: const ValueKey('otp'),
          contactValue: contactValue,
          onVerifySuccess: (otp) {
            setState(() {
              _model.otpCode = otp;
              _model.isOtpVerified = true;
              if (_model.authMode == AuthMode.signin) {
                _currentStep = OnboardingStep.kynHome;
              } else {
                _currentStep = OnboardingStep.basicProfile;
              }
            });
          },
          onChangeContact: () =>
              setState(() => _currentStep = OnboardingStep.contact),
          onBack: () => setState(() {
            _currentStep = _model.authMode == AuthMode.signin
                ? OnboardingStep.signIn
                : OnboardingStep.contact;
          }),
          onResendOtp: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'A fresh 6-digit verification code was dispatched.',
                  style: TextStyle(color: AppColors.white),
                ),
                backgroundColor: AppColors.primary,
              ),
            );
          },
        );

      case OnboardingStep.basicProfile:
        return Step4BasicProfileScreen(
          key: const ValueKey('basicProfile'),
          initialFullName: _model.fullName,
          initialCity: _model.city,
          initialBirthDate: _model.birthDate,
          onSubmit: (name, city, birthDate, calculatedAge) {
            setState(() {
              _model.fullName = name;
              _model.city = city;
              _model.birthDate = birthDate;
              _model.age = (calculatedAge ?? 29).toString();
              _currentStep = OnboardingStep.professionalProfile;
            });
          },
          onBack: () => setState(() => _currentStep = OnboardingStep.otp),
        );

      case OnboardingStep.professionalProfile:
        return Step5ProfessionalProfileScreen(
          key: const ValueKey('professionalProfile'),
          initialCompany: _model.company,
          initialRole: _model.role,
          initialLinkedInUrl: _model.linkedInUrl,
          onSubmit: (company, role, linkedIn) {
            setState(() {
              _model.company = company;
              _model.role = role;
              _model.linkedInUrl = linkedIn;
              _currentStep = OnboardingStep.interestsIntent;
            });
          },
          onSkip: () => setState(
              () => _currentStep = OnboardingStep.interestsIntent),
          onBack: () =>
              setState(() => _currentStep = OnboardingStep.basicProfile),
        );

      case OnboardingStep.interestsIntent:
        return Step6InterestsIntentScreen(
          key: const ValueKey('interestsIntent'),
          initialIntents: _model.currentIntents,
          initialInterests: _model.interests,
          onSubmit: (intents, interests) {
            setState(() {
              _model.currentIntents = intents;
              _model.interests = interests;
              _currentStep = OnboardingStep.privacySettings;
            });
          },
          onBack: () => setState(
              () => _currentStep = OnboardingStep.professionalProfile),
        );

      case OnboardingStep.privacySettings:
        return Step7PrivacyDiscoveryScreen(
          key: const ValueKey('privacySettings'),
          initialEnableKynDiscovery: _model.enableKynDiscovery,
          initialDiscoveryRadiusKm: _model.discoveryRadiusKm,
          initialIsProfilePrivate: _model.isProfilePrivate,
          onSubmit: (kyn, radius, isPrivate) {
            setState(() {
              _model.enableKynDiscovery = kyn;
              _model.discoveryRadiusKm = radius;
              _model.isProfilePrivate = isPrivate;
              _currentStep = OnboardingStep.complete;
            });
          },
          onBack: () =>
              setState(() => _currentStep = OnboardingStep.interestsIntent),
        );

      case OnboardingStep.complete:
        return Step8CompleteSummaryScreen(
          key: const ValueKey('complete'),
          model: _model,
          onEnterKyn: () =>
              setState(() => _currentStep = OnboardingStep.kynHome),
          onRestart: _restart,
        );

      case OnboardingStep.kynHome:
        return KynHomePreviewScreen(
          key: const ValueKey('kynHome'),
          userData: _model,
          onRestartOnboarding: _restart,
        );
    }
  }
}
