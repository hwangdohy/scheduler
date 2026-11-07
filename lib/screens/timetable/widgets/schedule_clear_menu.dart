import 'package:flutter/material.dart';

import '../../../../models/schedule.dart';
import '../../../../theme/app_colors.dart';

/// The caller scopes deletion to templates or the currently displayed week.
class ScheduleClearMenu extends StatefulWidget {
  const ScheduleClearMenu({super.key, this.week, required this.onClear});
  final DateTime? week;
  final Future<void> Function(int? dayOfWeek) onClear;

  @override
  State<ScheduleClearMenu> createState() => _ScheduleClearMenuState();
}

class _ScheduleClearMenuState extends State<ScheduleClearMenu> {
  bool _busy = false;

  Future<void> _confirm(bool singleDay) async {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    var day = DateTime.now().weekday - 1;
    final monday = widget.week == null ? null : mondayOfWeek(widget.week!);
    String dayLabel(int d) {
      if (monday == null) return '매주 ${weekdays[d]}요일';
      final date = monday.add(Duration(days: d));
      return '${date.month}월 ${date.day}일 (${weekdays[d]})';
    }

    String scope() {
      if (singleDay) return dayLabel(day);
      if (monday == null) return '모든 요일의 기본 일정';
      final sunday = monday.add(const Duration(days: 6));
      return '${monday.month}월 ${monday.day}일~${sunday.month}월 ${sunday.day}일의 일정';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, update) => AlertDialog(
                title: Text(singleDay ? '당일 스케줄 지우기' : '전체 스케줄 지우기'),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (singleDay) ...[
                        DropdownButtonFormField<int>(
                          initialValue: day,
                          decoration:
                              const InputDecoration(labelText: '지울 요일 선택'),
                          items: [
                            for (var d = 0; d < 7; d++)
                              DropdownMenuItem(
                                  value: d, child: Text(dayLabel(d)))
                          ],
                          onChanged: (value) {
                            if (value != null) update(() => day = value);
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text('${scope()}을 지울까요?'),
                      const SizedBox(height: 8),
                      Text(monday == null
                          ? '반복하는 기본 일정만 삭제합니다. 날짜별로 따로 수정한 일정과 일기는 유지됩니다. 이 삭제는 되돌릴 수 없습니다.'
                          : '표시된 주의 선택 범위만 비웁니다. 매주 반복하는 기본 일정과 다른 주의 일정, 일기는 유지됩니다. 삭제한 개별 일정은 복구할 수 없으며, 날짜를 누르면 기본 일정으로 다시 채울 수 있습니다.'),
                    ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('취소')),
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger),
                      child: const Text('지우기')),
                ],
              )),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.onClear(singleDay ? day : null);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${scope()}을 지웠습니다.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('일정을 지우지 못했습니다. 다시 시도해 주세요.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopupMenuButton<bool>(
        enabled: !_busy,
        tooltip: '스케줄 지우기',
        icon: const Icon(Icons.delete_sweep_outlined),
        onSelected: _confirm,
        itemBuilder: (_) => const [
          PopupMenuItem(value: false, child: Text('전체 스케줄 지우기')),
          PopupMenuItem(value: true, child: Text('당일 스케줄 지우기')),
        ],
      );
}
