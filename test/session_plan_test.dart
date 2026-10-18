import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/exercises/exercise.dart';
import 'package:physio_app/session/session_plan.dart';

Exercise exercise(Prescription rx, {String id = 'x'}) =>
    Exercise(id: id, title: id, bodyRegion: 'knee', steps: const ['Do it'], prescription: rx);

void main() {
  group('timer comes from the prescription, never the video', () {
    // Medbridge GO review (Jul 2025): "3 reps with a 30 second hold" got a 25 s timer.
    const holdComplaint = Prescription(sets: 1, reps: 3, holdSeconds: 30, moveSeconds: 2, releaseSeconds: 2);

    test('3 reps with a 30 s hold takes 105 s, not 25 s', () {
      expect(SessionPlan.setDuration(holdComplaint), const Duration(seconds: 3 + 3 * (2 + 30 + 2)));
    });

    test('every hold phase lasts the full 30 s', () {
      final holds = SessionPlan.build([exercise(holdComplaint)])
          .phases
          .where((p) => p.kind == PhaseKind.hold);
      expect(holds, hasLength(3));
      expect(holds.every((p) => p.seconds == 30), isTrue);
    });
  });

  test('a rep is move, hold, release after a count-in', () {
    final plan = SessionPlan.build([
      exercise(const Prescription(sets: 1, reps: 1, holdSeconds: 5)),
    ]);
    expect(plan.phases.map((p) => p.kind), [
      PhaseKind.prepare,
      PhaseKind.move,
      PhaseKind.hold,
      PhaseKind.release,
    ]);
  });

  test('no hold phase when the hold is 0 s', () {
    final plan = SessionPlan.build([exercise(const Prescription(sets: 1, reps: 2))]);
    expect(plan.phases.where((p) => p.kind == PhaseKind.hold), isEmpty);
  });

  test('per-side exercises do left then right, and rest only between sets', () {
    final plan = SessionPlan.build([
      exercise(const Prescription(sets: 2, reps: 1, restSeconds: 30, perSide: true)),
    ]);
    final outline = plan.phases
        .where((p) => p.kind == PhaseKind.prepare || p.kind == PhaseKind.rest)
        .map((p) => p.kind == PhaseKind.rest ? 'rest' : '${p.set}-${p.side!.name}')
        .toList();
    expect(outline, ['1-left', '1-right', 'rest', '2-left', '2-right']);
  });

  test('timed exercises hold for their duration each set', () {
    final plan = SessionPlan.build([
      exercise(const Prescription(sets: 3, durationSeconds: 30, restSeconds: 15)),
    ]);
    final timed = plan.phases.where((p) => p.kind == PhaseKind.timed).toList();
    expect(timed.map((p) => p.seconds), [30, 30, 30]);
    expect(plan.phases.where((p) => p.kind == PhaseKind.rest), hasLength(2));
  });

  test('a transition sits between exercises, not after the last', () {
    const rx = Prescription(sets: 1, reps: 1);
    final plan = SessionPlan.build([exercise(rx, id: 'a'), exercise(rx, id: 'b')]);
    final transitions = plan.phases.where((p) => p.kind == PhaseKind.transition).toList();
    expect(transitions, hasLength(1));
    expect(transitions.single.exerciseIndex, 1);
    expect(plan.phases.last.kind, PhaseKind.release);
  });

  test('exercise duration matches the built plan', () {
    const rx = Prescription(sets: 2, reps: 10, holdSeconds: 3, restSeconds: 30, perSide: true);
    final plan = SessionPlan.build([exercise(rx)]);
    expect(plan.totalDuration, SessionPlan.exerciseDuration(rx));
  });

  test('the bundled starter library loads 10 valid exercises', () {
    final library = ExerciseLibrary.fromJson(
      File('assets/exercises/starter_exercises.json').readAsStringSync(),
    );
    expect(library.exercises, hasLength(10));
    expect(library.exercises.map((e) => e.id).toSet(), hasLength(10));
    expect(library.demoProgram, isNotEmpty);
    expect(library.reviewedByPhysio, isFalse, reason: 'flip only after a physiotherapist signs off');
    for (final e in library.exercises) {
      expect(e.steps, isNotEmpty, reason: e.id);
      expect(SessionPlan.exerciseDuration(e.prescription), greaterThan(Duration.zero), reason: e.id);
    }
  });
}
