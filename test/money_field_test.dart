import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toss_schedule/screens/budget/money_field.dart';

void main() {
  testWidgets('Money input accepts zero and validates blank values',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final key = GlobalKey<FormState>();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Form(
                key: key,
                child: MoneyField(controller: controller, label: '월급')))));
    expect(key.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('0 이상의 금액을 입력해주세요'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '0');
    expect(key.currentState!.validate(), isTrue);
    await tester.enterText(find.byType(TextFormField), '123456789012345');
    expect(controller.text, '123456789012');
  });
}
