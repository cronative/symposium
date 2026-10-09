import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/onboarding_model.dart';
import '../../widgets/step_indicator.dart';

import 'step1_welcome_screen.dart';
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
  final OnboardingModel _model = OnboardingModel();

  int get _stepNumber {
    switch (_currentStep) {
      case OnboardingStep.welcome:
        return 1;
      case OnboardingStep.contact:
        return 2;
      case OnboardingStep.otp:
        return 3;
      case OnboardingStep.basicProfile:
        return 4;
      case OnboardingStep.professionalProfile:
        return 5;
      case OnboardingStep.interestsIntent:
        return 6;
      case OnboardingStep.privacySettings:
        return 7;
      case OnboardingStep.complete:
      case OnboardingStep.kynHome:
        return 8;
    }
  }

  String get _stepTitle {
    switch (_currentStep) {
      case OnboardingStep.welcome:
        return 'Welcome';
      case OnboardingStep.contact:
        return 'Identity';
      case OnboardingStep.otp:
        return 'OTP Verification';
      case OnboardingStep.basicProfile:
        return 'Basic Profile';
      case OnboardingStep.professionalProfile:
        return 'Professional Profile';
      case OnboardingStep.interestsIntent:
        return 'Intent & Interests';
      case OnboardingStep.privacySettings:
        return 'Discovery Radius';
      case OnboardingStep.complete:
        return 'Profile Ready';
      case OnboardingStep.kynHome:
        return 'KYN Home';
    }
  }

  void _restart() {
    setState(() {
      _currentStep = OnboardingStep.welcome;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool showIndicator = _currentStep != OnboardingStep.welcome &&
        _currentStep != OnboardingStep.complete &&
        _currentStep != OnboardingStep.kynHome;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            if (showIndicator)
              StepIndicator(
                currentStep: _stepNumber,
                totalSteps: 7,
                title: _stepTitle,
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                child: _buildCurrentScreen(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentStep) {
      case OnboardingStep.welcome:
        return Step1WelcomeScreen(
          key: const ValueKey('step1'),
          authMode: _model.authMode,
          onSelectMode: (mode) => setState(() => _model.authMode = mode),
          onContinue: (type) {
            setState(() {
              _model.contactType = type;
              _currentStep = OnboardingStep.contact;
            });
          },
        );

      case OnboardingStep.contact:
        return Step2ContactInputScreen(
          key: const ValueKey('step2'),
          authMode: _model.authMode,
          contactType: _model.contactType,
          onChangeContactType: (type) =>
              setState(() => _model.contactType = type),
          onSubmitContact: (code, phone, email) {
            setState(() {
              _model.countryCode = code;
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
            : _model.email;
        return Step3OtpVerifyScreen(
          key: const ValueKey('step3'),
          contactValue: contactValue,
          onVerifySuccess: (otp) {
            setState(() {
              _model.otpCode = otp;
              _model.isOtpVerified = true;
              _currentStep = OnboardingStep.basicProfile;
            });
          },
          onBack: () => setState(() => _currentStep = OnboardingStep.contact),
          onResendOtp: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'A fresh 6-digit OTP code has been dispatched.',
                  style: TextStyle(color: AppColors.white),
                ),
                backgroundColor: AppColors.surfaceElevated,
              ),
            );
          },
        );

      case OnboardingStep.basicProfile:
        return Step4BasicProfileScreen(
          key: const ValueKey('step4'),
          initialFullName: _model.fullName,
          initialCity: _model.city,
          initialAge: _model.age,
          initialBio: _model.bio,
          initialAvatarUrl: _model.avatarUrl,
          onSubmit: (name, city, age, bio, avatar) {
            setState(() {
              _model.fullName = name;
              _model.city = city;
              _model.age = age;
              _model.bio = bio;
              _model.avatarUrl = avatar;
              _currentStep = OnboardingStep.professionalProfile;
            });
          },
          onBack: () => setState(() => _currentStep = OnboardingStep.otp),
        );

      case OnboardingStep.professionalProfile:
        return Step5ProfessionalProfileScreen(
          key: const ValueKey('step5'),
          initialCompany: _model.company,
          initialRole: _model.role,
          initialIndustry: _model.industry,
          initialLinkedInUrl: _model.linkedInUrl,
          onSubmit: (company, role, industry, linkedIn) {
            setState(() {
              _model.company = company;
              _model.role = role;
              _model.industry = industry;
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
          key: const ValueKey('step6'),
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
          key: const ValueKey('step7'),
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
          key: const ValueKey('step8'),
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
