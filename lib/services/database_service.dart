import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/calendar_event.dart';
import '../models/diary_entry.dart';
import '../models/schedule.dart';
import '../models/todo_item.dart';
import '../models/monthly_budget.dart';
import 'todo_repository.dart';
import 'db_factory_io.dart' if (dart.library.js_interop) 'db_factory_web.dart';

/// Single SQLite gateway for the whole app. Kept as a lazy singleton so
/// every screen shares one open database connection.
class DatabaseService implements TodoRepository {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();
  final ValueNotifier<int> budgetRevision = ValueNotifier(0);

  // Holding the future (not the database) makes concurrent first calls
  // share one open instead of racing to open several.
  Future<Database>? _dbFuture;

  Future<Database> get database => _dbFuture ??= _open();

  static Future<void> _createBudgetTables(Database db) async {
    await db.execute('''CREATE TABLE monthly_budgets (
      month TEXT PRIMARY KEY, salary INTEGER NOT NULL,
      extra_income INTEGER NOT NULL, savings_goal INTEGER NOT NULL,
      fixed_expenses TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE daily_expenses (
      date TEXT PRIMARY KEY, amount INTEGER NOT NULL CHECK(amount >= 0))''');
  }

  Future<MonthlyBudget> getMonthlyBudget(int year, int month) async {
    final db = await database;
    final key = '$year-${month.toString().padLeft(2, '0')}';
    final rows =
        await db.query('monthly_budgets', where: 'month = ?', whereArgs: [key]);
    return rows.isEmpty
        ? MonthlyBudget(year: year, month: month)
        : MonthlyBudget.fromMap(rows.first);
  }

