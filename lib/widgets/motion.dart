import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// True when the OS asks for reduced motion. Every animation in the app
/// checks this and either skips or collapses to zero duration.
bool reducedMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

Duration motionDuration(BuildContext context, int milliseconds) =>
    reducedMotion(context) ? Duration.zero : Duration(milliseconds: milliseconds);

/// Fade + slide-up entrance, delayed by [index] so siblings stagger.
Widget staggerIn(
  BuildContext context,
  Widget child,
  int index, {
  int stepMs = 70,
  double dy = 0.12,
}) {
  if (reducedMotion(context)) return child;
  return child
      .animate(delay: Duration(milliseconds: index * stepMs))
      .fadeIn(duration: 350.ms, curve: Curves.easeOut)
      .slideY(begin: dy, end: 0, duration: 450.ms, curve: Curves.easeOutBack);
}

/// Plays a quick scale pop whenever [value] changes (and [when] agrees).
class BounceOnChange<T> extends StatefulWidget {
  const BounceOnChange({
    super.key,
    required this.value,
    required this.child,
    this.when,
    this.peak = 1.15,
  });

  final T value;
  final Widget child;
  final double peak;

  /// Optional filter, e.g. `(old, now) => now > old` to pop only on growth.
  final bool Function(T oldValue, T newValue)? when;

  @override
  State<BounceOnChange<T>> createState() => _BounceOnChangeState<T>();
}

class _BounceOnChangeState<T> extends State<BounceOnChange<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: widget.peak)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(begin: widget.peak, end: 1.0)
          .chain(CurveTween(curve: Curves.elasticOut)),
      weight: 65,
    ),
  ]).animate(_controller);

  @override
  void didUpdateWidget(covariant BounceOnChange<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed = oldWidget.value != widget.value;
    final allowed = widget.when?.call(oldWidget.value, widget.value) ?? true;
    if (changed && allowed && !reducedMotion(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}
