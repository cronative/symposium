export type AuthMode = 'signup' | 'signin';

export interface OnboardingState {
  // Step 1 & 2
  authMode: AuthMode;
  contactType: 'phone' | 'email';
  countryCode: string;
  phoneNumber: string;
  email: string;
  
  // Step 3
  otpCode: string;
  isOtpVerified: boolean;

  // Step 4: Basic Profile
  avatarUri: string;
  fullName: string;
  age: string;
  city: string;
  bio: string;

  // Step 5: Professional Profile
  company: string;
  role: string;
  industry: string;
  linkedInUrl: string;

  // Step 6: Interests & Intent
  currentIntents: string[];
  interests: string[];

  // Step 7: Privacy & Discovery
  enableKynDiscovery: boolean;
  discoveryRadiusKm: number;
  isProfilePrivate: boolean;
}

export type StepKey = 
  | 'welcome'
  | 'contact'
  | 'otp'
  | 'basic_profile'
  | 'professional_profile'
  | 'interests_intent'
  | 'privacy_settings'
  | 'complete';
