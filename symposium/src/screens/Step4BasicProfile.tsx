import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  Image,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '../theme/colors';
import { Input } from '../components/Input';
import { Button } from '../components/Button';

interface Props {
  initialValues: {
    fullName: string;
    city: string;
    age: string;
    bio: string;
    avatarUri: string;
  };
  onSubmit: (values: {
    fullName: string;
    city: string;
    age: string;
    bio: string;
    avatarUri: string;
  }) => void;
  onBack: () => void;
}

const DEFAULT_AVATARS = [
  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&h=200&fit=crop&crop=face',
  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop&crop=face',
  'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200&h=200&fit=crop&crop=face',
  'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&h=200&fit=crop&crop=face',
];

const POPULAR_CITIES = ['Mumbai', 'Bengaluru', 'Delhi NCR', 'Pune', 'Hyderabad'];

export const Step4BasicProfile: React.FC<Props> = ({
  initialValues,
  onSubmit,
  onBack,
}) => {
  const [fullName, setFullName] = useState(initialValues.fullName || '');
  const [city, setCity] = useState(initialValues.city || '');
  const [age, setAge] = useState(initialValues.age || '');
  const [bio, setBio] = useState(initialValues.bio || '');
  const [avatarUri, setAvatarUri] = useState(
    initialValues.avatarUri || DEFAULT_AVATARS[0]
  );
  const [errors, setErrors] = useState<{ [key: string]: string }>({});

  const handleContinue = () => {
    const errs: { [key: string]: string } = {};

    if (!fullName.trim()) {
      errs.fullName = 'Full Name is required.';
    }
    if (!city.trim()) {
      errs.city = 'City is required for localized discovery.';
    }
    if (!age.trim()) {
      errs.age = 'Age is required (Must be 18+).';
    } else {
      const parsedAge = parseInt(age, 10);
      if (isNaN(parsedAge) || parsedAge < 18 || parsedAge > 100) {
        errs.age = 'You must be at least 18 years old.';
      }
    }

    if (Object.keys(errs).length > 0) {
      setErrors(errs);
      return;
    }

    setErrors({});
    onSubmit({
      fullName: fullName.trim(),
      city: city.trim(),
      age: age.trim(),
      bio: bio.trim(),
      avatarUri,
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
        <TouchableOpacity style={styles.backBtn} onPress={onBack}>
          <Ionicons name="arrow-back" size={24} color={Colors.textPrimary} />
        </TouchableOpacity>

        <View style={styles.header}>
          <Text style={styles.title}>Basic Profile Setup</Text>
          <Text style={styles.subtitle}>
            Introduce yourself to your neighborhood and future collaborators.
          </Text>
        </View>

        {/* Avatar Picker Section */}
        <View style={styles.avatarSection}>
          <View style={styles.avatarWrap}>
            <Image source={{ uri: avatarUri }} style={styles.avatarImage} />
            <TouchableOpacity
              style={styles.avatarCameraBtn}
              onPress={() => {
                // Cycle avatar for preview
                const currentIndex = DEFAULT_AVATARS.indexOf(avatarUri);
                const nextIndex = (currentIndex + 1) % DEFAULT_AVATARS.length;
                setAvatarUri(DEFAULT_AVATARS[nextIndex]);
              }}
            >
              <Ionicons name="camera" size={16} color={Colors.white} />
            </TouchableOpacity>
          </View>
          <Text style={styles.avatarHint}>Tap camera to switch avatar</Text>
        </View>

        {/* Input Fields */}
        <Input
          label="Full Name *"
          placeholder="e.g. Nikunj Maheshwari"
          value={fullName}
          onChangeText={(t) => {
            setErrors((prev) => ({ ...prev, fullName: '' }));
            setFullName(t);
          }}
          error={errors.fullName}
          prefix={<Ionicons name="person-outline" size={18} color={Colors.textMuted} />}
        />

        <View style={styles.row}>
          <View style={{ flex: 1.2 }}>
            <Input
              label="City *"
              placeholder="e.g. Mumbai"
              value={city}
              onChangeText={(t) => {
                setErrors((prev) => ({ ...prev, city: '' }));
                setCity(t);
              }}
              error={errors.city}
              prefix={<Ionicons name="location-outline" size={18} color={Colors.textMuted} />}
            />
          </View>
          <View style={{ flex: 0.8, marginLeft: 12 }}>
            <Input
              label="Age (18+) *"
              placeholder="26"
              keyboardType="number-pad"
              maxLength={2}
              value={age}
              onChangeText={(t) => {
                setErrors((prev) => ({ ...prev, age: '' }));
                setAge(t);
              }}
              error={errors.age}
            />
          </View>
        </View>

        {/* City Quick Pills */}
        <View style={styles.pillsRow}>
          {POPULAR_CITIES.map((c) => (
            <TouchableOpacity
              key={c}
              style={[styles.cityPill, city === c && styles.cityPillActive]}
              onPress={() => {
                setCity(c);
                setErrors((prev) => ({ ...prev, city: '' }));
              }}
            >
              <Text
                style={[styles.cityPillText, city === c && styles.cityPillTextActive]}
              >
                {c}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        <Input
          label="Short Bio (Optional)"
          placeholder="Building cool tech, exploring design and hosting dinners."
          value={bio}
          onChangeText={setBio}
          multiline
          numberOfLines={3}
          containerStyle={{ marginTop: 8 }}
        />

        <View style={styles.footer}>
          <Button title="Save & Continue" onPress={handleContinue} />
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
  avatarSection: {
    alignItems: 'center',
    marginBottom: 24,
  },
  avatarWrap: {
    position: 'relative',
  },
  avatarImage: {
    width: 88,
    height: 88,
    borderRadius: 44,
    borderWidth: 2,
    borderColor: Colors.primary,
  },
  avatarCameraBtn: {
    position: 'absolute',
    right: 0,
    bottom: 0,
    backgroundColor: Colors.primary,
    width: 30,
    height: 30,
    borderRadius: 15,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: Colors.background,
  },
  avatarHint: {
    color: Colors.textMuted,
    fontSize: 12,
    marginTop: 8,
  },
  row: {
    flexDirection: 'row',
  },
  pillsRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginBottom: 16,
    marginTop: -8,
  },
  cityPill: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 20,
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
  },
  cityPillActive: {
    backgroundColor: Colors.surfaceElevated,
    borderColor: Colors.primaryLight,
  },
  cityPillText: {
    color: Colors.textSecondary,
    fontSize: 12,
  },
  cityPillTextActive: {
    color: Colors.primaryLight,
    fontWeight: '600',
  },
  footer: {
    marginTop: 24,
  },
});
