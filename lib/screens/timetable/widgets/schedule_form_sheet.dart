import 'package:flutter/material.dart';

import '../../../models/schedule.dart';
import '../../../services/database_service.dart';
import '../../../services/schedule_conflict.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/wheel_time_picker.dart';

const List<String> kWeekDaysKr = ['월', '화', '수', '목', '금', '토', '일'];

// Shared by the dated and template editors for this app session.
Schedule? _copiedSchedule;

/// Opens the add/edit sheet for a timetable block. Returns true if the
/// schedule list changed (created, updated or deleted).
///
/// With [date] null the sheet edits the 기본 일정 itself; with a date it
/// edits that one day, which detaches the day from the template.
Future<bool?> showScheduleFormSheet(
  BuildContext context, {
  DateTime? date,
  Schedule? existing,
  int? initialDay,
  int? initialHour,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ScheduleFormSheet(
      date: date,
      existing: existing,
      initialDay: initialDay,
      initialHour: initialHour,
    ),
  );
}

class ScheduleFormSheet extends StatefulWidget {
  const ScheduleFormSheet({
    super.key,
    this.date,
    this.existing,
    this.initialDay,
    this.initialHour,
  });

  final DateTime? date;
  final Schedule? existing;
  final int? initialDay;
  final int? initialHour;

  @override
  State<ScheduleFormSheet> createState() => _ScheduleFormSheetState();
}

