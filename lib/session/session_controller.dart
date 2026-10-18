import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'session_plan.dart';

/// Receives the moments a session should be heard: phase changes, the last
/// three seconds of a phase, and the end.
abstract interface class SessionCues {
  void phaseStarted(Phase phase);
  void countdown(int secondsLeft, Phase phase);
  void finished();
}

/// Runs a [SessionPlan] in real time. Tests drive it with [advance] directly;
/// the app calls [start], which ticks it once per displayed frame.
///
/// Listeners hear only discrete changes (a new second, phase, pause or end),
/// so widgets rebuild about once a second. Painters that need every frame,
/// such as the dial, listen to [frames] instead and repaint without rebuilding.
class SessionController extends ChangeNotifier {
  SessionController(this.plan, {this.cues})
    : assert(plan.phases.isNotEmpty),
      _remaining = plan.phases.first.duration,
      _phaseLength = plan.phases.first.duration {
    _laterSeconds = List.filled(plan.phases.length, 0);
    for (var i = plan.phases.length - 2; i >= 0; i--) {
      _laterSeconds[i] = _laterSeconds[i + 1] + plan.phases[i + 1].seconds;
    }
  }

  /// A longer gap between frames means frames stopped (app hidden or the
  /// ticker muted); that time is not counted as exercise.
  static const _maxFrameGap = Duration(seconds: 1);

  final SessionPlan plan;
  final SessionCues? cues;
  late final List<int> _laterSeconds;

  int _index = 0;
  Duration _remaining;
  Duration _phaseLength;
  Duration _elapsed = Duration.zero;
  bool _begun = false;
  bool _paused = false;
  bool _finished = false;
  Ticker? _ticker;
  Duration _lastFrame = Duration.zero;
  final _frames = _FrameSignal();

  /// Fires on every frame and every change; for painters, not for rebuilds.
  Listenable get frames => _frames;

  Phase get phase => plan.phases[_index];
  int get phaseIndex => _index;
  Duration get remaining => _remaining;
  int get secondsLeft => (_remaining.inMilliseconds / 1000).ceil();
  bool get isPaused => _paused;
  bool get isFinished => _finished;

  /// Active exercise time so far (pauses excluded).
  Duration get elapsed => _elapsed;

  /// Time left in the whole session, including any time added.
  Duration get remainingTotal => _remaining + Duration(seconds: _laterSeconds[_index]);

  double get phaseProgress => _phaseLength == Duration.zero
      ? 1
      : (1 - _remaining.inMilliseconds / _phaseLength.inMilliseconds).clamp(0, 1).toDouble();

  double get sessionProgress {
    final total = _elapsed + remainingTotal;
    return total == Duration.zero ? 1 : _elapsed.inMilliseconds / total.inMilliseconds;
  }

  bool get canAddTime => phase.kind == PhaseKind.rest || phase.kind == PhaseKind.transition;

  /// Announces the first phase. Safe to call more than once.
  void begin() {
    if (_begun) return;
    _begun = true;
    cues?.phaseStarted(phase);
    _countdownFrom(phase.seconds + 1);
    _changed();
  }

  /// Ticks once per displayed frame (up to the screen's 120 Hz), so the dial
  /// moves fluidly while timing stays exact.
  void start(TickerProvider vsync) {
    begin();
    if (_ticker != null || _finished) return;
    _ticker = vsync.createTicker((now) {
      final dt = now - _lastFrame;
      _lastFrame = now;
      if (dt <= _maxFrameGap) advance(dt);
    })..start();
  }

  void advance(Duration dt) {
    if (!_begun || _paused || _finished || dt <= Duration.zero) return;
    _elapsed += dt;
    final before = secondsLeft;
    final startIndex = _index;
    _remaining -= dt;
    while (_remaining <= Duration.zero && !_finished) {
      final overflow = -_remaining;
      if (!_enter(_index + 1)) break;
      _remaining -= overflow;
    }
    if (!_finished) _countdownFrom(_index == startIndex ? before : phase.seconds + 1);
    _frames.tick();
    if (_finished || _index != startIndex || secondsLeft != before) notifyListeners();
  }

  void pause() => _setPaused(true);
  void resume() => _setPaused(false);
  void togglePause() => _setPaused(!_paused);

  /// Extends a rest or the gap between exercises, e.g. to change equipment.
  void addTime(Duration extra) {
    if (!canAddTime || _finished) return;
    _remaining += extra;
    _phaseLength += extra;
    _changed();
  }

  /// Jumps to the next phase.
  void skip() => _jump(_index + 1);

  /// Quick complete: ends the current set (or side) and moves to what follows it.
  void finishSet() {
    const boundaries = {PhaseKind.prepare, PhaseKind.rest, PhaseKind.transition};
    var next = _index + 1;
    while (next < plan.phases.length && !boundaries.contains(plan.phases[next].kind)) {
      next++;
    }
    _jump(next);
  }

  void _jump(int target) {
    if (_finished) return;
    if (_enter(target)) _countdownFrom(phase.seconds + 1);
    _changed();
  }

  /// Moves to phase [i], or finishes the session when there is none.
  bool _enter(int i) {
    if (i >= plan.phases.length) {
      _finished = true;
      _remaining = Duration.zero;
      _ticker?.stop();
      cues?.finished();
      return false;
    }
    _index = i;
    _remaining = phase.duration;
    _phaseLength = phase.duration;
    cues?.phaseStarted(phase);
    return true;
  }

  void _countdownFrom(int previousSecondsLeft) {
    // Rep halves are paced by tones; counting them down would beep every rep.
    if (phase.kind == PhaseKind.move || phase.kind == PhaseKind.release) return;
    final now = secondsLeft;
    if (now != previousSecondsLeft && now >= 1 && now <= 3) cues?.countdown(now, phase);
  }

  void _setPaused(bool value) {
    if (_finished || _paused == value) return;
    _paused = value;
    _changed();
  }

  void _changed() {
    _frames.tick();
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _frames.dispose();
    super.dispose();
  }
}

class _FrameSignal extends ChangeNotifier {
  void tick() => notifyListeners();
}
