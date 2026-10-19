enum TodoPriority { low, medium, high }

int? parseTodoTime(String value) {
  final match =
      RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$').firstMatch(value.trim());
  if (match == null) return null;
  return int.parse(match[1]!) * 60 + int.parse(match[2]!);
}

class TodoItem {
  final int? id;
  final String title;
  final bool isDone;
  final TodoPriority priority;
  final DateTime createdAt;
  final int? scheduledMinutes;
  final String participants;
  final String? locationLabel;

  String? get timeLabel => scheduledMinutes == null
      ? null
      : '${(scheduledMinutes! ~/ 60).toString().padLeft(2, '0')}:${(scheduledMinutes! % 60).toString().padLeft(2, '0')}';

  const TodoItem({
    this.id,
    required this.title,
    this.isDone = false,
    this.priority = TodoPriority.medium,
    required this.createdAt,
    this.scheduledMinutes,
    this.participants = '',
    this.locationLabel,
  });

  TodoItem copyWith({
    int? id,
    String? title,
    bool? isDone,
    TodoPriority? priority,
    DateTime? createdAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      scheduledMinutes: scheduledMinutes,
      participants: participants,
      locationLabel: locationLabel,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'is_done': isDone ? 1 : 0,
      'priority': priority.index,
      'created_at': createdAt.toIso8601String(),
      'scheduled_minutes': scheduledMinutes,
      'participants': participants,
      'location_label': locationLabel,
    };
  }

  factory TodoItem.fromMap(Map<String, Object?> map) {
    return TodoItem(
      id: map['id'] as int?,
      title: map['title'] as String,
      isDone: (map['is_done'] as int) == 1,
      priority: TodoPriority.values[map['priority'] as int],
      createdAt: DateTime.parse(map['created_at'] as String),
      scheduledMinutes: map['scheduled_minutes'] as int?,
      participants: (map['participants'] as String?) ?? '',
      locationLabel: map['location_label'] as String?,
    );
  }
}