class _ScheduleFormSheetState extends State<ScheduleFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _memoController;
  late int _dayOfWeek;
  late final Set<int> _selectedDays;
  late int _startMinutes;
  late int _endMinutes;
  late int _colorValue;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;
  bool get _isDateMode => widget.date != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _memoController = TextEditingController(text: e?.memo ?? '');
    _dayOfWeek = widget.date != null
        ? widget.date!.weekday - 1
        : e?.dayOfWeek ?? widget.initialDay ?? 0;
    _selectedDays = {_dayOfWeek};
    _startMinutes = e?.startMinutes ?? (widget.initialHour ?? 9) * 60;
    _endMinutes = e?.endMinutes ?? (_startMinutes + 60).clamp(1, 1440).toInt();
    _colorValue = e?.colorValue ?? AppColors.scheduleColors.first.toARGB32();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _copy() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정 제목을 입력해주세요')),
      );
      return;
    }
    setState(() {
      _copiedSchedule = Schedule(
        dayOfWeek: _dayOfWeek,
        startHour: _startMinutes ~/ 60,
        startMinute: _startMinutes % 60,
        endHour: _endMinutes ~/ 60,
        endMinute: _endMinutes % 60,
        title: _titleController.text.trim(),
        colorValue: _colorValue,
        memo: _memoController.text.trim(),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('일정을 복사했어요. 원하는 시간에 일정을 추가하고 붙여넣으세요.')),
    );
  }

  void _paste() {
    final copied = _copiedSchedule;
    if (copied == null) return;
    setState(() {
      _titleController.text = copied.title;
      _memoController.text = copied.memo;
      _colorValue = copied.colorValue;
      _endMinutes = (_startMinutes + copied.endMinutes - copied.startMinutes)
          .clamp(_startMinutes + 1, 1440)
          .toInt();
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정 제목을 입력해주세요')),
      );
      return;
    }
    setState(() => _saving = true);
    final date = widget.date;
    final edited = Schedule(
      id: widget.existing?.id,
      date: date == null ? null : scheduleDateKey(date),
      dayOfWeek: _dayOfWeek,
      startHour: _startMinutes ~/ 60,
      startMinute: _startMinutes % 60,
      endHour: _endMinutes ~/ 60,
      endMinute: _endMinutes % 60,
      title: title,
      colorValue: _colorValue,
      memo: _memoController.text.trim(),
    );
    final db = DatabaseService.instance;
    try {
      await db.saveScheduleDays(edited, _selectedDays,
          date: date, existing: widget.existing);
      if (mounted) Navigator.of(context).pop(true);
    } on ScheduleConflict catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장하지 못했습니다. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickTime(bool isEnd) async {
    final picked = await showWheelTimePicker(
      context,
      title: isEnd ? '종료 시간' : '시작 시간',
      initialMinutes: isEnd ? _endMinutes : _startMinutes,
      minimumMinutes: isEnd ? _startMinutes + 1 : 0,
      allowEndOfDay: isEnd,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isEnd) {
        _endMinutes = picked;
      } else {
        _startMinutes = picked;
        if (_endMinutes <= picked) {
          _endMinutes = (picked + 60).clamp(picked + 1, 1440).toInt();
        }
      }
    });
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final date = widget.date;
    if (date != null) {
      await DatabaseService.instance.deleteScheduleOnDate(date, existing);
    } else {
      await DatabaseService.instance.deleteTemplateSchedule(existing.id!);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                _isEdit ? '일정 수정' : '일정 추가',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                _isDateMode
                    ? _selectedDays.length == 1
                        ? '${_dateLabel(widget.date!)} 하루에만 적용돼요'
                        : '선택한 요일에 적용 · ${_dateLabel(mondayOfWeek(widget.date!))} 주간'
                    : '기본 일정 · 매주 ${(_selectedDays.toList()..sort()).map((d) => kWeekDaysKr[d]).join('·')}요일 반복',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: _isEdit
                    ? TextButton.icon(
                        onPressed: _saving ? null : _copy,
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('일정 복사'),
                      )
                    : TextButton.icon(
                        onPressed:
                            _saving || _copiedSchedule == null ? null : _paste,
                        icon: const Icon(Icons.content_paste_rounded),
                        label: const Text('일정 붙여넣기'),
                      ),
              ),
              TextField(
                controller: _titleController,
                autofocus: !_isEdit,
                decoration: const InputDecoration(hintText: '일정 제목'),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _memoController,
                decoration: const InputDecoration(hintText: '메모 (선택)'),
                minLines: 1,
                maxLines: 3,
              ),
              ...[
                const SizedBox(height: 20),
                Text(_isDateMode ? '적용할 요일 (이번 주)' : '반복할 요일 (여러 개 선택)',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                if (_isEdit) const Text('원래 요일은 유지하고, 다른 요일에는 새 일정으로 추가합니다.'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (int d = 0; d < 7; d++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: _DayChip(
                            label: kWeekDaysKr[d],
                            selected: _selectedDays.contains(d),
                            onTap: () {
                              if (_saving || (_isEdit && d == _dayOfWeek)) {
                                return;
                              }
                              setState(() {
                                if (_selectedDays.contains(d)) {
                                  if (_selectedDays.length > 1) {
                                    _selectedDays.remove(d);
                                  }
                                } else {
                                  _selectedDays.add(d);
                                }
                              });
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: _TimeButton(
                        label: '시작 시간',
                        value: _startMinutes,
                        onTap: _saving ? null : () => _pickTime(false))),
                const SizedBox(width: 12),
                Expanded(
                    child: _TimeButton(
                        label: '종료 시간',
                        value: _endMinutes,
                        onTap: _saving ? null : () => _pickTime(true))),
              ]),
              const SizedBox(height: 20),
              const Text('색상 자동 배정',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text(
                  '같은 제목이거나 한글 2글자·영문 5글자가 연속으로 겹치면 같은 색을 사용합니다. '
                  '영문 대소문자는 구분하지 않으며, 다른 제목에는 다른 색을 배정합니다.',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 28),
              Row(
                children: [
                  if (_isEdit) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : _delete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('삭제'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_isEdit ? '수정 완료' : '추가하기'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton(
      {required this.label, required this.value, required this.onTap});
  final String label;
  final int value;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton(
        key: ValueKey(label),
        onPressed: onTap,
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14)),
        child: Column(children: [
          Text(label),
          const SizedBox(height: 4),
          Text(formatScheduleTime(value),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))
        ]),
      );
}

String _dateLabel(DateTime date) =>
    '${date.month}월 ${date.day}일 (${kWeekDaysKr[date.weekday - 1]})';
