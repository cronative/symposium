import React, { useState } from 'react';
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

interface Props {
  initialIntents: string[];
  initialInterests: string[];
  onSubmit: (data: { currentIntents: string[]; interests: string[] }) => void;
  onBack: () => void;
}

const INTENT_OPTIONS = [
  { id: 'hiring', label: 'Hiring Talent', icon: 'person-add-outline' },
  { id: 'jobs', label: 'Seeking Opportunities / Jobs', icon: 'briefcase-outline' },
  { id: 'cofounder', label: 'Finding a Co-Founder', icon: 'git-network-outline' },
  { id: 'freelance', label: 'Freelance & Consulting Gigs', icon: 'laptop-outline' },
  { id: 'investing', label: 'Angel Investing / Raising', icon: 'trending-up-outline' },
  { id: 'friends', label: 'Making Quality Local Friends', icon: 'chatbubbles-outline' },
  { id: 'experiences', label: 'Attending Dinners & Events', icon: 'restaurant-outline' },
];

const INTEREST_TAGS = [
  'Artificial Intelligence',
  'Product Design',
  'Venture Capital',
  'SaaS & B2B',
  'Health & Longevity',
  'Deep Tech',
  'Architecture & Cities',
  'Electronic Music',
  'Podcasting',
  'Philosophy & Books',
  'Running / Fitness',
  'Culinary & Wine',
  'Fintech',
];

export const Step6InterestsIntent: React.FC<Props> = ({
  initialIntents,
  initialInterests,
  onSubmit,
  onBack,
}) => {
  const [selectedIntents, setSelectedIntents] = useState<string[]>(
    initialIntents.length > 0 ? initialIntents : ['experiences']
  );
  const [selectedInterests, setSelectedInterests] = useState<string[]>(
    initialInterests.length > 0 ? initialInterests : ['Artificial Intelligence', 'Product Design']
  );
  const [error, setError] = useState('');

  const toggleIntent = (id: string) => {
    setError('');
    if (selectedIntents.includes(id)) {
      setSelectedIntents(selectedIntents.filter((item) => item !== id));
    } else {
      setSelectedIntents([...selectedIntents, id]);
    }
  };

  const toggleInterest = (tag: string) => {
    setError('');
    if (selectedInterests.includes(tag)) {
      setSelectedInterests(selectedInterests.filter((t) => t !== tag));
    } else {
      setSelectedInterests([...selectedInterests, tag]);
    }
  };

  const handleContinue = () => {
    if (selectedIntents.length === 0) {
      setError('Please select at least 1 current intent.');
      return;
    }
    if (selectedInterests.length < 3) {
      setError(`Please select at least 3 interests (Currently selected: ${selectedInterests.length}).`);
      return;
    }

    onSubmit({
      currentIntents: selectedIntents,
      interests: selectedInterests,
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
        <Text style={styles.title}>Intent & Interests</Text>
        <Text style={styles.subtitle}>
          Symposium matches you based on real-time intent, not passive swiping.
        </Text>
      </View>

      {/* Primary Intent Section */}
      <View style={styles.sectionHeader}>
        <Text style={styles.sectionTitle}>What is your primary intent right now? *</Text>
        <Text style={styles.sectionSubtitle}>Select all that apply</Text>
      </View>

      <View style={styles.intentsList}>
        {INTENT_OPTIONS.map((item) => {
          const isSelected = selectedIntents.includes(item.id);
          return (
            <TouchableOpacity
              key={item.id}
              style={[styles.intentCard, isSelected && styles.intentCardActive]}
              onPress={() => toggleIntent(item.id)}
              activeOpacity={0.7}
            >
              <View
                style={[
                  styles.intentIconBox,
                  isSelected && styles.intentIconBoxActive,
                ]}
              >
                <Ionicons
                  name={item.icon as any}
                  size={18}
                  color={isSelected ? Colors.white : Colors.textSecondary}
                />
              </View>
              <Text
                style={[
                  styles.intentCardText,
                  isSelected && styles.intentCardTextActive,
                ]}
              >
                {item.label}
              </Text>
              <Ionicons
                name={isSelected ? 'checkbox' : 'square-outline'}
                size={20}
                color={isSelected ? Colors.primaryLight : Colors.surfaceBorder}
              />
            </TouchableOpacity>
          );
        })}
      </View>

      {/* Topic Interests Section */}
      <View style={[styles.sectionHeader, { marginTop: 24 }]}>
        <Text style={styles.sectionTitle}>Select at least 3 topics of interest *</Text>
        <Text style={styles.sectionSubtitle}>
          ({selectedInterests.length} selected)
        </Text>
      </View>

      <View style={styles.tagsContainer}>
        {INTEREST_TAGS.map((tag) => {
          const isSelected = selectedInterests.includes(tag);
          return (
            <TouchableOpacity
              key={tag}
              style={[styles.tag, isSelected && styles.tagActive]}
              onPress={() => toggleInterest(tag)}
            >
              <Text style={[styles.tagText, isSelected && styles.tagTextActive]}>
                {tag}
              </Text>
              {isSelected && (
                <Ionicons name="checkmark-sharp" size={14} color={Colors.white} />
              )}
            </TouchableOpacity>
          );
        })}
      </View>

      {error ? (
        <View style={styles.errorBanner}>
          <Ionicons name="alert-circle" size={16} color={Colors.error} />
          <Text style={styles.errorText}>{error}</Text>
        </View>
      ) : null}

      <View style={styles.footer}>
        <Button title="Continue" onPress={handleContinue} />
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
    marginBottom: 20,
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
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'baseline',
    marginBottom: 12,
  },
  sectionTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  sectionSubtitle: {
    fontSize: 12,
    color: Colors.textMuted,
  },
  intentsList: {
    gap: 8,
  },
  intentCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.surface,
    padding: 14,
    borderRadius: 14,
    borderWidth: 1.5,
    borderColor: Colors.surfaceBorder,
    gap: 12,
  },
  intentCardActive: {
    backgroundColor: Colors.surfaceElevated,
    borderColor: Colors.primary,
  },
  intentIconBox: {
    width: 36,
    height: 36,
    borderRadius: 10,
    backgroundColor: Colors.surfaceElevated,
    alignItems: 'center',
    justifyContent: 'center',
  },
  intentIconBoxActive: {
    backgroundColor: Colors.primary,
  },
  intentCardText: {
    flex: 1,
    fontSize: 14,
    color: Colors.textSecondary,
    fontWeight: '500',
  },
  intentCardTextActive: {
    color: Colors.textPrimary,
    fontWeight: '600',
  },
  tagsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginBottom: 16,
  },
  tag: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
    gap: 6,
  },
  tagActive: {
    backgroundColor: Colors.primary,
    borderColor: Colors.primaryLight,
  },
  tagText: {
    color: Colors.textSecondary,
    fontSize: 13,
  },
  tagTextActive: {
    color: Colors.white,
    fontWeight: '600',
  },
  errorBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(239, 68, 68, 0.1)',
    padding: 12,
    borderRadius: 10,
    gap: 8,
    marginTop: 8,
    marginBottom: 16,
  },
  errorText: {
    color: Colors.error,
    fontSize: 13,
    fontWeight: '500',
  },
  footer: {
    marginTop: 20,
  },
});
