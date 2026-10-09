import React, { useState } from 'react';
import { View, StyleSheet, SafeAreaView, StatusBar, Alert } from 'react-native';
import { Colors } from '../theme/colors';
import { StepIndicator } from '../components/StepIndicator';
import { OnboardingState, StepKey, AuthMode } from '../types/onboarding';

import { Step1Welcome } from './Step1Welcome';
import { Step2ContactInput } from './Step2ContactInput';
import { Step3OtpVerify } from './Step3OtpVerify';
import { Step4BasicProfile } from './Step4BasicProfile';
import { Step5ProfessionalProfile } from './Step5ProfessionalProfile';
import { Step6InterestsIntent } from './Step6InterestsIntent';
import { Step7PrivacyDiscovery } from './Step7PrivacyDiscovery';
import { Step8CompleteSummary } from './Step8CompleteSummary';
import { KynHomePreview } from './KynHomePreview';

const INITIAL_STATE: OnboardingState = {
  authMode: 'signup',
  contactType: 'phone',
  countryCode: '+91',
  phoneNumber: '',
  email: '',
  otpCode: '',
  isOtpVerified: false,
  avatarUri: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&h=200&fit=crop&crop=face',
  fullName: '',
  age: '24',
  city: 'Mumbai',
  bio: '',
  company: '',
  role: '',
  industry: 'Technology & AI',
  linkedInUrl: '',
  currentIntents: ['experiences', 'cofounder'],
  interests: ['Artificial Intelligence', 'Product Design', 'Venture Capital'],
  enableKynDiscovery: true,
  discoveryRadiusKm: 5,
  isProfilePrivate: false,
};

