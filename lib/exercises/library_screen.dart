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
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(
            '${library.exercises.length} exercises',
            style: text.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          for (final region in regions) ...[
            const SizedBox(height: 20),
            Text(capitalize(region), style: text.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (final (i, exercise) in byRegion[region]!.indexed) ...[
                    if (i > 0) const Divider(height: 1, indent: 72),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: IconBadge(region: exercise.bodyRegion),
                      title: Text(exercise.title),
                      subtitle: Text(exercise.prescription.summary),
                      trailing: const Icon(Icons.chevron_right),
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
            ),
          ],
        ],
      ),
    );
  }
}
