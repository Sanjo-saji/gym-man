import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../logic/date_utils.dart';
import '../models/body_part.dart';
import '../models/workout_day.dart';

/// SQLite access. Dates are stored as `yyyy-MM-dd` text, which sorts and
/// range-queries correctly.
class DatabaseHelper {
  DatabaseHelper._(this._path);

  static final DatabaseHelper instance = DatabaseHelper._(null);

  /// For tests: pass `inMemoryDatabasePath` together with an ffi factory.
  factory DatabaseHelper.forTesting(String path) => DatabaseHelper._(path);

  final String? _path;
  Future<Database>? _opening;

  Future<Database> get database => _opening ??= _open();

  Future<Database> _open() async {
    final path = _path ?? p.join(await getDatabasesPath(), 'gym_tracker.db');
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE workout_days (
            date TEXT PRIMARY KEY,
            went INTEGER NOT NULL DEFAULT 0
          )''');
        await db.execute('''
          CREATE TABLE workout_parts (
            date TEXT NOT NULL,
            part TEXT NOT NULL,
            PRIMARY KEY (date, part),
            FOREIGN KEY (date) REFERENCES workout_days(date) ON DELETE CASCADE
          )''');
      },
    );
  }

  Future<void> close() async {
    final opening = _opening;
    _opening = null;
    if (opening != null) await (await opening).close();
  }

  /// `[start, end)` keys of the month containing [month].
  (String, String) _bounds(DateTime month) => (
        dateKey(DateTime(month.year, month.month, 1)),
        dateKey(DateTime(month.year, month.month + 1, 1)),
      );

  Future<Map<String, WorkoutDay>> getMonth(DateTime month) async {
    final db = await database;
    final (start, end) = _bounds(month);
    const where = 'date >= ? AND date < ?';

    final dayRows =
        await db.query('workout_days', where: where, whereArgs: [start, end]);
    final partRows =
        await db.query('workout_parts', where: where, whereArgs: [start, end]);

    final parts = <String, Set<BodyPart>>{};
    for (final row in partRows) {
      final part = BodyPart.fromName(row['part'] as String);
      if (part == null) continue;
      (parts[row['date'] as String] ??= <BodyPart>{}).add(part);
    }

    return {
      for (final row in dayRows)
        row['date'] as String: WorkoutDay(
          date: dateFromKey(row['date'] as String),
          went: (row['went'] as int) == 1,
          parts: parts[row['date'] as String] ?? const <BodyPart>{},
        ),
    };
  }

  /// Upsert. Turning a day off also removes its body parts.
  Future<void> setWent(DateTime date, bool went) async {
    final db = await database;
    final key = dateKey(date);
    final value = went ? 1 : 0;
    await db.transaction((txn) async {
      // Insert-ignore then update: unlike REPLACE this never deletes the row,
      // so existing parts are not cascaded away when switching a day on.
      await txn.insert('workout_days', {'date': key, 'went': value},
          conflictAlgorithm: ConflictAlgorithm.ignore);
      await txn.update('workout_days', {'went': value},
          where: 'date = ?', whereArgs: [key]);
      if (!went) {
        await txn.delete('workout_parts', where: 'date = ?', whereArgs: [key]);
      }
    });
  }

  /// Marks the day as gone and replaces its parts, atomically.
  Future<void> setParts(DateTime date, Set<BodyPart> parts) async {
    final db = await database;
    final key = dateKey(date);
    await db.transaction((txn) async {
      await txn.insert('workout_days', {'date': key, 'went': 1},
          conflictAlgorithm: ConflictAlgorithm.ignore);
      await txn.update('workout_days', {'went': 1},
          where: 'date = ?', whereArgs: [key]);
      await txn.delete('workout_parts', where: 'date = ?', whereArgs: [key]);
      final batch = txn.batch();
      for (final part in parts) {
        batch.insert('workout_parts', {'date': key, 'part': part.name});
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<DateTime>> getAllGymDates() async {
    final db = await database;
    final rows = await db.query('workout_days',
        columns: ['date'], where: 'went = 1', orderBy: 'date ASC');
    return [for (final r in rows) dateFromKey(r['date'] as String)];
  }

  Future<Map<BodyPart, int>> getPartCounts(DateTime month) async {
    final db = await database;
    final (start, end) = _bounds(month);
    final rows = await db.rawQuery('''
      SELECT p.part AS part, COUNT(*) AS count
      FROM workout_parts p
      JOIN workout_days d ON d.date = p.date
      WHERE d.went = 1 AND p.date >= ? AND p.date < ?
      GROUP BY p.part''', [start, end]);

    final result = <BodyPart, int>{};
    for (final row in rows) {
      final part = BodyPart.fromName(row['part'] as String);
      if (part != null) result[part] = row['count'] as int;
    }
    return result;
  }
}
