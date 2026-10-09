import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Image,
  TouchableOpacity,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '../theme/colors';
import { OnboardingState } from '../types/onboarding';

interface Props {
  userData: OnboardingState;
  onRestartOnboarding: () => void;
}

const NEARBY_PEOPLE = [
  {
    id: '1',
    name: 'Aarav Sharma',
    role: 'AI Research Engineer',
    company: 'HyperScale AI',
    distance: '1.2 km away',
    area: 'Bandra West',
    mutuals: 4,
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop&crop=face',
    intent: 'Looking for Co-founder',
    verified: true,
  },
  {
    id: '2',
    name: 'Pooja Mehta',
    role: 'Principal Designer',
    company: 'Studio Craft',
    distance: '2.5 km away',
    area: 'Khar West',
    mutuals: 7,
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&h=200&fit=crop&crop=face',
    intent: 'Hosting Design Dinners',
    verified: true,
  },
  {
    id: '3',
    name: 'Vikram Patel',
    role: 'Angel Investor / VP',
    company: 'Nexus Ventures',
    distance: '3.1 km away',
    area: 'Juhu',
    mutuals: 2,
    avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&h=200&fit=crop&crop=face',
    intent: 'Mentorship & Angel Checks',
    verified: true,
  },
];

export const KynHomePreview: React.FC<Props> = ({
  userData,
  onRestartOnboarding,
}) => {
  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      {/* Top Bar */}
      <View style={styles.topBar}>
        <View>
          <View style={styles.locationTag}>
            <Ionicons name="location" size={14} color={Colors.primaryLight} />
            <Text style={styles.locationText}>
              {userData.city || 'Mumbai'} • Within {userData.discoveryRadiusKm} km
            </Text>
          </View>
          <Text style={styles.headerTitle}>Know Your Neighbor</Text>
        </View>

        <TouchableOpacity onPress={onRestartOnboarding} style={styles.profileBtn}>
          <Image source={{ uri: userData.avatarUri }} style={styles.miniAvatar} />
        </TouchableOpacity>
      </View>

      {/* Discovery Active Banner */}
      <View style={styles.banner}>
        <View style={styles.bannerIcon}>
          <Ionicons name="radio" size={20} color={Colors.accent} />
        </View>
        <View style={{ flex: 1 }}>
          <Text style={styles.bannerTitle}>KYN Radar Active</Text>
          <Text style={styles.bannerDesc}>
            Showing verified members nearby. Your exact GPS is hidden.
          </Text>
        </View>
      </View>

      {/* People Nearby Section */}
      <View style={styles.sectionHeadingRow}>
        <Text style={styles.sectionHeading}>CURATED NEARBY ({NEARBY_PEOPLE.length})</Text>
        <TouchableOpacity>
          <Text style={styles.filterBtn}>Filter (Radius {userData.discoveryRadiusKm}km)</Text>
        </TouchableOpacity>
      </View>

      {NEARBY_PEOPLE.map((person) => (
        <View key={person.id} style={styles.personCard}>
          <View style={styles.cardTop}>
            <Image source={{ uri: person.avatar }} style={styles.personAvatar} />
            <View style={{ flex: 1, marginLeft: 12 }}>
              <View style={styles.nameRow}>
                <Text style={styles.personName}>{person.name}</Text>
                {person.verified && (
                  <Ionicons name="shield-checkmark" size={16} color={Colors.accent} />
                )}
              </View>
              <Text style={styles.personRole}>
                {person.role} • {person.company}
              </Text>
              <Text style={styles.distanceText}>
                📍 {person.area} ({person.distance}) • {person.mutuals} mutuals
              </Text>
            </View>
          </View>

          <View style={styles.intentBadgeRow}>
            <View style={styles.intentChip}>
              <Ionicons name="sparkles" size={12} color={Colors.warning} />
              <Text style={styles.intentChipText}>{person.intent}</Text>
            </View>
          </View>

          <View style={styles.cardActions}>
            <TouchableOpacity style={styles.sayHiBtn}>
              <Ionicons name="chatbubble-ellipses-outline" size={16} color={Colors.white} />
              <Text style={styles.sayHiText}>Say Hi / Request Intro</Text>
            </TouchableOpacity>
          </View>
        </View>
      ))}

      {/* Onboarding Complete Notice */}
      <View style={styles.finishBox}>
        <Ionicons name="checkmark-done-circle" size={24} color={Colors.accent} />
        <Text style={styles.finishTitle}>01 · Onboarding Flow Complete</Text>
        <Text style={styles.finishSubtitle}>
          All 8 onboarding steps with validation, state management, and modern aesthetics are successfully integrated.
        </Text>
        <TouchableOpacity style={styles.testAgainBtn} onPress={onRestartOnboarding}>
          <Text style={styles.testAgainText}>Re-test Onboarding Flow</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 20,
    paddingTop: 16,
    paddingBottom: 40,
  },
  topBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 20,
  },
  locationTag: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    marginBottom: 4,
  },
  locationText: {
    color: Colors.primaryLight,
    fontSize: 12,
    fontWeight: '600',
  },
  headerTitle: {
    fontSize: 22,
    fontWeight: '800',
    color: Colors.textPrimary,
  },
  profileBtn: {
    padding: 3,
    borderRadius: 24,
    borderWidth: 2,
    borderColor: Colors.primary,
  },
  miniAvatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
  },
  banner: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(16, 185, 129, 0.1)',
    borderRadius: 14,
    padding: 14,
    gap: 12,
    borderWidth: 1,
    borderColor: 'rgba(16, 185, 129, 0.25)',
    marginBottom: 24,
  },
  bannerIcon: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: 'rgba(16, 185, 129, 0.2)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  bannerTitle: {
    color: Colors.accent,
    fontSize: 13,
    fontWeight: '700',
  },
  bannerDesc: {
    color: Colors.textSecondary,
    fontSize: 12,
    marginTop: 2,
  },
  sectionHeadingRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  sectionHeading: {
    color: Colors.textMuted,
    fontSize: 12,
    fontWeight: '700',
    letterSpacing: 1,
  },
  filterBtn: {
    color: Colors.primaryLight,
    fontSize: 12,
    fontWeight: '600',
  },
  personCard: {
    backgroundColor: Colors.surface,
    borderRadius: 16,
    padding: 16,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
    marginBottom: 14,
  },
  cardTop: {
    flexDirection: 'row',
  },
  personAvatar: {
    width: 52,
    height: 52,
    borderRadius: 26,
  },
  nameRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  personName: {
    color: Colors.textPrimary,
    fontSize: 16,
    fontWeight: '700',
  },
  personRole: {
    color: Colors.textSecondary,
    fontSize: 13,
    marginTop: 2,
  },
  distanceText: {
    color: Colors.textMuted,
    fontSize: 11,
    marginTop: 4,
  },
  intentBadgeRow: {
    marginTop: 12,
  },
  intentChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: 'rgba(245, 158, 11, 0.1)',
    alignSelf: 'flex-start',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 8,
  },
  intentChipText: {
    color: Colors.warning,
    fontSize: 12,
    fontWeight: '600',
  },
  cardActions: {
    marginTop: 14,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: Colors.surfaceBorder,
  },
  sayHiBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.primary,
    paddingVertical: 10,
    borderRadius: 10,
    gap: 8,
  },
  sayHiText: {
    color: Colors.white,
    fontSize: 13,
    fontWeight: '600',
  },
  finishBox: {
    marginTop: 24,
    backgroundColor: Colors.surfaceElevated,
    borderRadius: 16,
    padding: 20,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
  },
  finishTitle: {
    color: Colors.textPrimary,
    fontSize: 16,
    fontWeight: '700',
    marginTop: 8,
  },
  finishSubtitle: {
    color: Colors.textSecondary,
    fontSize: 12,
    textAlign: 'center',
    marginTop: 6,
    lineHeight: 18,
  },
  testAgainBtn: {
    marginTop: 14,
    backgroundColor: Colors.surface,
    paddingHorizontal: 18,
    paddingVertical: 8,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
  },
  testAgainText: {
    color: Colors.primaryLight,
    fontSize: 12,
    fontWeight: '600',
  },
});
