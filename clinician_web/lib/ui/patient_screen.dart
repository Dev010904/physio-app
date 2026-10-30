import 'package:flutter/material.dart';
import 'package:physio_app/theme/app_theme.dart';

import '../data/errors.dart';
import '../data/models.dart';
import '../logic/adherence.dart';
import '../logic/dose.dart';
import '../logic/text.dart';
import 'code_reveal.dart';
import 'pain_chart.dart';
import 'program_builder_screen.dart';
import 'scope.dart';
import 'shell.dart';
import 'widgets.dart';

/// One patient: how they are doing, what needs attention, and their program.
class PatientScreen extends StatelessWidget {
  const PatientScreen({super.key, required this.patientId, required this.name});

  final String patientId;

  /// Shown while the page loads.
  final String name;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      body: Loader<PatientDetail>(
        load: () => scope.api.patientDetail(patientId),
        refreshOn: scope.changes,
        loadingLabel: 'Loading $name…',
        builder: (context, detail, reload) => _PatientBody(detail: detail),
      ),
    );
  }
}

class _PatientBody extends StatefulWidget {
  const _PatientBody({required this.detail});

  final PatientDetail detail;

  @override
  State<_PatientBody> createState() => _PatientBodyState();
}

class _PatientBodyState extends State<_PatientBody> {
  bool _resetting = false;

  PatientDetail get d => widget.detail;

