import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../camera/camera_count.dart';
import '../camera/camera_view.dart';
import '../camera/pose_rules.dart';
import '../common/ui.dart';
import '../exercises/exercise.dart';
import '../l10n/l10n.dart';
import '../program/program.dart';
import '../program/program_controller.dart';
import '../safety/safety_screen.dart';
import '../theme/app_theme.dart';
import '../tutorials/tutorial.dart';
import '../tutorials/tutorial_view.dart';
import 'check_in.dart';
import 'cue_player.dart';
import 'session_controller.dart';
import 'session_log.dart';
import 'session_plan.dart';

class SessionPlayerScreen extends StatefulWidget {
  const SessionPlayerScreen({super.key, required this.entries, required this.programs, this.programId});

  /// What to do, in order, with each exercise's dose.
  final List<ProgramEntry> entries;
  final ProgramController programs;

  /// The server program these entries come from; null for the starter
  /// program and the library, whose logs stay on the phone.
  final String? programId;

  @override
  State<SessionPlayerScreen> createState() => _SessionPlayerScreenState();
}

class _SessionPlayerScreenState extends State<SessionPlayerScreen>
    with SingleTickerProviderStateMixin {
  late final List<Exercise> _exercises = [for (final e in widget.entries) e.exercise];
  late final SessionPlan _plan = SessionPlan.build(_exercises);
  late final CuePlayer _cues = CuePlayer(_exercises, AppLocalizations.of(context));
  late final SessionController _controller = SessionController(_plan, cues: _cues);
  late final SessionLogger _log = SessionLogger(
    store: widget.programs.store,
    entries: widget.entries,
    programId: widget.programId,
  );

  // Leaving the app mid-session pauses it instead of silently skipping ahead.
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(onHide: _controller.pause);

  int _phaseIndex = -1;
  int _exerciseIndex = 0;
  bool _asking = false;

  // Camera counting stays on for the session once chosen, with a fresh
  // count for each exercise the camera can read.
  bool _cameraOn = false;
  CameraCount? _count;

  @override
  void initState() {
    super.initState();
    _lifecycle; // start listening
    WakelockPlus.enable();
    _log.start();
    _controller.addListener(_onProgress);
    _cues.init().whenComplete(() {
      if (mounted) _controller.start(this);
    });
  }

  @override
  void dispose() {
    _count?.dispose();
    _controller.removeListener(_onProgress);
    _lifecycle.dispose();
    _controller.dispose();
    _cues.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  /// Tracks the work reached and asks how each exercise felt when it ends.
  void _onProgress() {
    if (_controller.phaseIndex != _phaseIndex && !_controller.isFinished) {
      _phaseIndex = _controller.phaseIndex;
      _log.phaseEntered(_controller.phase);
    }
    final index = _controller.isFinished ? _exercises.length : _controller.phase.exerciseIndex;
    if (index > _exerciseIndex) {
      final done = _exerciseIndex;
      _exerciseIndex = index;
      final count = _count;
      if (count != null && count.exerciseIndex == done && count.wholeExercise) {
        _log.cameraCounted(done, reps: count.counter.reps, peak: count.counter.peak);
      }
      _setCount(_cameraOn ? _newCount(index) : null);
      _askHowItFelt(done);
    }
  }

  CameraCount? _newCount(int index) {
    final rule = index < _exercises.length ? poseRules[_exercises[index].id] : null;
    // Counted from before the first set, the camera's count can stand in
    // for the timer's; switched on midway, it is shown but not logged.
    return rule == null ? null : CameraCount(index, rule, wholeExercise: _log.setsDone(index) == 0);
  }

  void _setCount(CameraCount? count) {
    final old = _count;
    setState(() => _count = count);
    // The camera view lets go of the old count when it next builds.
    if (old != null) WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  /// New reps may begin only while the timer runs a rep, not in rests.
  bool _canStartRep() =>
      !_controller.isPaused &&
      !_controller.isFinished &&
      const {PhaseKind.move, PhaseKind.hold, PhaseKind.release}.contains(_controller.phase.kind);

  Future<void> _toggleCamera() async {
    if (_cameraOn) {
      _cameraOn = false;
      _setCount(null);
      return;
    }
    final index = _controller.phase.exerciseIndex;
    final rule = poseRules[_exercises[index].id];
    if (rule == null) return;
    final wasPaused = _controller.isPaused;
    _controller.pause();
    final start = await showCameraGuide(context, rule.placement);
    if (!mounted) return;
    if (!wasPaused) _controller.resume();
    if (!start || _controller.isFinished) return;
    _cameraOn = true;
    _setCount(_newCount(_controller.phase.exerciseIndex));
  }

  void _cameraProblem(CameraProblem problem) {
    if (!mounted) return;
    _cameraOn = false;
    _setCount(null);
    final l = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(problem == CameraProblem.denied ? l.cameraDenied : l.cameraFailed)),
    );
  }

  Future<void> _askHowItFelt(int index) async {
    if (_asking || _log.isRecorded(index)) return;
    _asking = true;
    final wasPaused = _controller.isPaused;
    _controller.pause();
    final answer = await showPainCheck(
      context,
      exerciseTitle: _exercises[index].title,
      canShare: widget.programs.isLinked,
    );
    _asking = false;
    if (!mounted) return;
    await _log.exerciseDone(index, answer ?? const PainAnswer());
    final pain = answer?.pain;
    if (pain != null && SafetyRules.painNeedsStop(pain)) {
      await _log.raiseFlag('high_pain', {'pain': pain, 'exercise': _exercises[index].id});
      await _stopForSafety(pain: pain);
      return;
    }
    if (!wasPaused) _controller.resume();
  }

  /// The Stop button: a red-flag symptom ends the session at once.
  Future<void> _onStop() async {
    final wasPaused = _controller.isPaused;
    _controller.pause();
    final choice = await showStopSheet(context);
    if (!mounted) return;
    if (choice == null) {
      if (!wasPaused) _controller.resume();
      return;
    }
    final flag = choice.flag;
    if (flag == null) {
      await _endEarly();
      return;
    }
    final current = _controller.isFinished ? _exercises.length - 1 : _controller.phase.exerciseIndex;
    await _log.raiseFlag('red_flag', {'symptom': flag.name, 'exercise': _exercises[current].id});
    await _stopForSafety(flag: flag);
  }

  Future<void> _stopForSafety({RedFlag? flag, int? pain}) async {
    await _log.end(stoppedForSafety: true);
    widget.programs
      ..logsChanged()
      ..sync();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => SafetyStopScreen(flag: flag, pain: pain, link: widget.programs.link)),
    );
  }

  /// Leaves before the end. What was done so far is kept.
  Future<void> _endEarly() async {
    await _log.end();
    widget.programs
      ..logsChanged()
      ..sync();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _finish(String? feedback) async {
    await _log.end(feedback: feedback);
    widget.programs
      ..logsChanged()
      ..sync();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmExit() async {
    final wasPaused = _controller.isPaused;
    _controller.pause();
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.endSessionQuestion),
        content: Text(context.l10n.progressSaved),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.keepGoing)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(context.l10n.endSession)),
        ],
      ),
    );
    if (!mounted) return;
    if (leave == true) {
      await _endEarly();
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
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            finished ? _finish(null) : _confirmExit();
          },
          child: Scaffold(
            appBar: AppBar(
              leading: finished
                  ? null
                  : IconButton(
                      tooltip: context.l10n.endSession,
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.maybePop(context),
                    ),
              automaticallyImplyLeading: false,
              centerTitle: true,
              title: finished || _plan.exercises.length == 1
                  ? null
                  : Text(
                      context.l10n.exerciseXofY(_controller.phase.exerciseIndex + 1, _plan.exercises.length),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
              actions: [
                if (!finished)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                    onPressed: _onStop,
                    icon: const Icon(Icons.pan_tool_outlined),
                    label: Text(context.l10n.stop),
                  ),
                ValueListenableBuilder(
                  valueListenable: _cues.voiceOn,
                  builder: (context, on, _) => IconButton(
                    tooltip: on ? context.l10n.voiceOff : context.l10n.voiceOn,
                    icon: Icon(on ? Icons.record_voice_over : Icons.voice_over_off),
                    onPressed: () => _cues.voiceOn.value = !on,
                  ),
                ),
              ],
            ),
            body: finished
                ? _CompleteView(controller: _controller, onFeedback: _finish)
                : _PlayerView(
                    controller: _controller,
                    camera: _count,
                    cameraOn: _cameraOn,
                    onToggleCamera: poseRules.containsKey(_exercises[_controller.phase.exerciseIndex].id) ? _toggleCamera : null,
                    canStartRep: _canStartRep,
                    onCameraProblem: _cameraProblem,
                  ),
          ),
        );
      },
    );
  }
}

