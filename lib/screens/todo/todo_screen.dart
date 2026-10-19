import 'package:flutter/material.dart';

import '../../models/todo_item.dart';
import '../../services/database_service.dart';
import '../../services/todo_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/toss_card.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key, this.repository});
  final TodoRepository? repository;

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  List<TodoItem> _todos = [];
  bool _loading = true;
  String? _error;
  bool _formOpen = false;
  TodoRepository get _repository =>
      widget.repository ?? DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final todos = await _repository.getTodos();
      if (!mounted) return;
      setState(() {
        _todos = todos;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = '할 일을 불러오지 못했어요';
        });
    }
  }

  Future<void> _openAddForm() async {
    if (_formOpen) return;
    _formOpen = true;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TodoForm(repository: _repository),
    );
    _formOpen = false;
    if (saved == true && mounted) await _load();
  }

  Future<void> _toggle(TodoItem todo) async {
    await _repository.updateTodo(todo.copyWith(isDone: !todo.isDone));
    _load();
  }

  Future<void> _delete(TodoItem todo) async {
    if (todo.id != null) await _repository.deleteTodo(todo.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('할 일'), actions: [
        IconButton(
            tooltip: '할 일 추가',
            onPressed: _openAddForm,
            icon: const Icon(Icons.add_rounded)),
      ]),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.textPrimary))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openAddForm,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('새 할 일 추가'),
                      )),
                ),
                if (_error != null) ...[
                  Text(_error!,
                      style: const TextStyle(color: AppColors.danger)),
                  TextButton(onPressed: _load, child: const Text('다시 시도')),
                ],
                Expanded(
                  child: _todos.isEmpty
                      ? const Center(
                          child: Text('아직 할 일이 없어요',
                              style: TextStyle(color: AppColors.textSecondary)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: _todos.length,
                          itemBuilder: (context, index) {
                            final todo = _todos[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Dismissible(
                                key: ValueKey(todo.id),
                                direction: DismissDirection.endToStart,
                                onDismissed: (_) => _delete(todo),
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(Icons.delete_outline,
                                      color: AppColors.danger),
                                ),
                                child: TossCard(
                                  onTap: () => _toggle(todo),
                                  child: Row(
                                    children: [
                                      Icon(
                                        todo.isDone
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        color: todo.isDone
                                            ? AppColors.accentDark
                                            : AppColors.textTertiary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                todo.title,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  decoration: todo.isDone
                                                      ? TextDecoration
                                                          .lineThrough
                                                      : null,
                                                  color: todo.isDone
                                                      ? AppColors.textTertiary
                                                      : AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                  todo.timeLabel == null
                                                      ? '시간 미지정'
                                                      : '시간 ${todo.timeLabel}',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .textSecondary)),
                                              if ((todo.locationLabel ?? '')
                                                  .isNotEmpty)
                                                Text('위치 ${todo.locationLabel}',
                                                    style: const TextStyle(
                                                        fontSize: 12)),
                                              if (todo.participants.isNotEmpty)
                                                Text('인원 ${todo.participants}',
                                                    style: const TextStyle(
                                                        fontSize: 12)),
                                            ]),
                                      ),
                                      _PriorityDot(priority: todo.priority),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _TodoForm extends StatefulWidget {
  const _TodoForm({required this.repository});
  final TodoRepository repository;

  @override
  State<_TodoForm> createState() => _TodoFormState();
}

class _TodoFormState extends State<_TodoForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _time = TextEditingController();
  final _location = TextEditingController();
  final _participants = TextEditingController();
  TodoPriority _priority = TodoPriority.medium;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _time.dispose();
    _location.dispose();
    _participants.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.insertTodo(TodoItem(
        title: _title.text.trim(),
        priority: _priority,
        createdAt: DateTime.now(),
        scheduledMinutes: parseTodoTime(_time.text)!,
        locationLabel: _location.text.trim(),
        participants: _participants.text.trim(),
      ));
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted)
        setState(() {
          _saving = false;
          _error = '할 일을 저장하지 못했어요. 다시 시도해주세요.';
        });
    }
  }

  Future<void> _pickTime() async {
    final minutes = parseTodoTime(_time.text);
    final picked = await showTimePicker(
      context: context,
      initialTime: minutes == null
          ? TimeOfDay.now()
          : TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      _time.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_saving,
        child: SafeArea(
            child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              20, 24, 20, 24 + MediaQuery.of(context).viewInsets.bottom),
          child: Form(
            key: _formKey,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('할 일 추가',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const ValueKey('todo-name'),
                    controller: _title,
                    autofocus: true,
                    enabled: !_saving,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                        labelText: '이름 (필수)', hintText: '할 일을 입력하세요'),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? '할 일을 입력해주세요' : null,
                    onFieldSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('todo-time'),
                    controller: _time,
                    enabled: !_saving,
                    keyboardType: TextInputType.datetime,
                    decoration: InputDecoration(
                      labelText: '시간 (필수)',
                      hintText: '09:30',
                      helperText: '24시간 형식으로 입력하거나 시계 버튼으로 선택하세요',
                      suffixIcon: IconButton(
                          tooltip: '시간 선택',
                          onPressed: _saving ? null : _pickTime,
                          icon: const Icon(Icons.access_time)),
                    ),
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? '시간을 입력해주세요'
                        : parseTodoTime(v!) == null
                            ? '00:00~23:59 형식으로 입력해주세요'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('todo-location'),
                    controller: _location,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                        labelText: '위치 (선택)', hintText: '예: 강남역 2번 출구'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('todo-participants'),
                    controller: _participants,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                        labelText: '인원 (선택)', hintText: '예: 3명 / 철수, 영희'),
                    onFieldSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 16),
                  const Text('우선순위',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final p in TodoPriority.values)
                      _PriorityChip(
                        priority: p,
                        selected: _priority == p,
                        onTap: () {
                          if (!_saving) setState(() => _priority = p);
                        },
                      ),
                  ]),
                  if (_error != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.danger))),
                  const SizedBox(height: 24),
                  ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? '저장 중…' : '추가하기')),
                  TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('취소')),
                ]),
          ),
        )),
      );
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip(
      {required this.priority, required this.selected, required this.onTap});
  final TodoPriority priority;
  final bool selected;
  final VoidCallback onTap;

  String get _label {
    switch (priority) {
      case TodoPriority.low:
        return '낮음';
      case TodoPriority.medium:
        return '보통';
      case TodoPriority.high:
        return '높음';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          _label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  const _PriorityDot({required this.priority});
  final TodoPriority priority;

  Color get _color {
    switch (priority) {
      case TodoPriority.low:
        return AppColors.textTertiary;
      case TodoPriority.medium:
        return AppColors.scheduleColors[1];
      case TodoPriority.high:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
    );
  }
}
