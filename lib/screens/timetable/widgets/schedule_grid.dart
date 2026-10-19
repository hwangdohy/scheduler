import 'package:flutter/material.dart';

import '../../../models/schedule.dart';
import '../../../theme/app_colors.dart';

const double kCellHeight = 56.0;
const double kTimeColumnWidth = 44.0;

/// The scrollable Mon-Sun x 24h body, shared by the dated week view and
/// the 기본 일정 editor. [columns] always holds 7 lists, Monday first.
class ScheduleGrid extends StatelessWidget {
  const ScheduleGrid({
    super.key,
    required this.columns,
    required this.onEmptyTap,
    required this.onBlockTap,
    this.highlightedDay,
  });

  final List<List<Schedule>> columns;
  final int? highlightedDay;
  final void Function(int day, int hour) onEmptyTap;
  final void Function(int day, Schedule schedule) onBlockTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TimeColumn(),
          for (int day = 0; day < 7; day++)
            Expanded(
              child: _DayColumn(
                isHighlighted: day == highlightedDay,
                schedules: columns[day],
                onEmptyTap: (hour) => onEmptyTap(day, hour),
                onBlockTap: (schedule) => onBlockTap(day, schedule),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  const _TimeColumn();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kTimeColumnWidth,
      child: Column(
        children: [
          for (int h = 0; h < 24; h++)
            SizedBox(
              height: kCellHeight,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    h.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.isHighlighted,
    required this.schedules,
    required this.onEmptyTap,
    required this.onBlockTap,
  });

  final bool isHighlighted;
  final List<Schedule> schedules;
  final ValueChanged<int> onEmptyTap;
  final ValueChanged<Schedule> onBlockTap;

  void _handleTapUp(TapUpDetails details) {
    final hour = (details.localPosition.dy / kCellHeight).floor().clamp(0, 23).toInt();
    // Taps landing on a block are consumed by its own GestureDetector,
    // which sits above this background in the Stack.
    onEmptyTap(hour);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kCellHeight * 24,
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: _handleTapUp,
            child: Container(
              color: isHighlighted
                  ? AppColors.accent.withOpacity(0.06)
                  : Colors.transparent,
              child: Column(
                children: [
                  for (int h = 0; h < 24; h++)
                    Container(
                      height: kCellHeight,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.divider),
                          left: BorderSide(color: AppColors.divider),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          for (final schedule in schedules)
            _ScheduleBlock(
              schedule: schedule,
              onTap: () => onBlockTap(schedule),
            ),
        ],
      ),
    );
  }
}

class _ScheduleBlock extends StatelessWidget {
  const _ScheduleBlock({required this.schedule, required this.onTap});
  final Schedule schedule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(schedule.colorValue);
    final brightness = ThemeData.estimateBrightnessForColor(color);
    final textColor =
        brightness == Brightness.dark ? Colors.white : AppColors.textPrimary;
    final top = schedule.startHour * kCellHeight;
    final height = (schedule.endHour - schedule.startHour) * kCellHeight;

    return Positioned(
      top: top + 2,
      left: 2,
      right: 2,
      height: height - 4,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.topLeft,
          child: Text(
            schedule.title,
            maxLines: height > 40 ? 3 : 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