  Future<void> _resetCode() async {
    final scope = AppScope.of(context);
    final p = d.patient;
    final ok = await confirm(
      context,
      title: 'Make a new code for ${p.displayName}?',
      body: Text(
        p.linked
            ? 'Use this when the patient has a new phone. The phone linked now stops getting program updates until the new code is entered on a phone.'
            : 'Any earlier code stops working. The new code works for 30 days.',
      ),
      yes: 'Make new code',
      danger: p.linked,
    );
    if (!ok || !mounted) return;
    setState(() => _resetting = true);
    try {
      final code = await scope.api.resetCode(p.id);
      if (!mounted) return;
      await showCodeDialog(context, name: p.displayName, code: code);
      scope.changes.bump();
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  void _editProgram() =>
      Navigator.of(context).push(pageRoute(ProgramBuilderScreen(patientId: d.patient.id, patientName: d.patient.displayName), 'builder'));

  @override
  Widget build(BuildContext context) {
    final p = d.patient;
    final a = d.adherence;
    final now = DateTime.now();
    final String status;
    if (p.linked) {
      status = p.linkedAt == null ? 'Phone linked' : 'Phone linked since ${relativeDay(p.linkedAt!, now)}';
    } else if (p.codeExpiresAt != null && p.codeExpiresAt!.isAfter(now)) {
      status = 'Not linked yet · code works until ${relativeDay(p.codeExpiresAt!, now)}';
    } else {
      status = 'Not linked · the code has expired, make a new one';
    }
    final run = a.currentMissedRun;
    return PageBody(
      children: [
        PageHeader(
          title: p.displayName,
          leading: InitialsAvatar(initials(p.displayName), size: 52),
          subtitle: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Pill(p.languageLabel, icon: Icons.translate),
              Pill(status, icon: p.linked ? Icons.phone_android : Icons.link_off, tone: p.linked ? Tone.good : Tone.neutral),
            ],
          ),
          actions: [
            FilledButton.icon(
              style: compactButton,
              onPressed: _editProgram,
              icon: Icon(d.current == null ? Icons.playlist_add : Icons.edit_note),
              label: Text(d.current == null ? 'Build program' : 'Edit program'),
            ),
            OutlinedButton.icon(
              style: compactOutlined,
              onPressed: _resetting ? null : _resetCode,
              icon: _resetting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.key_outlined),
              label: const Text('Reset code'),
            ),
          ],
        ),
        if (a.showMissedWarning) ...[
          Notice(
            icon: Icons.event_busy,
            tone: Tone.warn,
            text:
                'Missed ${run.length} scheduled days in a row (${dayLabel(run.last)} to ${dayLabel(run.first)}). '
                'A quick call may help ${p.displayName} get back on track.',
          ),
          const SizedBox(height: 20),
        ],
        if (!p.linked && d.sessions.isEmpty) ...[
          const Notice(
            icon: Icons.phone_android,
            text: 'Waiting for the patient to enter their code in the PhysioSathi app. Progress appears here after their first session.',
          ),
          const SizedBox(height: 20),
        ],
        TwoColumns(
          left: [
            _AdherencePanel(adherence: a),
            _PainPanel(detail: d),
            _SessionsPanel(sessions: d.sessions),
          ],
          right: [
            _FlagsPanel(detail: d),
            _ProgramPanel(program: d.current, onEdit: _editProgram),
            _HistoryPanel(programs: d.programs),
          ],
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ adherence

class _AdherencePanel extends StatelessWidget {
  const _AdherencePanel({required this.adherence});

  final Adherence adherence;

  @override
  Widget build(BuildContext context) {
    final started = adherence.start != null;
    return Panel(
      title: 'Adherence',
      icon: Icons.insights,
      trailing: Tooltip(
        message: 'Scheduled days with a session. Today counts once it is done; rest days are not counted.',
        child: Icon(Icons.help_outline, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _Stat(label: 'Last 7 days', counts: adherence.countsFor(7), started: started)),
              const SizedBox(width: 14),
              Expanded(child: _Stat(label: 'Last 28 days', counts: adherence.countsFor(28), started: started)),
            ],
          ),
          const SizedBox(height: 20),
          _DayStrip(days: adherence.recentDays(28)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.counts, required this.started});

  final String label;
  final ({int done, int scheduled}) counts;
  final bool started;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final rate = counts.scheduled == 0 ? null : counts.done / counts.scheduled;
    final color = rate == null
        ? c.onSurfaceVariant
        : rate >= 0.8
        ? c.primary
        : rate >= 0.5
        ? toneColors(context, Tone.warn).fg
        : c.error;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.surfaceContainerHigh, borderRadius: BorderRadius.circular(Brand.of(context).radius - 4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(
            rate == null ? '–' : '${(rate * 100).round()}%',
            style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(value: rate ?? 0, minHeight: 8, color: color, backgroundColor: Brand.of(context).ringTrack),
          ),
          const SizedBox(height: 8),
          Text(
            !started
                ? 'Starts when the phone is linked'
                : rate == null
                ? 'Nothing scheduled yet'
                : '${counts.done} of ${counts.scheduled} scheduled days',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.days});

  final List<(DateTime, DayStatus)> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    BoxDecoration look(DayStatus s) => switch (s) {
      DayStatus.done => BoxDecoration(color: c.primary, shape: BoxShape.circle),
      DayStatus.missed => BoxDecoration(color: c.errorContainer, shape: BoxShape.circle, border: Border.all(color: c.error, width: 2)),
      DayStatus.due => BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.primary, width: 2)),
      DayStatus.rest => BoxDecoration(color: c.surfaceContainerHigh, shape: BoxShape.circle, border: Border.all(color: c.outlineVariant)),
      DayStatus.outside => BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.outlineVariant.withValues(alpha: 0.5))),
    };
    String word(DayStatus s) => switch (s) {
      DayStatus.done => 'done',
      DayStatus.missed => 'missed',
      DayStatus.due => 'due today',
      DayStatus.rest => 'rest day',
      DayStatus.outside => 'not started',
    };
    Widget legend(DayStatus s, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 14, decoration: look(s)),
        const SizedBox(width: 6),
        Text(text, style: theme.textTheme.bodyMedium),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final (day, status) in days)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Tooltip(
                    message: '${dayLabel(day)}: ${word(status)}',
                    child: AspectRatio(aspectRatio: 1, child: Container(decoration: look(status))),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(dayLabel(days.first.$1), style: theme.textTheme.bodySmall?.copyWith(color: c.onSurfaceVariant)),
            const Spacer(),
            Text('Today', style: theme.textTheme.bodySmall?.copyWith(color: c.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            legend(DayStatus.done, 'Done'),
            legend(DayStatus.missed, 'Missed'),
            legend(DayStatus.rest, 'Rest day'),
            if (days.any((d) => d.$2 == DayStatus.due)) legend(DayStatus.due, 'Due today'),
          ],
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ pain

class _PainPanel extends StatelessWidget {
  const _PainPanel({required this.detail});

  final PatientDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = detail.adherence.today;
    final from = DateTime(today.year, today.month, today.day - 27);
    final trends = [
      for (final t in detail.painTrends)
        (title: t.title, points: [for (final p in t.points) if (!p.day.isBefore(from)) p]),
    ].where((t) => t.points.isNotEmpty).toList();
    return Panel(
      title: 'Pain, last 4 weeks',
      icon: Icons.show_chart,
      child: trends.isEmpty
          ? const EmptyState(
              icon: Icons.show_chart,
              title: 'No pain scores yet',
              message: 'After each exercise the patient rates pain from 0 to 10. The scores appear here.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < trends.length; i++) ...[
                  if (i > 0) const Divider(height: 32),
                  Row(
                    children: [
                      Expanded(child: Text(trends[i].title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600))),
                      _PainPill(pain: trends[i].points.last.pain, prefix: 'Latest'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  PainChart(points: trends[i].points, from: from, to: today),
                ],
              ],
            ),
    );
  }
}

class _PainPill extends StatelessWidget {
  const _PainPill({required this.pain, this.prefix = 'Pain'});

  final int pain;
  final String prefix;

  @override
  Widget build(BuildContext context) => Pill(
    '$prefix $pain/10',
    icon: Icons.healing_outlined,
    tone: pain >= PainChart.highPain
        ? Tone.bad
        : pain >= 4
        ? Tone.warn
        : Tone.good,
  );
}

// ------------------------------------------------------------------ sessions

class _SessionsPanel extends StatefulWidget {
  const _SessionsPanel({required this.sessions});

  final List<SessionEntry> sessions;

  @override
  State<_SessionsPanel> createState() => _SessionsPanelState();
}

class _SessionsPanelState extends State<_SessionsPanel> {
  static const _first = 8;
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final sessions = widget.sessions;
    final shown = _all ? sessions : sessions.take(_first).toList();
    return Panel(
      title: 'Recent sessions',
      icon: Icons.history,
      trailing: sessions.isEmpty ? null : Text('${sessions.length} logged', style: Theme.of(context).textTheme.bodyMedium),
      child: sessions.isEmpty
          ? const EmptyState(icon: Icons.history, title: 'No sessions yet', message: 'Sessions appear here once the phone syncs them.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final s in shown) _SessionTile(session: s),
                if (sessions.length > _first)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _all = !_all),
                      icon: Icon(_all ? Icons.expand_less : Icons.expand_more),
                      label: Text(_all ? 'Show fewer' : 'Show all ${sessions.length}'),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final SessionEntry session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final f = session.feedback;
    final pain = session.maxPain;
    final feedbackPill = f?.level == null
        ? null
        : Pill(
            'Felt ${f!.level!.label.toLowerCase()}',
            icon: switch (f.level!) {
              FeedbackLevel.easy => Icons.sentiment_very_satisfied_outlined,
              FeedbackLevel.ok => Icons.sentiment_neutral_outlined,
              FeedbackLevel.hard => Icons.sentiment_dissatisfied_outlined,
            },
            tone: switch (f.level!) {
              FeedbackLevel.easy => Tone.good,
              FeedbackLevel.ok => Tone.info,
              FeedbackLevel.hard => Tone.warn,
            },
          );
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: 4, bottom: 12),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text('${dayLabel(session.performedOn)} · ${relativeDay(session.performedOn, DateTime.now())}', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ?feedbackPill,
              Pill('${session.exercises.length} ${session.exercises.length == 1 ? 'exercise' : 'exercises'}', icon: Icons.fitness_center),
              if (pain != null) _PainPill(pain: pain, prefix: 'Pain up to'),
            ],
          ),
        ),
        children: [
          if (f?.text != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _Quote(text: f!.text!),
            ),
          for (final e in session.exercises)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: 20, color: c.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.title, style: theme.textTheme.bodyLarge),
                        Text(
                          [
                            e.doneLabel,
                            if (e.pain != null) 'pain ${e.pain}/10',
                            if (e.peakAngle != null) 'peak ${e.peakAngle!.round()}°',
                          ].join(' · '),
                          style: theme.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant),
                        ),
                        if (e.sharedNote != null) ...[const SizedBox(height: 6), _Quote(text: e.sharedNote!)],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (session.exercises.isEmpty) Text('No exercises were logged.', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _Quote extends StatelessWidget {
  const _Quote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: c.surfaceContainerHigh,
        border: Border(left: BorderSide(color: c.primary, width: 3)),
      ),
      child: Text('“$text”', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
    );
  }
}

