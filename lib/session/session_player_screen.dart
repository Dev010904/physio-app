import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../common/ui.dart';
import '../exercises/exercise.dart';
import '../theme/app_theme.dart';
import 'cue_player.dart';
import 'session_controller.dart';
import 'session_plan.dart';

class SessionPlayerScreen extends StatefulWidget {
  const SessionPlayerScreen({super.key, required this.exercises});

  final List<Exercise> exercises;

  @override
  State<SessionPlayerScreen> createState() => _SessionPlayerScreenState();
}

class _SessionPlayerScreenState extends State<SessionPlayerScreen>
    with SingleTickerProviderStateMixin {
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
      if (mounted) _controller.start(this);
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
              leading: finished
                  ? null
                  : IconButton(
                      tooltip: 'End session',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.maybePop(context),
                    ),
              centerTitle: true,
              title: finished || _plan.exercises.length == 1
                  ? null
                  : Text(
                      'Exercise ${_controller.phase.exerciseIndex + 1} of ${_plan.exercises.length}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
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
    final exercise = controller.plan.exercises[phase.exerciseIndex];
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final muted = theme.colorScheme.onSurfaceVariant;
    final working = !controller.canAddTime;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: RepaintBoundary(
              child: CustomPaint(
                size: const Size.fromHeight(6),
                painter: _BarPainter(controller, theme.colorScheme.primary, Brand.of(context).ringTrack),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              children: [
                Text(
                  exercise.title,
                  style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                Text(_detailLine(phase), style: text.bodyLarge?.copyWith(color: muted), textAlign: TextAlign.center),
              ],
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: controller.canAddTime
                      ? OutlinedButton.icon(
                          onPressed: () => controller.addTime(const Duration(seconds: 30)),
                          icon: const Icon(Icons.more_time),
                          label: const Text('+30 s'),
                        )
                      : OutlinedButton.icon(
                          onPressed: working ? controller.finishSet : null,
                          icon: const Icon(Icons.done_all),
                          label: Text(phase.side == null ? 'Finish set' : 'Finish side'),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.skip,
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Skip'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Text(
              '${clockLabel(controller.remainingTotal)} left in this session',
              style: text.bodyMedium?.copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
  }

  static String _detailLine(Phase phase) {
    final parts = <String>[
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
    // Move, hold and release each get their own shade so the rhythm of a rep
    // is visible at a glance; count-ins and rests stay neutral.
    final color = switch (phase.kind) {
      PhaseKind.move => colors.primary,
      PhaseKind.hold || PhaseKind.timed => colors.secondary,
      PhaseKind.release => colors.tertiary,
      _ => colors.outline,
    };

    // The ring repaints every frame from controller.frames; the text inside
    // rebuilds only when the second, phase or pause state changes.
    return SizedBox.square(
      dimension: 288,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _RingPainter(controller, color: color, track: Brand.of(context).ringTrack),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_label(phase, exercise), style: text.titleLarge, textAlign: TextAlign.center),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.85, end: 1.0).animate(animation),
                    child: child,
                  ),
                ),
                child: Text(
                  '${controller.secondsLeft}',
                  key: ValueKey('${controller.phaseIndex}-${controller.secondsLeft}'),
                  style: text.displayLarge?.copyWith(fontSize: 76, fontWeight: FontWeight.w600, color: colors.onSurface),
                ),
              ),
              Text(
                controller.isPaused ? 'Paused · tap to resume' : 'Tap to pause',
                style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
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

/// Phase ring, painted every frame so it sweeps continuously instead of in steps.
class _RingPainter extends CustomPainter {
  _RingPainter(this.controller, {required this.color, required this.track})
    : super(repaint: controller.frames);

  final SessionController controller;
  final Color color;
  final Color track;

  static const _stroke = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = track);
    final sweep = 2 * math.pi * controller.phaseProgress;
    if (sweep > 0) canvas.drawArc(rect, -math.pi / 2, sweep, false, paint..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.color != color || old.track != track;
}

/// Whole-session progress line under the app bar.
class _BarPainter extends CustomPainter {
  _BarPainter(this.controller, this.color, this.track) : super(repaint: controller.frames);

  final SessionController controller;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, radius), Paint()..color = track);
    final filled = size.width * controller.sessionProgress;
    if (filled > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & Size(filled.clamp(size.height, size.width), size.height), radius),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.color != color || old.track != track;
}

class _CompleteView extends StatelessWidget {
  const _CompleteView({required this.controller});

  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final colors = theme.colorScheme;
    final count = controller.plan.exercises.length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(color: Brand.of(context).soft, shape: BoxShape.circle),
              child: Icon(Icons.check_rounded, size: 72, color: colors.primary),
            ),
            const SizedBox(height: 24),
            Text('Session complete', style: text.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              '$count ${count == 1 ? 'exercise' : 'exercises'} · '
              '${clockLabel(controller.elapsed)} of exercise',
              style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
          ],
        ),
      ),
    );
  }
}
