import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toss_schedule/services/gemini_service.dart';
import 'package:toss_schedule/services/schedule_import_service.dart';

void main() {
  test('CSV is sent as data and structured output is validated', () async {
    final client = MockClient((request) async {
      final body = jsonDecode(request.body);
      expect(body['contents'][0]['parts'][0]['text'],
          '요일,시작,종료,제목\n월,09:00,10:00,운동');
      expect(body['generationConfig']['responseMimeType'], 'application/json');
      return http.Response(
          jsonEncode({
            'candidates': [
              {
                'finishReason': 'STOP',
                'content': {
                  'parts': [
                    {
                      'text':
                          '[{"day":0,"start":540,"end":600,"title":"운동","memo":""}]'
                    }
                  ]
                },
              }
            ]
          }),
          200, headers: {'content-type': 'application/json; charset=utf-8'});
    });
    final result = await GeminiService(client: client)
        .organizeScheduleCsv('요일,시작,종료,제목\n월,09:00,10:00,운동', apiKey: 'test');
    expect(result.single.title, '운동');
  });

  test('API failures and truncated responses cannot become imports', () async {
    for (final response in [
      http.Response('{}', 429),
      http.Response('{"candidates":[{"finishReason":"MAX_TOKENS"}]}', 200),
      http.Response('{"candidates":[]}', 200),
    ]) {
      final service = GeminiService(client: MockClient((_) async => response));
      await expectLater(service.organizeScheduleCsv('csv', apiKey: 'test'),
          throwsFormatException);
    }
  });

  test('Missing key and oversized CSV are rejected before requests', () async {
    final service = GeminiService(
        client:
            MockClient((_) async => throw StateError('Should not request')));
    await expectLater(
        service.organizeScheduleCsv('csv', apiKey: ''), throwsFormatException);
    await expectLater(service.organizeScheduleCsv('a' * 100001, apiKey: 'test'),
        throwsFormatException);
  });
  test('AI results preserve minute precision and weekly recurrence', () {
    final s = parseImportedSchedules(
      '[{"day":6,"start":1415,"end":1440,"title":" 독서 ","memo":"책"}]',
    ).single;
    expect(s.isTemplate, isTrue);
    expect(s.dayOfWeek, 6);
    expect(s.startLabel, '23:35');
    expect(s.endLabel, '24:00');
    expect(s.title, '독서');
    expect(s.memo, '책');
    expect(templateScheduleKey(s), templateScheduleKey(s.copyWith(memo: '변경')));
    expect(templateScheduleKey(s),
        isNot(templateScheduleKey(s.copyWith(dayOfWeek: 0))));
  });

  test('Reject invalid AI rows instead of partially importing', () {
    for (final text in [
      '[]',
      '{}',
      '[{"day":7,"start":540,"end":600,"title":"a"}]',
      '[{"day":0,"start":600,"end":540,"title":"a"}]',
      '[{"day":0,"start":-1,"end":540,"title":"a"}]',
      '[{"day":0,"start":540,"end":1441,"title":"a"}]',
      '[{"day":0,"start":540,"end":600,"title":" "}]',
      '[{"day":0,"start":540.5,"end":600,"title":"a"}]',
      '[{"day":0,"start":540,"end":600,"title":"a","memo":42}]',
    ]) {
      expect(() => parseImportedSchedules(text), throwsFormatException);
    }
  });
}
