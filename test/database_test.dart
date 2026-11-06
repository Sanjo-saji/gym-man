import 'package:flutter_test/flutter_test.dart';
import 'package:gym_man/db/database_helper.dart';
import 'package:gym_man/logic/date_utils.dart';
import 'package:gym_man/models/body_part.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late DatabaseHelper db;
  final day = DateTime(2026, 10, 20);
  final month = DateTime(2026, 10);

  setUp(() => db = DatabaseHelper.forTesting(inMemoryDatabasePath));
  tearDown(() => db.close());

  test('setting parts and reading the month back returns the same data', () async {
    await db.setParts(day, {BodyPart.chest, BodyPart.biceps});
    final data = await db.getMonth(month);
    final entry = data[dateKey(day)]!;
    expect(entry.went, isTrue);
    expect(entry.parts, {BodyPart.chest, BodyPart.biceps});
  });

  test('clearing all parts keeps the day marked', () async {
    await db.setParts(day, {BodyPart.chest});
    await db.setParts(day, {});
    final entry = (await db.getMonth(month))[dateKey(day)]!;
    expect(entry.went, isTrue);
    expect(entry.parts, isEmpty);
  });

  test('switching a day off removes its parts', () async {
    await db.setParts(day, {BodyPart.legs});
    await db.setWent(day, false);
    final entry = (await db.getMonth(month))[dateKey(day)]!;
    expect(entry.went, isFalse);
    expect(entry.parts, isEmpty);
  });

  test('switching a day back on does not lose existing parts', () async {
    await db.setParts(day, {BodyPart.back});
    await db.setWent(day, true);
    expect((await db.getMonth(month))[dateKey(day)]!.parts, {BodyPart.back});
  });

  test('getAllGymDates is ascending and only includes gone days', () async {
    await db.setWent(DateTime(2026, 10, 22), true);
    await db.setWent(DateTime(2026, 10, 18), true);
    await db.setWent(DateTime(2026, 10, 20), false);
    expect(await db.getAllGymDates(),
        [DateTime(2026, 10, 18), DateTime(2026, 10, 22)]);
  });

  test('getPartCounts groups by part within the month only', () async {
    await db.setParts(DateTime(2026, 10, 1), {BodyPart.chest, BodyPart.biceps});
    await db.setParts(DateTime(2026, 10, 2), {BodyPart.chest});
    await db.setParts(DateTime(2026, 11, 1), {BodyPart.chest});
    expect(await db.getPartCounts(month),
        {BodyPart.chest: 2, BodyPart.biceps: 1});
  });

  test('months do not leak into each other', () async {
    await db.setWent(DateTime(2026, 9, 30), true);
    await db.setWent(DateTime(2026, 11, 1), true);
    expect(await db.getMonth(month), isEmpty);
  });
}
