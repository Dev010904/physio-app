import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../program/program_controller.dart';
import '../tutorials/tutorial_view.dart';
import 'exercise.dart';
import 'exercise_page.dart';

/// Every bundled exercise, grouped by body region.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key, required this.library, required this.programs});

  final ExerciseLibrary library;
  final ProgramController programs;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final byRegion = <String, List<Exercise>>{};
    for (final e in library.inLanguage(context.lang).exercises) {
      byRegion.putIfAbsent(e.bodyRegion, () => []).add(e);
    }
    final regions = byRegion.keys.toList()..sort();
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.navLibrary)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(
            l.exerciseCount(library.exercises.length),
            style: text.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          for (final region in regions) ...[
            const SizedBox(height: 20),
            Text(l.region(region), style: text.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (final (i, exercise) in byRegion[region]!.indexed) ...[
                    if (i > 0) const Divider(height: 1, indent: 88),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: TutorialThumb(exercise: exercise),
                      title: Text(exercise.title),
                      subtitle: Text(doseSummary(l, exercise.prescription)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ExercisePage(
                            exercise: exercise,
                            reviewedByPhysio: library.reviewedByPhysio,
                            programs: programs,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
