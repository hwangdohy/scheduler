import 'package:flutter_test/flutter_test.dart';
import 'package:toss_schedule/models/todo_item.dart';

void main() {
  test('Validates clock times including midnight and last minute', () {
    expect(parseTodoTime('00:00'), 0);
    expect(parseTodoTime('23:59'), 1439);
    expect(parseTodoTime('9:30'), 570);
    for (final value in ['', '24:00', '-1:00', '09:60', '09:3', 'noon']) {
      expect(parseTodoTime(value), isNull);
    }
  });
  test(
      'Time, free text location and participants survive storage and completion',
      () {
    final item = TodoItem(
        title: '회의',
        createdAt: DateTime(2026, 10, 19),
        scheduledMinutes: 570,
        locationLabel: '회의실 A',
        participants: '철수·영희 외 2명');
    final restored =
        TodoItem.fromMap(item.toMap()).copyWith(id: 8, isDone: true);
    expect(restored.timeLabel, '09:30');
    expect(restored.locationLabel, '회의실 A');
    expect(restored.participants, '철수·영희 외 2명');
    expect(restored.isDone, isTrue);
  });
  test('Existing todos without newly added fields can still be loaded', () {
    final item = TodoItem.fromMap({
      'id': 1,
      'title': '기존 할 일',
      'is_done': 0,
      'priority': 1,
      'created_at': '2026-10-19T00:00:00.000'
    });
    expect(item.timeLabel, isNull);
    expect(item.locationLabel, isNull);
    expect(item.participants, '');
  });
}
