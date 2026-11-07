import 'package:flutter_test/flutter_test.dart';
import 'package:toss_schedule/models/schedule.dart';
import 'package:toss_schedule/services/schedule_color_service.dart';

Schedule colored(String title, int color) => Schedule(
    dayOfWeek: 0, startHour: 9, endHour: 10, title: title, colorValue: color);

void main() {
  test('Exact titles match even when shorter than the substring thresholds',
      () {
    expect(scheduleTitlesShareColor(' 밥 ', '밥'), isTrue);
    expect(scheduleTitlesShareColor(' Gym ', 'GYM'), isTrue);
    expect(scheduleTitlesShareColor('a  b', 'A B'), isTrue);
    expect(scheduleTitlesShareColor('', ''), isFalse);
  });

  test('Korean requires two consecutive shared syllables', () {
    expect(scheduleTitlesShareColor('오전 운동', '저녁 운동'), isTrue);
    expect(scheduleTitlesShareColor('수영', '수학'), isFalse);
    expect(scheduleTitlesShareColor('운 동', '운동'), isFalse);
    expect(scheduleTitlesShareColor('가나', '나가'), isFalse);
  });

  test('English requires five consecutive shared letters, ignoring case', () {
    expect(scheduleTitlesShareColor('Study maths', 'STUDY physics'), isTrue);
    expect(scheduleTitlesShareColor('abcdeX', 'yABCDE'), isTrue);
    expect(scheduleTitlesShareColor('abcdX', 'abcdY'), isFalse);
    expect(scheduleTitlesShareColor('ab cde', 'abcde'), isFalse);
    expect(scheduleTitlesShareColor('12345x', '12345y'), isFalse);
  });

  test('Exact matches take priority over other similar historical titles', () {
    final existing = [
      colored('오전 운동', 0xFF3182F6),
      colored('저녁 운동', 0xFFFF6B6B)
    ];
    expect(colorForScheduleTitle('저녁 운동', existing), 0xFFFF6B6B);
    expect(colorForScheduleTitle('주말 운동', existing), 0xFF3182F6);
    expect(colorForScheduleTitle('독서', existing, preferredColor: 0xFF3182F6),
        isNot(anyOf(0xFF3182F6, 0xFFFF6B6B)));
  });

  test(
      'Unrelated titles receive unique colors even after the palette is exhausted',
      () {
    final existing = <Schedule>[];
    for (var i = 0; i < 50; i++) {
      final title = 'item $i';
      final color =
          colorForScheduleTitle(title, existing, preferredColor: 0xFFF2FF3A);
      expect(existing.map((s) => s.colorValue), isNot(contains(color)));
      existing.add(colored(title, color));
    }
    expect(existing.map((s) => s.colorValue).toSet(), hasLength(50));
  });
}
