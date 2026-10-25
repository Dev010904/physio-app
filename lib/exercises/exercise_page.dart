import 'package:flutter/material.dart';

import '../common/ui.dart';
import '../l10n/l10n.dart';
import '../program/program.dart';
import '../program/program_controller.dart';
import '../session/session_plan.dart';
import '../session/session_player_screen.dart';
import '../theme/app_theme.dart';
import '../tutorials/tutorial.dart';
import '../tutorials/tutorial_view.dart';
import 'exercise.dart';

class ExercisePage extends StatelessWidget {
  const ExercisePage({
    super.key,
    required this.exercise,
    required this.reviewedByPhysio,
    required this.programs,
    this.entry,
  });

  final Exercise exercise;
  final bool reviewedByPhysio;
  final ProgramController programs;

  /// Set when opened from the patient's program, so its log reaches the physio.
  final ProgramEntry? entry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final rx = exercise.prescription;
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final colors = theme.colorScheme;
    final brand = Brand.of(context);
    final tutorial = tutorials[exercise.id];

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          // Realistic footage of one rep, looping at the exercise's own tempo.
          if (tutorial != null) ...[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(brand.radius + 4),
                  child: ColoredBox(
                    color: brand.soft,
                    child: AspectRatio(aspectRatio: 1, child: TutorialLoop.forExercise(tutorial, exercise)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text(exercise.title, style: text.headlineMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(l.region(exercise.bodyRegion))),
              for (final item in exercise.equipment) Chip(label: Text(l.equipment(item))),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: Icon(Icons.timer_outlined, color: colors.primary),
              title: Text(doseSummary(l, rx)),
              subtitle: Text(l.aboutMinutesInTotal((SessionPlan.exerciseDuration(rx).inSeconds / 60).ceil())),
            ),
          ),
          const SizedBox(height: 24),
          Text(l.whatItDoes, style: text.titleMedium),
          const SizedBox(height: 4),
          MuscleLegend(exercise: exercise),
          if (!reviewedByPhysio) ...[const SizedBox(height: 12), const DraftContentNotice()],
          const SizedBox(height: 24),
          Text(l.howToDoIt, style: text.titleMedium),
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
              MaterialPageRoute<void>(
                builder: (_) => SessionPlayerScreen(
                  entries: [entry ?? ProgramEntry(exercise: exercise)],
                  programs: programs,
                  programId: entry?.itemId != null ? programs.program.id : null,
                ),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 28),
            label: Text(l.startExercise),
          ),
        ),
      ),
    );
  }
}
