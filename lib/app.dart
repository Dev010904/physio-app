import 'package:flutter/material.dart';

import 'exercises/exercise.dart';
import 'home/home_shell.dart';
import 'settings/appearance.dart';
import 'theme/app_theme.dart';

/// Chosen 2026-10-19 (Play Store and .com checked; trademark search still to do).
const appName = 'PhysioSathi';

class PhysioApp extends StatelessWidget {
  PhysioApp({super.key, required this.library, AppearanceController? appearance})
    : appearance = appearance ?? AppearanceController();

  final ExerciseLibrary library;
  final AppearanceController appearance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appearance,
      builder: (context, mode, _) => MaterialApp(
        title: appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode,
        home: HomeShell(library: library, appearance: appearance),
      ),
    );
  }
}
