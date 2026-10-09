import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  TextInput,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '../theme/colors';
import { Button } from '../components/Button';

interface Props {
  contactValue: string;
  onVerifySuccess: (otp: string) => void;
  onBack: () => void;
  onResendOtp: () => void;
}

export const Step3OtpVerify: React.FC<Props> = ({
  contactValue,
  onVerifySuccess,
  onBack,
  onResendOtp,
}) => {
  const [otp, setOtp] = useState(['', '', '', '', '', '']);
  const [timer, setTimer] = useState(45);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    let interval: ReturnType<typeof setInterval>;
    if (timer > 0) {
      interval = setInterval(() => setTimer((t) => t - 1), 1000);
    }
    return () => clearInterval(interval);
  }, [timer]);

  const handleOtpChange = (value: string, index: number) => {
    setError('');
    const newOtp = [...otp];
    newOtp[index] = value;
    setOtp(newOtp);

    // Auto verify if 6 digits entered
    const code = newOtp.join('');
    if (code.length === 6) {
      validateAndSubmit(code);
    }
  };

  const validateAndSubmit = (code: string) => {
    if (code.length !== 6) {
      setError('Please enter all 6 digits.');
      return;
    }

    setLoading(true);
    // Simulating validation logic
    setTimeout(() => {
      setLoading(false);
      // For demo MVP: any 6 digits or '123456' is accepted, e.g. '000000' triggers invalid for testing
      if (code === '000000') {
        setError('Incorrect OTP. Try 123456 or request a new code.');
      } else {
        onVerifySuccess(code);
      }
    }, 600);
  };

  const handleResend = () => {
    if (timer === 0) {
      setTimer(45);
      setOtp(['', '', '', '', '', '']);
      setError('');
      onResendOtp();
    }
  };

  return (
    <KeyboardAvoidingView
      style={styles.keyboardView}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <View style={styles.container}>
        <TouchableOpacity style={styles.backBtn} onPress={onBack}>
          <Ionicons name="arrow-back" size={24} color={Colors.textPrimary} />
        </TouchableOpacity>

        <View style={styles.header}>
          <Text style={styles.title}>Enter Verification Code</Text>
          <Text style={styles.subtitle}>
            A 6-digit code was sent to{' '}
            <Text style={styles.contactHighlight}>{contactValue}</Text>
          </Text>
        </View>

        {/* 6 Digit Box Display */}
        <View style={styles.otpContainer}>
          {otp.map((digit, index) => (
            <View
              key={index}
              style={[
                styles.otpBox,
                digit ? styles.otpBoxFilled : null,
                error ? styles.otpBoxError : null,
              ]}
            >
              <TextInput
                style={styles.otpText}
                keyboardType="number-pad"
                maxLength={1}
                value={digit}
                onChangeText={(text) => handleOtpChange(text, index)}
              />
            </View>
          ))}
        </View>

        {error ? (
          <View style={styles.errorBanner}>
            <Ionicons name="alert-circle" size={16} color={Colors.error} />
            <Text style={styles.errorText}>{error}</Text>
          </View>
        ) : null}

        {/* Resend Section */}
        <View style={styles.resendRow}>
          <Text style={styles.resendLabel}>Didn't receive the code?</Text>
          <TouchableOpacity onPress={handleResend} disabled={timer > 0}>
            <Text
              style={[
                styles.resendAction,
                timer > 0 && styles.resendActionDisabled,
              ]}
            >
              {timer > 0 ? `Resend in ${timer}s` : 'Resend Code'}
            </Text>
          </TouchableOpacity>
        </View>

        {/* Quick test hint */}
        <View style={styles.hintBadge}>
          <Ionicons name="bulb-outline" size={16} color={Colors.primaryLight} />
          <Text style={styles.hintText}>
            Tip: You can enter any 6 digits (e.g. 1 2 3 4 5 6) to proceed.
          </Text>
        </View>

        <View style={styles.footer}>
          <Button
            title="Verify & Continue"
            loading={loading}
            onPress={() => validateAndSubmit(otp.join(''))}
          />
        </View>
      </View>
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
    flex: 1,
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
    marginBottom: 28,
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
  contactHighlight: {
    color: Colors.primaryLight,
    fontWeight: '600',
  },
  otpContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 20,
    gap: 8,
  },
  otpBox: {
    flex: 1,
    height: 56,
    borderRadius: 14,
    backgroundColor: Colors.surface,
    borderWidth: 1.5,
    borderColor: Colors.surfaceBorder,
    alignItems: 'center',
    justifyContent: 'center',
  },
  otpBoxFilled: {
    borderColor: Colors.primary,
    backgroundColor: Colors.surfaceElevated,
  },
  otpBoxError: {
    borderColor: Colors.error,
  },
  otpText: {
    fontSize: 22,
    fontWeight: '700',
    color: Colors.textPrimary,
    textAlign: 'center',
    width: '100%',
  },
  errorBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(239, 68, 68, 0.1)',
    padding: 12,
    borderRadius: 10,
    gap: 8,
    marginBottom: 16,
  },
  errorText: {
    color: Colors.error,
    fontSize: 13,
    fontWeight: '500',
  },
  resendRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: 8,
    marginVertical: 12,
  },
  resendLabel: {
    color: Colors.textMuted,
    fontSize: 13,
  },
  resendAction: {
    color: Colors.primaryLight,
    fontSize: 13,
    fontWeight: '700',
  },
  resendActionDisabled: {
    color: Colors.textMuted,
    fontWeight: '500',
  },
  hintBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.surface,
    padding: 12,
    borderRadius: 12,
    gap: 10,
    marginTop: 8,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
  },
  hintText: {
    flex: 1,
    color: Colors.textSecondary,
    fontSize: 12,
  },
  footer: {
    marginTop: 'auto',
  },
});
