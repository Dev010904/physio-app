import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:physio_app/session/session_plan.dart';
import 'package:physio_app/theme/app_theme.dart';

import '../data/errors.dart';
import '../data/models.dart';
import '../logic/dose.dart';
import '../logic/text.dart';
import 'scope.dart';
import 'widgets.dart';

IconData regionIcon(String region) => switch (region) {
  'knee' => Icons.directions_walk,
  'hip' => Icons.accessibility_new,
  'ankle' => Icons.directions_run,
  'back' => Icons.airline_seat_flat,
  'neck' => Icons.face,
  'shoulder' => Icons.fitness_center,
  _ => Icons.self_improvement,
};

String _cap(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Pick exercises, set each dose, check the session length, and publish a
/// new version. Starts from the latest published version.
class ProgramBuilderScreen extends StatelessWidget {
  const ProgramBuilderScreen({super.key, required this.patientId, required this.patientName});

  final String patientId;
  final String patientName;

  @override
  Widget build(BuildContext context) {
    final api = AppScope.of(context).api;
    return Scaffold(
      body: Loader<(List<LibraryExercise>, ProgramVersion?)>(
        load: () async {
          final r = await Future.wait<Object?>([api.library(), api.latestProgram(patientId)]);
          return (r[0] as List<LibraryExercise>, r[1] as ProgramVersion?);
        },
        loadingLabel: 'Loading the exercise library…',
        builder: (context, data, _) => _Builder(patientId: patientId, patientName: patientName, library: data.$1, latest: data.$2),
      ),
    );
  }
}

class _Builder extends StatefulWidget {
  const _Builder({required this.patientId, required this.patientName, required this.library, required this.latest});

  final String patientId;
  final String patientName;
  final List<LibraryExercise> library;
  final ProgramVersion? latest;

  @override
  State<_Builder> createState() => _BuilderState();
}

class _BuilderState extends State<_Builder> {
  late final List<ItemDraft> _items = [for (final i in widget.latest?.items ?? const <ItemDraft>[]) i.copy()];
  late final _notes = TextEditingController(text: widget.latest?.notes ?? '');
  late int _baseVersion = widget.latest?.version ?? 0;
  bool _dirty = false;
  bool _publishing = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _changed() => setState(() => _dirty = true);

  bool _has(LibraryExercise e) => _items.any((i) => i.exerciseId == e.id);

  void _add(LibraryExercise e) {
    setState(() {
      _items.add(e.toDraft());
      _dirty = true;
    });
    showMessage(context, '${e.title} added.');
  }

  void _move(int from, int to) {
    if (to < 0 || to >= _items.length) return;
    setState(() {
      _items.insert(to, _items.removeAt(from));
      _dirty = true;
    });
  }

  Future<void> _publish() async {
    final scope = AppScope.of(context);
    final next = _baseVersion + 1;
    final perDay = [for (var d = 1; d <= 7; d++) sessionDurationOn(d, _items)];
    final longest = perDay.reduce((a, b) => a > b ? a : b);
    final ok = await confirm(
      context,
      title: 'Publish version $next for ${widget.patientName}?',
      yes: 'Publish',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (n, i) in _items.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${n + 1}. ${i.title}: ${i.prescription.summary} · ${daysLabel(i.days)}'),
            ),
          const SizedBox(height: 8),
          Text('Longest day: ${minutesLabel(longest)}.'),
          const SizedBox(height: 8),
          Text(
            "The patient's phone gets it the next time it is online. Earlier versions stay in the history.",
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
    if (!ok || !mounted) return;
    setState(() => _publishing = true);
    try {
      final version = await scope.api.publish(patientId: widget.patientId, items: _items, notes: _notes.text);
      scope.changes.bump();
      if (!mounted) return;
      setState(() {
        _baseVersion = version;
        _dirty = false;
      });
      final back = await showDialog<bool>(
        context: context,
        builder: (context) => _PublishedDialog(version: version, name: widget.patientName),
      );
      if ((back ?? false) && mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _openLibrarySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.88,
        child: StatefulBuilder(
          builder: (context, setSheet) => _LibraryPane(
            library: widget.library,
            isAdded: _has,
            onAdd: (e) {
              _add(e);
              setSheet(() {});
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await confirm(
          context,
          title: 'Leave without publishing?',
          body: const Text('Your changes to this program are not saved. The patient keeps the last published version.'),
          yes: 'Leave',
          danger: true,
        );
        if (leave && context.mounted) Navigator.of(context).pop();
      },
      child: LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth >= 1080;
          final program = _programPane(context, wide);
          if (!wide) return program;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: program),
              const VerticalDivider(width: 1),
              SizedBox(width: 380, child: _LibraryPane(library: widget.library, isAdded: _has, onAdd: _add)),
            ],
          );
        },
      ),
    );
  }

  Widget _programPane(BuildContext context, bool wide) {
    final pad = isWide(context) ? 32.0 : 16.0;
    final problems = [for (final i in _items) if (!i.isValid) i];
    final latest = widget.latest;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(pad, pad - 8, pad, 0),
          sliver: SliverToBoxAdapter(
            child: PageHeader(
              title: 'Program for ${widget.patientName}',
              subtitle: Text(
                latest == null
                    ? 'A new program. Add exercises, set each dose, then publish.'
                    : 'Starting from version ${latest.version}, published ${relativeDay(latest.createdAt, DateTime.now(), inSentence: true)}. '
                          'Publishing makes version ${_baseVersion + 1}.',
              ),
              actions: [
                if (!wide)
                  FilledButton.icon(
                    style: compactButton,
                    onPressed: _openLibrarySheet,
                    icon: const Icon(Icons.add),
                    label: const Text('Add exercises'),
                  ),
              ],
            ),
          ),
        ),
        if (_items.isEmpty)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            sliver: SliverToBoxAdapter(
              child: Panel(
                child: EmptyState(
                  icon: Icons.playlist_add,
                  title: 'No exercises yet',
                  message: wide
                      ? 'Pick exercises from the library on the right. Each starts with its usual dose, which you can change.'
                      : 'Tap "Add exercises" to pick from the library. Each starts with its usual dose, which you can change.',
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          sliver: SliverReorderableList(
            itemCount: _items.length,
            onReorderItem: _move,
            proxyDecorator: (child, index, animation) => Material(
              elevation: 8,
              color: Colors.transparent,
              shadowColor: Colors.black38,
              borderRadius: BorderRadius.circular(Brand.of(context).radius),
              child: child,
            ),
            itemBuilder: (context, i) {
              final item = _items[i];
              return Padding(
                key: ObjectKey(item),
                padding: const EdgeInsets.only(bottom: 14),
                child: _ItemCard(
                  index: i,
                  count: _items.length,
                  draft: item,
                  onChanged: _changed,
                  onMove: (to) => _move(i, to),
                  onRemove: () => setState(() {
                    _items.removeAt(i);
                    _dirty = true;
                  }),
                ),
              );
            },
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(pad, 6, pad, 48),
          sliver: SliverToBoxAdapter(child: _footer(context, problems)),
        ),
      ],
    );
  }

  Widget _footer(BuildContext context, List<ItemDraft> problems) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final perDay = [for (var d = 1; d <= 7; d++) sessionDurationOn(d, _items)];
    final canPublish = _items.isNotEmpty && problems.isEmpty && !_publishing;
    return Panel(
      title: 'Session length and notes',
      icon: Icons.timer_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (var d = 1; d <= 7; d++)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: perDay[d - 1] == Duration.zero ? c.surfaceContainerHigh : Brand.of(context).soft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(weekdayShort[d - 1], style: theme.textTheme.labelLarge),
                        const SizedBox(height: 2),
                        FittedBox(
                          child: Text(
                            perDay[d - 1] == Duration.zero ? 'Rest' : '${(perDay[d - 1].inSeconds / 60).ceil()} min',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: perDay[d - 1] == Duration.zero ? c.onSurfaceVariant : c.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Worked out like the phone\'s session player: a ${SessionPlan.prepareSeconds} s count-in before each set or side, '
            'and ${SessionPlan.transitionSeconds} s between exercises.',
            style: theme.textTheme.bodySmall?.copyWith(color: c.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _notes,
            minLines: 2,
            maxLines: 5,
            onChanged: (_) => _changed(),
            style: theme.textTheme.bodyLarge,
            decoration: const InputDecoration(
              labelText: 'Program notes for the patient (optional)',
              hintText: 'e.g. Ice the knee for 10 minutes after the session.',
              alignLabelWithHint: true,
            ),
          ),
          if (problems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Notice(
              icon: Icons.error_outline,
              tone: Tone.bad,
              text: '${problems.length == 1 ? '1 exercise needs' : '${problems.length} exercises need'} fixing before you can publish: '
                  '${problems.map((p) => p.title).join(', ')}.',
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: canPublish ? _publish : null,
            icon: _publishing
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Icon(Icons.send_outlined),
            label: Text(_items.isEmpty ? 'Add an exercise to publish' : 'Publish version ${_baseVersion + 1}'),
          ),
        ],
      ),
    );
  }
}

