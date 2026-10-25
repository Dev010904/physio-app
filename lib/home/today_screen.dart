import 'package:flutter/material.dart';

import '../branding/logo.dart';
import '../common/ui.dart';
import '../exercises/exercise.dart';
import '../exercises/exercise_page.dart';
import '../l10n/l10n.dart';
import '../link/link_screen.dart';
import '../program/program_controller.dart';
import '../reminders/reminders.dart';
import '../session/session_plan.dart';
import '../session/session_player_screen.dart';
import '../settings/about_screen.dart';
import '../settings/appearance.dart';
import '../settings/language.dart';
import '../theme/app_theme.dart';
import '../tutorials/tutorial_view.dart';

/// Home: today's exercises with one obvious action. Once the app is linked
/// they come from the physio's program; until then from the starter program.
class TodayScreen extends StatelessWidget {
  const TodayScreen({
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

  static String _greeting(AppLocalizations l, DateTime now) => now.hour < 12
      ? l.greetingMorning
      : now.hour < 17
      ? l.greetingAfternoon
      : l.greetingEvening;

  Future<void> _openLink(BuildContext context) async {
    final l = context.l10n;
    final linked = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => LinkScreen(programs: programs)));
    if (linked != true || !context.mounted) return;
    // A Hindi patient gets Hindi, unless they already chose a language.
    final patientLanguage = programs.link?.language;
    if (language.value == null && patientLanguage != null && patientLanguage != context.lang) {
      await language.set(patientLanguage);
    }
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.linkedSnack)));
  }

  @override
  Widget build(BuildContext context) {
    void open(Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

    return Scaffold(
      appBar: AppBar(
        title: const Wordmark(size: 28),
        actions: [
          IconButton(
            tooltip: context.l10n.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => open(
              AboutScreen(appearance: appearance, programs: programs, reminders: reminders, language: language),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListenableBuilder(
        listenable: programs,
        builder: (context, _) {
          final l = context.l10n;
          final theme = Theme.of(context);
          final text = theme.textTheme;
          final muted = theme.colorScheme.onSurfaceVariant;
          final program = programs.program.inLanguage(context.lang);
          final link = programs.link;
          final now = DateTime.now();
          final today = program.on(now);
          final exercises = [for (final e in today) e.exercise];
          final next = today.isEmpty ? program.nextSessionAfter(now) : null;
          final title = program.fromClinic ? l.yourProgram : library.inLanguage(context.lang).starterTitle;

          final list = ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(_greeting(l, now), style: text.bodyLarge?.copyWith(color: muted)),
              Text(today.isEmpty ? l.restDay : l.letsMove, style: text.headlineMedium),
              const SizedBox(height: 16),
              if (programs.programUpdated) ...[
                _UpdatedBanner(onDismiss: programs.dismissUpdate),
                const SizedBox(height: 12),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link == null
                            ? l.todaysProgram
                            : l.fromPhysio(link.clinicianName ?? link.clinicName ?? l.yourPhysio),
                        style: text.bodyMedium?.copyWith(color: muted),
                      ),
                      const SizedBox(height: 2),
                      Text(title, style: text.titleLarge),
                      const SizedBox(height: 10),
                      if (today.isEmpty)
                        Text(
                          next == null ? l.nothingScheduled : l.nothingTodayNext(weekdayName(context, next)),
                          style: text.bodyLarge,
                        )
                      else ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(label: Text(l.exerciseCount(exercises.length))),
                            Chip(label: Text(aboutMinutes(l, SessionPlan.build(exercises).totalDuration))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () =>
                              open(SessionPlayerScreen(entries: today, programs: programs, programId: program.id)),
                          icon: const Icon(Icons.play_arrow_rounded, size: 28),
                          label: Text(l.startSession),
                        ),
                      ],
                      if (programs.state == SyncState.offline) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.cloud_off_outlined, size: 18, color: muted),
                            const SizedBox(width: 8),
                            Expanded(child: Text(l.offlineSaved, style: text.bodyMedium?.copyWith(color: muted))),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (program.notes != null) ...[
                const SizedBox(height: 16),
                _PhysioNote(text: program.notes!),
              ],
              if (today.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(l.exercisesHeading, style: text.titleMedium),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: [
                      for (final (i, entry) in today.indexed) ...[
                        if (i > 0) const Divider(height: 1, indent: 88),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: TutorialThumb(exercise: entry.exercise),
                          title: Text(entry.exercise.title),
                          subtitle: Text(doseSummary(l, entry.exercise.prescription)),
                          trailing: Text(
                            l.minutesShort(
                              (SessionPlan.exerciseDuration(entry.exercise.prescription).inSeconds / 60).ceil(),
                            ),
                            style: text.bodyMedium?.copyWith(color: muted),
                          ),
                          onTap: () => open(
                            ExercisePage(
                              exercise: entry.exercise,
                              reviewedByPhysio: library.reviewedByPhysio,
                              programs: programs,
                              entry: entry,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (link == null && programs.canLink) ...[
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Icon(Icons.link_rounded, color: theme.colorScheme.primary, size: 32),
                    title: Text(l.haveCode),
                    subtitle: Text(l.haveCodeBody),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openLink(context),
                  ),
                ),
              ],
              if (!library.reviewedByPhysio) ...[const SizedBox(height: 16), const DraftContentNotice()],
            ],
          );

          return programs.isLinked ? RefreshIndicator(onRefresh: programs.sync, child: list) : list;
        },
      ),
    );
  }
}

class _UpdatedBanner extends StatelessWidget {
  const _UpdatedBanner({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.primaryContainer,
      borderRadius: BorderRadius.circular(Brand.of(context).radius),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
        leading: Icon(Icons.auto_awesome_outlined, color: colors.onPrimaryContainer),
        title: Text(context.l10n.programUpdated, style: TextStyle(color: colors.onPrimaryContainer)),
        trailing: IconButton(
          tooltip: context.l10n.dismiss,
          icon: Icon(Icons.close, color: colors.onPrimaryContainer),
          onPressed: onDismiss,
        ),
      ),
    );
  }
}

class _PhysioNote extends StatelessWidget {
  const _PhysioNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Brand.of(context).soft,
        borderRadius: BorderRadius.circular(Brand.of(context).radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.noteFromPhysio, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(text, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
