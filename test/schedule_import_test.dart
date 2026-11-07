import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:toss_schedule/services/schedule_import_service.dart';

void main() {
  test('Weekly CSV supports BOM, CRLF, minute precision and midnight', () {
    final s = parseScheduleCsv(
            '\uFEFF$scheduleCsvHeader\r\n일요일,23:35,24:00, 독서 ,책\r\n')
        .single;
    expect(s.isTemplate, isTrue);
    expect(s.dayOfWeek, 6);
    expect(s.startLabel, '23:35');
    expect(s.endLabel, '24:00');
    expect(s.title, '독서');
    expect(s.memo, '책');
    expect(templateScheduleKey(s), templateScheduleKey(s.copyWith(memo: '변경')));
    expect(templateScheduleKey(s),
        isNot(templateScheduleKey(s.copyWith(dayOfWeek: 0))));
  });

  test('Quoted commas, escaped quotes and multiline memos survive parsing', () {
    final s = parseScheduleCsv(
            '$scheduleCsvHeader\n월요일,09:00,10:30,"운동, 독서","책 ""제목""\n다음 줄"')
        .single;
    expect(s.title, '운동, 독서');
    expect(s.memo, '책 "제목"\n다음 줄');
    expect(
        parseScheduleCsv('$scheduleCsvHeader\n\n월요일,09:00,10:00,운동,\n')
            .single
            .memo,
        '');
  });

  test('Invalid rows reject the whole import', () {
    for (final row in [
      '월,09:00,10:00,운동,',
      '월요일,9:00,10:00,운동,',
      '월요일,24:00,24:00,운동,',
      '월요일,09:60,10:00,운동,',
      '월요일,09:00,24:01,운동,',
      '월요일,10:00,09:00,운동,',
      '월요일,10:00,10:00,운동,',
      '월요일,09:00,10:00, ,',
      '월요일,09:00,10:00,운동',
      '월요일,09:00,10:00,운동,,',
      '월요일,09:00,10:00,"운동,',
      '월요일,09:00,10:00,운"동,',
      '월요일,09:00,10:00,"운동"oops,',
    ]) {
      expect(
          () =>
              parseScheduleCsv('$scheduleCsvHeader\n화요일,08:00,09:00,정상,\n$row'),
          throwsFormatException,
          reason: row);
    }
    expect(
        () => parseScheduleCsv('$scheduleCsvHeader\n월,09:00,10:00,운동,'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'row', contains('2번째 행'))));
  });

  test('Header, size and row limits are enforced', () {
    for (final csv in [
      '',
      scheduleCsvHeader,
      'day,start,end,title,memo\n월요일,09:00,10:00,운동,',
      '$scheduleCsvHeader\n월요일,09:00,10:00,${'a' * 201},',
      'a' * 100001,
      '$scheduleCsvHeader\n${List.filled(201, '월요일,09:00,10:00,운동,').join('\n')}',
    ]) {
      expect(() => parseScheduleCsv(csv), throwsFormatException);
    }
    expect(
        parseScheduleCsv(
            '$scheduleCsvHeader\n${List.filled(200, '월요일,09:00,10:00,운동,').join('\n')}'),
        hasLength(200));
  });

  test('Example follows the format advertised in the prompt', () {
    expect(
        parseScheduleCsv(
            File('examples/weekly_schedule.csv').readAsStringSync()),
        hasLength(3));
    expect(scheduleCsvPrompt, contains(scheduleCsvHeader));
  });
}
