import 'package:flutter/foundation.dart';

import 'body_part.dart';

@immutable
class WorkoutDay {
  const WorkoutDay({
    required this.date,
    required this.went,
    this.parts = const <BodyPart>{},
  });

  /// Date-only (local midnight).
  final DateTime date;
  final bool went;
  final Set<BodyPart> parts;

  WorkoutDay copyWith({bool? went, Set<BodyPart>? parts}) => WorkoutDay(
        date: date,
        went: went ?? this.went,
        parts: parts ?? this.parts,
      );

  @override
  bool operator ==(Object other) =>
      other is WorkoutDay &&
      other.date == date &&
      other.went == went &&
      setEquals(other.parts, parts);

  @override
  int get hashCode => Object.hash(date, went, Object.hashAllUnordered(parts));
}
