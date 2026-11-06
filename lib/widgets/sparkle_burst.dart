import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One-shot confetti/sparkle burst drawn from simple shapes.
/// [progress] runs from 0 to 1; nothing is drawn at 0 or past 1.
class SparkleBurstPainter extends CustomPainter {
  const SparkleBurstPainter({required this.progress, required this.colors});

  final double progress;
  final List<Color> colors;

  static const int _count = 10;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final center = size.center(Offset.zero);
    final base = size.shortestSide * 0.4;
    final t = Curves.easeOutCubic.transform(progress);
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < _count; i++) {
      final angle = (2 * math.pi / _count) * i + 0.3;
      final distance = base + size.shortestSide * 0.35 * t;
      final position = center + Offset(math.cos(angle), math.sin(angle)) * distance;
      paint.color =
          colors[i % colors.length].withValues(alpha: (1 - progress).clamp(0, 1));
      final radius = (i.isEven ? 3.4 : 2.2) * (1 - 0.6 * t);
      canvas.drawCircle(position, radius, paint);
    }
  }

  @override
  bool shouldRepaint(SparkleBurstPainter old) => old.progress != progress;
}
