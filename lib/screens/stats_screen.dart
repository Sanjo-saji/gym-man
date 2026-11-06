import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../logic/date_utils.dart';
import '../models/body_part.dart';
import '../models/workout_day.dart';
import '../providers/providers.dart';
import '../widgets/motion.dart';
import '../widgets/stat_card.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key, this.isActive = true});

  /// Whether this tab is currently visible. Becoming active replays the
  /// entrance animations (the tab itself stays alive in an IndexedStack).
  final bool isActive;

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int _epoch = 0;

  @override
  void didUpdateWidget(covariant StatsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) _epoch++;
  }

  int _elapsedDays(DateTime month, DateTime today) {
    final thisMonth = DateTime(today.year, today.month);
    if (month.isAfter(thisMonth)) return 0;
    if (month == thisMonth) return today.day;
    return DateUtils.getDaysInMonth(month.year, month.month);
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedMonthProvider);
    final streak = ref.watch(streakProvider);
    final counts = ref.watch(partCountsProvider);
    final monthData = ref.watch(monthDataProvider);

    final Widget body;
    if (streak.hasError || counts.hasError) {
      body = _MessageState(
        icon: Icons.error_outline_rounded,
        title: "Couldn't load your stats",
        action: FilledButton.tonal(
          onPressed: () {
            ref.invalidate(streakProvider);
            ref.invalidate(partCountsProvider);
            ref.invalidate(monthDataProvider);
          },
          child: const Text('Try again'),
        ),
      );
    } else if (!streak.hasValue || !counts.hasValue) {
      body = const _LoadingState();
    } else {
      final stats = streak.requireValue;
      final partCounts = counts.requireValue;
      final days = monthData.value ?? const <String, WorkoutDay>{};
      final gone = days.values
          .where((d) =>
              d.went && d.date.year == month.year && d.date.month == month.month)
          .length;
      final today = dateOnly(DateTime.now());
      final elapsed = _elapsedDays(month, today);
      final isCurrent = month == DateTime(today.year, today.month);

      if (stats.best == 0 && gone == 0) {
        body = const _MessageState(
          icon: Icons.fitness_center_rounded,
          title: 'No workouts logged yet',
          subtitle: 'Tap a day on the calendar to log your first gym session.',
        );
      } else {
        final cards = <Widget>[
          _HeroStreakCard(current: stats.current),
          _BestStreakCard(best: stats.best),
          _MonthProgressCard(gone: gone, elapsed: elapsed, isCurrent: isCurrent),
          _BodyPartsCard(counts: partCounts),
        ];
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, card) in cards.indexed) ...[
              staggerIn(context, card, i + 1),
              const SizedBox(height: 16),
            ],
          ],
        );
      }
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: KeyedSubtree(
          key: ValueKey(_epoch),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MonthSelector(month: month),
              const SizedBox(height: 16),
              body,
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthSelector extends ConsumerWidget {
  const _MonthSelector({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final canGoForward = month.isBefore(DateTime(now.year, now.month));
    final notifier = ref.read(selectedMonthProvider.notifier);
    return Row(
      children: [
        IconButton.filledTonal(
          tooltip: 'Previous month',
          onPressed: () => notifier.set(DateTime(month.year, month.month - 1)),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            DateFormat.yMMMM().format(month),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Next month',
          onPressed: canGoForward
              ? () => notifier.set(DateTime(month.year, month.month + 1))
              : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _HeroStreakCard extends StatelessWidget {
  const _HeroStreakCard({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onColor = scheme.onPrimaryContainer;

    Widget flame = Icon(
      Icons.local_fire_department_rounded,
      size: 72,
      color: current > 0 ? onColor : onColor.withValues(alpha: 0.5),
    );
    if (!reducedMotion(context) && current > 0) {
      flame = flame
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1, end: 1.12, duration: 900.ms, curve: Curves.easeInOut);
    }

    return Semantics(
      label: '$current day streak',
      child: ExcludeSemantics(
        child: StatCard(
          color: scheme.primaryContainer,
          padding: const EdgeInsets.all(28),
          child: Row(
            children: [
              flame,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BounceOnChange<int>(
                      value: current,
                      when: (old, now) => now > old,
                      peak: 1.2,
                      child: _CountUp(
                        value: current,
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: onColor,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'day streak',
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: onColor, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      current == 0
                          ? 'Log a workout to start a streak'
                          : 'Keep it going!',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: onColor.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountUp extends StatelessWidget {
  const _CountUp({required this.value, this.style});

  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: motionDuration(context, 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('$v', style: style),
    );
  }
}

class _BestStreakCard extends StatelessWidget {
  const _BestStreakCard({required this.best});

  final int best;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StatCard(
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded,
              size: 36, color: theme.colorScheme.tertiary),
          const SizedBox(width: 16),
          Expanded(
            child: Text('Best streak',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          Text(
            '$best ${best == 1 ? 'day' : 'days'}',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _MonthProgressCard extends StatelessWidget {
  const _MonthProgressCard({
    required this.gone,
    required this.elapsed,
    required this.isCurrent,
  });

  final int gone;
  final int elapsed;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fraction = elapsed == 0 ? 0.0 : (gone / elapsed).clamp(0.0, 1.0);
    return StatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This month',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            '$gone / $elapsed ${isCurrent ? 'days so far' : 'days'}',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction),
            duration: motionDuration(context, 700),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 12,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyPartsCard extends StatelessWidget {
  const _BodyPartsCard({required this.counts});

  final Map<BodyPart, int> counts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.index.compareTo(b.key.index);
      });
    final maxCount = entries.isEmpty ? 1 : entries.first.value;

    return StatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Body parts',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            Text(
              'No body parts logged this month.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            )
          else
            for (final (i, e) in entries.indexed)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 14),
                child: _BarRow(
                  part: e.key,
                  count: e.value,
                  fraction: e.value / maxCount,
                  index: i,
                ),
              ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.part,
    required this.count,
    required this.fraction,
    required this.index,
  });

  final BodyPart part;
  final int count;
  final double fraction;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget bar = Container(
      height: 12,
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(100),
      ),
    );
    if (!reducedMotion(context)) {
      bar = bar.animate(delay: Duration(milliseconds: 200 + index * 90)).scaleX(
            begin: 0,
            end: 1,
            alignment: Alignment.centerLeft,
            duration: 600.ms,
            curve: Curves.easeOutCubic,
          );
    }

    return Semantics(
      label: '${part.label}, $count ${count == 1 ? 'day' : 'days'}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(part.icon, size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(part.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Text('$count',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 6),
            Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: fraction.clamp(0.04, 1.0),
                  child: bar,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: scheme.onSecondaryContainer),
          ),
          const SizedBox(height: 24),
          Text(title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ],
          if (action != null) ...[const SizedBox(height: 24), action!],
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduce = reducedMotion(context);
    return Column(
      children: [
        for (final height in const [150.0, 80.0, 120.0])
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: () {
              Widget block = Container(
                height: height,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(28),
                ),
              );
              if (!reduce) {
                block = block
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 1200.ms, color: scheme.surfaceContainerHighest);
              }
              return block;
            }(),
          ),
      ],
    );
  }
}
