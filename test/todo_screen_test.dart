import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toss_schedule/models/todo_item.dart';
import 'package:toss_schedule/screens/todo/todo_screen.dart';
import 'package:toss_schedule/services/todo_repository.dart';

class MemoryTodos implements TodoRepository {
  final items = <TodoItem>[];
  int insertCalls = 0;
  bool fail = false;
  Completer<void>? pending;
  @override
  Future<List<TodoItem>> getTodos() async => List.of(items);
  @override
  Future<TodoItem> insertTodo(TodoItem todo) async {
    insertCalls++;
    await pending?.future;
    if (fail) throw StateError('Storage unavailable');
    final saved = todo.copyWith(id: items.length + 1);
    items.add(saved);
    return saved;
  }

  @override
  Future<void> updateTodo(TodoItem todo) async {
    items[items.indexWhere((e) => e.id == todo.id)] = todo;
  }

  @override
  Future<void> deleteTodo(int id) async => items.removeWhere((e) => e.id == id);
}

void main() {
  testWidgets(
      'Mobile form scrolls with keyboard and time picker requires confirmation',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = MemoryTodos();
    await tester.pumpWidget(MaterialApp(home: TodoScreen(repository: store)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('할 일 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('todo-name')), '모임');
    await tester.tap(find.byTooltip('시간 선택'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    final time =
        tester.widget<TextFormField>(find.byKey(const ValueKey('todo-time')));
    expect(time.controller!.text, '');
    await tester.enterText(find.byKey(const ValueKey('todo-time')), '18:45');
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('추가하기'));
    await tester.tap(find.text('추가하기'));
    await tester.pumpAndSettle();
    tester.view.resetViewInsets();
    expect(store.items.single.scheduledMinutes, 1125);
    expect(tester.takeException(), isNull);
  });

  Future<void> show(WidgetTester tester, MemoryTodos store) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: TodoScreen(repository: store)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('할 일 추가'));
    await tester.pumpAndSettle();
  }

  testWidgets('Plus opens a form, validates title, and saves chosen priority',
      (tester) async {
    final store = MemoryTodos();
    await show(tester, store);
    expect(find.byType(TextFormField), findsNWidgets(4));
    await tester.tap(find.text('추가하기'));
    await tester.pumpAndSettle();
    expect(find.text('할 일을 입력해주세요'), findsOneWidget);
    expect(find.text('시간을 입력해주세요'), findsOneWidget);
    expect(store.insertCalls, 0);
    await tester.enterText(find.byKey(const ValueKey('todo-name')), '  장보기  ');
    await tester.enterText(find.byKey(const ValueKey('todo-time')), '25:00');
    await tester.tap(find.text('추가하기'));
    await tester.pumpAndSettle();
    expect(find.text('00:00~23:59 형식으로 입력해주세요'), findsOneWidget);
    expect(store.insertCalls, 0);
    await tester.enterText(find.byKey(const ValueKey('todo-time')), '09:30');
    await tester.enterText(
        find.byKey(const ValueKey('todo-location')), '  강남역 2번 출구  ');
    await tester.enterText(
        find.byKey(const ValueKey('todo-participants')), '  철수, 영희 포함 3명  ');
    await tester.tap(find.text('높음'));
    await tester.tap(find.text('추가하기'));
    await tester.pumpAndSettle();
    expect(store.items.single.title, '장보기');
    expect(store.items.single.priority, TodoPriority.high);
    expect(store.items.single.scheduledMinutes, 570);
    expect(store.items.single.locationLabel, '강남역 2번 출구');
    expect(store.items.single.participants, '철수, 영희 포함 3명');
    expect(find.text('시간 09:30'), findsOneWidget);
    expect(find.text('위치 강남역 2번 출구'), findsOneWidget);
    expect(find.text('인원 철수, 영희 포함 3명'), findsOneWidget);
    expect(find.text('장보기'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    await tester.tap(find.text('장보기'));
    await tester.pumpAndSettle();
    expect(store.items.single.isDone, isTrue);
    expect(store.items.single.participants, '철수, 영희 포함 3명');
    expect(store.items.single.scheduledMinutes, 570);
  });

  testWidgets('Failed save preserves input for retry', (tester) async {
    final store = MemoryTodos()..fail = true;
    await show(tester, store);
    await tester.enterText(find.byKey(const ValueKey('todo-name')), '운동');
    await tester.enterText(find.byKey(const ValueKey('todo-time')), '00:00');
    await tester.tap(find.byKey(const ValueKey('todo-name')));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('할 일을 저장하지 못했어요. 다시 시도해주세요.'), findsOneWidget);
    expect(find.text('운동'), findsOneWidget);
    store.fail = false;
    await tester.tap(find.text('추가하기'));
    await tester.pumpAndSettle();
    expect(store.items.single.title, '운동');
    expect(store.items.single.scheduledMinutes, 0);
    expect(store.items.single.locationLabel, '');
    expect(store.items.single.participants, '');
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('Saving prevents duplicate submissions, cancel creates no item',
      (tester) async {
    final store = MemoryTodos()..pending = Completer<void>();
    await show(tester, store);
    await tester.enterText(find.byKey(const ValueKey('todo-name')), '청소');
    await tester.enterText(find.byKey(const ValueKey('todo-time')), '23:59');
    await tester.tap(find.text('추가하기'));
    await tester.pump();
    expect(find.text('저장 중…'), findsOneWidget);
    await tester.tap(find.text('저장 중…'));
    await tester.pump();
    expect(store.insertCalls, 1);
    store.pending!.complete();
    await tester.pumpAndSettle();
    expect(store.items.length, 1);
    await tester.tap(find.text('새 할 일 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(store.items.length, 1);
    expect(find.byType(TextFormField), findsNothing);
  });
}
