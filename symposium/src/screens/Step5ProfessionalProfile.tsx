import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '../theme/colors';
import { Input } from '../components/Input';
import { Button } from '../components/Button';

interface Props {
  initialValues: {
    company: string;
    role: string;
    industry: string;
    linkedInUrl: string;
  };
  onSubmit: (values: {
    company: string;
    role: string;
    industry: string;
    linkedInUrl: string;
  }) => void;
  onSkip: () => void;
  onBack: () => void;
}

const INDUSTRIES = [
  'Technology & AI',
  'Design & Creative',
  'Venture & Startups',
  'Product Management',
  'Finance & FinTech',
  'Media & Content',
];

export const Step5ProfessionalProfile: React.FC<Props> = ({
  initialValues,
  onSubmit,
  onSkip,
  onBack,
}) => {
  const [company, setCompany] = useState(initialValues.company || '');
  const [role, setRole] = useState(initialValues.role || '');
  const [industry, setIndustry] = useState(initialValues.industry || INDUSTRIES[0]);
  const [linkedInUrl, setLinkedInUrl] = useState(initialValues.linkedInUrl || '');
  const [error, setError] = useState('');

  const handleContinue = () => {
    setError('');
    // LinkedIn validation if filled
    if (linkedInUrl.trim()) {
      if (!linkedInUrl.toLowerCase().includes('linkedin.com')) {
        setError('Please enter a valid LinkedIn URL (e.g. linkedin.com/in/username).');
        return;
      }
    }

    onSubmit({
      company: company.trim(),
      role: role.trim(),
      industry,
      linkedInUrl: linkedInUrl.trim(),
    });
  };

  return (
    <KeyboardAvoidingView
      style={styles.keyboardView}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <ScrollView
        contentContainerStyle={styles.container}
        keyboardShouldPersistTaps="handled"
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.topBar}>
          <TouchableOpacity style={styles.backBtn} onPress={onBack}>
            <Ionicons name="arrow-back" size={24} color={Colors.textPrimary} />
          </TouchableOpacity>
          <TouchableOpacity onPress={onSkip} style={styles.skipBtn}>
            <Text style={styles.skipText}>Skip for now</Text>
          </TouchableOpacity>
        </View>

        <View style={styles.header}>
          <Text style={styles.title}>Professional Background</Text>
          <Text style={styles.subtitle}>
            Helps verify your credibility and matches you with relevant opportunities on Seek & KYN.
          </Text>
        </View>

        {/* Inputs */}
        <Input
          label="Current Company / Organization"
          placeholder="e.g. Google, Stripe, or Stealth Startup"
          value={company}
          onChangeText={setCompany}
          prefix={<Ionicons name="business-outline" size={18} color={Colors.textMuted} />}
        />

        <Input
          label="Job Role / Title"
          placeholder="e.g. Product Designer, Founder, Lead Engineer"
          value={role}
          onChangeText={setRole}
          prefix={<Ionicons name="briefcase-outline" size={18} color={Colors.textMuted} />}
        />

        <Text style={styles.label}>Industry / Domain</Text>
        <View style={styles.industryGrid}>
          {INDUSTRIES.map((item) => (
            <TouchableOpacity
              key={item}
              style={[
                styles.industryChip,
                industry === item && styles.industryChipActive,
              ]}
              onPress={() => setIndustry(item)}
            >
              <Text
                style={[
                  styles.industryChipText,
                  industry === item && styles.industryChipTextActive,
                ]}
              >
                {item}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        <Input
          label="LinkedIn Profile URL (Recommended)"
          placeholder="https://linkedin.com/in/username"
          autoCapitalize="none"
          keyboardType="url"
          value={linkedInUrl}
          onChangeText={(t) => {
            setError('');
            setLinkedInUrl(t);
          }}
          error={error}
          prefix={<Ionicons name="logo-linkedin" size={18} color="#0A66C2" />}
          containerStyle={{ marginTop: 12 }}
        />

        {/* Verification badge preview */}
        <View style={styles.verificationNote}>
          <Ionicons name="shield-checkmark" size={20} color={Colors.accent} />
          <View style={{ flex: 1 }}>
            <Text style={styles.verifTitle}>Verified Member Status</Text>
            <Text style={styles.verifDesc}>
              Profiles with valid professional links get a Verified badge and 3x more connection responses.
            </Text>
          </View>
        </View>

        <View style={styles.footer}>
          <Button title="Continue" onPress={handleContinue} />
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  keyboardView: {
    flex: 1,
  },
  container: {
    paddingHorizontal: 24,
    paddingTop: 16,
    paddingBottom: 32,
  },
  topBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 20,
  },
  backBtn: {
    width: 44,
    height: 44,
    borderRadius: 12,
    backgroundColor: Colors.surface,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
  },
  skipBtn: {
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  skipText: {
    color: Colors.textSecondary,
    fontSize: 14,
    fontWeight: '600',
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
  label: {
    color: Colors.textSecondary,
    fontSize: 13,
    fontWeight: '600',
    marginBottom: 10,
    letterSpacing: 0.2,
  },
  industryGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginBottom: 16,
  },
  industryChip: {
    paddingHorizontal: 14,
    paddingVertical: 9,
    borderRadius: 12,
    backgroundColor: Colors.surface,
    borderWidth: 1.5,
    borderColor: Colors.surfaceBorder,
  },
  industryChipActive: {
    backgroundColor: 'rgba(99, 102, 241, 0.15)',
    borderColor: Colors.primary,
  },
  industryChipText: {
    color: Colors.textSecondary,
    fontSize: 13,
    fontWeight: '500',
  },
  industryChipTextActive: {
    color: Colors.primaryLight,
    fontWeight: '700',
  },
  verificationNote: {
    flexDirection: 'row',
    backgroundColor: Colors.surface,
    borderRadius: 14,
    padding: 14,
    gap: 12,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
    marginTop: 8,
  },
  verifTitle: {
    color: Colors.textPrimary,
    fontSize: 13,
    fontWeight: '600',
  },
  verifDesc: {
    color: Colors.textMuted,
    fontSize: 11,
    lineHeight: 16,
    marginTop: 2,
  },
  footer: {
    marginTop: 24,
  },
});
