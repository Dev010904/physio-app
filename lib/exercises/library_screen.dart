import 'package:flutter/material.dart';

import '../common/ui.dart';
import 'exercise.dart';
import 'exercise_page.dart';

/// Every bundled exercise, grouped by body region.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key, required this.library});

  final ExerciseLibrary library;

  @override
  Widget build(BuildContext context) {
    final byRegion = <String, List<Exercise>>{};
    for (final e in library.exercises) {
      byRegion.putIfAbsent(e.bodyRegion, () => []).add(e);
    }
    final regions = byRegion.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: Text('Exercise library (${library.exercises.length})')),
      body: ListView(
        children: [
          for (final region in regions) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(capitalize(region), style: Theme.of(context).textTheme.titleSmall),
            ),
            for (final exercise in byRegion[region]!)
              ListTile(
                leading: Icon(bodyRegionIcon(exercise.bodyRegion)),
                title: Text(exercise.title),
                subtitle: Text(exercise.prescription.summary),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ExercisePage(
                      exercise: exercise,
                      reviewedByPhysio: library.reviewedByPhysio,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
