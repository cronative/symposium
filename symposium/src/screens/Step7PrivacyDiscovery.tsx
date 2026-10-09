import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Switch,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '../theme/colors';
import { Button } from '../components/Button';

interface Props {
  initialValues: {
    enableKynDiscovery: boolean;
    discoveryRadiusKm: number;
    isProfilePrivate: boolean;
  };
  onSubmit: (values: {
    enableKynDiscovery: boolean;
    discoveryRadiusKm: number;
    isProfilePrivate: boolean;
  }) => void;
  onBack: () => void;
}

const RADIUS_OPTIONS = [2, 5, 10, 20];

export const Step7PrivacyDiscovery: React.FC<Props> = ({
  initialValues,
  onSubmit,
  onBack,
}) => {
  const [enableKynDiscovery, setEnableKynDiscovery] = useState(
    initialValues.enableKynDiscovery ?? true
  );
  const [discoveryRadiusKm, setDiscoveryRadiusKm] = useState(
    initialValues.discoveryRadiusKm || 5
  );
  const [isProfilePrivate, setIsProfilePrivate] = useState(
    initialValues.isProfilePrivate ?? false
  );

  const handleContinue = () => {
    onSubmit({
      enableKynDiscovery,
      discoveryRadiusKm,
      isProfilePrivate,
    });
  };

  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      <TouchableOpacity style={styles.backBtn} onPress={onBack}>
        <Ionicons name="arrow-back" size={24} color={Colors.textPrimary} />
      </TouchableOpacity>

      <View style={styles.header}>
        <Text style={styles.title}>Privacy & Discovery</Text>
        <Text style={styles.subtitle}>
          Control how and when you appear to others nearby. You are always in control.
        </Text>
      </View>

      {/* Main KYN Discovery Toggle Card */}
      <View style={styles.card}>
        <View style={styles.cardRow}>
          <View style={styles.iconWrap}>
            <Ionicons name="location-outline" size={22} color={Colors.primaryLight} />
          </View>
          <View style={{ flex: 1 }}>
            <Text style={styles.cardTitle}>Know Your Neighbor (KYN)</Text>
            <Text style={styles.cardDesc}>
              Allow relevant professionals and neighbors in your area to discover your profile.
            </Text>
          </View>
          <Switch
            value={enableKynDiscovery}
            onValueChange={setEnableKynDiscovery}
            trackColor={{ false: Colors.surfaceBorder, true: Colors.primary }}
            thumbColor={Colors.white}
          />
        </View>

        {enableKynDiscovery && (
          <View style={styles.subSettings}>
            <Text style={styles.subLabel}>Discovery Radius</Text>
            <View style={styles.radiusRow}>
              {RADIUS_OPTIONS.map((km) => (
                <TouchableOpacity
                  key={km}
                  style={[
                    styles.radiusBtn,
                    discoveryRadiusKm === km && styles.radiusBtnActive,
                  ]}
                  onPress={() => setDiscoveryRadiusKm(km)}
                >
                  <Text
                    style={[
                      styles.radiusBtnText,
                      discoveryRadiusKm === km && styles.radiusBtnTextActive,
                    ]}
                  >
                    {km} km
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>
        )}
      </View>

      {/* Approximate Location Security Box */}
      <View style={styles.securityBox}>
        <Ionicons name="shield-checkmark" size={20} color={Colors.accent} />
        <View style={{ flex: 1 }}>
          <Text style={styles.securityTitle}>Zero Exact-GPS Exposure</Text>
          <Text style={styles.securityDesc}>
            Symposium never reveals your exact apartment or street address. Only approximate general vicinity (e.g. "Bandra West - 2 km away") is displayed.
          </Text>
        </View>
      </View>

      {/* Incognito / Private Mode */}
      <View style={[styles.card, { marginTop: 16 }]}>
        <View style={styles.cardRow}>
          <View style={[styles.iconWrap, { backgroundColor: 'rgba(239, 68, 68, 0.15)' }]}>
            <Ionicons name="eye-off-outline" size={20} color={Colors.error} />
          </View>
          <View style={{ flex: 1 }}>
            <Text style={styles.cardTitle}>Private / Incognito Mode</Text>
            <Text style={styles.cardDesc}>
              Only people you initiate contact with or invite to meetings will see your profile.
            </Text>
          </View>
          <Switch
            value={isProfilePrivate}
            onValueChange={(val) => {
              setIsProfilePrivate(val);
              if (val) setEnableKynDiscovery(false);
            }}
            trackColor={{ false: Colors.surfaceBorder, true: Colors.error }}
            thumbColor={Colors.white}
          />
        </View>
      </View>

      <View style={styles.footer}>
        <Button title="Complete Profile" onPress={handleContinue} />
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 24,
    paddingTop: 16,
    paddingBottom: 32,
  },
  backBtn: {
    width: 44,
    height: 44,
    borderRadius: 12,
    backgroundColor: Colors.surface,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 20,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
  },
  header: {
    marginBottom: 24,
  },
  title: {
    fontSize: 24,
    fontWeight: '700',
    color: Colors.textPrimary,
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 14,
    color: Colors.textSecondary,
    lineHeight: 20,
  },
  card: {
    backgroundColor: Colors.surface,
    borderRadius: 16,
    padding: 16,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
  },
  cardRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  iconWrap: {
    width: 40,
    height: 40,
    borderRadius: 12,
    backgroundColor: 'rgba(99, 102, 241, 0.15)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  cardTitle: {
    color: Colors.textPrimary,
    fontSize: 15,
    fontWeight: '600',
    marginBottom: 2,
  },
  cardDesc: {
    color: Colors.textMuted,
    fontSize: 12,
    lineHeight: 16,
  },
  subSettings: {
    marginTop: 16,
    paddingTop: 14,
    borderTopWidth: 1,
    borderTopColor: Colors.surfaceBorder,
  },
  subLabel: {
    color: Colors.textSecondary,
    fontSize: 12,
    fontWeight: '600',
    marginBottom: 10,
  },
  radiusRow: {
    flexDirection: 'row',
    gap: 8,
  },
  radiusBtn: {
    flex: 1,
    paddingVertical: 10,
    alignItems: 'center',
    borderRadius: 10,
    backgroundColor: Colors.surfaceElevated,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
  },
  radiusBtnActive: {
    borderColor: Colors.primary,
    backgroundColor: Colors.primary,
  },
  radiusBtnText: {
    color: Colors.textSecondary,
    fontSize: 13,
    fontWeight: '600',
  },
  radiusBtnTextActive: {
    color: Colors.white,
  },
  securityBox: {
    flexDirection: 'row',
    backgroundColor: 'rgba(16, 185, 129, 0.08)',
    borderRadius: 14,
    padding: 14,
    gap: 12,
    marginTop: 16,
    borderWidth: 1,
    borderColor: 'rgba(16, 185, 129, 0.25)',
  },
  securityTitle: {
    color: Colors.accent,
    fontSize: 13,
    fontWeight: '700',
    marginBottom: 2,
  },
  securityDesc: {
    color: Colors.textSecondary,
    fontSize: 12,
    lineHeight: 17,
  },
  footer: {
    marginTop: 36,
  },
});
