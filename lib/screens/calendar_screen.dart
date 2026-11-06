import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../logic/date_utils.dart';
import '../models/body_part.dart';
import '../models/workout_day.dart';
import '../providers/providers.dart';
import '../widgets/day_sheet.dart';
import '../widgets/motion.dart';
import '../widgets/sparkle_burst.dart';
import '../widgets/streak_badge.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final month = ref.watch(selectedMonthProvider);
    final monthAsync = ref.watch(monthDataProvider);
    final streak = ref.watch(streakProvider);

    final days = monthAsync.value ?? const <String, WorkoutDay>{};
    final today = dateOnly(DateTime.now());
    final isCurrentMonth = month.year == today.year && month.month == today.month;
    final gone = days.values
        .where((d) =>
            d.went && d.date.year == month.year && d.date.month == month.month)
        .length;

    Widget cell(DateTime raw, {required bool isToday}) {
      final date = dateOnly(raw);
      final key = dateKey(date);
      return _DayCell(
        key: ValueKey(key),
        date: date,
        day: days[key],
        isToday: isToday,
        isFuture: date.isAfter(today),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: motionDuration(context, 250),
                      child: Align(
                        key: ValueKey(month),
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            DateFormat.yMMMM().format(month),
                            style: theme.textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: isCurrentMonth
                        ? null
                        : () => ref
                            .read(selectedMonthProvider.notifier)
                            .set(DateTime.now()),
                    icon: const Icon(Icons.today_rounded, size: 18),
                    label: const Text('Today'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Thin progress line keeps layout stable while a month loads.
            SizedBox(
              height: 4,
              child: monthAsync.isLoading
                  ? const ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      child: LinearProgressIndicator(),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(28),
              ),
              child: TableCalendar<void>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: isCurrentMonth ? today : month,
                startingDayOfWeek: StartingDayOfWeek.monday,
                headerVisible: false,
                calendarFormat: CalendarFormat.month,
                availableGestures: AvailableGestures.horizontalSwipe,
                rowHeight: 58,
                daysOfWeekHeight: 36,
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: theme.textTheme.labelMedium!.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700),
                  weekendStyle: theme.textTheme.labelMedium!.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700),
                ),
                calendarStyle: const CalendarStyle(outsideDaysVisible: false),
                onPageChanged: (focused) =>
                    ref.read(selectedMonthProvider.notifier).set(focused),
                onDaySelected: (selected, _) {
                  final date = dateOnly(selected);
                  final selectedDate = ref.read(selectedDateProvider.notifier);
                  selectedDate.set(date);
                  showDaySheet(context, date)
                      .whenComplete(() => selectedDate.set(null));
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, _) => cell(day, isToday: false),
                  todayBuilder: (context, day, _) => cell(day, isToday: true),
                  outsideBuilder: (context, day, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            monthAsync.when(
              skipLoadingOnReload: true,
              data: (_) => _SummaryRow(
                gone: gone,
                streak: streak.value?.current,
              ),
              loading: () => _SummaryRow(gone: gone, streak: streak.value?.current),
              error: (error, _) => _ErrorBanner(
                onRetry: () => ref.invalidate(monthDataProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.gone, required this.streak});

  final int gone;
  final int? streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$gone ${gone == 1 ? 'day' : 'days'} this month',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (streak != null) StreakBadge(count: streak!),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Couldn't load this month",
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// One calendar cell. Stateful so it can pop in and burst when a day flips
/// from not-gone to gone, without animating on first build or month change.
class _DayCell extends StatefulWidget {
  const _DayCell({
    super.key,
    required this.date,
    required this.day,
    required this.isToday,
    required this.isFuture,
  });

  final DateTime date;
  final WorkoutDay? day;
  final bool isToday;
  final bool isFuture;

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell>
    with SingleTickerProviderStateMixin {
  // Starts at 1.0 (finished) so cells never animate on first build.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    value: 1,
  );
  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.6, curve: Curves.elasticOut),
  );

  bool get _went => widget.day?.went ?? false;

  @override
  void didUpdateWidget(covariant _DayCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasWent = oldWidget.day?.went ?? false;
    if (!wasWent && _went && !reducedMotion(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _semanticLabel() {
    final base = DateFormat('d MMMM').format(widget.date);
    final today = widget.isToday ? ', today' : '';
    if (widget.isFuture) return '$base$today, upcoming';
    if (!_went) return '$base$today, no gym';
    final parts = (widget.day?.parts ?? const <BodyPart>{}).toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final names = parts.map((p) => p.label.toLowerCase()).toList();
    if (names.isEmpty) return '$base$today, gym day';
    final joined = names.length == 1
        ? names.first
        : '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
    return '$base$today, gym day, $joined';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final went = _went;
    final partCount = widget.day?.parts.length ?? 0;

    final textColor = went
        ? scheme.onPrimary
        : widget.isFuture
            ? scheme.onSurface.withValues(alpha: 0.38)
            : scheme.onSurface;

    final circle = Container(
      width: 46,
      height: 46,
      padding: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: went ? scheme.primary : null,
        border: widget.isToday && !went
            ? Border.all(color: scheme.primary, width: 2)
            : null,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.date.day}',
              style: textTheme.bodyLarge?.copyWith(
                color: textColor,
                fontWeight: went || widget.isToday
                    ? FontWeight.w800
                    : FontWeight.w500,
              ),
            ),
            if (went && partCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _PartDots(count: partCount, color: scheme.onPrimary),
              ),
          ],
        ),
      ),
    );

    return Semantics(
      label: _semanticLabel(),
      button: true,
      excludeSemantics: true,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            ScaleTransition(scale: _scale, child: circle),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => CustomPaint(
                    painter: SparkleBurstPainter(
                      progress: _controller.value,
                      colors: [
                        scheme.primary,
                        scheme.tertiary,
                        scheme.secondary,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Up to three tiny dots, plus a "+" when more parts were trained.
class _PartDots extends StatelessWidget {
  const _PartDots({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final shown = count > 3 ? 3 : count;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < shown; i++)
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        if (count > 3)
          Text(
            '+',
            style: TextStyle(
              fontSize: 9,
              height: 1,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
      ],
    );
  }
}
