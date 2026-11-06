import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database_helper.dart';
import '../logic/date_utils.dart';
import '../logic/streak_logic.dart';
import '../models/body_part.dart';
import '../models/workout_day.dart';

final databaseProvider =
    Provider<DatabaseHelper>((ref) => DatabaseHelper.instance);

/// The month currently shown (day is always 1).
class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => monthOf(DateTime.now());

  void set(DateTime month) => state = monthOf(month);
}

final selectedMonthProvider =
    NotifierProvider<SelectedMonthNotifier, DateTime>(SelectedMonthNotifier.new);

/// The date last tapped on the calendar (null when no sheet is open).
class SelectedDateNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void set(DateTime? date) => state = date == null ? null : dateOnly(date);
}

final selectedDateProvider =
    NotifierProvider<SelectedDateNotifier, DateTime?>(SelectedDateNotifier.new);

/// Workout days of the visible month keyed by `yyyy-MM-dd`.
///
/// Writes update the state optimistically (so the UI reacts instantly and rapid
/// taps compose correctly), persist, and roll back by reloading on failure.
class MonthDataNotifier extends AsyncNotifier<Map<String, WorkoutDay>> {
  DatabaseHelper get _db => ref.read(databaseProvider);

  @override
  Future<Map<String, WorkoutDay>> build() {
    final month = ref.watch(selectedMonthProvider);
    return _db.getMonth(month);
  }

  Future<void> toggleWent(DateTime date, bool went) {
    final d = dateOnly(date);
    final existing = state.value?[dateKey(d)];
    _applyLocal(WorkoutDay(
      date: d,
      went: went,
      parts: went ? (existing?.parts ?? const <BodyPart>{}) : const <BodyPart>{},
    ));
    return _persist(() => _db.setWent(d, went));
  }

  Future<void> setParts(DateTime date, Set<BodyPart> parts) {
    final d = dateOnly(date);
    _applyLocal(WorkoutDay(
      date: d,
      went: true,
      parts: Set<BodyPart>.unmodifiable(parts),
    ));
    return _persist(() => _db.setParts(d, parts));
  }

  void _applyLocal(WorkoutDay day) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData({...current, dateKey(day.date): day});
  }

  Future<void> _persist(Future<void> Function() write) async {
    final month = ref.read(selectedMonthProvider);
    try {
      await write();
    } catch (_) {
      // Roll the optimistic change back to what is really stored.
      final stored = await _db.getMonth(month);
      if (ref.read(selectedMonthProvider) == month) {
        state = AsyncData(stored);
      }
      rethrow;
    }
    ref.invalidate(streakProvider);
    ref.invalidate(partCountsProvider);
  }
}

final monthDataProvider =
    AsyncNotifierProvider<MonthDataNotifier, Map<String, WorkoutDay>>(
        MonthDataNotifier.new);

typedef StreakStats = ({int current, int best});

final streakProvider = FutureProvider<StreakStats>((ref) async {
  final dates = (await ref.watch(databaseProvider).getAllGymDates()).toSet();
  return (current: currentStreak(dates, DateTime.now()), best: bestStreak(dates));
});

final partCountsProvider = FutureProvider<Map<BodyPart, int>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(databaseProvider).getPartCounts(month);
});
