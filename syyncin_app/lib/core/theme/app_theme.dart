import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static bool get _ios => defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.blue,
          primary: AppColors.blue,
          surface: AppColors.white,
        ),
        // Native touch feedback: ripple on Android, none (opacity) on iOS.
        splashFactory: _ios ? NoSplash.splashFactory : InkRipple.splashFactory,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.blue),
        datePickerTheme: const DatePickerThemeData(backgroundColor: AppColors.white),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.ink,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 1.5,
          shadowColor: AppColors.barShadow,
          centerTitle: true,
          toolbarHeight: 56,
          titleTextStyle: AppText.appBarTitle,
          systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
        ),
        dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
        switchTheme: SwitchThemeData(
          thumbColor: const WidgetStatePropertyAll(AppColors.white),
          trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.blue : AppColors.segment),
          trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.white,
          surfaceTintColor: Colors.transparent,
          showDragHandle: false,
        ),
        dialogTheme: const DialogThemeData(backgroundColor: AppColors.white, surfaceTintColor: Colors.transparent),
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      );
}
