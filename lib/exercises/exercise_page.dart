import 'package:flutter/material.dart';

import '../common/ui.dart';
import '../session/session_plan.dart';
import '../session/session_player_screen.dart';
import '../theme/app_theme.dart';
import 'exercise.dart';

class ExercisePage extends StatelessWidget {
  const ExercisePage({super.key, required this.exercise, required this.reviewedByPhysio});

  final Exercise exercise;
  final bool reviewedByPhysio;

  @override
  Widget build(BuildContext context) {
    final rx = exercise.prescription;
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final colors = theme.colorScheme;
    final brand = Brand.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          // Placeholder until filmed demonstrations exist (see spec: content risk).
          Container(
            height: 190,
            decoration: BoxDecoration(color: brand.soft, borderRadius: BorderRadius.circular(brand.radius + 4)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(bodyRegionIcon(exercise.bodyRegion), size: 72, color: colors.onSurface),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('Video coming soon', style: text.bodyMedium),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(exercise.title, style: text.headlineMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(capitalize(exercise.bodyRegion))),
              for (final item in exercise.equipment) Chip(label: Text(capitalize(item))),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: Icon(Icons.timer_outlined, color: colors.primary),
              title: Text(rx.summary),
              subtitle: Text('${capitalize(minutesLabel(SessionPlan.exerciseDuration(rx)))} in total'),
            ),
          ),
          if (!reviewedByPhysio) ...[const SizedBox(height: 12), const DraftContentNotice()],
          const SizedBox(height: 24),
          Text('How to do it', style: text.titleMedium),
          const SizedBox(height: 8),
          for (final (i, step) in exercise.steps.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: brand.soft,
                    foregroundColor: colors.onSurface,
                    child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Padding(padding: const EdgeInsets.only(top: 4), child: Text(step, style: text.bodyLarge))),
                ],
              ),
            ),
          const SizedBox(height: 12),
          const SafetyNotice(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => SessionPlayerScreen(exercises: [exercise])),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 28),
            label: const Text('Start exercise'),
          ),
        ),
      ),
    );
  }
}
