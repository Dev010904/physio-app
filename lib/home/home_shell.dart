import 'package:flutter/material.dart';

import '../exercises/exercise.dart';
import '../exercises/library_screen.dart';
import '../l10n/l10n.dart';
import '../program/program_controller.dart';
import '../progress/progress_screen.dart';
import '../reminders/reminders.dart';
import '../settings/appearance.dart';
import '../settings/language.dart';
import 'today_screen.dart';

/// Three big tabs keep navigation obvious: today's plan, progress and the library.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.library,
    required this.appearance,
    required this.programs,
    required this.reminders,
    required this.language,
  });

  final ExerciseLibrary library;
  final AppearanceController appearance;
  final ProgramController programs;
  final ReminderController reminders;
  final LanguageController language;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  // Coming back to the app is a natural moment to send logs and fetch changes.
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(onResume: widget.programs.sync);

  @override
  void initState() {
    super.initState();
    _lifecycle; // start listening
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          TodayScreen(
            library: widget.library,
            appearance: widget.appearance,
            programs: widget.programs,
            reminders: widget.reminders,
            language: widget.language,
          ),
          ProgressScreen(library: widget.library, programs: widget.programs),
          LibraryScreen(library: widget.library, programs: widget.programs),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: context.l10n.navToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights),
            label: context.l10n.navProgress,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: context.l10n.navLibrary,
          ),
        ],
      ),
    );
  }
}
