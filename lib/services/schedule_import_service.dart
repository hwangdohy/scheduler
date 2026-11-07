import 'dart:convert';

import '../models/schedule.dart';

/// Validate AI output before allowing any writes to the user's database.
List<Schedule> parseImportedSchedules(String text) {
  final data = jsonDecode(text);
  if (data is! List || data.isEmpty || data.length > 200) {
    throw const FormatException('일정을 1~200개 범위로 정리해 주세요.');
  }
  return data.map<Schedule>((row) {
    if (row is! Map ||
        row['day'] is! int ||
        row['start'] is! int ||
        row['end'] is! int ||
        row['title'] is! String ||
        (row['memo'] != null && row['memo'] is! String)) {
      throw const FormatException('AI가 반환한 일정 형식이 올바르지 않습니다.');
    }
    final day = row['day'] as int;
    final start = row['start'] as int;
    final end = row['end'] as int;
    final title = (row['title'] as String).trim();
    if (day < 0 ||
        day > 6 ||
        start < 0 ||
        end > 1440 ||
        start >= end ||
        title.isEmpty ||
        title.length > 200) {
      throw const FormatException('요일, 시간 또는 제목이 올바르지 않습니다. CSV를 확인해 주세요.');
    }
    return Schedule(
      dayOfWeek: day,
      startHour: start ~/ 60,
      startMinute: start % 60,
      endHour: end ~/ 60,
      endMinute: end % 60,
      title: title,
      colorValue: 0xFF3182F6,
      memo: (row['memo'] as String?) ?? '',
    );
  }).toList();
}

String templateScheduleKey(Schedule s) =>
    jsonEncode([s.dayOfWeek, s.startMinutes, s.endMinutes, s.title.trim()]);
