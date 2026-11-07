import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../models/schedule.dart';
import '../../services/database_service.dart';
import '../../services/schedule_import_service.dart';

class CsvImportScreen extends StatefulWidget {
  const CsvImportScreen({super.key});

  @override
  State<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends State<CsvImportScreen> {
  List<Schedule> _preview = [];
  final Set<int> _selected = {};
  bool _busy = false;
  String? _error;
  String? _fileName;

  Future<void> _chooseFile() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await openFile(acceptedTypeGroups: [
        const XTypeGroup(
            label: 'CSV',
            extensions: ['csv'],
            mimeTypes: ['text/csv', 'application/csv'],
            uniformTypeIdentifiers: ['public.comma-separated-values-text']),
      ]);
      if (file == null || !mounted) return;
      if (await file.length() > 100000) {
        throw const FormatException('100KB 이하의 CSV를 선택해 주세요.');
      }
      final String csv;
      try {
        csv = utf8
            .decode(await file.readAsBytes())
            .replaceFirst(RegExp('^\uFEFF'), '');
      } on FormatException {
        throw const FormatException(
            'UTF-8 CSV가 아닙니다. 엑셀에서 CSV UTF-8 형식으로 다시 저장해 주세요.');
      }
      final schedules = parseScheduleCsv(csv);
      final existing = await DatabaseService.instance.getTemplateSchedules();
      final keys = existing.map(templateScheduleKey).toSet();
      final unique =
          schedules.where((s) => keys.add(templateScheduleKey(s))).toList()
            ..sort((a, b) {
              final day = a.dayOfWeek.compareTo(b.dayOfWeek);
              return day == 0 ? a.startMinutes.compareTo(b.startMinutes) : day;
            });
      if (!mounted) return;
      setState(() {
        _fileName = file.name;
        _preview = unique;
        _selected
          ..clear()
          ..addAll(List.generate(unique.length, (i) => i));
        if (unique.isEmpty) _error = '추가할 새 일정이 없습니다. 기존 일정과 중복되는지 확인해 주세요.';
      });
    } on FormatException catch (e) {
      if (mounted) setState(() => _error = e.message.toString());
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'CSV를 읽지 못했습니다. 파일 내용을 확인하고 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final count = await DatabaseService.instance.importTemplateSchedules([
        for (var i = 0; i < _preview.length; i++)
          if (_selected.contains(i)) _preview[i],
      ]);
      if (mounted) Navigator.of(context).pop(count);
    } catch (_) {
      if (mounted) {
        setState(() => _error = '저장하지 못했습니다. 기존 데이터는 유지됩니다. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_busy,
        child: Scaffold(
          appBar: AppBar(title: const Text('CSV로 기본 일정 추가')),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('API 키 없이 CSV를 읽어 매주 반복되는 기본 일정으로 추가합니다.\n'
                        '요일·시작 시간·종료 시간·제목이 포함된 UTF-8 CSV(100KB 이하)를 선택하세요.\n'
                        '첫 행: 요일,시작 시간,종료 시간,제목,메모\n'
                        '예: 월요일,09:00,10:30,운동,\n\n'
                        '기존 일정에 추가하며 같은 요일·시간·제목은 건너뜁니다. '
                        '이미 개별 수정한 날짜에는 기본 일정 변경이 반영되지 않습니다.'),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _chooseFile,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_preview.isEmpty ? 'CSV 파일 선택' : '다른 CSV 선택'),
                    ),
                    if (_fileName != null) Text(_fileName!),
                    if (_preview.isNotEmpty)
                      const Text('요일과 시간을 확인하고 추가할 일정을 선택하세요.'),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_error!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      ),
                  ]),
            ),
            if (_busy) const LinearProgressIndicator(),
            Expanded(
                child: ListView.builder(
              itemCount: _preview.length,
              itemBuilder: (context, i) {
                final s = _preview[i];
                return CheckboxListTile(
                  value: _selected.contains(i),
                  onChanged: _busy
                      ? null
                      : (value) => setState(() {
                            if (value == true) {
                              _selected.add(i);
                            } else {
                              _selected.remove(i);
                            }
                          }),
                  title: Text(s.title),
                  subtitle: Text('${const [
                    '월',
                    '화',
                    '수',
                    '목',
                    '금',
                    '토',
                    '일'
                  ][s.dayOfWeek]}요일 '
                      '${s.startLabel}–${s.endLabel}${s.memo.isEmpty ? '' : '\n${s.memo}'}'),
                );
              },
            )),
            SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: _busy || _selected.isEmpty ? null : _save,
                    child: Text('선택한 ${_selected.length}개 기본 일정 추가'),
                  ),
                )),
          ]),
        ),
      );
}
