import 'package:flutter_test/flutter_test.dart';
import 'package:toss_schedule/models/schedule.dart';

void main() {
  test('Minute precision survives storage, copy and date materialization', () {
    const block = Schedule(
        dayOfWeek: 0,
        startHour: 19,
        startMinute: 35,
        endHour: 20,
        endMinute: 10,
        title: '운동',
        colorValue: 0xFF123456);
    final restored = Schedule.fromMap(block.toMap())
        .copyWith(title: '운동 수정')
        .withDate('2026-10-19');
    expect(restored.startLabel, '19:35');
    expect(restored.endLabel, '20:10');
    expect(restored.endMinutes - restored.startMinutes, 35);
    expect(restored.startMinute, 35);
    expect(restored.endMinute, 10);
  });
  test('Legacy hourly rows and midnight end remain compatible', () {
    final old = Schedule.fromMap({
      'id': 1,
      'day_of_week': 0,
      'start_hour': 23,
      'end_hour': 24,
      'title': '기존 일정',
      'color': 0xFF123456
    });
    expect(old.startLabel, '23:00');
    expect(old.endLabel, '24:00');
    expect(old.endMinutes, 1440);
  });
}
