import '../exercises/exercise.dart';

enum PhaseKind {
  /// Short count-in before each set (or each side of a set).
  prepare,

  /// First half of a rep (lift, slide down, tighten...).
  move,
  hold,

  /// Second half of a rep (lower, relax...). Gets its own tone.
  release,

  /// A timed hold such as a stretch.
  timed,
  rest,

  /// Pause between two exercises.
  transition,
}

enum Side { left, right }

/// One step of a session. Every duration comes from the prescription, never
/// from a video's length.
class Phase {
  const Phase({
    required this.kind,
    required this.seconds,
    required this.exerciseIndex,
    required this.set,
    required this.setCount,
    this.rep,
    this.repCount,
    this.side,
  });

  final PhaseKind kind;
  final int seconds;
  final int exerciseIndex;
  final int set;
  final int setCount;
  final int? rep;
  final int? repCount;
  final Side? side;

  Duration get duration => Duration(seconds: seconds);
}

class SessionPlan {
  SessionPlan(this.exercises, this.phases);

  /// Seconds of count-in before each set or side.
  static const prepareSeconds = 3;

  /// Seconds between two exercises; the patient can skip or extend it.
  static const transitionSeconds = 20;

  factory SessionPlan.build(List<Exercise> exercises) {
    final phases = <Phase>[];
    for (var i = 0; i < exercises.length; i++) {
      final rx = exercises[i].prescription;
      final sides = rx.perSide ? Side.values : const <Side?>[null];
      for (var set = 1; set <= rx.sets; set++) {
        for (final side in sides) {
          Phase phase(PhaseKind kind, int seconds, {int? rep}) => Phase(
            kind: kind,
            seconds: seconds,
            exerciseIndex: i,
            set: set,
            setCount: rx.sets,
            rep: rep,
            repCount: rx.reps,
            side: side,
          );

          phases.add(phase(PhaseKind.prepare, prepareSeconds));
          if (rx.isTimed) {
            phases.add(phase(PhaseKind.timed, rx.durationSeconds!));
          } else {
            for (var rep = 1; rep <= rx.reps!; rep++) {
              phases.add(phase(PhaseKind.move, rx.moveSeconds, rep: rep));
              if (rx.holdSeconds > 0) phases.add(phase(PhaseKind.hold, rx.holdSeconds, rep: rep));
              phases.add(phase(PhaseKind.release, rx.releaseSeconds, rep: rep));
            }
          }
        }
        if (set < rx.sets) {
          phases.add(Phase(
            kind: PhaseKind.rest,
            seconds: rx.restSeconds,
            exerciseIndex: i,
            set: set,
            setCount: rx.sets,
          ));
        }
      }
      if (i < exercises.length - 1) {
        phases.add(Phase(
          kind: PhaseKind.transition,
          seconds: transitionSeconds,
          exerciseIndex: i + 1,
          set: 0,
          setCount: exercises[i + 1].prescription.sets,
        ));
      }
    }
    return SessionPlan(exercises, phases);
  }

  final List<Exercise> exercises;
  final List<Phase> phases;

  Duration get totalDuration => Duration(seconds: phases.fold(0, (sum, p) => sum + p.seconds));

  /// Time for one set of [rx] on one side, including its count-in.
  static Duration setDuration(Prescription rx) {
    final work = rx.isTimed
        ? rx.durationSeconds!
        : rx.reps! * (rx.moveSeconds + rx.holdSeconds + rx.releaseSeconds);
    return Duration(seconds: prepareSeconds + work);
  }

  /// Time for the whole exercise: every set and side, plus rests between sets.
  static Duration exerciseDuration(Prescription rx) {
    final sides = rx.perSide ? 2 : 1;
    final seconds = rx.sets * sides * setDuration(rx).inSeconds + (rx.sets - 1) * rx.restSeconds;
    return Duration(seconds: seconds);
  }
}
