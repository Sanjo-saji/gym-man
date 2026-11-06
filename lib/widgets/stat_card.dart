import 'package:flutter/material.dart';

/// Shared card: 28dp rounded, tonal surface, generous padding.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final Color? color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color ?? scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(padding: padding, child: child),
    );
  }
}
