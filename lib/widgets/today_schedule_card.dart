import 'package:flutter/material.dart';

import '../models/schedule.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import 'toss_card.dart';

const List<String> _weekDays = ['월', '화', '수', '목', '금', '토', '일'];
const int _maxVisible = 3;

/// At-a-glance summary of today's timetable. Bump [reloadToken] to make it
/// re-read the database after a schedule changes elsewhere.
class TodayScheduleCard extends StatefulWidget {
  const TodayScheduleCard({super.key, required this.reloadToken});

  final int reloadToken;

  @override
  State<TodayScheduleCard> createState() => _TodayScheduleCardState();
}

class _TodayScheduleCardState extends State<TodayScheduleCard> {
  List<Schedule> _schedules = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(TodayScheduleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadToken != widget.reloadToken) _load();
  }

  Future<void> _load() async {
    final schedules =
        await DatabaseService.instance.getSchedulesForDate(DateTime.now());
    if (!mounted) return;
    setState(() {
      _schedules = schedules;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final visible = _schedules.take(_maxVisible).toList();
    final hidden = _schedules.length - visible.length;

    return TossCard(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${today.month}월 ${today.day}일 (${_weekDays[today.weekday - 1]})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _loading ? '' : '오늘 일정 ${_schedules.length}개',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (!_loading) ...[
            const SizedBox(height: 10),
            if (_schedules.isEmpty)
              const Text(
                '오늘은 등록된 일정이 없어요',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
              )
            else
              for (final schedule in visible) _SummaryRow(schedule: schedule),
            if (hidden > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '+ $hidden개 더',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.schedule});
  final Schedule schedule;

  @override
  Widget build(BuildContext context) {
    final start = schedule.startHour.toString().padLeft(2, '0');
    final end = schedule.endHour.toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: Color(schedule.colorValue),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$start-$end',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              schedule.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
