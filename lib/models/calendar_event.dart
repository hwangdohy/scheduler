/// A one-off event tied to a specific calendar date (yyyy-MM-dd).
class CalendarEvent {
  final int? id;
  final String date; // yyyy-MM-dd
  final String title;
  final String memo;
  final int colorValue;

  const CalendarEvent({
    this.id,
    required this.date,
    required this.title,
    this.memo = '',
    required this.colorValue,
  });

  CalendarEvent copyWith({
    int? id,
    String? date,
    String? title,
    String? memo,
    int? colorValue,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      memo: memo ?? this.memo,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': date,
      'title': title,
      'memo': memo,
      'color': colorValue,
    };
  }

  factory CalendarEvent.fromMap(Map<String, Object?> map) {
    return CalendarEvent(
      id: map['id'] as int?,
      date: map['date'] as String,
      title: map['title'] as String,
      memo: (map['memo'] as String?) ?? '',
      colorValue: map['color'] as int,
    );
  }
}
