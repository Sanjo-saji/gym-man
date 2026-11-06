import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../logic/date_utils.dart';
import '../models/body_part.dart';
import '../providers/providers.dart';
import 'body_part_chips.dart';
import 'motion.dart';

Future<void> showDaySheet(BuildContext context, DateTime date) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => DaySheet(date: date),
  );
}

/// Edits one day. Reads live state from [monthDataProvider], so changes show
/// instantly and everything saves immediately.
class DaySheet extends ConsumerWidget {
  const DaySheet({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final key = dateKey(date);

    final day = ref.watch(monthDataProvider.select((a) => a.value?[key]));
    final went = day?.went ?? false;
    final parts = day?.parts ?? const <BodyPart>{};
    final isFuture = dateOnly(date).isAfter(dateOnly(DateTime.now()));
    final notifier = ref.read(monthDataProvider.notifier);

    Future<void> guarded(Future<void> Function() action) async {
      try {
        await action();
      } catch (error, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'day sheet',
        ));
      }
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('EEEE, d MMM').format(date),
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              tileColor: scheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                'Went to gym',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              value: went,
              onChanged: isFuture
                  ? null
                  : (value) {
                      value
                          ? HapticFeedback.lightImpact()
                          : HapticFeedback.selectionClick();
                      guarded(() => notifier.toggleWent(date, value));
                    },
            ),
            if (isFuture)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 8),
                child: Text(
                  "You can't mark future days",
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            AnimatedSize(
              duration: motionDuration(context, 250),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: went
                  ? Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Body parts',
                            style: theme.textTheme.titleSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          BodyPartChips(
                            selected: parts,
                            onChanged: (next) =>
                                guarded(() => notifier.setParts(date, next)),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}