export const OnboardingContainer: React.FC = () => {
  const [currentStep, setCurrentStep] = useState<StepKey>('welcome');
  const [state, setState] = useState<OnboardingState>(INITIAL_STATE);

  // Step 1 Handlers
  const handleSelectAuthMode = (mode: AuthMode) => {
    setState((prev) => ({ ...prev, authMode: mode }));
  };

  const handleStartContact = (type: 'phone' | 'email') => {
    setState((prev) => ({ ...prev, contactType: type }));
    setCurrentStep('contact');
  };

  // Step 2 Handlers
  const handleSubmitContact = (contact: { countryCode: string; phone: string; email: string }) => {
    setState((prev) => ({
      ...prev,
      countryCode: contact.countryCode,
      phoneNumber: contact.phone,
      email: contact.email,
    }));
    setCurrentStep('otp');
  };

  // Step 3 Handlers
  const handleVerifyOtp = (otp: string) => {
    setState((prev) => ({
      ...prev,
      otpCode: otp,
      isOtpVerified: true,
    }));
    // If sign in, could go straight to home, but for onboarding demo we go to profile setup
    setCurrentStep('basic_profile');
  };

  const handleResendOtp = () => {
    Alert.alert('OTP Sent', 'A fresh 6-digit verification code has been dispatched.');
  };

  // Step 4 Handlers
  const handleSubmitBasicProfile = (basic: {
    fullName: string;
    city: string;
    age: string;
    bio: string;
    avatarUri: string;
  }) => {
    setState((prev) => ({ ...prev, ...basic }));
    setCurrentStep('professional_profile');
  };

  // Step 5 Handlers
  const handleSubmitProfessional = (prof: {
    company: string;
    role: string;
    industry: string;
    linkedInUrl: string;
  }) => {
    setState((prev) => ({ ...prev, ...prof }));
    setCurrentStep('interests_intent');
  };

  const handleSkipProfessional = () => {
    setCurrentStep('interests_intent');
  };

  // Step 6 Handlers
  const handleSubmitInterests = (interestsData: {
    currentIntents: string[];
    interests: string[];
  }) => {
    setState((prev) => ({ ...prev, ...interestsData }));
    setCurrentStep('privacy_settings');
  };

  // Step 7 Handlers
  const handleSubmitPrivacy = (privacyData: {
    enableKynDiscovery: boolean;
    discoveryRadiusKm: number;
    isProfilePrivate: boolean;
  }) => {
    setState((prev) => ({ ...prev, ...privacyData }));
    setCurrentStep('complete');
  };

  // Step 8 Handlers
  const [inKynHome, setInKynHome] = useState(false);

  const handleEnterKyn = () => {
    setInKynHome(true);
  };

  const handleRestart = () => {
    setInKynHome(false);
    setCurrentStep('welcome');
    setState(INITIAL_STATE);
  };

  const getStepNumber = (): number => {
    switch (currentStep) {
      case 'welcome':
        return 1;
      case 'contact':
        return 2;
      case 'otp':
        return 3;
      case 'basic_profile':
        return 4;
      case 'professional_profile':
        return 5;
      case 'interests_intent':
        return 6;
      case 'privacy_settings':
        return 7;
      case 'complete':
        return 8;
      default:
        return 1;
    }
  };

  const getStepTitle = (): string => {
    switch (currentStep) {
      case 'welcome':
        return 'Welcome';
      case 'contact':
        return 'Identity';
      case 'otp':
        return 'OTP Verification';
      case 'basic_profile':
        return 'Basic Profile';
      case 'professional_profile':
        return 'Career & Role';
      case 'interests_intent':
        return 'Preferences';
      case 'privacy_settings':
        return 'Discovery Radius';
      case 'complete':
        return 'Ready';
      default:
        return '';
    }
  };

  if (inKynHome) {
    return (
      <SafeAreaView style={styles.safeArea}>
        <StatusBar barStyle="light-content" backgroundColor={Colors.background} />
        <KynHomePreview userData={state} onRestartOnboarding={handleRestart} />
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar barStyle="light-content" backgroundColor={Colors.background} />

      {/* Show Step Indicator for steps 2 to 7 */}
      {currentStep !== 'welcome' && currentStep !== 'complete' && (
        <StepIndicator
          currentStep={getStepNumber()}
          totalSteps={7}
          title={getStepTitle()}
        />
      )}

      <View style={styles.content}>
        {currentStep === 'welcome' && (
          <Step1Welcome
            authMode={state.authMode}
            onSelectMode={handleSelectAuthMode}
            onContinue={handleStartContact}
          />
        )}

        {currentStep === 'contact' && (
          <Step2ContactInput
            authMode={state.authMode}
            contactType={state.contactType}
            onChangeContactType={(t) => setState((prev) => ({ ...prev, contactType: t }))}
            onSubmitContact={handleSubmitContact}
            onBack={() => setCurrentStep('welcome')}
          />
        )}

        {currentStep === 'otp' && (
          <Step3OtpVerify
            contactValue={
              state.contactType === 'phone'
                ? `${state.countryCode} ${state.phoneNumber}`
                : state.email
            }
            onVerifySuccess={handleVerifyOtp}
            onBack={() => setCurrentStep('contact')}
            onResendOtp={handleResendOtp}
          />
        )}

        {currentStep === 'basic_profile' && (
          <Step4BasicProfile
            initialValues={{
              fullName: state.fullName,
              city: state.city,
              age: state.age,
              bio: state.bio,
              avatarUri: state.avatarUri,
            }}
            onSubmit={handleSubmitBasicProfile}
            onBack={() => setCurrentStep('otp')}
          />
        )}

        {currentStep === 'professional_profile' && (
          <Step5ProfessionalProfile
            initialValues={{
              company: state.company,
              role: state.role,
              industry: state.industry,
              linkedInUrl: state.linkedInUrl,
            }}
            onSubmit={handleSubmitProfessional}
            onSkip={handleSkipProfessional}
            onBack={() => setCurrentStep('basic_profile')}
          />
        )}

        {currentStep === 'interests_intent' && (
          <Step6InterestsIntent
            initialIntents={state.currentIntents}
            initialInterests={state.interests}
            onSubmit={handleSubmitInterests}
            onBack={() => setCurrentStep('professional_profile')}
          />
        )}

        {currentStep === 'privacy_settings' && (
          <Step7PrivacyDiscovery
            initialValues={{
              enableKynDiscovery: state.enableKynDiscovery,
              discoveryRadiusKm: state.discoveryRadiusKm,
              isProfilePrivate: state.isProfilePrivate,
            }}
            onSubmit={handleSubmitPrivacy}
            onBack={() => setCurrentStep('interests_intent')}
          />
        )}

        {currentStep === 'complete' && (
          <Step8CompleteSummary
            data={state}
            onEnterKyn={handleEnterKyn}
            onRestart={handleRestart}
          />
        )}
      </View>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  content: {
    flex: 1,
  },
});
