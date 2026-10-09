import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  StyleSheet,
  TextInputProps,
  ViewStyle,
} from 'react-native';
import { Colors } from '../theme/colors';

interface InputProps extends TextInputProps {
  label?: string;
  error?: string;
  helper?: string;
  prefix?: React.ReactNode;
  suffix?: React.ReactNode;
  containerStyle?: ViewStyle;
}

export const Input: React.FC<InputProps> = ({
  label,
  error,
  helper,
  prefix,
  suffix,
  containerStyle,
  ...rest
}) => {
  const [isFocused, setIsFocused] = useState(false);

  return (
    <View style={[styles.container, containerStyle]}>
      {label && <Text style={styles.label}>{label}</Text>}
      
      <View
        style={[
          styles.inputWrapper,
          isFocused && styles.inputFocused,
          !!error && styles.inputError,
        ]}
      >
        {prefix && <View style={styles.prefixContainer}>{prefix}</View>}
        <TextInput
          placeholderTextColor={Colors.textMuted}
          style={styles.textInput}
          onFocus={() => setIsFocused(true)}
          onBlur={() => setIsFocused(false)}
          {...rest}
        />
        {suffix && <View style={styles.suffixContainer}>{suffix}</View>}
      </View>

      {error ? (
        <Text style={styles.errorText}>{error}</Text>
      ) : helper ? (
        <Text style={styles.helperText}>{helper}</Text>
      ) : null}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    marginBottom: 16,
  },
  label: {
    color: Colors.textSecondary,
    fontSize: 13,
    fontWeight: '600',
    marginBottom: 8,
    letterSpacing: 0.2,
  },
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.surface,
    borderWidth: 1.5,
    borderColor: Colors.surfaceBorder,
    borderRadius: 14,
    paddingHorizontal: 16,
    height: 52,
  },
  inputFocused: {
    borderColor: Colors.primary,
    backgroundColor: Colors.surfaceElevated,
  },
  inputError: {
    borderColor: Colors.error,
  },
  prefixContainer: {
    marginRight: 10,
  },
  suffixContainer: {
    marginLeft: 10,
  },
  textInput: {
    flex: 1,
    color: Colors.textPrimary,
    fontSize: 15,
    fontWeight: '500',
  },
  errorText: {
    color: Colors.error,
    fontSize: 12,
    marginTop: 6,
    fontWeight: '500',
  },
  helperText: {
    color: Colors.textMuted,
    fontSize: 12,
    marginTop: 6,
  },
});
