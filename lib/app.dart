import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/home_shell.dart';

/// The system accent color (Material You wallpaper color on Android 12+),
/// or null when the platform has none.
///
/// Only a plain `Color` crosses the package boundary, so this keeps working
/// even when a package still uses a different copy of Flutter's Material types
/// (the `flutter` vs `material_ui` split).
Future<Color?> loadSystemAccent() async {
  try {
    return await DynamicColorPlugin.getAccentColor();
  } catch (_) {
    return null;
  }
}

class GymTrackerApp extends StatelessWidget {
  const GymTrackerApp({super.key, this.accent});

  final Color? accent;

  static const Color _fallbackSeed = Color(0xFF00A67E);
  static const double _radius = 28;

  @override
  Widget build(BuildContext context) {
    final seed = accent ?? _fallbackSeed;
    return MaterialApp(
      title: 'Gym Man',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(ColorScheme.fromSeed(seedColor: seed)),
      darkTheme: _buildTheme(
        ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
      ),
      themeMode: ThemeMode.system,
      home: const HomeShell(),
    );
  }

  static ThemeData _buildTheme(ColorScheme scheme) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final textTheme = _withNunito(base.textTheme);
    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(_radius)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        showCheckmark: false,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Applies Nunito to every style. Built from `GoogleFonts.nunito(...)`
  /// (which returns a plain TextStyle) instead of `GoogleFonts.nunitoTextTheme`,
  /// so it does not depend on which TextTheme class google_fonts was built with.
  static TextTheme _withNunito(TextTheme t) {
    TextStyle? f(TextStyle? s) =>
        s == null ? null : GoogleFonts.nunito(textStyle: s);
    return t.copyWith(
      displayLarge: f(t.displayLarge),
      displayMedium: f(t.displayMedium),
      displaySmall: f(t.displaySmall),
      headlineLarge: f(t.headlineLarge),
      headlineMedium: f(t.headlineMedium),
      headlineSmall: f(t.headlineSmall),
      titleLarge: f(t.titleLarge),
      titleMedium: f(t.titleMedium),
      titleSmall: f(t.titleSmall),
      bodyLarge: f(t.bodyLarge),
      bodyMedium: f(t.bodyMedium),
      bodySmall: f(t.bodySmall),
      labelLarge: f(t.labelLarge),
      labelMedium: f(t.labelMedium),
      labelSmall: f(t.labelSmall),
    );
  }
}