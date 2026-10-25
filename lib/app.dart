import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

import 'exercises/exercise.dart';
import 'home/home_shell.dart';
import 'onboarding/welcome.dart';
import 'program/program_controller.dart';
import 'reminders/reminders.dart';
import 'settings/appearance.dart';
import 'settings/language.dart';
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
    ReminderController? reminders,
    LanguageController? language,
  }) : appearance = appearance ?? AppearanceController(),
       language = language ?? LanguageController(),
       welcome = welcome ?? WelcomeController(seen: true),
       programs = programs ?? ProgramController.starter(library),
       reminders = reminders ?? ReminderController(NoReminderScheduler());

  final ExerciseLibrary library;
  final AppearanceController appearance;

  /// Today's program: the physio's once linked, else the starter.
  final ProgramController programs;
  final ReminderController reminders;

  /// English, Hindi, or the phone's language.
  final LanguageController language;

  /// First launch shows the welcome pages before Today.
  final WelcomeController welcome;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([appearance, language]),
      builder: (context, _) => MaterialApp(
        title: appName,
        debugShowCheckedModeBanner: false,
        locale: language.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: appearance.value,
        home: ValueListenableBuilder(
          valueListenable: welcome,
          builder: (context, seen, _) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: seen
                ? HomeShell(library: library, appearance: appearance, programs: programs, reminders: reminders, language: language)
                : WelcomeScreen(onDone: welcome.markSeen),
          ),
        ),
      ),
    );
  }
}
