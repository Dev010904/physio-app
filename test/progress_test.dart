import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:physio_app/data/local_store.dart';
import 'package:physio_app/exercises/exercise.dart';
import 'package:physio_app/program/program.dart';
import 'package:physio_app/progress/progress.dart';

void main() {
  final library = ExerciseLibrary.fromJson(File('assets/exercises/starter_exercises.json').readAsStringSync());
  final everyDay = Program.starter(library);
  // Mon, Wed, Fri only.
  final mwf = Program(
    title: 'MWF',
    entries: [ProgramEntry(exercise: library.exercises.first, days: const {1, 3, 5})],
  );

  SessionRecord on(DateTime day, {List<ExerciseRecord> exercises = const []}) =>
      SessionRecord(id: '${day.toIso8601String()}-${exercises.length}', performedOn: day, startedAt: day.add(const Duration(hours: 9)), ended: true, exercises: exercises);

  // Thursday 29 October 2026.
  final thu = DateTime(2026, 10, 29);
  DateTime daysAgo(int n) => thu.subtract(Duration(days: n));

  test('no sessions yet: no streak, no adherence, days before starting are not "missed"', () {
    final p = Progress(everyDay, const [], today: thu);
    expect(p.hasHistory, isFalse);
    expect(p.streak, 0);
    expect(p.adherence(), isNull);
    expect(p.statusOn(daysAgo(3)), DayStatus.before);
    expect(p.statusOn(thu), DayStatus.before);
  });

  test('today still due does not break the streak or count against adherence', () {
    final p = Progress(everyDay, [on(daysAgo(1)), on(daysAgo(2)), on(daysAgo(3))], today: thu);
    expect(p.statusOn(thu), DayStatus.due);
    expect(p.streak, 3);
    expect(p.adherence(), 1.0, reason: 'only days since the first session count');
  });

  test('a missed scheduled day ends the streak and lowers adherence', () {
    final p = Progress(everyDay, [on(thu), on(daysAgo(1)), on(daysAgo(3)), on(daysAgo(4))], today: thu);
    expect(p.statusOn(daysAgo(2)), DayStatus.missed);
    expect(p.streak, 2);
    expect(p.adherence(), closeTo(4 / 5, 1e-9));
  });

  test('rest days neither break the streak nor count in adherence', () {
    // Done Mon 26, Wed 28; Tue and Thu-morning are not scheduled/due.
    final p = Progress(mwf, [on(DateTime(2026, 10, 26)), on(DateTime(2026, 10, 28))], today: thu);
    expect(p.statusOn(DateTime(2026, 10, 27)), DayStatus.rest);
    expect(p.statusOn(thu), DayStatus.rest);
    expect(p.streak, 2);
    expect(p.adherence(), 1.0);
  });

  test('history groups each exercise newest first', () {
    ExerciseRecord rec(String id, DateTime at, int pain) => ExerciseRecord(
      id: id,
      sessionId: 's',
      exerciseId: 'wall_squat',
      setsDone: 2,
      setsPlanned: 2,
      pain: pain,
      createdAt: at,
    );
    final p = Progress(everyDay, [
      on(daysAgo(2), exercises: [rec('a', daysAgo(2), 4)]),
      on(daysAgo(1), exercises: [rec('b', daysAgo(1), 2)]),
    ], today: thu);
    final history = p.historyByExercise['wall_squat']!;
    expect([for (final h in history) h.record.pain], [2, 4]);
    expect(p.recentDays().length, 14);
    expect(p.recentDays().last.$1, thu);
  });
}