class _PublishedDialog extends StatelessWidget {
  const _PublishedDialog({required this.version, required this.name});

  final int version;
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              builder: (context, s, child) => Transform.scale(scale: s, child: child),
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                child: Icon(Icons.check, size: 52, color: theme.colorScheme.onPrimary),
              ),
            ),
            const SizedBox(height: 18),
            Text('Version $version published', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              "$name's phone gets it the next time it is online.",
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
      actions: [
        OutlinedButton(style: compactOutlined, onPressed: () => Navigator.pop(context, false), child: const Text('Keep editing')),
        FilledButton(style: compactButton, onPressed: () => Navigator.pop(context, true), child: const Text('Back to patient')),
      ],
    );
  }
}

// ------------------------------------------------------------------ one exercise

class _ItemCard extends StatefulWidget {
  const _ItemCard({
    required this.index,
    required this.count,
    required this.draft,
    required this.onChanged,
    required this.onMove,
    required this.onRemove,
  });

  final int index;
  final int count;
  final ItemDraft draft;
  final VoidCallback onChanged;
  final ValueChanged<int> onMove;
  final VoidCallback onRemove;

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  late final _note = TextEditingController(text: widget.draft.notes);

  ItemDraft get d => widget.draft;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _set(void Function() change) {
    change();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final problems = d.problems;
    final duration = d.duration;
    final compact = MediaQuery.sizeOf(context).width < 700;
    final steppers = <Widget>[
      NumberStepper(label: 'Sets', value: d.sets, min: 1, max: 10, onChanged: (v) => _set(() => d.sets = v)),
      if (d.isTimed)
        NumberStepper(label: 'Hold for', suffix: 's', value: d.durationSeconds, min: 5, max: 600, step: 5, onChanged: (v) => _set(() => d.durationSeconds = v))
      else ...[
        NumberStepper(label: 'Reps', value: d.reps, min: 1, max: 100, onChanged: (v) => _set(() => d.reps = v)),
        NumberStepper(label: 'Move', suffix: 's', value: d.moveSeconds, min: 0, max: 20, onChanged: (v) => _set(() => d.moveSeconds = v)),
        NumberStepper(label: 'Hold', suffix: 's', value: d.holdSeconds, min: 0, max: 60, onChanged: (v) => _set(() => d.holdSeconds = v)),
        NumberStepper(label: 'Release', suffix: 's', value: d.releaseSeconds, min: 0, max: 20, onChanged: (v) => _set(() => d.releaseSeconds = v)),
      ],
      NumberStepper(label: 'Rest between sets', suffix: 's', value: d.restSeconds, min: 0, max: 300, step: 5, onChanged: (v) => _set(() => d.restSeconds = v)),
    ];

    return Panel(
      padding: const EdgeInsets.fromLTRB(12, 14, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ReorderableDragStartListener(
                index: widget.index,
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Tooltip(
                    message: 'Drag to reorder',
                    child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.drag_indicator, color: c.onSurfaceVariant)),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: Brand.of(context).soft, shape: BoxShape.circle),
                child: Icon(regionIcon(d.bodyRegion), color: c.onSurface, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${widget.index + 1}. ${d.title}', style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                    Text(
                      d.isValid ? '${d.prescription.summary}${compact ? ' · ${minutesLabel(duration!)}' : ''}' : 'Check the dose below',
                      style: theme.textTheme.bodyMedium?.copyWith(color: d.isValid ? c.onSurfaceVariant : c.error),
                      maxLines: compact ? 3 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (duration != null && !compact) Pill(minutesLabel(duration), icon: Icons.timer_outlined, tone: Tone.info),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Move up',
                onPressed: widget.index == 0 ? null : () => widget.onMove(widget.index - 1),
                icon: const Icon(Icons.arrow_upward),
              ),
              IconButton(
                tooltip: 'Move down',
                onPressed: widget.index == widget.count - 1 ? null : () => widget.onMove(widget.index + 1),
                icon: const Icon(Icons.arrow_downward),
              ),
              IconButton(tooltip: 'Remove from program', onPressed: widget.onRemove, icon: Icon(Icons.delete_outline, color: c.error)),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 18,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SegmentedButton<DoseMode>(
                      segments: const [
                        ButtonSegment(value: DoseMode.reps, label: Text('Repetitions'), icon: Icon(Icons.repeat)),
                        ButtonSegment(value: DoseMode.time, label: Text('Timed hold'), icon: Icon(Icons.timer_outlined)),
                      ],
                      selected: {d.mode},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => _set(() => d.mode = s.first),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(99),
                      onTap: () => _set(() => d.perSide = !d.perSide),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(value: d.perSide, onChanged: (v) => _set(() => d.perSide = v)),
                            const SizedBox(width: 8),
                            Text('Each side (left and right)', style: theme.textTheme.bodyLarge),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(spacing: 16, runSpacing: 14, children: steppers),
                const SizedBox(height: 16),
                Text('Days', style: theme.textTheme.labelLarge?.copyWith(color: c.onSurfaceVariant)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (var day = 1; day <= 7; day++)
                      FilterChip(
                        label: Text(weekdayShort[day - 1]),
                        selected: d.days.contains(day),
                        showCheckmark: false,
                        selectedColor: c.primary,
                        labelStyle: TextStyle(
                          color: d.days.contains(day) ? c.onPrimary : c.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        onSelected: (on) => _set(() => on ? d.days.add(day) : d.days.remove(day)),
                      ),
                    if (d.days.length < 7)
                      TextButton(onPressed: () => _set(() => d.days = {...ItemDraft.allDays}), child: const Text('Every day')),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _note,
                  onChanged: (v) => _set(() => d.notes = v),
                  style: theme.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Note for this exercise (optional)',
                    hintText: 'e.g. Stop if the knee clicks or hurts.',
                    isDense: true,
                  ),
                ),
                if (problems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final p in problems)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, size: 18, color: c.error),
                          const SizedBox(width: 6),
                          Expanded(child: Text(p, style: theme.textTheme.bodyMedium?.copyWith(color: c.error))),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A number with big − and + buttons; the clinician can also type it.
class NumberStepper extends StatefulWidget {
  const NumberStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 999,
    this.step = 1,
    this.suffix,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;
  final String? suffix;

  @override
  State<NumberStepper> createState() => _NumberStepperState();
}

class _NumberStepperState extends State<NumberStepper> {
  late final _text = TextEditingController(text: '${widget.value}');
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // On leaving the field, show the value actually in use.
    _focus.addListener(() {
      if (!_focus.hasFocus) _text.text = '${widget.value}';
    });
  }

  @override
  void didUpdateWidget(NumberStepper old) {
    super.didUpdateWidget(old);
    if (int.tryParse(_text.text) != widget.value && !_focus.hasFocus) _text.text = '${widget.value}';
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _bump(int by) {
    // Snap to the step, so 32 + 5 gives 35 rather than 37.
    final raw = by > 0 ? (widget.value ~/ widget.step + 1) * widget.step : ((widget.value - 1) ~/ widget.step) * widget.step;
    final v = raw.clamp(widget.min, widget.max);
    _text.text = '$v';
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final v = widget.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: theme.textTheme.labelLarge?.copyWith(color: c.onSurfaceVariant, fontSize: 14)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: c.surfaceContainerLowest,
            border: Border.all(color: c.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Less',
                visualDensity: VisualDensity.compact,
                onPressed: v > widget.min ? () => _bump(-1) : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: widget.suffix == null ? 44 : 60,
                child: TextField(
                  controller: _text,
                  focusNode: _focus,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                  style: theme.textTheme.titleMedium,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    suffixText: widget.suffix,
                    semanticCounterText: widget.label,
                  ),
                  onChanged: (s) {
                    final n = int.tryParse(s);
                    if (n != null) widget.onChanged(n);
                  },
                ),
              ),
              IconButton(
                tooltip: 'More',
                visualDensity: VisualDensity.compact,
                onPressed: v < widget.max ? () => _bump(1) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ library

class _LibraryPane extends StatefulWidget {
  const _LibraryPane({required this.library, required this.isAdded, required this.onAdd});

  final List<LibraryExercise> library;
  final bool Function(LibraryExercise) isAdded;
  final ValueChanged<LibraryExercise> onAdd;

  @override
  State<_LibraryPane> createState() => _LibraryPaneState();
}

class _LibraryPaneState extends State<_LibraryPane> {
  String _query = '';
  String? _region;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final regions = {for (final e in widget.library) e.bodyRegion}.toList()..sort();
    final q = _query.trim().toLowerCase();
    final shown = [
      for (final e in widget.library)
        if ((_region == null || e.bodyRegion == _region) && (q.isEmpty || e.title.toLowerCase().contains(q) || e.bodyRegion.contains(q))) e,
    ];
    return Material(
      color: c.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Exercise library', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('${widget.library.length} exercises with tutorials in the app', style: theme.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
                const SizedBox(height: 14),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: theme.textTheme.bodyLarge,
                  decoration: const InputDecoration(hintText: 'Search exercises', prefixIcon: Icon(Icons.search), isDense: true),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(label: const Text('All'), selected: _region == null, onSelected: (_) => setState(() => _region = null)),
                    for (final r in regions)
                      ChoiceChip(label: Text(_cap(r)), selected: _region == r, onSelected: (on) => setState(() => _region = on ? r : null)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: shown.isEmpty
                ? const EmptyState(icon: Icons.search_off, title: 'No exercises match', message: 'Try another word or body area.')
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, indent: 20, endIndent: 20),
                    itemBuilder: (context, i) {
                      final e = shown[i];
                      final added = widget.isAdded(e);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(color: Brand.of(context).soft, shape: BoxShape.circle),
                              child: Icon(regionIcon(e.bodyRegion), color: c.onSurface, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                                  Text(
                                    '${_cap(e.bodyRegion)} · ${e.doseSummary}',
                                    style: theme.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            added
                                ? const Pill('Added', icon: Icons.check, tone: Tone.good)
                                : FilledButton.tonalIcon(
                                    style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 14)),
                                    onPressed: () => widget.onAdd(e),
                                    icon: const Icon(Icons.add, size: 20),
                                    label: const Text('Add'),
                                  ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
