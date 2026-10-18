import 'package:flutter/material.dart';

import '../app.dart';
import '../common/ui.dart';
import '../exercises/exercise.dart';
import '../exercises/exercise_page.dart';
import '../exercises/library_screen.dart';
import '../session/session_plan.dart';
import '../session/session_player_screen.dart';

/// Home: today's program. Until clinicians assign programs (M2) this is the
/// bundled starter program.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, required this.library});

  final ExerciseLibrary library;

  @override
  Widget build(BuildContext context) {
    final program = library.demoProgram;
    final total = SessionPlan.build(program).totalDuration;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            tooltip: 'Exercise library',
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => LibraryScreen(library: library)),
            ),
          ),
          IconButton(
            tooltip: 'About this build',
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const StatusScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(library.demoProgramTitle, style: text.titleLarge),
          const SizedBox(height: 4),
          Text('${program.length} exercises · ${minutesLabel(total)}', style: text.bodyMedium),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => SessionPlayerScreen(exercises: program)),
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start session'),
          ),
          const SizedBox(height: 16),
          for (final exercise in program)
            Card(
              child: ListTile(
                leading: Icon(bodyRegionIcon(exercise.bodyRegion)),
                title: Text(exercise.title),
                subtitle: Text(exercise.prescription.summary),
                trailing: Text(
                  '${(SessionPlan.exerciseDuration(exercise.prescription).inSeconds / 60).ceil()} min',
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ExercisePage(
                      exercise: exercise,
                      reviewedByPhysio: library.reviewedByPhysio,
                    ),
                  ),
                ),
              ),
            ),
          if (!library.reviewedByPhysio) ...[
            const SizedBox(height: 8),
            const DraftContentNotice(),
          ],
        ],
      ),
    );
  }
}
