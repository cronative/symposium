import 'package:flutter/widgets.dart';

/// Spacing scale (4 / 8 px grid). Use these instead of raw numbers in layouts.
abstract final class AppSpace {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;

  /// Horizontal padding of every screen.
  static const double screen = 16;

  /// Gap between sections on a screen.
  static const double section = 24;

  static const screenH = EdgeInsets.symmetric(horizontal: screen);

  /// Standard scrolling-content padding (top 16, bottom 24).
  static const content = EdgeInsets.fromLTRB(screen, x4, screen, x6);

  /// Top bar: toolbar height (status bar excluded) and minimum touch target.
  static const double topBar = 56;
  static const double touch = 48;
}
