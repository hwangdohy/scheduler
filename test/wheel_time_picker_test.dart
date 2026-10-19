import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toss_schedule/widgets/wheel_time_picker.dart';

void main() {
  Future<void> open(WidgetTester tester, ValueChanged<int?> result,
      {int initial = 19 * 60, int minimum = 0, bool end = false}) async {
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async => result(await showWheelTimePicker(
                        context,
                        title: '시간 선택',
                        initialMinutes: initial,
                        minimumMinutes: minimum,
                        allowEndOfDay: end)),
                    child: const Text('열기'))))));
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
  }

  Future<void> select(WidgetTester tester, String key, int value) async {
    final picker = tester.widget<CupertinoPicker>(find.byKey(ValueKey(key)));
    final animation = picker.scrollController!.animateToItem(value,
        duration: const Duration(milliseconds: 150), curve: Curves.linear);
    await tester.pumpAndSettle();
    await animation;
  }

  testWidgets('Hour and minute wheels drag and confirm independently',
      (tester) async {
    int? result;
    await open(tester, (v) => result = v);
    expect(find.byType(CupertinoPicker), findsNWidgets(2));
    final hour = tester
        .widget<CupertinoPicker>(find.byKey(const ValueKey('wheel-hour')));
    await tester.drag(
        find.byKey(const ValueKey('wheel-hour')), const Offset(0, -88));
    await tester.pumpAndSettle();
    expect(hour.scrollController!.selectedItem % 24, isNot(19));
    await select(tester, 'wheel-hour', 20);
    await select(tester, 'wheel-minute', 35);
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();
    expect(result, 1235);
  });

  testWidgets('Cancel does not apply changes', (tester) async {
    int? result = 100;
    await open(tester, (v) => result = v);
    await select(tester, 'wheel-minute', 59);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('End must be later than start, midnight remains available',
      (tester) async {
    int? result;
    await open(tester, (v) => result = v,
        initial: 20 * 60, minimum: 19 * 60 + 36, end: true);
    await select(tester, 'wheel-hour', 19);
    await select(tester, 'wheel-minute', 35);
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();
    expect(find.text('종료 시간은 시작 시간보다 늦어야 해요'), findsOneWidget);
    expect(result, isNull);
    await select(tester, 'wheel-hour', 0);
    await select(tester, 'wheel-minute', 0);
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();
    expect(result, 1440);
  });
}
