enum TodoPriority { low, medium, high }

class TodoItem {
  final int? id;
  final String title;
  final bool isDone;
  final TodoPriority priority;
  final DateTime createdAt;

  const TodoItem({
    this.id,
    required this.title,
    this.isDone = false,
    this.priority = TodoPriority.medium,
    required this.createdAt,
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
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'is_done': isDone ? 1 : 0,
      'priority': priority.index,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TodoItem.fromMap(Map<String, Object?> map) {
    return TodoItem(
      id: map['id'] as int?,
      title: map['title'] as String,
      isDone: (map['is_done'] as int) == 1,
      priority: TodoPriority.values[map['priority'] as int],
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
