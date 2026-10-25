import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../common/ui.dart';
import '../data/local_store.dart';
import '../exercises/exercise.dart';
import '../l10n/l10n.dart';
import '../program/program_controller.dart';
import '../session/session_plan.dart';
import '../theme/app_theme.dart';
import '../tutorials/tutorial_view.dart';
import 'progress.dart';

/// The patient's progress: streak, how much of this week is done, the last
/// two weeks, what is coming up, and each exercise's history.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key, required this.library, required this.programs});

  final ExerciseLibrary library;
  final ProgramController programs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navProgress)),
      body: ListenableBuilder(
        listenable: Listenable.merge([programs, programs.logRevision]),
        builder: (context, _) => FutureBuilder<List<SessionRecord>>(
          future: programs.store.sessions(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final progress = Progress(programs.program, snapshot.data!);
            return progress.hasHistory ? _ProgressList(progress: progress, library: library, programs: programs) : const _Empty();
          },
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(color: Brand.of(context).soft, shape: BoxShape.circle),
              child: Icon(Icons.insights_rounded, size: 60, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(context.l10n.noSessionsYet, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              context.l10n.noSessionsBody,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressList extends StatelessWidget {
  const _ProgressList({required this.progress, required this.library, required this.programs});

  final Progress progress;
  final ExerciseLibrary library;
  final ProgramController programs;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l = context.l10n;
    final titles = {
      for (final e in library.inLanguage(context.lang).exercises) e.id: e,
      for (final e in programs.program.inLanguage(context.lang).exercises) e.id: e,
    };
    final history = progress.historyByExercise;
    final week = progress.adherence();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department_rounded,
                value: '${progress.streak}',
                label: l.daysInARow(progress.streak),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _WeekCard(fraction: week)),
          ],
        ),
        const SizedBox(height: 16),
        Text(l.last2Weeks, style: text.titleMedium),
        const SizedBox(height: 8),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: _DayGrid(days: progress.recentDays()))),
        const SizedBox(height: 20),
        Text(l.comingUp, style: text.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (var i = 1; i <= 7; i++)
                Builder(
                  builder: (context) {
                    final day = progress.today.add(Duration(days: i));
                    final entries = programs.program.on(day);
                    final exercises = [for (final e in entries) e.exercise];
                    return ListTile(
                      dense: true,
                      title: Text(i == 1 ? l.tomorrow : weekdayName(context, day), style: text.bodyLarge),
                      trailing: Text(
                        entries.isEmpty
                            ? l.rest
                            : '${l.exerciseCount(entries.length)} · ${aboutMinutes(l, SessionPlan.build(exercises).totalDuration)}',
                        style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(l.yourExercises, style: text.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (final (i, MapEntry(key: id, value: rows)) in history.entries.indexed) ...[
                  if (i > 0) const Divider(height: 1, indent: 88),
                  _ExerciseRow(exercise: titles[id], id: id, rows: rows),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: const Color(0xFFF26B1D)),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700)),
            Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.fraction});

  final double? fraction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = fraction;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: 32,
              child: CustomPaint(painter: _RingPainter(f ?? 0, theme.colorScheme.primary, Brand.of(context).ringTrack)),
            ),
            const SizedBox(height: 8),
            Text(f == null ? '–' : '${(f * 100).round()}%', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700)),
            Text(context.l10n.ofThisWeeksPlan, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.fraction, this.color, this.track);

  final double fraction;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(3);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = track);
    if (fraction > 0) canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * fraction, false, paint..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction || old.color != color || old.track != track;
}

class _DayGrid extends StatelessWidget {
  const _DayGrid({required this.days});

  final List<(DateTime, DayStatus)> days;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    Widget dot((DateTime, DayStatus) d) {
      final (day, status) = d;
      final (Color? fill, Color? border, IconData? icon) = switch (status) {
        DayStatus.done => (colors.primary, null, Icons.check_rounded),
        DayStatus.missed => (null, colors.error, null),
        DayStatus.due => (null, colors.primary, null),
        DayStatus.rest || DayStatus.before => (colors.surfaceContainerHighest, null, null),
      };
      return Semantics(
        label: '${dayAndMonth(context, day)}: ${status.name}',
        child: Column(
          children: [
            Text(DateFormat.EEEEE(context.lang).format(day), style: text.labelMedium?.copyWith(color: colors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: border == null ? null : Border.all(color: border, width: 2.5),
              ),
              child: icon == null ? null : Icon(icon, size: 20, color: colors.onPrimary),
            ),
            const SizedBox(height: 2),
            Text('${day.day}', style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (var row = 0; row < days.length; row += 7) ...[
          if (row > 0) const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [for (final d in days.skip(row).take(7)) dot(d)],
          ),
        ],
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise, required this.id, required this.rows});

  final Exercise? exercise;
  final String id;
  final List<ExerciseHistoryEntry> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pains = [for (final r in rows.reversed) r.record.pain].whereType<int>().toList();
    final last = rows.first.record.pain;
    final title = exercise?.title ?? capitalize(id.replaceAll('_', ' '));
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: exercise == null ? const Icon(Icons.fitness_center) : TutorialThumb(exercise: exercise!),
      title: Text(title),
      subtitle: Text('${context.l10n.timesDone(rows.length)} · ${last == null ? context.l10n.painNotRecorded : context.l10n.lastPain(last)}'),
      trailing: pains.length < 2
          ? const Icon(Icons.chevron_right)
          : SizedBox(
              width: 64,
              height: 28,
              child: CustomPaint(painter: _Sparkline(pains.take(10).toList(), theme.colorScheme.tertiary)),
            ),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => _ExerciseHistoryScreen(title: title, rows: rows))),
    );
  }
}

/// Pain over time, 0 at the bottom and 10 at the top.
class _Sparkline extends CustomPainter {
  _Sparkline(this.values, this.color);

  final List<int> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height * (1 - values[i] / 10);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_Sparkline old) => old.values != values || old.color != color;
}

class _ExerciseHistoryScreen extends StatelessWidget {
  const _ExerciseHistoryScreen({required this.title, required this.rows});

  final String title;
  final List<ExerciseHistoryEntry> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: rows.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final r = rows[i].record;
          final l = context.l10n;
          final parts = [
            l.setsOfPlanned(r.setsDone, r.setsPlanned),
            if (r.repsDone != null) l.repsCount(r.repsDone!),
            r.pain == null ? l.painNotRecorded : l.painOutOf10(r.pain!),
          ];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${weekdayName(context, rows[i].day)}, ${dayAndMonth(context, rows[i].day)}', style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(parts.join(' · '), style: theme.textTheme.bodyLarge),
                if (r.note != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(r.shareNote ? Icons.share_outlined : Icons.lock_outline, size: 18, color: muted),
                      const SizedBox(width: 6),
                      Expanded(child: Text(r.note!, style: theme.textTheme.bodyMedium)),
                    ],
                  ),
                  Text(r.shareNote ? l.sharedWithPhysio : l.privateOnPhone, style: theme.textTheme.labelSmall?.copyWith(color: muted)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
