import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/body_part.dart';
import 'motion.dart';

/// Multi-select chips for every [BodyPart]. Stateless: the caller owns the
/// selection and receives the new set on every tap.
class BodyPartChips extends StatelessWidget {
  const BodyPartChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<BodyPart> selected;
  final ValueChanged<Set<BodyPart>> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (index, part) in BodyPart.values.indexed)
          staggerIn(
            context,
            BounceOnChange<bool>(
              value: selected.contains(part),
              child: FilterChip(
                avatar: Icon(
                  part.icon,
                  size: 18,
                  color: selected.contains(part)
                      ? scheme.onSecondaryContainer
                      : scheme.onSurfaceVariant,
                ),
                label: Text(part.label),
                selected: selected.contains(part),
                selectedColor: scheme.secondaryContainer,
                onSelected: (isSelected) {
                  HapticFeedback.selectionClick();
                  final next = {...selected};
                  isSelected ? next.add(part) : next.remove(part);
                  onChanged(next);
                },
              ),
            ),
            index,
            stepMs: 35,
            dy: 0.3,
          ),
      ],
    );
  }
}