class _PlayerView extends StatelessWidget {
  const _PlayerView({
    required this.controller,
    required this.camera,
    required this.cameraOn,
    required this.onToggleCamera,
    required this.canStartRep,
    required this.onCameraProblem,
  });

  final SessionController controller;

  /// The camera's count for this exercise, shown in place of the footage.
  final CameraCount? camera;
  final bool cameraOn;

  /// Null when the camera cannot count this exercise.
  final VoidCallback? onToggleCamera;
  final bool Function() canStartRep;
  final ValueChanged<CameraProblem> onCameraProblem;

  @override
  Widget build(BuildContext context) {
    final phase = controller.phase;
    final exercise = controller.plan.exercises[phase.exerciseIndex];
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final muted = theme.colorScheme.onSurfaceVariant;
    final working = !controller.canAddTime;
    final l = context.l10n;

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
                Text(_detailLine(l, phase), style: text.bodyLarge?.copyWith(color: muted), textAlign: TextAlign.center),
                if (onToggleCamera != null)
                  TextButton.icon(
                    onPressed: onToggleCamera,
                    icon: Icon(cameraOn ? Icons.videocam_off_outlined : Icons.videocam_outlined),
                    label: Text(cameraOn ? l.stopCamera : l.countWithCamera),
                  ),
              ],
            ),
          ),
          Expanded(
            // Tap anywhere on the dial area to pause or resume.
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: controller.togglePause,
              child: LayoutBuilder(
                builder: (context, box) {
                  // The footage moves with the reps, so it gets the most room;
                  // on short screens it steps aside so the timer always fits.
                  final tutorial = tutorials[exercise.id];
                  final count = camera;
                  final showTutorial = (tutorial != null || count != null) && box.maxHeight >= 420;
                  // Room left after 12 above, 16 between and 12 below.
                  final room = box.maxHeight - (showTutorial ? 40 : 24);
                  final tutorialSize = showTutorial ? math.min(box.maxWidth - 40, (room * 0.5).clamp(150.0, 340.0)) : 0.0;
                  final dial = math.min(288.0, room - tutorialSize);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (showTutorial) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(Brand.of(context).radius + 4),
                          child: ColoredBox(
                            color: Brand.of(context).soft,
                            child: SizedBox.square(
                              dimension: tutorialSize,
                              child: count != null
                                  // Tapping the picture should not pause the session by accident.
                                  ? GestureDetector(
                                      onTap: () {},
                                      child: CameraPoseView(count: count, canStart: canStartRep, onProblem: onCameraProblem),
                                    )
                                  : TutorialFrames(
                                      tutorial: tutorial!,
                                      progress: () => tutorialProgress(controller, tutorial, exercise),
                                      repaint: controller.frames,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _PhaseDial(controller: controller, exercise: exercise, size: dial),
                    ],
                  );
                },
              ),
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
                          label: Text(l.addTime30),
                        )
                      : OutlinedButton.icon(
                          onPressed: working ? controller.finishSet : null,
                          icon: const Icon(Icons.done_all),
                          label: Text(phase.side == null ? l.finishSet : l.finishSide),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.skip,
                    icon: const Icon(Icons.skip_next),
                    label: Text(l.skip),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Text(
              l.timeLeft(clockLabel(controller.remainingTotal)),
              style: text.bodyMedium?.copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
  }

  static String _detailLine(AppLocalizations l, Phase phase) {
    final parts = <String>[
      if (phase.kind == PhaseKind.rest) l.nextSet(phase.set + 1, phase.setCount),
      if (phase.kind != PhaseKind.rest && phase.kind != PhaseKind.transition) l.setXofY(phase.set, phase.setCount),
      if (phase.rep != null) l.repXofY(phase.rep!, phase.repCount!),
      if (phase.side != null) phase.side == Side.left ? l.leftSide : l.rightSide,
    ];
    return parts.join(' · ');
  }
}

class _PhaseDial extends StatelessWidget {
  const _PhaseDial({required this.controller, required this.exercise, this.size = 288});

  final SessionController controller;
  final Exercise exercise;
  final double size;

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
      dimension: size,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _RingPainter(controller, color: color, track: Brand.of(context).ringTrack),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_label(context.l10n, phase, exercise), style: text.titleLarge, textAlign: TextAlign.center),
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
                  style: text.displayLarge?.copyWith(fontSize: size * 0.26, fontWeight: FontWeight.w600, color: colors.onSurface),
                ),
              ),
              Text(
                controller.isPaused ? context.l10n.pausedTapResume : context.l10n.tapToPause,
                style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _label(AppLocalizations l, Phase phase, Exercise exercise) => switch (phase.kind) {
    PhaseKind.prepare => phase.side == null ? l.getReady : (phase.side == Side.left ? l.leftSide : l.rightSide),
    PhaseKind.move => exercise.moveLabel,
    PhaseKind.hold => l.hold,
    PhaseKind.release => exercise.releaseLabel,
    PhaseKind.timed => l.keepGoing,
    PhaseKind.rest => l.rest,
    PhaseKind.transition => l.upNext,
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
  const _CompleteView({required this.controller, required this.onFeedback});

  final SessionController controller;

  /// Called with "easy", "ok", "hard", or null when the patient just closes.
  final ValueChanged<String?> onFeedback;

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
            Text(context.l10n.sessionComplete, style: text.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              context.l10n.completeSummary(count, clockLabel(controller.elapsed)),
              style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Text(context.l10n.howWasIt, style: text.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FeedbackButtons(onChosen: onFeedback),
            const SizedBox(height: 12),
            TextButton(onPressed: () => onFeedback(null), child: Text(context.l10n.skip)),
          ],
        ),
      ),
    );
  }
}

/// Where the tutorial footage should be at this moment of the session:
/// rising during "move", held at the top, lowering during "release".
double tutorialProgress(SessionController c, Tutorial tutorial, Exercise exercise) {
  final phase = c.phase;
  final p = c.phaseProgress;
  return switch (phase.kind) {
    PhaseKind.move => Curves.easeInOut.transform(p),
    PhaseKind.hold => 1,
    PhaseKind.release => 1 - Curves.easeInOut.transform(p),
    // Ease into a held stretch over its first 2.5 s; a pendulum keeps swinging.
    PhaseKind.timed => tutorial.sway
        ? demoProgress((c.elapsed.inMilliseconds % 3000) / 3000, tutorial)
        : Curves.easeInOut.transform((p * phase.seconds / 2.5).clamp(0.0, 1.0)),
    // After a held stretch, ease back out over the first 1.5 s of rest.
    PhaseKind.rest when exercise.prescription.isTimed && !tutorial.sway =>
      1 - Curves.easeInOut.transform((p * phase.seconds / 1.5).clamp(0.0, 1.0)),
    _ => 0,
  };
}
