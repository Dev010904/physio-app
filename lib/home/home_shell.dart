import 'package:flutter/material.dart';

import '../exercises/exercise.dart';
import '../exercises/library_screen.dart';
import '../program/program_controller.dart';
import '../settings/appearance.dart';
import 'today_screen.dart';

/// Two big tabs keep navigation obvious: today's plan and the library.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.library, required this.appearance, required this.programs});

  final ExerciseLibrary library;
  final AppearanceController appearance;
  final ProgramController programs;

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
          TodayScreen(library: widget.library, appearance: widget.appearance, programs: widget.programs),
          LibraryScreen(library: widget.library),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Today'),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Library',
          ),
        ],
      ),
    );
  }
}
