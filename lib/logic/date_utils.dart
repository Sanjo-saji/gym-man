// Date helpers. Every stored or compared date goes through these so that
// time-of-day and time zones can never leak into the data.

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// `2026-10-20`. Built manually so it is locale independent.
String dateKey(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

DateTime dateFromKey(String key) {
  final p = key.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

/// First day of the month containing [d].
DateTime monthOf(DateTime d) => DateTime(d.year, d.month);
