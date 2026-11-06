import 'package:flutter/material.dart';

/// Muscle groups a workout day can include. [name] is what gets persisted.
enum BodyPart {
  chest('Chest', Icons.fitness_center),
  back('Back', Icons.accessibility_new),
  shoulders('Shoulders', Icons.sports_gymnastics),
  biceps('Biceps', Icons.sports_martial_arts),
  triceps('Triceps', Icons.sports_handball),
  forearms('Forearms', Icons.back_hand_outlined),
  abs('Abs', Icons.self_improvement),
  legs('Legs', Icons.directions_run),
  glutes('Glutes', Icons.directions_walk),
  cardio('Cardio', Icons.monitor_heart_outlined);

  const BodyPart(this.label, this.icon);

  final String label;
  final IconData icon;

  /// Returns null for unknown names so a bad row can never crash the app.
  static BodyPart? fromName(String name) {
    for (final part in values) {
      if (part.name == name) return part;
    }
    return null;
  }
}
