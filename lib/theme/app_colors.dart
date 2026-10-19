import 'package:flutter/material.dart';

/// TOSS-inspired color palette: white base, near-black text,
/// fluorescent yellow accent.
class AppColors {
  AppColors._();

  static const Color accent = Color(0xFFF2FF3A);
  static const Color accentDark = Color(0xFFD8E600);

  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F7F9);
  static const Color surfaceAlt = Color(0xFFF1F2F4);

  static const Color textPrimary = Color(0xFF191F28);
  static const Color textSecondary = Color(0xFF8B95A1);
  static const Color textTertiary = Color(0xFFB0B8C1);

  static const Color divider = Color(0xFFEEEFF1);
  static const Color border = Color(0xFFE5E8EB);

  static const Color danger = Color(0xFFFF5B5B);
  static const Color success = Color(0xFF4CD787);

  /// Palette offered when creating a schedule / event block.
  static const List<Color> scheduleColors = [
    Color(0xFFF2FF3A), // accent yellow
    Color(0xFF3182F6), // toss blue
    Color(0xFFFF6B6B), // coral
    Color(0xFF4CD787), // green
    Color(0xFFB28DFF), // purple
    Color(0xFFFFA94D), // orange
    Color(0xFF636E85), // slate
    Color(0xFFFF8FB1), // pink
  ];
}
