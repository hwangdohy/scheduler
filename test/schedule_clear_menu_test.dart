import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toss_schedule/screens/timetable/widgets/schedule_clear_menu.dart';

void main() {
  testWidgets('Cancelling bulk deletion never calls the storage callback',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            appBar: AppBar(actions: [
      ScheduleClearMenu(onClear: (_) async {
        calls++;
      }),
    ]))));
    await tester.tap(find.byTooltip('스케줄 지우기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('전체 스케줄 지우기'));
    await tester.pumpAndSettle();
    expect(find.text('모든 요일의 기본 일정을 지울까요?'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    await tester.tap(find.byTooltip('스케줄 지우기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('전체 스케줄 지우기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('지우기'));
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets(
      'Single-day deletion uses the selected date in the displayed week',
      (tester) async {
    int? selected;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            appBar: AppBar(actions: [
      ScheduleClearMenu(
          week: DateTime(2026, 11, 2),
          onClear: (day) async {
            selected = day;
          }),
    ]))));
    await tester.tap(find.byTooltip('스케줄 지우기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('당일 스케줄 지우기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('11월 4일 (수)').last);
    await tester.pumpAndSettle();
    expect(find.text('11월 4일 (수)을 지울까요?'), findsOneWidget);
    await tester.tap(find.text('지우기'));
    await tester.pumpAndSettle();
    expect(selected, 2);
  });
}
