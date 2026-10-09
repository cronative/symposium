import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  Image,
  ScrollView,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '../theme/colors';
import { Button } from '../components/Button';
import { OnboardingState } from '../types/onboarding';

interface Props {
  data: OnboardingState;
  onEnterKyn: () => void;
  onRestart: () => void;
}

export const Step8CompleteSummary: React.FC<Props> = ({
  data,
  onEnterKyn,
  onRestart,
}) => {
  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      {/* Celebration Header */}
      <View style={styles.header}>
        <View style={styles.successIconBadge}>
          <Ionicons name="checkmark-circle" size={48} color={Colors.accent} />
        </View>
        <Text style={styles.title}>You're All Set!</Text>
        <Text style={styles.subtitle}>
          Your Symposium profile is live and your local neighborhood network is ready to explore.
        </Text>
      </View>

      {/* Profile Card Preview */}
      <View style={styles.profileCard}>
        <View style={styles.cardHeader}>
          <Image source={{ uri: data.avatarUri }} style={styles.avatar} />
          <View style={{ flex: 1, marginLeft: 14 }}>
            <View style={styles.nameRow}>
              <Text style={styles.name}>{data.fullName || 'Member'}</Text>
              <Ionicons name="shield-checkmark" size={18} color={Colors.accent} />
            </View>
            <Text style={styles.roleText}>
              {data.role ? `${data.role} at ${data.company}` : 'Community Member'}
            </Text>
            <View style={styles.locationRow}>
              <Ionicons name="location" size={13} color={Colors.primaryLight} />
              <Text style={styles.locationText}>
                {data.city || 'Mumbai'} • {data.age || '25'} yrs
              </Text>
            </View>
          </View>
        </View>

        {data.bio ? <Text style={styles.bioText}>"{data.bio}"</Text> : null}

        {/* Selected Intents */}
        <View style={styles.divider} />
        <Text style={styles.sectionHeading}>CURRENT INTENT</Text>
        <View style={styles.intentsRow}>
          {data.currentIntents.map((item) => (
            <View key={item} style={styles.intentBadge}>
              <Ionicons name="flash" size={12} color={Colors.warning} />
              <Text style={styles.intentBadgeText}>{item}</Text>
            </View>
          ))}
        </View>

        {/* Selected Interests */}
        <Text style={[styles.sectionHeading, { marginTop: 14 }]}>CORE INTERESTS</Text>
        <View style={styles.interestsRow}>
          {data.interests.map((t) => (
            <View key={t} style={styles.interestPill}>
              <Text style={styles.interestPillText}>{t}</Text>
            </View>
          ))}
        </View>

        {/* Discovery & Privacy Summary */}
        <View style={styles.discoverySummary}>
          <Ionicons
            name={data.enableKynDiscovery ? 'eye' : 'eye-off'}
            size={16}
            color={data.enableKynDiscovery ? Colors.accent : Colors.error}
          />
          <Text style={styles.discoverySummaryText}>
            KYN Discovery:{' '}
            <Text style={{ fontWeight: '700', color: Colors.textPrimary }}>
              {data.enableKynDiscovery
                ? `Active within ${data.discoveryRadiusKm} km`
                : 'Private Mode (Hidden from nearby search)'}
            </Text>
          </Text>
        </View>
      </View>

      {/* Ready Action */}
      <View style={styles.actions}>
        <Button
          title="Enter KYN (Know Your Neighbor)"
          icon={<Ionicons name="compass" size={20} color={Colors.white} />}
          onPress={onEnterKyn}
        />
        <Button
          title="Restart Demo / Edit Onboarding"
          variant="ghost"
          onPress={onRestart}
          style={{ marginTop: 8 }}
        />
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 24,
    paddingTop: 24,
    paddingBottom: 36,
  },
  header: {
    alignItems: 'center',
    marginBottom: 24,
  },
  successIconBadge: {
    marginBottom: 12,
  },
  title: {
    fontSize: 26,
    fontWeight: '800',
    color: Colors.textPrimary,
    marginBottom: 6,
  },
  subtitle: {
    fontSize: 14,
    color: Colors.textSecondary,
    textAlign: 'center',
    lineHeight: 20,
    paddingHorizontal: 12,
  },
  profileCard: {
    backgroundColor: Colors.surface,
    borderRadius: 20,
    padding: 20,
    borderWidth: 1.5,
    borderColor: Colors.surfaceBorder,
    marginBottom: 28,
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  avatar: {
    width: 64,
    height: 64,
    borderRadius: 32,
    borderWidth: 2,
    borderColor: Colors.primary,
  },
  nameRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  name: {
    fontSize: 18,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  roleText: {
    color: Colors.textSecondary,
    fontSize: 13,
    marginTop: 2,
  },
  locationRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    marginTop: 4,
  },
  locationText: {
    color: Colors.textMuted,
    fontSize: 12,
  },
  bioText: {
    color: Colors.textSecondary,
    fontSize: 13,
    fontStyle: 'italic',
    marginTop: 14,
    lineHeight: 18,
  },
  divider: {
    height: 1,
    backgroundColor: Colors.surfaceBorder,
    marginVertical: 16,
  },
  sectionHeading: {
    color: Colors.textMuted,
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 1,
    marginBottom: 8,
  },
  intentsRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
  },
  intentBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: 'rgba(245, 158, 11, 0.12)',
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 8,
  },
  intentBadgeText: {
    color: Colors.warning,
    fontSize: 12,
    fontWeight: '600',
  },
  interestsRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
  },
  interestPill: {
    backgroundColor: Colors.surfaceElevated,
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 8,
  },
  interestPillText: {
    color: Colors.textSecondary,
    fontSize: 12,
  },
  discoverySummary: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.surfaceElevated,
    padding: 12,
    borderRadius: 12,
    marginTop: 18,
    gap: 10,
  },
  discoverySummaryText: {
    color: Colors.textSecondary,
    fontSize: 12,
  },
  actions: {
    gap: 8,
  },
});
