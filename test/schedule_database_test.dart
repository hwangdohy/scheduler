import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:toss_schedule/models/schedule.dart';
import 'package:toss_schedule/models/diary_entry.dart';
import 'package:toss_schedule/services/database_service.dart';
import 'package:toss_schedule/services/schedule_conflict.dart';

Schedule block(int day, int start, int end, {String title = '일정'}) => Schedule(
    dayOfWeek: day,
    startHour: start ~/ 60,
    startMinute: start % 60,
    endHour: end ~/ 60,
    endMinute: end % 60,
    title: title,
    colorValue: 0xFF3182F6);

void main() {
  late Database db;
  late DatabaseService service;
  setUpAll(sqfliteFfiInit);
  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(
        'CREATE TABLE schedules (id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT, template_id INTEGER, day_of_week INTEGER, start_hour INTEGER, end_hour INTEGER, start_minute INTEGER, end_minute INTEGER, title TEXT, color INTEGER, memo TEXT)');
    await db.execute('CREATE TABLE customized_dates (date TEXT PRIMARY KEY)');
    await db.execute(
        'CREATE TABLE diary_entries (id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT UNIQUE, content TEXT, summary TEXT, updated_at TEXT)');
    service = DatabaseService.forTesting(db);
  });
  tearDown(() => db.close());

  test('Overlap is rejected; adjacent times and other weekdays are allowed',
      () async {
    await service.insertTemplateSchedule(block(0, 540, 600));
    for (final times in [
      [539, 541],
      [550, 560],
      [530, 610],
      [590, 610],
      [540, 600]
    ]) {
      await expectLater(
          service.insertTemplateSchedule(block(0, times[0], times[1])),
          throwsA(isA<ScheduleConflict>()));
    }
    await service.insertTemplateSchedule(block(0, 600, 630));
    await service.insertTemplateSchedule(block(1, 540, 600));
    expect(await service.getTemplateSchedules(), hasLength(3));
  });

  test('Multi-day template writes roll back entirely if one day conflicts',
      () async {
    await service.insertTemplateSchedule(block(4, 540, 600, title: '기존'));
    await expectLater(service.saveScheduleDays(block(0, 550, 580), {0, 2, 4}),
        throwsA(isA<ScheduleConflict>()));
    expect((await service.getTemplateSchedules()).single.title, '기존');
    await service.saveScheduleDays(block(0, 600, 630), {0, 2, 4});
    expect(await service.getTemplateSchedules(), hasLength(4));
  });

  test('Editing excludes itself and copies changes to extra weekdays',
      () async {
    await service.insertTemplateSchedule(block(0, 540, 600));
    final original = (await service.getTemplateSchedules()).single;
    await service.saveScheduleDays(original.copyWith(title: '수정'), {0, 2},
        existing: original);
    final rows = await service.getTemplateSchedules();
    expect(rows.map((s) => s.dayOfWeek), [0, 2]);
    expect(rows.every((s) => s.title == '수정'), isTrue);
    expect(rows.first.id, original.id);
  });

  test('Date edits materialize templates and exclude the matching copied row',
      () async {
    final monday = DateTime(2026, 11, 2);
    await service.insertTemplateSchedule(block(0, 540, 600));
    final original = (await service.getSchedulesForDate(monday)).single;
    await service.saveScheduleDays(original.copyWith(title: '이번 주'), {0, 2},
        date: monday, existing: original);
    expect((await service.getSchedulesForDate(monday)).single.title, '이번 주');
    expect(
        (await service.getSchedulesForDate(monday.add(const Duration(days: 2))))
            .single
            .title,
        '이번 주');
    expect((await service.getTemplateSchedules()).single.title, '일정');
    expect(
        (await service.getSchedulesForDate(monday.add(const Duration(days: 7))))
            .single
            .title,
        '일정');
    final saved = (await service.getSchedulesForDate(monday)).single;
    await service.updateScheduleOnDate(
        monday, saved, saved.copyWith(title: '다시 수정'));
    expect((await service.getSchedulesForDate(monday)).single.title, '다시 수정');
  });

  test('Failed multi-date save rolls back snapshots and preserves diary data',
      () async {
    final monday = DateTime(2026, 11, 2);
    await service.insertTemplateSchedule(block(4, 540, 600));
    await service.upsertDiary(
        DiaryEntry(date: '2026-11-02', content: '보존할 일기', updatedAt: monday));
    await expectLater(
        service.saveScheduleDays(block(0, 550, 580), {0, 4}, date: monday),
        throwsA(isA<ScheduleConflict>()));
    expect(await db.query('customized_dates'), isEmpty);
    expect(await service.getSchedulesForDate(monday), isEmpty);
    expect((await service.getDiaryForDate('2026-11-02'))!.content, '보존할 일기');
  });

  test('CSV deduplicates exact matches but rolls back overlapping rows',
      () async {
    await service.insertTemplateSchedule(block(0, 540, 600));
    expect(await service.importTemplateSchedules([block(0, 540, 600)]), 0);
    await expectLater(
        service
            .importTemplateSchedules([block(1, 540, 600), block(0, 550, 580)]),
        throwsA(isA<ScheduleConflict>()));
    expect(await service.getTemplateSchedules(), hasLength(1));
    await expectLater(
        service
            .importTemplateSchedules([block(1, 540, 600), block(1, 550, 580)]),
        throwsA(isA<ScheduleConflict>()));
    expect(await service.getTemplateSchedules(), hasLength(1));
  });

  test('Concurrent conflicting requests cannot both write', () async {
    var conflicts = 0;
    await Future.wait(List.generate(2, (_) async {
      try {
        await service.insertTemplateSchedule(block(0, 540, 600));
      } on ScheduleConflict {
        conflicts++;
      }
    }));
    expect(conflicts, 1);
    expect(await service.getTemplateSchedules(), hasLength(1));
  });

  test('Widget snapshot includes custom empty dates and recurring schedules',
      () async {
    await service.insertTemplateSchedule(block(0, 540, 600));
    await db.insert('customized_dates', {'date': '2026-11-02'});
    final snapshot = await service.getWidgetScheduleSnapshot();
    expect(snapshot['customized_dates'], ['2026-11-02']);
    expect(snapshot['schedules'], hasLength(1));
  });

  test(
      'Clearing template day or all templates preserves customized dates and diary',
      () async {
    final monday = DateTime(2026, 11, 2);
    await service.saveScheduleDays(block(0, 540, 600), {0, 1});
    await service.addScheduleToDate(monday, block(0, 600, 660));
    await service.upsertDiary(
        DiaryEntry(date: '2026-11-02', content: '일기', updatedAt: monday));
    await service.clearTemplateSchedules(dayOfWeek: 0);
    expect((await service.getTemplateSchedules()).single.dayOfWeek, 1);
    expect(await service.getSchedulesForDate(monday), hasLength(2));
    await service.clearTemplateSchedules();
    expect(await service.getTemplateSchedules(), isEmpty);
    expect(await service.getSchedulesForDate(monday), hasLength(2));
    expect((await service.getDiaryForDate('2026-11-02'))!.content, '일기');
  });

  test('Clearing a week day leaves an empty override and preserves other dates',
      () async {
    final monday = DateTime(2026, 11, 2);
    await service.saveScheduleDays(block(0, 540, 600), {0, 1});
    await service.addScheduleToDate(monday, block(0, 600, 660));
    await service.clearWeekSchedules(monday, dayOfWeek: 0);
    expect(await service.getSchedulesForDate(monday), isEmpty);
    expect(
        await service.getSchedulesForDate(monday.add(const Duration(days: 1))),
        hasLength(1));
    expect(
        await service.getSchedulesForDate(monday.add(const Duration(days: 7))),
        hasLength(1));
    expect(await service.getTemplateSchedules(), hasLength(2));
    await service.resetDateToTemplate(monday);
    expect(await service.getSchedulesForDate(monday), hasLength(1));
  });

  test('Clearing the displayed week keeps templates, other weeks and diary',
      () async {
    final monday = DateTime(2026, 11, 2);
    await service.saveScheduleDays(block(0, 540, 600), {0, 1, 2, 3, 4, 5, 6});
    await service.addScheduleToDate(monday, block(0, 600, 660));
    final nextMonday = monday.add(const Duration(days: 7));
    await service.addScheduleToDate(nextMonday, block(0, 600, 660));
    await service.upsertDiary(
        DiaryEntry(date: '2026-11-02', content: '일기', updatedAt: monday));
    await service.clearWeekSchedules(monday.add(const Duration(days: 2)));
    final week = await service.getWeek(monday);
    expect(week.byDate.values.every((day) => day.isEmpty), isTrue);
    expect(week.customizedDates, hasLength(7));
    expect(await service.getTemplateSchedules(), hasLength(7));
    expect(await service.getSchedulesForDate(nextMonday), hasLength(2));
    expect((await service.getDiaryForDate('2026-11-02'))!.content, '일기');
  });
}
