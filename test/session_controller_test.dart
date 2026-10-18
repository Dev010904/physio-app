import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/exercises/exercise.dart';
import 'package:physio_app/session/session_controller.dart';
import 'package:physio_app/session/session_plan.dart';

class RecordingCues implements SessionCues {
  final events = <String>[];

  @override
  void phaseStarted(Phase phase) => events.add('start:${phase.kind.name}');

  @override
  void countdown(int secondsLeft, Phase phase) => events.add('count:$secondsLeft');

  @override
  void finished() => events.add('finished');
}

SessionController controllerFor(Prescription rx, {RecordingCues? cues}) => SessionController(
  SessionPlan.build([
    Exercise(id: 'x', title: 'X', bodyRegion: 'knee', steps: const ['Do it'], prescription: rx),
  ]),
  cues: cues,
)..begin();

const second = Duration(seconds: 1);

void advanceSeconds(SessionController c, int seconds) {
  // Real ticks are 100 ms; stepping in tenths catches every countdown second.
  for (var i = 0; i < seconds * 10; i++) {
    c.advance(const Duration(milliseconds: 100));
  }
}

void main() {
  test('count-in counts 3, 2, 1 and then the rep starts', () {
    final cues = RecordingCues();
    final c = controllerFor(const Prescription(sets: 1, reps: 1, holdSeconds: 5), cues: cues);
    advanceSeconds(c, 3);
    expect(cues.events, ['start:prepare', 'count:3', 'count:2', 'count:1', 'start:move']);
  });

  test('a 30 s hold counts down in real time and only calls the last 3 seconds', () {
    final cues = RecordingCues();
    final c = controllerFor(const Prescription(sets: 1, reps: 1, holdSeconds: 30), cues: cues);
    advanceSeconds(c, 3 + 2); // count-in + move
    expect(c.phase.kind, PhaseKind.hold);
    expect(c.secondsLeft, 30);

    cues.events.clear();
    advanceSeconds(c, 20);
    expect(c.secondsLeft, 10);
    expect(cues.events, isEmpty);

    advanceSeconds(c, 10);
    expect(cues.events, ['count:3', 'count:2', 'count:1', 'start:release']);
  });

  test('time stands still while paused', () {
    final c = controllerFor(const Prescription(sets: 1, reps: 1, holdSeconds: 30));
    c.pause();
    advanceSeconds(c, 10);
    expect(c.phase.kind, PhaseKind.prepare);
    expect(c.secondsLeft, 3);
    c.resume();
    advanceSeconds(c, 1);
    expect(c.secondsLeft, 2);
  });

  test('+30 s works during rest only', () {
    final c = controllerFor(const Prescription(sets: 2, reps: 1, restSeconds: 30));
    c.addTime(const Duration(seconds: 30));
    expect(c.secondsLeft, 3, reason: 'no extra time during the count-in');

    c.finishSet();
    expect(c.phase.kind, PhaseKind.rest);
    c.addTime(const Duration(seconds: 30));
    expect(c.secondsLeft, 60);
  });

  test('quick complete ends the set and goes to rest', () {
    final c = controllerFor(const Prescription(sets: 2, reps: 10, holdSeconds: 5));
    advanceSeconds(c, 4);
    expect(c.phase.kind, PhaseKind.move);
    c.finishSet();
    expect(c.phase.kind, PhaseKind.rest);
  });

  test('skipping past the last phase finishes the session once', () {
    final cues = RecordingCues();
    final c = controllerFor(const Prescription(sets: 1, reps: 1), cues: cues);
    for (var i = 0; i < 10; i++) {
      c.skip();
    }
    expect(c.isFinished, isTrue);
    expect(cues.events.where((e) => e == 'finished'), hasLength(1));
    expect(c.sessionProgress, 1);
  });

  test('a full session runs to the end in exactly its planned time', () {
    const rx = Prescription(sets: 2, reps: 3, holdSeconds: 5, restSeconds: 20, perSide: true);
    final c = controllerFor(rx);
    final planned = SessionPlan.exerciseDuration(rx).inSeconds;
    advanceSeconds(c, planned - 1);
    expect(c.isFinished, isFalse);
    advanceSeconds(c, 1);
    expect(c.isFinished, isTrue);
    expect(c.elapsed, Duration(seconds: planned));
  });
}
