import 'package:flutter/material.dart';

import '../../models/todo_item.dart';
import '../../services/database_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/toss_card.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  List<TodoItem> _todos = [];
  bool _loading = true;
  final _controller = TextEditingController();
  TodoPriority _newPriority = TodoPriority.medium;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final todos = await DatabaseService.instance.getTodos();
    if (!mounted) return;
    setState(() {
      _todos = todos;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    await DatabaseService.instance.insertTodo(
      TodoItem(title: title, priority: _newPriority, createdAt: DateTime.now()),
    );
    _controller.clear();
    _load();
  }

  Future<void> _toggle(TodoItem todo) async {
    await DatabaseService.instance.updateTodo(todo.copyWith(isDone: !todo.isDone));
    _load();
  }

  Future<void> _delete(TodoItem todo) async {
    if (todo.id != null) await DatabaseService.instance.deleteTodo(todo.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('할 일')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.textPrimary))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: const InputDecoration(hintText: '할 일을 입력하세요'),
                              onSubmitted: (_) => _add(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.textPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              minimumSize: const Size(48, 48),
                            ),
                            onPressed: _add,
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (final p in TodoPriority.values) ...[
                            _PriorityChip(
                              priority: p,
                              selected: _newPriority == p,
                              onTap: () => setState(() => _newPriority = p),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _todos.isEmpty
                      ? const Center(
                          child: Text('아직 할 일이 없어요', style: TextStyle(color: AppColors.textSecondary)),
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
                                  child: const Icon(Icons.delete_outline, color: AppColors.danger),
                                ),
                                child: TossCard(
                                  onTap: () => _toggle(todo),
                                  child: Row(
                                    children: [
                                      Icon(
                                        todo.isDone ? Icons.check_circle : Icons.circle_outlined,
                                        color: todo.isDone ? AppColors.accentDark : AppColors.textTertiary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          todo.title,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            decoration: todo.isDone ? TextDecoration.lineThrough : null,
                                            color: todo.isDone ? AppColors.textTertiary : AppColors.textPrimary,
                                          ),
                                        ),
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

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority, required this.selected, required this.onTap});
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
