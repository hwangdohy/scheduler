import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/diary_entry.dart';
import '../../services/database_service.dart';
import '../../services/gemini_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/toss_card.dart';

String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

/// Diary screen for a given date: shows the entry (if any) plus its
/// 2-3 keyword Gemini summary, and lets the user write/edit the entry.
/// Reached from the bottom tab (today), a calendar date tap (past days),
/// or a tapped diary-reminder push notification.
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key, required this.initialDate});
  final DateTime initialDate;

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  late DateTime _date;
  DiaryEntry? _entry;
  bool _loading = true;
  bool _summarizing = false;

  @override
  void initState() {
    super.initState();
    _date = DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final entry = await DatabaseService.instance.getDiaryForDate(_dateKey(_date));
    if (!mounted) return;
    setState(() {
      _entry = entry;
      _loading = false;
    });
  }

  void _changeDay(int delta) {
    setState(() => _date = _date.add(Duration(days: delta)));
    _load();
  }

  Future<void> _openEditor() async {
    final saved = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DiaryEditorSheet(initialText: _entry?.content ?? ''),
    );
    if (saved == null) return;

    final apiKey = context.read<SettingsService>().geminiApiKey;
    setState(() => _summarizing = true);
    final summary = await GeminiService().summarizeDiary(saved, apiKey: apiKey);
    final updated = await DatabaseService.instance.upsertDiary(
      DiaryEntry(
        date: _dateKey(_date),
        content: saved,
        summary: summary,
        updatedAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _entry = updated;
      _summarizing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFuture = _date.isAfter(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () => _changeDay(-1),
            ),
            Text(DateFormat('M월 d일 (E)', 'ko_KR').format(_date)),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: isFuture ? null : () => _changeDay(1),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.textPrimary))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_entry?.summary != null && _entry!.summary!.isNotEmpty) ...[
                  TossCard(
                    color: AppColors.accent.withOpacity(0.25),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, size: 18, color: AppColors.textPrimary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _entry!.summary!,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_summarizing)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary),
                        ),
                        SizedBox(width: 8),
                        Text('AI가 오늘의 기록을 요약하고 있어요...', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                TossCard(
                  onTap: _openEditor,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('오늘의 일기', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          const Spacer(),
                          Icon(
                            _entry == null || _entry!.content.isEmpty ? Icons.edit_note : Icons.edit,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _entry == null || _entry!.content.isEmpty
                            ? '오늘 하루는 어땠나요? 눌러서 기록해보세요.'
                            : _entry!.content,
                        style: TextStyle(
                          color: _entry == null || _entry!.content.isEmpty
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _DiaryEditorSheet extends StatefulWidget {
  const _DiaryEditorSheet({required this.initialText});
  final String initialText;

  @override
  State<_DiaryEditorSheet> createState() => _DiaryEditorSheetState();
}

class _DiaryEditorSheetState extends State<_DiaryEditorSheet> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
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
                const Text('일기 쓰기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: true,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(hintText: '오늘 있었던 일을 자유롭게 적어보세요...'),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, _controller.text.trim()),
              child: const Text('저장하고 AI 요약받기'),
            ),
          ],
        ),
      ),
    );
  }
}
