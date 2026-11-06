import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Resolved before the first frame so the theme never flashes.
  final accent = await loadSystemAccent();
  runApp(ProviderScope(child: GymTrackerApp(accent: accent)));
}