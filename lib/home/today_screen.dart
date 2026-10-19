import 'package:flutter/material.dart';

import '../branding/logo.dart';
import '../common/ui.dart';
import '../exercises/exercise.dart';
import '../exercises/exercise_page.dart';
import '../session/session_plan.dart';
import '../session/session_player_screen.dart';
import '../settings/about_screen.dart';
import '../settings/appearance.dart';

/// Home: today's program with one obvious action. Until clinicians assign
/// programs (M2) this is the bundled starter program.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, required this.library, required this.appearance});

  final ExerciseLibrary library;
  final AppearanceController appearance;

  static String _greeting(DateTime now) => now.hour < 12
      ? 'Good morning'
      : now.hour < 17
      ? 'Good afternoon'
      : 'Good evening';

  @override
  Widget build(BuildContext context) {
    final program = library.demoProgram;
    final total = SessionPlan.build(program).totalDuration;
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final muted = theme.colorScheme.onSurfaceVariant;

    void open(Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

    return Scaffold(
      appBar: AppBar(
        title: const Wordmark(size: 28),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => open(AboutScreen(appearance: appearance)),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(_greeting(DateTime.now()), style: text.bodyLarge?.copyWith(color: muted)),
          Text("Let's move", style: text.headlineMedium),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's program", style: text.bodyMedium?.copyWith(color: muted)),
                  const SizedBox(height: 2),
                  Text(library.demoProgramTitle, style: text.titleLarge),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('${program.length} exercises')),
                      Chip(label: Text(minutesLabel(total))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => open(SessionPlayerScreen(exercises: program)),
                    icon: const Icon(Icons.play_arrow_rounded, size: 28),
                    label: const Text('Start session'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Exercises', style: text.titleMedium),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                for (final (i, exercise) in program.indexed) ...[
                  if (i > 0) const Divider(height: 1, indent: 72),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: IconBadge(region: exercise.bodyRegion),
                    title: Text(exercise.title),
                    subtitle: Text(exercise.prescription.summary),
                    trailing: Text(
                      '${(SessionPlan.exerciseDuration(exercise.prescription).inSeconds / 60).ceil()} min',
                      style: text.bodyMedium?.copyWith(color: muted),
                    ),
                    onTap: () => open(ExercisePage(exercise: exercise, reviewedByPhysio: library.reviewedByPhysio)),
                  ),
                ],
              ],
            ),
          ),
          if (!library.reviewedByPhysio) ...[
            const SizedBox(height: 16),
            const DraftContentNotice(),
          ],
        ],
      ),
    );
  }
}
