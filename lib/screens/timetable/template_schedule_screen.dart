import 'package:flutter/material.dart';

import '../../models/schedule.dart';
import '../../services/database_service.dart';
import '../../services/home_widget_service.dart';
import '../../theme/app_colors.dart';
import 'widgets/schedule_form_sheet.dart';
import 'widgets/schedule_grid.dart';

/// Editor for the 기본 일정 — the weekly template every date falls back to
/// until that date is edited on its own.
class TemplateScheduleScreen extends StatefulWidget {
  const TemplateScheduleScreen({super.key});

  @override
  State<TemplateScheduleScreen> createState() => _TemplateScheduleScreenState();
}

class _TemplateScheduleScreenState extends State<TemplateScheduleScreen> {
  List<Schedule> _schedules = [];
  bool _loading = true;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final schedules = await DatabaseService.instance.getTemplateSchedules();
    if (!mounted) return;
    setState(() {
      _schedules = schedules;
      _loading = false;
    });
    HomeWidgetService.instance.refresh();
  }

  Future<void> _openForm({Schedule? existing, int? day, int? hour}) async {
    final changed = await showScheduleFormSheet(
      context,
      existing: existing,
      initialDay: day,
      initialHour: hour,
    );
    if (changed == true) {
      _changed = true;
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('기본 일정'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _openForm(day: now.weekday - 1, hour: now.hour),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.textPrimary),
              )
            : Column(
                children: [
                  const _TemplateBanner(),
                  const _WeekdayHeader(),
                  const Divider(height: 1),
                  Expanded(
                    child: ScheduleGrid(
                      columns: [
                        for (int d = 0; d < 7; d++)
                          _schedules.where((s) => s.dayOfWeek == d).toList(),
                      ],
                      onEmptyTap: (day, hour) => _openForm(day: day, hour: hour),
                      onBlockTap: (_, schedule) => _openForm(existing: schedule),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TemplateBanner extends StatelessWidget {
  const _TemplateBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        '여기서 정한 일정이 매주 같은 요일에 자동으로 채워져요.\n'
        '특정 날짜만 다르게 바꾸고 싶다면 시간표에서 그 날짜를 수정하세요.',
        style: TextStyle(
          fontSize: 13,
          height: 1.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const SizedBox(width: kTimeColumnWidth),
          for (int d = 0; d < 7; d++)
            Expanded(
              child: Text(
                kWeekDaysKr[d],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
