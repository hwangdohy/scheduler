import '../models/schedule.dart';

class ScheduleConflict implements Exception {
  ScheduleConflict(this.message);
  final String message;
  @override
  String toString() => message;
}

void checkScheduleConflict(Schedule candidate, Iterable<Schedule> existing,
    {String? label, int? excludingId}) {
  if (candidate.dayOfWeek < 0 ||
      candidate.dayOfWeek > 6 ||
      candidate.startMinutes < 0 ||
      candidate.endMinutes > 1440 ||
      candidate.startMinutes >= candidate.endMinutes) {
    throw ScheduleConflict('올바른 요일과 시작·종료 시간을 선택해 주세요.');
  }
  for (final other in existing) {
    if (excludingId != null && other.id == excludingId) continue;
    if (other.dayOfWeek == candidate.dayOfWeek &&
        candidate.startMinutes < other.endMinutes &&
        other.startMinutes < candidate.endMinutes) {
      final day = label ??
          '${const ['월', '화', '수', '목', '금', '토', '일'][candidate.dayOfWeek]}요일';
      throw ScheduleConflict(
          '$day ${other.startLabel}–${other.endLabel} 「${other.title}」 일정과 시간이 겹칩니다.');
    }
  }
}
