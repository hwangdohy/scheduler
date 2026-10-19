import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/calendar_event.dart';
import '../../services/database_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/toss_card.dart';
import '../diary/diary_screen.dart';
import '../budget/daily_expense_card.dart';
import '../budget/money_field.dart';

String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<String, List<CalendarEvent>> _eventsByDate = {};
  Map<String, int> _expensesByDate = {};
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    DatabaseService.instance.budgetRevision.addListener(_reloadExpenses);
    _loadMonth(_focusedDay);
  }

  void _reloadExpenses() => _loadMonth(_focusedDay);

  @override
  void dispose() {
    DatabaseService.instance.budgetRevision.removeListener(_reloadExpenses);
    super.dispose();
  }

  Future<void> _loadMonth(DateTime month) async {
    final token = ++_loadToken;
    final events = await DatabaseService.instance
        .getEventsForMonth(month.year, month.month);
    final expenses = await DatabaseService.instance
        .getMonthlyExpenses(month.year, month.month);
    final map = <String, List<CalendarEvent>>{};
    for (final e in events) {
      map.putIfAbsent(e.date, () => []).add(e);
    }
    if (!mounted || token != _loadToken) return;
    setState(() {
      _eventsByDate = map;
      _expensesByDate = expenses;
    });
  }

  List<CalendarEvent> _eventsFor(DateTime day) =>
      _eventsByDate[_dateKey(day)] ?? [];

  void _selectDay(DateTime selected, DateTime focused) {
    setState(() {
      _selectedDay = selected;
      _focusedDay = focused;
    });
    _showDaySheet(selected);
  }

  Future<void> _showDaySheet(DateTime day) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DayEventsSheet(
        day: day,
        events: _eventsFor(day),
        onChanged: () => _loadMonth(_focusedDay),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('캘린더')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TossCard(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: TableCalendar<CalendarEvent>(
              rowHeight: 62,
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  final amount = _expensesByDate[_dateKey(day)];
                  if (amount == null) return null;
                  return Positioned(
                      bottom: 0,
                      child: Text(
                        money(amount),
                        style: const TextStyle(
                            fontSize: 9, color: AppColors.textSecondary),
                      ));
                },
              ),
              firstDay: DateTime(2020, 1, 1),
              lastDay: DateTime(2035, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              onDaySelected: _selectDay,
              onPageChanged: (focused) {
                _focusedDay = focused;
                _loadMonth(focused);
              },
              eventLoader: _eventsFor,
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle:
                    TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600),
                weekendStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.textPrimary, width: 1.4),
                ),
                todayTextStyle: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w800),
                selectedDecoration: const BoxDecoration(
                    color: AppColors.accent, shape: BoxShape.circle),
                selectedTextStyle: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w800),
                markerDecoration: const BoxDecoration(
                    color: AppColors.accentDark, shape: BoxShape.circle),
                markersAnchor: 0.9,
                weekendTextStyle: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TossCard(
            onTap: () => _showDaySheet(_selectedDay),
            child: Row(
              children: [
                const Icon(Icons.event_note_outlined,
                    color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Text(
                  '${DateFormat('M월 d일 (E)', 'ko_KR').format(_selectedDay)} 일정 · 지출',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textTertiary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayEventsSheet extends StatefulWidget {
  const _DayEventsSheet(
      {required this.day, required this.events, required this.onChanged});
  final DateTime day;
  final List<CalendarEvent> events;
  final VoidCallback onChanged;

  @override
  State<_DayEventsSheet> createState() => _DayEventsSheetState();
}

class _DayEventsSheetState extends State<_DayEventsSheet> {
  late List<CalendarEvent> _events = List.of(widget.events);

  Future<void> _refresh() async {
    final events =
        await DatabaseService.instance.getEventsForDate(_dateKey(widget.day));
    if (!mounted) return;
    setState(() => _events = events);
    widget.onChanged();
  }

  Future<void> _addOrEdit({CalendarEvent? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final memoController = TextEditingController(text: existing?.memo ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(existing == null ? '일정 추가' : '일정 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: '제목'),
                autofocus: true),
            const SizedBox(height: 10),
            TextField(
                controller: memoController,
                decoration: const InputDecoration(hintText: '메모 (선택)')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final title = titleController.text.trim();
    if (title.isEmpty) return;
    if (existing == null) {
      await DatabaseService.instance.insertEvent(
        CalendarEvent(
          date: _dateKey(widget.day),
          title: title,
          memo: memoController.text.trim(),
          colorValue: AppColors.scheduleColors[1].value,
        ),
      );
    } else {
      await DatabaseService.instance.updateEvent(
        existing.copyWith(title: title, memo: memoController.text.trim()),
      );
    }
    _refresh();
  }

  Future<void> _delete(CalendarEvent event) async {
    if (event.id != null) await DatabaseService.instance.deleteEvent(event.id!);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isPastOrToday = !widget.day.isAfter(DateTime.now());
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('M월 d일 (E)', 'ko_KR').format(widget.day),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle,
                        color: AppColors.textPrimary),
                    onPressed: () => _addOrEdit(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  itemCount: _events.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: DailyExpenseCard(date: widget.day),
                      );
                    }
                    if (index == 1) {
                      return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(_events.isEmpty ? '등록된 일정이 없어요' : '일정',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)));
                    }
                    final event = _events[index - 2];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TossCard(
                        onTap: () => _addOrEdit(existing: event),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: Color(event.colorValue),
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(event.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  if (event.memo.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(event.memo,
                                          style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12)),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 18, color: AppColors.textTertiary),
                              onPressed: () => _delete(event),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (isPastOrToday) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => DiaryScreen(initialDate: widget.day)),
                    );
                  },
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('이 날의 일기 보기'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
