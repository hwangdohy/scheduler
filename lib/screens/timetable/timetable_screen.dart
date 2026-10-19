import 'package:flutter/material.dart';

import '../../models/schedule.dart';
import '../../services/database_service.dart';
import '../../services/home_widget_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/today_schedule_card.dart';
import '../../widgets/toss_card.dart';
import 'template_schedule_screen.dart';
import 'widgets/schedule_form_sheet.dart';
import 'widgets/schedule_grid.dart';

/// Main screen: one real calendar week of the timetable. Every date starts
/// out filled from the 기본 일정 and keeps its own copy once edited.
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  late DateTime _monday = mondayOfWeek(DateTime.now());
  WeekSchedules? _week;
  bool _loading = true;
  int _reloadToken = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final week = await DatabaseService.instance.getWeek(_monday);
    if (!mounted) return;
    setState(() {
      _week = week;
      _loading = false;
      _reloadToken++;
    });
    HomeWidgetService.instance.refresh();
  }

  DateTime _dateAt(int index) => _monday.add(Duration(days: index));

  /// Index of today inside the week on screen, or null when out of view.
  int? get _todayIndex {
    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day).difference(_monday).inDays;
    return days >= 0 && days < 7 ? days : null;
  }

  void _goToWeek(DateTime monday) {
    setState(() {
      _monday = monday;
      _loading = true;
    });
    _load();
  }

  Future<void> _openForm({required int day, Schedule? existing, int? hour}) async {
    final changed = await showScheduleFormSheet(
      context,
      date: _dateAt(day),
      existing: existing,
      initialHour: hour,
    );
    if (changed == true) _load();
  }

  Future<void> _openTemplate() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const TemplateScheduleScreen()),
    );
    if (changed == true) _load();
  }

  Future<void> _confirmReset(int index) async {
    final date = _dateAt(index);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기본 일정으로 되돌릴까요?'),
        content: Text(
          '${date.month}월 ${date.day}일에 직접 수정한 내용이 지워지고 '
          '기본 일정으로 다시 채워져요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('되돌리기'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await DatabaseService.instance.resetDateToTemplate(date);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final week = _week;
    return Scaffold(
      appBar: AppBar(
        title: const Text('시간표'),
        actions: [
          IconButton(
            tooltip: '기본 일정',
            icon: const Icon(Icons.event_repeat_rounded),
            onPressed: _openTemplate,
          ),
          IconButton(
            tooltip: '일정 추가',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _openForm(
              day: _todayIndex ?? 0,
              hour: DateTime.now().hour,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading || week == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.textPrimary),
            )
          : Column(
              children: [
                if (week.byDate.values.every((day) => day.isEmpty) &&
                    week.customizedDates.isEmpty)
                  _EmptyTemplateHint(onOpenTemplate: _openTemplate)
                else
                  TodayScheduleCard(reloadToken: _reloadToken),
                _WeekNavigator(
                  monday: _monday,
                  onPrevious: () =>
                      _goToWeek(_monday.subtract(const Duration(days: 7))),
                  onNext: () => _goToWeek(_monday.add(const Duration(days: 7))),
                  onToday: _todayIndex == null
                      ? () => _goToWeek(mondayOfWeek(DateTime.now()))
                      : null,
                ),
                _DateHeader(
                  monday: _monday,
                  todayIndex: _todayIndex,
                  week: week,
                  onResetDay: _confirmReset,
                ),
                const Divider(height: 1),
                Expanded(
                  child: ScheduleGrid(
                    columns: [for (int d = 0; d < 7; d++) week.at(d)],
                    highlightedDay: _todayIndex,
                    onEmptyTap: (day, hour) => _openForm(day: day, hour: hour),
                    onBlockTap: (day, schedule) =>
                        _openForm(day: day, existing: schedule),
                  ),
                ),
              ],
            ),
    );
  }
}

class _EmptyTemplateHint extends StatelessWidget {
  const _EmptyTemplateHint({required this.onOpenTemplate});
  final VoidCallback onOpenTemplate;

  @override
  Widget build(BuildContext context) {
    return TossCard(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '기본 일정을 먼저 등록해보세요',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            '한 번 정해두면 매주 같은 요일이 자동으로 채워지고,\n'
            '특정 날짜만 따로 바꿀 수도 있어요.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onOpenTemplate,
              child: const Text('기본 일정 만들기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekNavigator extends StatelessWidget {
  const _WeekNavigator({
    required this.monday,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final DateTime monday;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  /// Null while the current week is already on screen.
  final VoidCallback? onToday;

  @override
  Widget build(BuildContext context) {
    final sunday = monday.add(const Duration(days: 6));
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: onPrevious,
          ),
          Expanded(
            child: Text(
              '${monday.month}월 ${monday.day}일 - ${sunday.month}월 ${sunday.day}일',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
          if (onToday != null)
            TextButton(onPressed: onToday, child: const Text('오늘'))
          else
            const SizedBox(width: 48),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({
    required this.monday,
    required this.todayIndex,
    required this.week,
    required this.onResetDay,
  });

  static const _labels = ['월', '화', '수', '목', '금', '토', '일'];

  final DateTime monday;
  final int? todayIndex;
  final WeekSchedules week;
  final ValueChanged<int> onResetDay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: kTimeColumnWidth),
          for (int d = 0; d < 7; d++)
            Expanded(
              child: _DayHeaderCell(
                label: _labels[d],
                day: monday.add(Duration(days: d)).day,
                isToday: d == todayIndex,
                isCustomized: week.isCustomized(d),
                onReset: week.isCustomized(d) ? () => onResetDay(d) : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _DayHeaderCell extends StatelessWidget {
  const _DayHeaderCell({
    required this.label,
    required this.day,
    required this.isToday,
    required this.isCustomized,
    required this.onReset,
  });

  final String label;
  final int day;
  final bool isToday;
  final bool isCustomized;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onReset,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isToday ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isToday ? AppColors.textPrimary : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isToday ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 3),
          // Marks a day that no longer follows the 기본 일정; tapping it
          // offers to restore the template.
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: isCustomized ? AppColors.accentDark : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
