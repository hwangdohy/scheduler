import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toss_schedule/models/schedule.dart';
import 'package:toss_schedule/screens/timetable/widgets/schedule_form_sheet.dart';

void main() {
  testWidgets('Schedule time buttons apply wheel minutes and adjust end time',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
      body: SingleChildScrollView(child: ScheduleFormSheet(initialHour: 19)),
    )));
    await tester.pumpAndSettle();
    expect(find.text('19:00'), findsOneWidget);
    expect(find.text('20:00'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('시작 시간')));
    await tester.pumpAndSettle();
    tester
        .widget<CupertinoPicker>(find.byKey(const ValueKey('wheel-hour')))
        .scrollController!
        .jumpToItem(20);
    tester
        .widget<CupertinoPicker>(find.byKey(const ValueKey('wheel-minute')))
        .scrollController!
        .jumpToItem(35);
    await tester.pumpAndSettle();
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();
    expect(find.text('20:35'), findsOneWidget);
    expect(find.text('21:35'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('종료 시간')));
    await tester.pumpAndSettle();
    tester
        .widget<CupertinoPicker>(find.byKey(const ValueKey('wheel-minute')))
        .scrollController!
        .jumpToItem(50);
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('21:35'), findsOneWidget);
  });

  testWidgets('Copy and paste across template and date editors',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> showForm(ScheduleFormSheet form) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: form)),
      ));
      await tester.pumpAndSettle();
    }

    await showForm(const ScheduleFormSheet());
    expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, '일정 붙여넣기'),
            )
            .onPressed,
        isNull);

    await showForm(ScheduleFormSheet(
      key: const ValueKey('source'),
      date: DateTime(2026, 10, 19),
      existing: const Schedule(
        id: 42,
        date: '2026-10-19',
        dayOfWeek: 0,
        startHour: 9,
        startMinute: 15,
        endHour: 12,
        endMinute: 45,
        title: 'Study',
        memo: 'Chapter 2',
        colorValue: 0xFF123456,
      ),
    ));
    await tester.enterText(find.byType(TextField).first, 'Study edited');
    await tester.tap(find.text('일정 복사'));
    await tester.pumpAndSettle();

    await showForm(const ScheduleFormSheet(
      key: ValueKey('template'),
      initialDay: 4,
      initialHour: 14,
    ));
    await tester.tap(find.text('일정 붙여넣기'));
    await tester.pumpAndSettle();
    expect(find.text('Study edited'), findsOneWidget);
    expect(find.text('Chapter 2'), findsOneWidget);
    expect(find.text('기본 일정 · 매주 금요일 반복'), findsOneWidget);
    expect(find.text('14:00'), findsOneWidget);
    expect(find.text('17:30'), findsOneWidget);
    expect(find.text('추가하기'), findsOneWidget);
    expect(find.text('삭제'), findsNothing);

    await showForm(ScheduleFormSheet(
      key: const ValueKey('late-date'),
      date: DateTime(2026, 10, 25),
      initialHour: 23,
    ));
    await tester.tap(find.text('일정 붙여넣기'));
    await tester.pumpAndSettle();
    expect(find.text('23:00'), findsOneWidget);
    expect(find.text('24:00'), findsOneWidget);
    expect(find.text('10월 25일 (일) 하루에만 적용돼요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
