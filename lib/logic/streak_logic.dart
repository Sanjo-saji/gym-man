import 'date_utils.dart';

DateTime _previousDay(DateTime d) => DateTime(d.year, d.month, d.day - 1);

DateTime _nextDay(DateTime d) => DateTime(d.year, d.month, d.day + 1);

/// Current streak ending today, or yesterday if today is not marked yet
/// (today only breaks the streak once the day is over).
///
/// Uses calendar arithmetic via the `DateTime(y, m, d)` constructor, never
/// hour-based durations, so daylight saving changes cannot skew the result.
int currentStreak(Set<DateTime> gymDates, DateTime today) {
  final days = gymDates.map(dateOnly).toSet();
  var cursor = dateOnly(today);
  if (!days.contains(cursor)) cursor = _previousDay(cursor);

  var streak = 0;
  while (days.contains(cursor)) {
    streak++;
    cursor = _previousDay(cursor);
  }
  return streak;
}

/// Longest run of consecutive calendar days in [gymDates].
int bestStreak(Set<DateTime> gymDates) {
  if (gymDates.isEmpty) return 0;
  final sorted = gymDates.map(dateOnly).toSet().toList()..sort();

  var best = 1;
  var run = 1;
  for (var i = 1; i < sorted.length; i++) {
    run = sorted[i] == _nextDay(sorted[i - 1]) ? run + 1 : 1;
    if (run > best) best = run;
  }
  return best;
}
