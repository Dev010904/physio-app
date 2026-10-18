import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../common/ui.dart';
import '../exercises/exercise.dart';
import 'cue_player.dart';
import 'session_controller.dart';
import 'session_plan.dart';

class SessionPlayerScreen extends StatefulWidget {
  const SessionPlayerScreen({super.key, required this.exercises});

  final List<Exercise> exercises;

  @override
  State<SessionPlayerScreen> createState() => _SessionPlayerScreenState();
}

class _SessionPlayerScreenState extends State<SessionPlayerScreen> {
  late final SessionPlan _plan = SessionPlan.build(widget.exercises);
  late final CuePlayer _cues = CuePlayer(widget.exercises);
  late final SessionController _controller = SessionController(_plan, cues: _cues);

  // Leaving the app mid-session pauses it instead of silently skipping ahead.
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(onHide: _controller.pause);

  @override
  void initState() {
    super.initState();
    _lifecycle; // start listening
    WakelockPlus.enable();
    _cues.init().whenComplete(() {
      if (mounted) _controller.start();
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _controller.dispose();
    _cues.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _confirmExit() async {
    final wasPaused = _controller.isPaused;
    _controller.pause();
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End this session?'),
        content: const Text('Your progress in this session will not be kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep going')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('End session')),
        ],
      ),
    );
    if (!mounted) return;
    if (leave == true) {
      Navigator.of(context).pop();
    } else if (!wasPaused) {
      _controller.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final finished = _controller.isFinished;
        return PopScope(
          canPop: finished,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmExit();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(finished ? 'Done' : _plan.exercises[_controller.phase.exerciseIndex].title),
              actions: [
                ValueListenableBuilder(
                  valueListenable: _cues.voiceOn,
                  builder: (context, on, _) => IconButton(
                    tooltip: on ? 'Turn voice off' : 'Turn voice on',
                    icon: Icon(on ? Icons.record_voice_over : Icons.voice_over_off),
                    onPressed: () => _cues.voiceOn.value = !on,
                  ),
                ),
              ],
            ),
            body: finished ? _CompleteView(controller: _controller) : _PlayerView(controller: _controller),
          ),
        );
      },
    );
  }
}

class _PlayerView extends StatelessWidget {
  const _PlayerView({required this.controller});

  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    final phase = controller.phase;
    final plan = controller.plan;
    final exercise = plan.exercises[phase.exerciseIndex];
    final text = Theme.of(context).textTheme;
    final working = !controller.canAddTime;

    return SafeArea(
      child: Column(
        children: [
          LinearProgressIndicator(value: controller.sessionProgress),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              _detailLine(phase, plan),
              style: text.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            // Tap anywhere on the dial area to pause or resume.
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: controller.togglePause,
              child: Center(child: _PhaseDial(controller: controller, exercise: exercise)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                if (controller.canAddTime)
                  OutlinedButton.icon(
                    onPressed: () => controller.addTime(const Duration(seconds: 30)),
                    icon: const Icon(Icons.more_time),
                    label: const Text('+30 s'),
                  ),
                if (working)
                  OutlinedButton.icon(
                    onPressed: controller.finishSet,
                    icon: const Icon(Icons.done_all),
                    label: Text(phase.side == null ? 'Finish set' : 'Finish side'),
                  ),
                OutlinedButton.icon(
                  onPressed: controller.skip,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Skip'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${clockLabel(controller.remainingTotal)} left in this session',
              style: text.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  static String _detailLine(Phase phase, SessionPlan plan) {
    final parts = <String>[
      if (plan.exercises.length > 1) 'Exercise ${phase.exerciseIndex + 1} of ${plan.exercises.length}',
      if (phase.kind == PhaseKind.rest) 'Next: set ${phase.set + 1} of ${phase.setCount}',
      if (phase.kind != PhaseKind.rest && phase.kind != PhaseKind.transition)
        'Set ${phase.set} of ${phase.setCount}',
      if (phase.rep != null) 'Rep ${phase.rep} of ${phase.repCount}',
      if (phase.side != null) phase.side == Side.left ? 'Left side' : 'Right side',
    ];
    return parts.join(' · ');
  }
}

class _PhaseDial extends StatelessWidget {
  const _PhaseDial({required this.controller, required this.exercise});

  final SessionController controller;
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final phase = controller.phase;
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final color = switch (phase.kind) {
      PhaseKind.move => colors.primary,
      PhaseKind.hold || PhaseKind.timed => colors.tertiary,
      PhaseKind.release => colors.secondary,
      _ => colors.outline,
    };

    return SizedBox.square(
      dimension: 280,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: controller.phaseProgress,
            strokeWidth: 14,
            color: color,
            backgroundColor: colors.surfaceContainerHighest,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_label(phase, exercise), style: text.titleLarge, textAlign: TextAlign.center),
              if (phase.kind == PhaseKind.transition)
                Text(exercise.title, style: text.titleMedium, textAlign: TextAlign.center),
              Text(
                '${controller.secondsLeft}',
                style: text.displayLarge?.copyWith(fontWeight: FontWeight.w600, color: color),
              ),
              Text(
                controller.isPaused ? 'Paused · tap to resume' : 'Tap to pause',
                style: text.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _label(Phase phase, Exercise exercise) => switch (phase.kind) {
    PhaseKind.prepare => phase.side == null
        ? 'Get ready'
        : (phase.side == Side.left ? 'Left side' : 'Right side'),
    PhaseKind.move => exercise.moveLabel,
    PhaseKind.hold => 'Hold',
    PhaseKind.release => exercise.releaseLabel,
    PhaseKind.timed => 'Keep going',
    PhaseKind.rest => 'Rest',
    PhaseKind.transition => 'Up next',
  };
}

class _CompleteView extends StatelessWidget {
  const _CompleteView({required this.controller});

  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final count = controller.plan.exercises.length;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 96, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('Session complete', style: text.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '$count ${count == 1 ? 'exercise' : 'exercises'} · '
              '${clockLabel(controller.elapsed)} of exercise',
              style: text.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
          ],
        ),
      ),
    );
  }
}
