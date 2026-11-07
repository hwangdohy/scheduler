import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:toss_schedule/screens/settings/settings_screen.dart';
import 'package:toss_schedule/services/settings_service.dart';
import 'package:toss_schedule/services/schedule_import_service.dart';

void main() {
  testWidgets('Users without API keys can expand and copy the CSV prompt',
      (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = call.arguments['text'] as String;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => SettingsService(),
      child: const MaterialApp(home: SettingsScreen()),
    ));
    final help = find.text('Gemini API 키가 없어요');
    final scrollable = find
        .descendant(
            of: find.byType(ListView), matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(help, 200, scrollable: scrollable);
    await tester.pumpAndSettle();
    await tester.tap(help);
    await tester.pumpAndSettle();
    final copy = find.text('변환 프롬프트 복사');
    await tester.scrollUntilVisible(copy, 200, scrollable: scrollable);
    await tester.pumpAndSettle();
    await tester.tap(copy);
    await tester.pumpAndSettle();
    expect(copied, scheduleCsvPrompt);
    expect(find.text('변환 프롬프트를 복사했습니다.'), findsOneWidget);
  });
}
