import 'package:flutter/material.dart';

import '../models/schedule.dart';
import '../theme/app_colors.dart';

String _normalizedTitle(String title) =>
    title.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

Set<String> _fragments(String title, RegExp alphabet, int length) => {
      for (final match in alphabet.allMatches(title))
        for (var i = 0; i <= match[0]!.length - length; i++)
          match[0]!.substring(i, i + length),
    };

/// Matching is based on contiguous Korean syllables or English letters.
/// Spaces/punctuation separate runs; English matching ignores letter case.
bool scheduleTitlesShareColor(String first, String second) {
  final a = _normalizedTitle(first);
  final b = _normalizedTitle(second);
  if (a.isEmpty || b.isEmpty) return false;
  if (a == b) return true;
  final korean = _fragments(a, RegExp(r'[가-힣]+'), 2);
  if (_fragments(b, RegExp(r'[가-힣]+'), 2).any(korean.contains)) return true;
  final english = _fragments(a, RegExp(r'[a-z]+'), 5);
  return _fragments(b, RegExp(r'[a-z]+'), 5).any(english.contains);
}

/// Exact titles take priority, then the first matching existing title.
/// Callers provide existing schedules in ID order for a stable result.
int colorForScheduleTitle(String title, Iterable<Schedule> schedules,
    {int? preferredColor}) {
  final existing = schedules.toList();
  final normalized = _normalizedTitle(title);
  for (final schedule in existing) {
    if (normalized.isNotEmpty &&
        _normalizedTitle(schedule.title) == normalized) {
      return schedule.colorValue;
    }
  }
  for (final schedule in existing) {
    if (scheduleTitlesShareColor(title, schedule.title)) {
      return schedule.colorValue;
    }
  }
  final used = existing.map((s) => s.colorValue).toSet();
  if (preferredColor != null && !used.contains(preferredColor)) {
    return preferredColor;
  }
  for (final color in AppColors.scheduleColors) {
    if (!used.contains(color.toARGB32())) return color.toARGB32();
  }
  // Extend the palette rather than recycling a color for an unrelated title.
  for (var i = 0;; i++) {
    final color = HSLColor.fromAHSL(1, (i * 137.507764) % 360, 0.65, 0.58)
        .toColor()
        .toARGB32();
    if (!used.contains(color)) return color;
  }
}
