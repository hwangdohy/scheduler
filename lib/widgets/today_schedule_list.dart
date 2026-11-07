import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../theme/app_colors.dart';

Future<void> showTodayScheduleList(
    BuildContext context, List<Schedule> schedules,
    {DateTime? date}) {
  final today = date ?? DateTime.now();
  final sorted = [...schedules]
    ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, controller) => ListView.builder(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        itemCount: sorted.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${today.month}월 ${today.day}일 · 오늘 일정 ${sorted.length}개',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                    if (sorted.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Text('오늘은 등록된 일정이 없어요'),
                      ),
                  ]),
            );
          }
          final schedule = sorted[i - 1];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 220 + i.clamp(0, 10) * 35),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                    offset: Offset(0, 24 * (1 - value)), child: child)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border(
                      left: BorderSide(
                          color: Color(schedule.colorValue), width: 4))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${schedule.startLabel}–${schedule.endLabel}',
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(schedule.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    if (schedule.memo.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(schedule.memo)),
                  ]),
            ),
          );
        },
      ),
    ),
  );
}
