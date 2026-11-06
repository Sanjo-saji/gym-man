import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../widgets/motion.dart';
import 'calendar_screen.dart';
import 'stats_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _index = 0;

  // Starts finished (1.0); restarted on every tab change for a fade-through.
  late final AnimationController _transition = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: 1,
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _transition, curve: Curves.easeOut);
  late final Animation<double> _scale = Tween<double>(begin: 0.96, end: 1)
      .animate(CurvedAnimation(parent: _transition, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _transition.dispose();
    super.dispose();
  }

  /// Streak depends on "today", so refresh it when the app comes back
  /// (e.g. after midnight).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(streakProvider);
    }
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    if (reducedMotion(context)) {
      _transition.value = 1;
    } else {
      _transition.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: IndexedStack(
            index: _index,
            children: [
              const CalendarScreen(),
              StatsScreen(isActive: _index == 1),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}
