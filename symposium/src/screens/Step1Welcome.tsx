import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '../theme/colors';
import { Button } from '../components/Button';
import { AuthMode } from '../types/onboarding';

interface Props {
  authMode: AuthMode;
  onSelectMode: (mode: AuthMode) => void;
  onContinue: (contactType: 'phone' | 'email') => void;
}

export const Step1Welcome: React.FC<Props> = ({
  authMode,
  onSelectMode,
  onContinue,
}) => {
  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      {/* Brand Header */}
      <View style={styles.brandContainer}>
        <View style={styles.logoBadge}>
          <Ionicons name="compass-outline" size={36} color={Colors.primaryLight} />
        </View>
        <Text style={styles.brandTitle}>SYMPOSIUM</Text>
        <Text style={styles.brandSubtitle}>
          Real-World Intent. Verified Neighbors. Curated Experiences.
        </Text>
      </View>

      {/* Mode Switcher Tab (Sign Up vs Sign In) */}
      <View style={styles.toggleContainer}>
        <TouchableOpacity
          style={[styles.toggleBtn, authMode === 'signup' && styles.toggleBtnActive]}
          onPress={() => onSelectMode('signup')}
          activeOpacity={0.8}
        >
          <Text
            style={[
              styles.toggleBtnText,
              authMode === 'signup' && styles.toggleBtnTextActive,
            ]}
          >
            Create Account
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.toggleBtn, authMode === 'signin' && styles.toggleBtnActive]}
          onPress={() => onSelectMode('signin')}
          activeOpacity={0.8}
        >
          <Text
            style={[
              styles.toggleBtnText,
              authMode === 'signin' && styles.toggleBtnTextActive,
            ]}
          >
            Sign In
          </Text>
        </TouchableOpacity>
      </View>

      {/* Highlights */}
      <View style={styles.highlightsContainer}>
        <View style={styles.highlightItem}>
          <View style={[styles.iconCircle, { backgroundColor: 'rgba(99, 102, 241, 0.15)' }]}>
            <Ionicons name="people" size={18} color={Colors.primaryLight} />
          </View>
          <View style={styles.highlightTextWrap}>
            <Text style={styles.highlightTitle}>Know Your Neighbor (KYN)</Text>
            <Text style={styles.highlightDesc}>
              Connect with nearby verified professionals without exposing exact GPS.
            </Text>
          </View>
        </View>

        <View style={styles.highlightItem}>
          <View style={[styles.iconCircle, { backgroundColor: 'rgba(16, 185, 129, 0.15)' }]}>
            <Ionicons name="briefcase" size={18} color={Colors.accent} />
          </View>
          <View style={styles.highlightTextWrap}>
            <Text style={styles.highlightTitle}>Seek Marketplace</Text>
            <Text style={styles.highlightDesc}>
              Jobs, freelance gigs, co-founders, and mentorship matched by intent.
            </Text>
          </View>
        </View>

        <View style={styles.highlightItem}>
          <View style={[styles.iconCircle, { backgroundColor: 'rgba(245, 158, 11, 0.15)' }]}>
            <Ionicons name="calendar" size={18} color={Colors.warning} />
          </View>
          <View style={styles.highlightTextWrap}>
            <Text style={styles.highlightTitle}>Curated Experiences</Text>
            <Text style={styles.highlightDesc}>
              Real-world small group dinners, talks, and community sessions.
            </Text>
          </View>
        </View>
      </View>

      {/* Action Buttons */}
      <View style={styles.actionsContainer}>
        <Button
          title="Continue with Mobile Number"
          icon={<Ionicons name="phone-portrait-outline" size={20} color={Colors.white} />}
          onPress={() => onContinue('phone')}
        />
        <Button
          title="Continue with Email"
          variant="secondary"
          icon={<Ionicons name="mail-outline" size={20} color={Colors.textPrimary} />}
          onPress={() => onContinue('email')}
        />
      </View>

      <Text style={styles.footerNotice}>
        By continuing, you agree to our{' '}
        <Text style={styles.linkText}>Community Guidelines</Text> &{' '}
        <Text style={styles.linkText}>Privacy Policy</Text>.
      </Text>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 24,
    paddingTop: 40,
    paddingBottom: 32,
    justifyContent: 'space-between',
  },
  brandContainer: {
    alignItems: 'center',
    marginBottom: 28,
  },
  logoBadge: {
    width: 68,
    height: 68,
    borderRadius: 20,
    backgroundColor: Colors.surfaceElevated,
    borderWidth: 1.5,
    borderColor: Colors.surfaceBorder,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
  },
  brandTitle: {
    fontSize: 26,
    fontWeight: '800',
    color: Colors.textPrimary,
    letterSpacing: 2,
  },
  brandSubtitle: {
    fontSize: 14,
    color: Colors.textSecondary,
    textAlign: 'center',
    marginTop: 8,
    lineHeight: 20,
    paddingHorizontal: 16,
  },
  toggleContainer: {
    flexDirection: 'row',
    backgroundColor: Colors.surface,
    borderRadius: 14,
    padding: 4,
    marginBottom: 24,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
  },
  toggleBtn: {
    flex: 1,
    paddingVertical: 10,
    borderRadius: 10,
    alignItems: 'center',
  },
  toggleBtnActive: {
    backgroundColor: Colors.surfaceElevated,
    shadowColor: Colors.black,
    shadowOpacity: 0.2,
    shadowRadius: 4,
    elevation: 2,
  },
  toggleBtnText: {
    color: Colors.textMuted,
    fontSize: 14,
    fontWeight: '600',
  },
  toggleBtnTextActive: {
    color: Colors.textPrimary,
    fontWeight: '700',
  },
  highlightsContainer: {
    backgroundColor: Colors.surface,
    borderRadius: 18,
    padding: 16,
    marginBottom: 28,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
    gap: 16,
  },
  highlightItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
  },
  iconCircle: {
    width: 40,
    height: 40,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  highlightTextWrap: {
    flex: 1,
  },
  highlightTitle: {
    color: Colors.textPrimary,
    fontSize: 14,
    fontWeight: '700',
    marginBottom: 2,
  },
  highlightDesc: {
    color: Colors.textSecondary,
    fontSize: 12,
    lineHeight: 16,
  },
  actionsContainer: {
    gap: 12,
    marginBottom: 20,
  },
  footerNotice: {
    textAlign: 'center',
    color: Colors.textMuted,
    fontSize: 12,
    lineHeight: 18,
  },
  linkText: {
    color: Colors.primaryLight,
    fontWeight: '600',
  },
});
