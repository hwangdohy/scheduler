/// A timetable block.
///
/// [date] is what separates the two kinds of row: `null` means this is a
/// *기본 일정* (default weekly template) block that repeats every
/// [dayOfWeek], while a `yyyy-MM-dd` value means the block belongs to that
/// one date only and overrides the template for it.
class Schedule {
  final int? id;
  final String? date;
  final int dayOfWeek; // 0 = Monday ... 6 = Sunday
  final int startHour; // 0-23
  final int endHour; // 0-24; 24:00 is the end of this day.
  final int startMinute;
  final int endMinute;
  int get startMinutes => startHour * 60 + startMinute;
  int get endMinutes => endHour * 60 + endMinute;
  String get startLabel => formatScheduleTime(startMinutes);
  String get endLabel => formatScheduleTime(endMinutes);
  final String title;
  final int colorValue;
  final String memo;

  const Schedule({
    this.id,
    this.date,
    required this.dayOfWeek,
    required this.startHour,
    required this.endHour,
    this.startMinute = 0,
    this.endMinute = 0,
    required this.title,
    required this.colorValue,
    this.memo = '',
  });

  bool get isTemplate => date == null;

  Schedule copyWith({
    int? id,
    int? dayOfWeek,
    int? startHour,
    int? endHour,
    int? startMinute,
    int? endMinute,
    String? title,
    int? colorValue,
    String? memo,
  }) {
    return Schedule(
      id: id ?? this.id,
      date: date,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
      title: title ?? this.title,
      colorValue: colorValue ?? this.colorValue,
      memo: memo ?? this.memo,
    );
  }

  /// Same block, rebound to [date] (or to the template when null).
  Schedule withDate(String? date) {
    return Schedule(
      id: id,
      date: date,
      dayOfWeek: dayOfWeek,
      startHour: startHour,
      endHour: endHour,
      startMinute: startMinute,
      endMinute: endMinute,
      title: title,
      colorValue: colorValue,
      memo: memo,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': date,
      'day_of_week': dayOfWeek,
      'start_hour': startHour,
      'end_hour': endHour,
      'start_minute': startMinute,
      'end_minute': endMinute,
      'title': title,
      'color': colorValue,
      'memo': memo,
    };
  }

  factory Schedule.fromMap(Map<String, Object?> map) {
    return Schedule(
      id: map['id'] as int?,
      date: map['date'] as String?,
      dayOfWeek: map['day_of_week'] as int,
      startHour: map['start_hour'] as int,
      endHour: map['end_hour'] as int,
      startMinute: (map['start_minute'] as int?) ?? 0,
      endMinute: (map['end_minute'] as int?) ?? 0,
      title: map['title'] as String,
      colorValue: map['color'] as int,
      memo: (map['memo'] as String?) ?? '',
    );
  }
}

String formatScheduleTime(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

/// `yyyy-MM-dd` key used for every date-scoped row in the database.
String scheduleDateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Monday of the week containing [date], with the time component dropped.
DateTime mondayOfWeek(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return day.subtract(Duration(days: day.weekday - 1));
}
