import 'dart:convert';

import '../models/schedule.dart';

const scheduleCsvHeader = '요일,시작 시간,종료 시간,제목,메모';
const scheduleCsvPrompt = '''아래 일정 자료를 앱에서 가져올 수 있는 CSV로 변환해 주세요.

규칙:
- 첫 행은 반드시: 요일,시작 시간,종료 시간,제목,메모
- 각 행은 반드시 5개 열로 작성
- 요일은 월요일~일요일 중 하나로 작성
- 시간은 24시간제 HH:mm 형식 사용
- 종료 시간의 24:00은 허용 (시작 시간은 00:00~23:59)
- 종료 시간은 시작 시간보다 늦어야 함
- 여러 요일에 반복되는 일정은 요일별로 행을 나누기
- 자정을 넘는 일정은 자정 기준으로 나누고 다음 요일에 배치
- 제목은 필수이며 200자 이하로 작성
- 메모가 없으면 빈칸으로 두되 마지막 쉼표는 유지
- 쉼표나 줄바꿈이 있는 값은 큰따옴표로 감싸고, 값 안의 큰따옴표는 두 번 작성
- 요일·시간이 불명확한 일정은 추측하지 말고 먼저 질문
- 최대 200개 일정으로 작성하고, 초과하면 먼저 질문
- 변환이 끝나면 설명이나 코드 블록 없이 CSV만 출력

일정 자료:
[여기에 붙여넣기]''';

/// Validate the complete file before allowing any database writes.
List<Schedule> parseScheduleCsv(String text) {
  if (utf8.encode(text).length > 100000) {
    throw const FormatException('100KB 이하의 CSV를 선택해 주세요.');
  }
  final rows = _readCsv(text.replaceFirst(RegExp('^\uFEFF'), ''));
  if (rows.isEmpty ||
      rows.first.length != 5 ||
      rows.first.map((v) => v.trim()).join(',') != scheduleCsvHeader) {
    throw const FormatException(
        'CSV 첫 행은 "$scheduleCsvHeader"이어야 합니다. 설정의 변환 프롬프트를 참고해 주세요.');
  }
  if (rows.length < 2 || rows.length > 201) {
    throw const FormatException('일정이 1~200개 포함된 CSV를 선택해 주세요.');
  }
  const days = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
  final schedules = <Schedule>[];
  for (var i = 1; i < rows.length; i++) {
    final row = rows[i];
    Never invalid(String message) =>
        throw FormatException('CSV ${i + 1}번째 행: $message');
    if (row.length != 5) invalid('요일,시작 시간,종료 시간,제목,메모의 5개 열이 필요합니다.');
    final day = days.indexOf(row[0].trim());
    if (day < 0) invalid('요일은 월요일~일요일로 입력해 주세요.');
    int time(String value, {bool end = false}) {
      value = value.trim();
      if (end && value == '24:00') return 1440;
      if (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(value)) {
        invalid('시간은 HH:mm 형식이어야 합니다. 종료 시간만 24:00을 허용합니다.');
      }
      final parts = value.split(':').map(int.parse).toList();
      return parts[0] * 60 + parts[1];
    }

    final start = time(row[1]);
    final end = time(row[2], end: true);
    if (end <= start) invalid('종료 시간은 시작 시간보다 늦어야 합니다. 자정을 넘으면 행을 나눠 주세요.');
    final title = row[3].trim();
    if (title.isEmpty || title.length > 200) invalid('제목은 1~200자로 입력해 주세요.');
    schedules.add(Schedule(
        dayOfWeek: day,
        startHour: start ~/ 60,
        startMinute: start % 60,
        endHour: end ~/ 60,
        endMinute: end % 60,
        title: title,
        colorValue: 0xFF3182F6,
        memo: row[4]));
  }
  return schedules;
}

/// Read commas, escaped quotes, CRLF and multiline quoted fields.
List<List<String>> _readCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  var field = StringBuffer();
  var quoted = false;
  var closed = false;
  var touched = false;
  void finishField() {
    row.add(field.toString());
    field = StringBuffer();
    closed = false;
  }

  void finishRow() {
    finishField();
    if (touched) rows.add(row);
    row = [];
    touched = false;
  }

  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (quoted) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
          closed = true;
        }
      } else {
        field.write(c);
      }
      continue;
    }
    if (c == ',') {
      touched = true;
      finishField();
    } else if (c == '\r' || c == '\n') {
      finishRow();
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
    } else {
      if (closed || (c == '"' && field.isNotEmpty)) {
        throw const FormatException('CSV 큰따옴표 형식이 올바르지 않습니다.');
      }
      touched = true;
      if (c == '"') {
        quoted = true;
      } else {
        field.write(c);
      }
    }
  }
  if (quoted) throw const FormatException('CSV에 닫히지 않은 큰따옴표가 있습니다.');
  if (touched) finishRow();
  return rows;
}

String templateScheduleKey(Schedule s) =>
    jsonEncode([s.dayOfWeek, s.startMinutes, s.endMinutes, s.title.trim()]);
