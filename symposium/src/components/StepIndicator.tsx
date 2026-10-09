import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Colors } from '../theme/colors';

interface Props {
  currentStep: number;
  totalSteps: number;
  title?: string;
}

export const StepIndicator: React.FC<Props> = ({ currentStep, totalSteps, title }) => {
  const progressPercent = Math.min(100, Math.max(0, (currentStep / totalSteps) * 100));

  return (
    <View style={styles.container}>
      <View style={styles.topRow}>
        <Text style={styles.stepText}>STEP {currentStep} OF {totalSteps}</Text>
        {title && <Text style={styles.titleText}>{title}</Text>}
      </View>
      <View style={styles.track}>
        <View style={[styles.fill, { width: `${progressPercent}%` }]} />
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 20,
    paddingVertical: 12,
  },
  topRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  stepText: {
    color: Colors.primaryLight,
    fontSize: 12,
    fontWeight: '700',
    letterSpacing: 1.2,
  },
  titleText: {
    color: Colors.textSecondary,
    fontSize: 13,
    fontWeight: '500',
  },
  track: {
    height: 4,
    backgroundColor: Colors.surfaceBorder,
    borderRadius: 2,
    overflow: 'hidden',
  },
  fill: {
    height: '100%',
    backgroundColor: Colors.primary,
    borderRadius: 2,
  },
});
