import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '../theme/colors';
import { Input } from '../components/Input';
import { Button } from '../components/Button';
import { AuthMode } from '../types/onboarding';

interface Props {
  authMode: AuthMode;
  contactType: 'phone' | 'email';
  onChangeContactType: (type: 'phone' | 'email') => void;
  onSubmitContact: (val: { countryCode: string; phone: string; email: string }) => void;
  onBack: () => void;
}

export const Step2ContactInput: React.FC<Props> = ({
  authMode,
  contactType,
  onChangeContactType,
  onSubmitContact,
  onBack,
}) => {
  const [countryCode, setCountryCode] = useState('+91');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [email, setEmail] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSendCode = () => {
    setError('');
    if (contactType === 'phone') {
      const cleanPhone = phoneNumber.replace(/\s+/g, '');
      if (cleanPhone.length < 10) {
        setError('Please enter a valid 10-digit mobile number.');
        return;
      }
    } else {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(email.trim())) {
        setError('Please enter a valid email address.');
        return;
      }
    }

    setLoading(true);
    // Simulate API call to send OTP
    setTimeout(() => {
      setLoading(false);
      onSubmitContact({
        countryCode,
        phone: phoneNumber.trim(),
        email: email.trim(),
      });
    }, 700);
  };

  return (
    <KeyboardAvoidingView
      style={styles.keyboardView}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <ScrollView contentContainerStyle={styles.container} keyboardShouldPersistTaps="handled">
        {/* Back and Title */}
        <TouchableOpacity style={styles.backBtn} onPress={onBack}>
          <Ionicons name="arrow-back" size={24} color={Colors.textPrimary} />
        </TouchableOpacity>

        <View style={styles.header}>
          <Text style={styles.title}>
            {authMode === 'signup' ? 'Verify your identity' : 'Welcome back'}
          </Text>
          <Text style={styles.subtitle}>
            We will send a one-time verification code (OTP) to authenticate your account.
          </Text>
        </View>

        {/* Contact Method Selector */}
        <View style={styles.tabSelector}>
          <TouchableOpacity
            style={[styles.tab, contactType === 'phone' && styles.tabActive]}
            onPress={() => {
              setError('');
              onChangeContactType('phone');
            }}
          >
            <Ionicons
              name="phone-portrait-outline"
              size={16}
              color={contactType === 'phone' ? Colors.white : Colors.textMuted}
            />
            <Text style={[styles.tabText, contactType === 'phone' && styles.tabTextActive]}>
              Mobile Number
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.tab, contactType === 'email' && styles.tabActive]}
            onPress={() => {
              setError('');
              onChangeContactType('email');
            }}
          >
            <Ionicons
              name="mail-outline"
              size={16}
              color={contactType === 'email' ? Colors.white : Colors.textMuted}
            />
            <Text style={[styles.tabText, contactType === 'email' && styles.tabTextActive]}>
              Email Address
            </Text>
          </TouchableOpacity>
        </View>

        {/* Input Field */}
        {contactType === 'phone' ? (
          <View style={styles.phoneInputRow}>
            <View style={styles.countryCodeBadge}>
              <Text style={styles.flag}>🇮🇳</Text>
              <Text style={styles.countryCodeText}>{countryCode}</Text>
            </View>
            <View style={styles.phoneInputWrap}>
              <Input
                label="Mobile Number"
                placeholder="98765 43210"
                keyboardType="phone-pad"
                value={phoneNumber}
                onChangeText={(text) => {
                  setError('');
                  setPhoneNumber(text);
                }}
                error={error}
                maxLength={10}
              />
            </View>
          </View>
        ) : (
          <Input
            label="Email Address"
            placeholder="you@company.com"
            keyboardType="email-address"
            autoCapitalize="none"
            value={email}
            onChangeText={(text) => {
              setError('');
              setEmail(text);
            }}
            error={error}
            prefix={<Ionicons name="mail" size={18} color={Colors.textMuted} />}
          />
        )}

        {/* Privacy Note */}
        <View style={styles.infoBadge}>
          <Ionicons name="shield-checkmark" size={18} color={Colors.accent} />
          <Text style={styles.infoText}>
            Your contact details are strictly encrypted and never shared with other users without your permission.
          </Text>
        </View>

        <View style={styles.footer}>
          <Button
            title="Get Verification Code"
            onPress={handleSendCode}
            loading={loading}
          />
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
    flexGrow: 1,
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
  tabSelector: {
    flexDirection: 'row',
    backgroundColor: Colors.surface,
    borderRadius: 12,
    padding: 4,
    marginBottom: 24,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
    gap: 6,
  },
  tab: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 10,
    borderRadius: 8,
    gap: 8,
  },
  tabActive: {
    backgroundColor: Colors.surfaceElevated,
  },
  tabText: {
    color: Colors.textMuted,
    fontSize: 13,
    fontWeight: '600',
  },
  tabTextActive: {
    color: Colors.textPrimary,
    fontWeight: '700',
  },
  phoneInputRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 10,
  },
  countryCodeBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    height: 52,
    marginTop: 25, // match label offset
    paddingHorizontal: 12,
    borderRadius: 14,
    backgroundColor: Colors.surface,
    borderWidth: 1.5,
    borderColor: Colors.surfaceBorder,
    gap: 6,
  },
  flag: {
    fontSize: 16,
  },
  countryCodeText: {
    color: Colors.textPrimary,
    fontSize: 14,
    fontWeight: '600',
  },
  phoneInputWrap: {
    flex: 1,
  },
  infoBadge: {
    flexDirection: 'row',
    backgroundColor: 'rgba(16, 185, 129, 0.08)',
    borderRadius: 12,
    padding: 14,
    borderWidth: 1,
    borderColor: 'rgba(16, 185, 129, 0.2)',
    gap: 12,
    marginTop: 12,
    alignItems: 'center',
  },
  infoText: {
    flex: 1,
    color: Colors.textSecondary,
    fontSize: 12,
    lineHeight: 17,
  },
  footer: {
    marginTop: 'auto',
    paddingTop: 32,
  },
});