// ------------------------------------------------------------------ flags

class _FlagsPanel extends StatefulWidget {
  const _FlagsPanel({required this.detail});

  final PatientDetail detail;

  @override
  State<_FlagsPanel> createState() => _FlagsPanelState();
}

class _FlagsPanelState extends State<_FlagsPanel> {
  final _busy = <String>{};

  Future<void> _resolve(FlagEntry flag) async {
    final scope = AppScope.of(context);
    final ok = await confirm(
      context,
      title: 'Mark this flag as resolved?',
      body: const Text('Do this once you have checked on the patient. It stays in the history.'),
      yes: 'Resolve',
    );
    if (!ok || !mounted) return;
    setState(() => _busy.add(flag.id));
    try {
      await scope.api.resolveFlag(flag: flag, patientId: widget.detail.patient.id, clinicId: scope.clinician.clinicId);
      if (mounted) showMessage(context, 'Flag resolved.');
      scope.changes.bump();
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(flag.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final open = widget.detail.openFlags;
    final resolved = [for (final f in widget.detail.flags) if (!f.isOpen) f].take(3).toList();
    String details(FlagEntry f) => flagDetailsLabel(f.reason, f.details, exerciseTitle: widget.detail.exerciseTitleForSlug);
    IconData icon(String reason) => switch (reason) {
      'red_flag' => Icons.warning_amber_rounded,
      'high_pain' => Icons.healing,
      'missed_days' => Icons.event_busy,
      _ => Icons.flag_outlined,
    };
    return Panel(
      title: 'Open flags',
      icon: Icons.flag_outlined,
      trailing: open.isEmpty ? null : Pill('${open.length}', tone: Tone.bad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (open.isEmpty)
            Row(
              children: [
                Icon(Icons.check_circle, color: c.primary),
                const SizedBox(width: 10),
                Expanded(child: Text('Nothing needs your attention.', style: theme.textTheme.bodyLarge)),
              ],
            ),
          for (final f in open)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: toneColors(context, f.reason == 'missed_days' ? Tone.warn : Tone.bad).bg,
                borderRadius: BorderRadius.circular(Brand.of(context).radius - 4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon(f.reason), color: f.reason == 'missed_days' ? toneColors(context, Tone.warn).fg : c.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(flagReasonLabel(f.reason), style: theme.textTheme.titleMedium),
                            const SizedBox(height: 2),
                            Text(details(f), style: theme.textTheme.bodyLarge),
                            const SizedBox(height: 4),
                            Text(dateTimeLabel(f.createdAt), style: theme.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      style: compactButton,
                      onPressed: _busy.contains(f.id) ? null : () => _resolve(f),
                      icon: _busy.contains(f.id)
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.done),
                      label: const Text('Resolve'),
                    ),
                  ),
                ],
              ),
            ),
          if (resolved.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Recently resolved', style: theme.textTheme.labelLarge?.copyWith(color: c.onSurfaceVariant)),
            for (final f in resolved)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${flagReasonLabel(f.reason)} · ${details(f)} · resolved ${f.resolvedAt == null ? '' : relativeDay(f.resolvedAt!, DateTime.now()).toLowerCase()}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ program

class _ProgramPanel extends StatelessWidget {
  const _ProgramPanel({required this.program, required this.onEdit});

  final ProgramVersion? program;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final p = program;
    if (p == null) {
      return Panel(
        title: 'Program',
        icon: Icons.fitness_center,
        child: EmptyState(
          icon: Icons.playlist_add,
          title: 'No program yet',
          message: 'Choose exercises from the library and set the dose. The phone gets it the next time it is online.',
          action: FilledButton.icon(style: compactButton, onPressed: onEdit, icon: const Icon(Icons.playlist_add), label: const Text('Build program')),
        ),
      );
    }
    final perDay = [for (var d = 1; d <= 7; d++) sessionDurationOn(d, p.items)];
    final longest = perDay.reduce((a, b) => a > b ? a : b);
    return Panel(
      title: 'Current program',
      icon: Icons.fitness_center,
      trailing: Pill('Version ${p.version}', tone: Tone.good),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Published ${relativeDay(p.createdAt, DateTime.now()).toLowerCase()}${p.authorName == null ? '' : ' by ${p.authorName}'} · longest day ${minutesLabel(longest)}',
            style: theme.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < p.items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Brand.of(context).soft, shape: BoxShape.circle),
                    child: Text('${i + 1}', style: theme.textTheme.labelLarge),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.items[i].title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                        Text(
                          '${p.items[i].isValid ? p.items[i].prescription.summary : ''} · ${daysLabel(p.items[i].days)}',
                          style: theme.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant),
                        ),
                        if (p.items[i].notes.isNotEmpty)
                          Text('Note: ${p.items[i].notes}', style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (p.notes != null) ...[const SizedBox(height: 8), _Quote(text: p.notes!)],
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(style: compactOutlined, onPressed: onEdit, icon: const Icon(Icons.edit_note), label: const Text('Edit program')),
          ),
        ],
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({required this.programs});

  final List<ProgramVersion> programs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    return Panel(
      title: 'Program history',
      icon: Icons.layers_outlined,
      child: programs.isEmpty
          ? Text('Each time you publish, a new version is kept here.', style: theme.textTheme.bodyMedium)
          : Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: Column(
                children: [
                  for (final (i, p) in programs.indexed)
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 10),
                      shape: const Border(),
                      collapsedShape: const Border(),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: i == 0 ? c.primary : Brand.of(context).soft,
                        foregroundColor: i == 0 ? c.onPrimary : c.onSurface,
                        child: Text('v${p.version}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                      title: Text(
                        '${dateTimeLabel(p.createdAt)}${i == 0 ? ' · current' : ''}',
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${p.items.length} ${p.items.length == 1 ? 'exercise' : 'exercises'}${p.authorName == null ? '' : ' · ${p.authorName}'}',
                      ),
                      children: [
                        for (final item in p.items)
                          Padding(
                            padding: const EdgeInsets.only(left: 52, top: 4, bottom: 4),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${item.title}: ${item.isValid ? item.prescription.summary : ''} · ${daysLabel(item.days)}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        if (p.notes != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 52, top: 6),
                            child: Align(alignment: Alignment.centerLeft, child: _Quote(text: p.notes!)),
                          ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}
