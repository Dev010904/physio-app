import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import 'session_log.dart';

/// Asks how an exercise felt: pain 0–10 with big buttons, and an optional
/// note. Returns null when the patient skips.
Future<PainAnswer?> showPainCheck(BuildContext context, {required String exerciseTitle, required bool canShare}) =>
    showModalBottomSheet<PainAnswer>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      showDragHandle: true,
      builder: (_) => _PainCheck(exerciseTitle: exerciseTitle, canShare: canShare),
    );

class _PainCheck extends StatefulWidget {
  const _PainCheck({required this.exerciseTitle, required this.canShare});

  final String exerciseTitle;
  final bool canShare;

  @override
  State<_PainCheck> createState() => _PainCheckState();
}

class _PainCheckState extends State<_PainCheck> {
  int? _pain;
  bool _noteOpen = false;
  bool _share = false;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.howDidItFeel(l.localeName == 'hi' ? widget.exerciseTitle : widget.exerciseTitle.toLowerCase()), style: text.headlineSmall),
            const SizedBox(height: 4),
            Text(
              l.painScale,
              style: text.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [for (var p = 0; p <= 10; p++) _PainButton(value: p, selected: _pain == p, onTap: () => setState(() => _pain = p))],
            ),
            if (_pain != null && SafetyRules.painNeedsStop(_pain!)) ...[
              const SizedBox(height: 12),
              Text(
                l.painTooHigh,
                style: text.bodyLarge?.copyWith(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            if (!_noteOpen)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _noteOpen = true),
                  icon: const Icon(Icons.edit_note),
                  label: Text(l.addNote),
                ),
              )
            else ...[
              TextField(
                controller: _note,
                autofocus: true,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: l.noteHint, border: const OutlineInputBorder()),
              ),
              if (widget.canShare)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _share,
                  onChanged: (v) => setState(() => _share = v),
                  title: Text(l.shareNote),
                  subtitle: Text(l.shareNoteOff),
                ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _pain == null
                  ? null
                  : () => Navigator.pop(context, PainAnswer(pain: _pain, note: _note.text, shareNote: _share)),
              child: Text(l.continueLabel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _note.text.trim().isEmpty ? null : PainAnswer(note: _note.text, shareNote: _share)),
              child: Text(l.skip),
            ),
          ],
        ),
      ),
    );
  }
}

class _PainButton extends StatelessWidget {
  const _PainButton({required this.value, required this.selected, required this.onTap});

  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Calm for little pain, warmer as it rises; the number is always shown,
    // so colour is never the only signal.
    final (bg, fg) = switch (value) {
      <= 3 => (colors.primaryContainer, colors.onPrimaryContainer),
      <= 6 => (colors.tertiaryContainer, colors.onTertiaryContainer),
      _ => (colors.errorContainer, colors.onErrorContainer),
    };
    return Semantics(
      button: true,
      selected: selected,
      label: context.l10n.painValue(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: selected ? fg : bg,
          borderRadius: BorderRadius.circular(Brand.of(context).radius),
          border: Border.all(color: selected ? fg : Colors.transparent, width: 2),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(Brand.of(context).radius),
            onTap: onTap,
            child: Center(
              child: Text(
                '$value',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: selected ? bg : fg, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks why the patient is stopping. Returns a [RedFlag], or null for "just
/// stop", or [cancelled] when they choose to keep going.
Future<StopChoice?> showStopSheet(BuildContext context) => showModalBottomSheet<StopChoice>(
  context: context,
  showDragHandle: true,
  builder: (context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.whyStopping, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            for (final flag in RedFlag.values)
              ListTile(
                leading: Icon(Icons.warning_amber_rounded, color: colors.error),
                title: Text(redFlagLabel(context.l10n, flag)),
                onTap: () => Navigator.pop(context, StopChoice(flag)),
              ),
            ListTile(
              leading: const Icon(Icons.pause_circle_outline),
              title: Text(context.l10n.justStop),
              onTap: () => Navigator.pop(context, const StopChoice(null)),
            ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.keepGoing)),
          ],
        ),
      ),
    );
  },
);

/// The answer from [showStopSheet]: a red flag, or null for an ordinary stop.
class StopChoice {
  const StopChoice(this.flag);

  final RedFlag? flag;
}

/// End-of-session feedback buttons: easy, OK or hard.
class FeedbackButtons extends StatelessWidget {
  const FeedbackButtons({super.key, required this.onChosen});

  final ValueChanged<String> onChosen;

  @override
  Widget build(BuildContext context) {
    Widget choice(String value, String label, IconData icon) => Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 88), padding: const EdgeInsets.all(8)),
        onPressed: () => onChosen(value),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon, size: 32), const SizedBox(height: 4), Text(label)],
        ),
      ),
    );
    return Row(
      children: [
        choice('easy', context.l10n.feedbackEasy, Icons.sentiment_very_satisfied_outlined),
        const SizedBox(width: 10),
        choice('ok', context.l10n.feedbackOk, Icons.sentiment_neutral_outlined),
        const SizedBox(width: 10),
        choice('hard', context.l10n.feedbackHard, Icons.sentiment_dissatisfied_outlined),
      ],
    );
  }
}
