import React from 'react';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { OnboardingContainer } from './src/screens/OnboardingContainer';

export default function App() {
  return (
    <SafeAreaProvider>
      <OnboardingContainer />
    </SafeAreaProvider>
  );
}
