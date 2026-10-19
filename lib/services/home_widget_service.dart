import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:home_widget/home_widget.dart';

import '../models/schedule.dart';
import 'database_service.dart';

const List<String> _weekDays = ['월', '화', '수', '목', '금', '토', '일'];

/// Publishes today's timetable to the Android home-screen widget.
///
/// The widget reads plain strings rather than the database, so the native
/// side needs no SQLite access of its own.
class HomeWidgetService {
  HomeWidgetService._internal();
  static final HomeWidgetService instance = HomeWidgetService._internal();

  static const String _androidProvider = 'TodayScheduleWidgetProvider';

  static const String keyDate = 'today_date';
  static const String keyCount = 'today_count';
  static const String keyLines = 'today_lines';

  Future<void> refresh() async {
    if (kIsWeb) return;

    final today = DateTime.now();
    final schedules = await DatabaseService.instance.getSchedulesForDate(today);
    final lines = schedules.take(4).map(_formatLine).join('\n');

    try {
      await HomeWidget.saveWidgetData<String>(keyDate, _formatDate(today));
      await HomeWidget.saveWidgetData<String>(
        keyCount,
        schedules.isEmpty ? '일정 없음' : '${schedules.length}개',
      );
      await HomeWidget.saveWidgetData<String>(keyLines, lines);
      await HomeWidget.updateWidget(androidName: _androidProvider);
    } on Exception {
      // No widget host on this platform (or none placed yet) — the app
      // itself must keep working regardless.
    }
  }

  String _formatDate(DateTime date) =>
      '${date.month}월 ${date.day}일 (${_weekDays[date.weekday - 1]})';

  String _formatLine(Schedule schedule) {
    final start = schedule.startLabel;
    final end = schedule.endLabel;
    return '$start-$end  ${schedule.title}';
  }
}
