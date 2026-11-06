import 'package:flutter_test/flutter_test.dart';
import 'package:gym_man/logic/streak_logic.dart';

DateTime d(int y, int m, int day) => DateTime(y, m, day);

void main() {
  group('currentStreak', () {
    test('empty set is 0', () {
      expect(currentStreak({}, d(2026, 10, 20)), 0);
    });

    test('only today marked is 1', () {
      expect(currentStreak({d(2026, 10, 20)}, d(2026, 10, 20)), 1);
    });

    test('today not marked but yesterday marked keeps the streak', () {
      final dates = {d(2026, 10, 19), d(2026, 10, 18), d(2026, 10, 17)};
      expect(currentStreak(dates, d(2026, 10, 20)), 3);
    });

    test('neither today nor yesterday marked is 0', () {
      expect(currentStreak({d(2026, 10, 17)}, d(2026, 10, 20)), 0);
    });

    test('a gap in the middle ends the streak', () {
      final dates = {d(2026, 10, 14), d(2026, 10, 15), d(2026, 10, 17), d(2026, 10, 18)};
      expect(currentStreak(dates, d(2026, 10, 18)), 2);
    });

    test('run crossing a month boundary', () {
      final dates = {d(2026, 1, 30), d(2026, 1, 31), d(2026, 2, 1), d(2026, 2, 2)};
      expect(currentStreak(dates, d(2026, 2, 2)), 4);
    });

    test('run crossing a year boundary', () {
      final dates = {d(2025, 12, 30), d(2025, 12, 31), d(2026, 1, 1)};
      expect(currentStreak(dates, d(2026, 1, 1)), 3);
    });

    test('times of day are ignored', () {
      final dates = {DateTime(2026, 10, 19, 23, 59), DateTime(2026, 10, 20, 0, 1)};
      expect(currentStreak(dates, DateTime(2026, 10, 20, 15, 30)), 2);
    });

    test('daylight saving changes do not break runs', () {
      // Around common DST changes (US spring/autumn, EU autumn).
      expect(
        currentStreak({d(2026, 3, 7), d(2026, 3, 8), d(2026, 3, 9)}, d(2026, 3, 9)),
        3,
      );
      expect(
        currentStreak({d(2026, 10, 31), d(2026, 11, 1), d(2026, 11, 2)}, d(2026, 11, 2)),
        3,
      );
    });
  });

  group('bestStreak', () {
    test('empty set is 0', () {
      expect(bestStreak({}), 0);
    });

    test('single day is 1', () {
      expect(bestStreak({d(2026, 10, 20)}), 1);
    });

    test('longest run wins across gaps', () {
      final dates = {
        d(2026, 10, 1), d(2026, 10, 2),
        d(2026, 10, 5), d(2026, 10, 6), d(2026, 10, 7),
        d(2026, 10, 10),
      };
      expect(bestStreak(dates), 3);
    });

    test('crosses month and year boundaries', () {
      expect(bestStreak({d(2025, 12, 31), d(2026, 1, 1), d(2026, 1, 2)}), 3);
      expect(bestStreak({d(2026, 1, 31), d(2026, 2, 1)}), 2);
    });

    test('best streak older than the current streak', () {
      final dates = {
        d(2026, 3, 1), d(2026, 3, 2), d(2026, 3, 3), d(2026, 3, 4), d(2026, 3, 5),
        d(2026, 3, 19), d(2026, 3, 20),
      };
      expect(currentStreak(dates, d(2026, 3, 20)), 2);
      expect(bestStreak(dates), 5);
    });
  });
}
