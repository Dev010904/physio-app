import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:physio_app/data/local_store.dart';
import 'package:physio_app/exercises/exercise.dart';
import 'package:physio_app/program/program.dart';
import 'package:physio_app/session/session_log.dart';
import 'package:physio_app/session/session_plan.dart';

void main() {
  final library = ExerciseLibrary.fromJson(File('assets/exercises/starter_exercises.json').readAsStringSync());
  final byId = {for (final e in library.exercises) e.id: e};

  SessionLogger logger(LocalStore store, List<ProgramEntry> entries) {
    var n = 0;
    return SessionLogger(
      store: store,
      entries: entries,
      programId: 'prog-1',
      clock: () => DateTime(2026, 10, 26, 9),
      newId: () => 'id-${n++}',
    );
  }

  test('pain of 8 or more stops the session; 7 does not', () {
    expect(SafetyRules.painNeedsStop(7), isFalse);
    expect(SafetyRules.painNeedsStop(8), isTrue);
    expect(SafetyRules.painNeedsStop(10), isTrue);
  });

  test('a full run records every set and rep reached, with pain and a private note', () async {
    final store = MemoryStore();
    final entries = [
      ProgramEntry(exercise: byId['quad_set']!, itemId: 'item-1'), // 2 sets × 10 reps
      ProgramEntry(exercise: byId['calf_stretch']!, itemId: 'item-2'), // timed, per side
    ];
    final log = logger(store, entries);
    await log.start();
    for (final phase in SessionPlan.build([for (final e in entries) e.exercise]).phases) {
      log.phaseEntered(phase);
    }

    expect(log.setsDone(0), 2);
    expect(log.repsDone(0), 20);
    expect(log.setsDone(1), 3);
    expect(log.repsDone(1), isNull, reason: 'timed exercises have no reps');

    await log.exerciseDone(0, const PainAnswer(pain: 2, note: '  left knee stiff ', shareNote: false));
    await log.exerciseDone(0, const PainAnswer(pain: 9)); // asked twice: only the first counts
    await log.exerciseDone(1, const PainAnswer());
    await log.end(feedback: 'ok');
    await log.end(feedback: 'hard'); // the first end wins

    final session = (await store.sessions()).single;
    expect(session.programId, 'prog-1');
    expect(session.ended, isTrue);
    expect(session.feedback, 'ok');
    expect(session.exercises, hasLength(2));
    final quad = session.exercises.firstWhere((e) => e.exerciseId == 'quad_set');
    expect(quad.pain, 2);
    expect(quad.note, 'left knee stiff');
    expect(quad.shareNote, isFalse);
    expect(quad.itemId, 'item-1');
    expect(session.exercises.firstWhere((e) => e.exerciseId == 'calf_stretch').pain, isNull);
  });

  test("reps the camera counted replace the timer's, with the best movement", () async {
    final store = MemoryStore();
    final entries = [ProgramEntry(exercise: byId['wall_squat']!), ProgramEntry(exercise: byId['glute_bridge']!)];
    final log = logger(store, entries);
    for (final phase in SessionPlan.build([for (final e in entries) e.exercise]).phases) {
      log.phaseEntered(phase);
    }
    log.cameraCounted(0, reps: 17, peak: 52.4);
    await log.exerciseDone(0, const PainAnswer(pain: 1));
    await log.exerciseDone(1, const PainAnswer(pain: 1));

    final rows = (await store.sessions()).single.exercises;
    final squat = rows.firstWhere((e) => e.exerciseId == 'wall_squat');
    expect((squat.repsDone, squat.repSource, squat.peakAngle), (17, 'camera', 52.4));
    final bridge = rows.firstWhere((e) => e.exerciseId == 'glute_bridge');
    expect((bridge.repsDone, bridge.repSource, bridge.peakAngle), (20, 'manual', null));
  });

  test('skipping part of an exercise lowers the sets and reps done', () async {
    final store = MemoryStore();
    final entries = [ProgramEntry(exercise: byId['quad_set']!)];
    final log = logger(store, entries);
    // Only the first set's first 4 reps were reached before "Finish set" and "Skip".
    final phases = SessionPlan.build([entries.first.exercise]).phases;
    for (final p in phases.where((p) => p.set == 1 && (p.rep ?? 0) <= 4)) {
      log.phaseEntered(p);
    }
    expect(log.setsDone(0), 1);
    expect(log.repsDone(0), 4);
  });

  test('a flag carries its session, and a safety stop is marked on the session', () async {
    final store = MemoryStore();
    final log = logger(store, [ProgramEntry(exercise: byId['wall_squat']!, itemId: 'item-1')]);
    await log.exerciseDone(0, const PainAnswer(pain: 8));
    await log.raiseFlag('high_pain', {'pain': 8, 'exercise': 'wall_squat'});
    await log.end(stoppedForSafety: true);

    final flag = (await store.unsyncedFlags()).single;
    expect(flag.reason, 'high_pain');
    expect(flag.details['session_id'], log.sessionId);
    expect((await store.sessions()).single.stoppedForSafety, isTrue);
  });
}
