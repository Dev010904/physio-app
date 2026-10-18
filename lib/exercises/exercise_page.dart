import 'package:flutter/material.dart';

import '../common/ui.dart';
import '../session/session_plan.dart';
import '../session/session_player_screen.dart';
import 'exercise.dart';

class ExercisePage extends StatelessWidget {
  const ExercisePage({super.key, required this.exercise, required this.reviewedByPhysio});

  final Exercise exercise;
  final bool reviewedByPhysio;

  @override
  Widget build(BuildContext context) {
    final rx = exercise.prescription;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(exercise.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Placeholder until filmed demonstrations exist (see spec: content risk).
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(bodyRegionIcon(exercise.bodyRegion), size: 64, color: colors.onPrimaryContainer),
                const SizedBox(height: 8),
                Text('Video coming soon', style: TextStyle(color: colors.onPrimaryContainer)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!reviewedByPhysio) const DraftContentNotice(),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(capitalize(exercise.bodyRegion))),
              for (final item in exercise.equipment) Chip(label: Text(capitalize(item))),
            ],
          ),
          const SizedBox(height: 12),
          Text(rx.summary, style: theme.textTheme.titleMedium),
          Text('${capitalize(minutesLabel(SessionPlan.exerciseDuration(rx)))} in total'),
          const SizedBox(height: 24),
          Text('How to do it', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final (i, step) in exercise.steps.indexed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(radius: 14, child: Text('${i + 1}')),
              title: Text(step),
            ),
          const SizedBox(height: 8),
          const SafetyNotice(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => SessionPlayerScreen(exercises: [exercise])),
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start exercise'),
          ),
        ),
      ),
    );
  }
}