  Future<void> saveMonthlyBudget(MonthlyBudget budget) async {
    final db = await database;
    await db.insert('monthly_budgets', budget.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    budgetRevision.value++;
  }

  Future<Map<String, int>> getMonthlyExpenses(int year, int month) async {
    final db = await database;
    final first = scheduleDateKey(DateTime(year, month));
    final next = scheduleDateKey(DateTime(year, month + 1));
    final rows = await db.query('daily_expenses',
        where: 'date >= ? AND date < ?',
        whereArgs: [first, next],
        orderBy: 'date');
    return {for (final r in rows) r['date'] as String: r['amount'] as int};
  }

  Future<int?> getDailyExpense(DateTime date) async {
    final db = await database;
    final rows = await db.query('daily_expenses',
        where: 'date = ?', whereArgs: [scheduleDateKey(date)]);
    return rows.isEmpty ? null : rows.first['amount'] as int;
  }

  Future<void> saveDailyExpense(DateTime date, int amount) async {
    if (amount < 0) throw ArgumentError.value(amount, 'amount');
    final db = await database;
    await db.insert(
        'daily_expenses', {'date': scheduleDateKey(date), 'amount': amount},
        conflictAlgorithm: ConflictAlgorithm.replace);
    budgetRevision.value++;
  }

  Future<void> deleteDailyExpense(DateTime date) async {
    final db = await database;
    await db.delete('daily_expenses',
        where: 'date = ?', whereArgs: [scheduleDateKey(date)]);
    budgetRevision.value++;
  }

  Future<Database> _open() async {
    configureDatabaseFactory();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'toss_schedule.db');
    return openDatabase(
      path,
      version: 4,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          await db.execute(
              'ALTER TABLE todos ADD COLUMN scheduled_minutes INTEGER');
          await db.execute(
              "ALTER TABLE todos ADD COLUMN participants TEXT NOT NULL DEFAULT ''");
          await db.execute('ALTER TABLE todos ADD COLUMN location_label TEXT');
        }
        if (oldVersion < 3) await _createBudgetTables(db);
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE schedules ADD COLUMN date TEXT');
          await db
              .execute('ALTER TABLE schedules ADD COLUMN template_id INTEGER');
          await db
              .execute('CREATE INDEX idx_schedules_date ON schedules(date)');
          await db.execute(
            'CREATE TABLE customized_dates (date TEXT PRIMARY KEY)',
          );
        }
      },
      onCreate: (db, version) async {
        await _createBudgetTables(db);
        await db.execute('''
          CREATE TABLE schedules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            template_id INTEGER,
            day_of_week INTEGER NOT NULL,
            start_hour INTEGER NOT NULL,
            end_hour INTEGER NOT NULL,
            title TEXT NOT NULL,
            color INTEGER NOT NULL,
            memo TEXT
          )
        ''');
        await db.execute('CREATE INDEX idx_schedules_date ON schedules(date)');
        await db.execute(
          'CREATE TABLE customized_dates (date TEXT PRIMARY KEY)',
        );
        await db.execute('''
          CREATE TABLE todos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            is_done INTEGER NOT NULL DEFAULT 0,
            priority INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL,
            scheduled_minutes INTEGER,
            participants TEXT NOT NULL DEFAULT '',
            location_label TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            title TEXT NOT NULL,
            memo TEXT,
            color INTEGER NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_events_date ON events(date)');
        await db.execute('''
          CREATE TABLE diary_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL UNIQUE,
            content TEXT NOT NULL,
            summary TEXT,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // ---------------------------------------------------------------------
  // Schedules — 기본 일정 (weekly template) + per-date overrides
  // ---------------------------------------------------------------------

  /// The weekly 기본 일정: rows with no date, repeating every week.
  Future<List<Schedule>> getTemplateSchedules() async {
    final db = await database;
    final rows = await db.query(
      'schedules',
      where: 'date IS NULL',
      orderBy: 'day_of_week, start_hour',
    );
    return rows.map(Schedule.fromMap).toList();
  }

  Future<void> insertTemplateSchedule(Schedule schedule) async {
    final db = await database;
    await db.insert('schedules', schedule.withDate(null).toMap()..remove('id'));
  }

  Future<void> updateTemplateSchedule(Schedule schedule) async {
    final db = await database;
    await db.update(
      'schedules',
      schedule.withDate(null).toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<void> deleteTemplateSchedule(int id) async {
    final db = await database;
    await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  /// What actually shows on each day of the week starting at [monday]:
  /// a date's own blocks once it has been customized, otherwise the
  /// 기본 일정 for that weekday.
  Future<WeekSchedules> getWeek(DateTime monday) async {
    final db = await database;
    final dates = [
      for (int i = 0; i < 7; i++)
        scheduleDateKey(monday.add(Duration(days: i))),
    ];
    final placeholders = List.filled(dates.length, '?').join(',');

    final customized = (await db.query(
      'customized_dates',
      where: 'date IN ($placeholders)',
      whereArgs: dates,
    ))
        .map((r) => r['date'] as String)
        .toSet();

    final template = await getTemplateSchedules();
    final overrides = <String, List<Schedule>>{};
    final overrideRows = await db.query(
      'schedules',
      where: 'date IN ($placeholders)',
      whereArgs: dates,
      orderBy: 'start_hour',
    );
    for (final row in overrideRows.map(Schedule.fromMap)) {
      overrides.putIfAbsent(row.date!, () => []).add(row);
    }

    final byDate = <String, List<Schedule>>{};
    for (int i = 0; i < 7; i++) {
      byDate[dates[i]] = customized.contains(dates[i])
          ? (overrides[dates[i]] ?? const [])
          : template.where((s) => s.dayOfWeek == i).toList();
    }
    return WeekSchedules(
      dates: dates,
      byDate: byDate,
      customizedDates: customized,
    );
  }

  Future<List<Schedule>> getSchedulesForDate(DateTime date) async {
    final db = await database;
    final key = scheduleDateKey(date);
    final customized = await db.query(
      'customized_dates',
      where: 'date = ?',
      whereArgs: [key],
      limit: 1,
    );
    final rows = customized.isNotEmpty
        ? await db.query(
            'schedules',
            where: 'date = ?',
            whereArgs: [key],
            orderBy: 'start_hour',
          )
        : await db.query(
            'schedules',
            where: 'date IS NULL AND day_of_week = ?',
            whereArgs: [date.weekday - 1],
            orderBy: 'start_hour',
          );
    return rows.map(Schedule.fromMap).toList();
  }

  /// Copy-on-write. The first date-specific edit snapshots that day's
  /// 기본 일정 into real rows, so later template edits leave the date alone.
  Future<void> _materializeDate(String date, int dayOfWeek) async {
    final db = await database;
    final already = await db.query(
      'customized_dates',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    if (already.isNotEmpty) return;

    await db.insert('customized_dates', {'date': date});
    final template = await db.query(
      'schedules',
      where: 'date IS NULL AND day_of_week = ?',
      whereArgs: [dayOfWeek],
    );
    final batch = db.batch();
    for (final row in template) {
      batch.insert(
        'schedules',
        Map<String, Object?>.from(row)
          ..remove('id')
          ..['date'] = date
          ..['template_id'] = row['id'],
      );
    }
    await batch.commit(noResult: true);
  }

  /// A block shown on a date may still be a template row the user has
  /// never touched; after materializing, its copy is found via template_id.
  Future<int?> _rowIdOnDate(String date, Schedule shown) async {
    if (!shown.isTemplate) return shown.id;
    final db = await database;
    final rows = await db.query(
      'schedules',
      columns: ['id'],
      where: 'date = ? AND template_id = ?',
      whereArgs: [date, shown.id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['id'] as int;
  }

  Future<void> addScheduleToDate(DateTime date, Schedule schedule) async {
    final key = scheduleDateKey(date);
    final dayOfWeek = date.weekday - 1;
    await _materializeDate(key, dayOfWeek);
    final db = await database;
    await db.insert(
      'schedules',
      schedule.withDate(key).toMap()
        ..remove('id')
        ..['day_of_week'] = dayOfWeek,
    );
  }

  Future<void> updateScheduleOnDate(
    DateTime date,
    Schedule shown,
    Schedule edited,
  ) async {
    final key = scheduleDateKey(date);
    final dayOfWeek = date.weekday - 1;
    await _materializeDate(key, dayOfWeek);
    final id = await _rowIdOnDate(key, shown);
    if (id == null) return;
    final db = await database;
    await db.update(
      'schedules',
      edited.withDate(key).toMap()
        ..['id'] = id
        ..['day_of_week'] = dayOfWeek,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteScheduleOnDate(DateTime date, Schedule shown) async {
    final key = scheduleDateKey(date);
    await _materializeDate(key, date.weekday - 1);
    final id = await _rowIdOnDate(key, shown);
    if (id == null) return;
    final db = await database;
    await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  /// Drops a date's own copy so it follows the 기본 일정 again.
  Future<void> resetDateToTemplate(DateTime date) async {
    final key = scheduleDateKey(date);
    final db = await database;
    await db.delete('schedules', where: 'date = ?', whereArgs: [key]);
    await db.delete('customized_dates', where: 'date = ?', whereArgs: [key]);
  }

  // ---------------------------------------------------------------------
  // Todos
  // ---------------------------------------------------------------------

  Future<List<TodoItem>> getTodos() async {
    final db = await database;
    final rows = await db.query('todos',
        orderBy: 'is_done ASC, priority DESC, created_at DESC');
    return rows.map(TodoItem.fromMap).toList();
  }

  Future<TodoItem> insertTodo(TodoItem todo) async {
    if (todo.title.trim().isEmpty ||
        todo.scheduledMinutes == null ||
        todo.scheduledMinutes! < 0 ||
        todo.scheduledMinutes! >= 24 * 60) {
      throw ArgumentError('할 일 이름과 올바른 시간이 필요합니다');
    }
    final db = await database;
    final id = await db.insert('todos', todo.toMap()..remove('id'));
    return todo.copyWith(id: id);
  }

  Future<void> updateTodo(TodoItem todo) async {
    final db = await database;
    await db
        .update('todos', todo.toMap(), where: 'id = ?', whereArgs: [todo.id]);
  }

  Future<void> deleteTodo(int id) async {
    final db = await database;
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------------
  // Calendar events
  // ---------------------------------------------------------------------

  Future<List<CalendarEvent>> getEventsForMonth(int year, int month) async {
    final db = await database;
    final prefix = '$year-${month.toString().padLeft(2, '0')}';
    final rows = await db.query(
      'events',
      where: 'date LIKE ?',
      whereArgs: ['$prefix%'],
      orderBy: 'date ASC',
    );
    return rows.map(CalendarEvent.fromMap).toList();
  }

  Future<List<CalendarEvent>> getEventsForDate(String date) async {
    final db = await database;
    final rows = await db.query('events', where: 'date = ?', whereArgs: [date]);
    return rows.map(CalendarEvent.fromMap).toList();
  }

  Future<CalendarEvent> insertEvent(CalendarEvent event) async {
    final db = await database;
    final id = await db.insert('events', event.toMap()..remove('id'));
    return event.copyWith(id: id);
  }

  Future<void> updateEvent(CalendarEvent event) async {
    final db = await database;
    await db.update('events', event.toMap(),
        where: 'id = ?', whereArgs: [event.id]);
  }

  Future<void> deleteEvent(int id) async {
    final db = await database;
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------------
  // Diary
  // ---------------------------------------------------------------------

  Future<DiaryEntry?> getDiaryForDate(String date) async {
    final db = await database;
    final rows =
        await db.query('diary_entries', where: 'date = ?', whereArgs: [date]);
    if (rows.isEmpty) return null;
    return DiaryEntry.fromMap(rows.first);
  }

  Future<DiaryEntry> upsertDiary(DiaryEntry entry) async {
    final db = await database;
    final existing = await getDiaryForDate(entry.date);
    if (existing == null) {
      final id = await db.insert('diary_entries', entry.toMap()..remove('id'));
      return entry.copyWith(id: id);
    }
    final updated = entry.copyWith(id: existing.id);
    await db.update(
      'diary_entries',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [existing.id],
    );
    return updated;
  }
}

/// One week of resolved timetable data, Monday first.
class WeekSchedules {
  final List<String> dates;
  final Map<String, List<Schedule>> byDate;
  final Set<String> customizedDates;

  const WeekSchedules({
    required this.dates,
    required this.byDate,
    required this.customizedDates,
  });

  List<Schedule> at(int index) => byDate[dates[index]] ?? const [];

  /// True once the date has its own copy and no longer follows the template.
  bool isCustomized(int index) => customizedDates.contains(dates[index]);
}
