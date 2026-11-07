import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toss_schedule/models/schedule.dart';
import 'package:toss_schedule/widgets/today_schedule_card.dart';
import 'package:toss_schedule/screens/timetable/widgets/schedule_form_sheet.dart';

void main() {
  testWidgets('Tap today count to reveal the complete scrollable agenda',
      (tester) async {
    final schedules = List.generate(
        12,
        (i) => Schedule(
            dayOfWeek: 0,
            startHour: i,
            endHour: i + 1,
            title: '오늘 일정 $i',
            memo: '메모 $i',
            colorValue: 0xFF3182F6));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: TodayScheduleCard(
      reloadToken: 0,
      loadSchedules: () async => schedules,
    ))));
    await tester.pumpAndSettle();
    expect(find.text('오늘 일정 11'), findsNothing);
    await tester.tap(find.text('오늘 일정 12개 ›'));
    await tester.pumpAndSettle();
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.text('메모 0'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('메모 11'), 250,
        scrollable: find.descendant(
            of: find.byType(DraggableScrollableSheet),
            matching: find.byType(Scrollable)));
    await tester.pumpAndSettle();
    expect(find.text('메모 11'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Empty today agenda opens with an empty-state message',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: TodayScheduleCard(
      reloadToken: 0,
      loadSchedules: () async => [],
    ))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('오늘 일정 0개 ›'));
    await tester.pumpAndSettle();
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.text('오늘은 등록된 일정이 없어요'), findsWidgets);
  });

  testWidgets('Template and date forms support selecting multiple weekdays',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: ScheduleFormSheet(initialDay: 0)))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('수'));
    await tester.tap(find.text('금'));
    await tester.pumpAndSettle();
    expect(find.text('기본 일정 · 매주 월·수·금요일 반복'), findsOneWidget);
    await tester.tap(find.text('월'));
    await tester.pumpAndSettle();
    expect(find.text('기본 일정 · 매주 수·금요일 반복'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: ScheduleFormSheet(
                    key: const ValueKey('date-form'),
                    date: DateTime(2026, 11, 2))))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('수'));
    await tester.pumpAndSettle();
    expect(find.text('선택한 요일에 적용 · 11월 2일 (월) 주간'), findsOneWidget);
  });
}
