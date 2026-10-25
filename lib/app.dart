import 'package:flutter/material.dart';

import 'exercises/exercise.dart';
import 'home/home_shell.dart';
import 'onboarding/welcome.dart';
import 'program/program_controller.dart';
import 'settings/appearance.dart';
import 'theme/app_theme.dart';

/// Chosen 2026-10-19 (Play Store and .com checked; trademark search still to do).
const appName = 'PhysioSathi';

class PhysioApp extends StatelessWidget {
  PhysioApp({
    super.key,
    required this.library,
    AppearanceController? appearance,
    WelcomeController? welcome,
    ProgramController? programs,
  }) : appearance = appearance ?? AppearanceController(),
       welcome = welcome ?? WelcomeController(seen: true),
       programs = programs ?? ProgramController.starter(library);

  final ExerciseLibrary library;
  final AppearanceController appearance;

  /// Today's program: the physio's once linked, else the starter.
  final ProgramController programs;

  /// First launch shows the welcome pages before Today.
  final WelcomeController welcome;

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
        home: ValueListenableBuilder(
          valueListenable: welcome,
          builder: (context, seen, _) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: seen
                ? HomeShell(library: library, appearance: appearance, programs: programs)
                : WelcomeScreen(onDone: welcome.markSeen),
          ),
        ),
      ),
    );
  }
}
