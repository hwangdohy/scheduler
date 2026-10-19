/// A diary entry for a specific date (yyyy-MM-dd), with an optional
/// AI-generated 2-3 keyword summary.
class DiaryEntry {
  final int? id;
  final String date; // yyyy-MM-dd
  final String content;
  final String? summary; // e.g. "workout, reading, tired"
  final DateTime updatedAt;

  const DiaryEntry({
    this.id,
    required this.date,
    required this.content,
    this.summary,
    required this.updatedAt,
  });

  DiaryEntry copyWith({
    int? id,
    String? date,
    String? content,
    String? summary,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': date,
      'content': content,
      'summary': summary,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DiaryEntry.fromMap(Map<String, Object?> map) {
    return DiaryEntry(
      id: map['id'] as int?,
      date: map['date'] as String,
      content: map['content'] as String,
      summary: map['summary'] as String?,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
