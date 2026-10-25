import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:physio_app/data/local_store.dart';
import 'package:physio_app/exercises/exercise.dart';
import 'package:physio_app/program/program.dart';
import 'package:physio_app/program/program_controller.dart';

Map<String, dynamic> _serverProgram({required int version, String id = 'prog-1'}) => {
  'id': id,
  'version': version,
  'clinician_notes': 'Go gently this week',
  'program_items': [
    {
      'id': 'item-2',
      'position': 2,
      'sets': 3,
      'reps': null,
      'duration_seconds': 30,
      'hold_seconds': 0,
      'rest_seconds': 15,
      'per_side': true,
      'move_seconds': 2,
      'release_seconds': 2,
      'days_of_week': [1, 3, 5],
      'notes': null,
      'exercises': {
        'id': 'ex-calf',
        'slug': 'calf_stretch',
        'title_en': 'Calf stretch',
        'title_hi': 'पिंडली स्ट्रेच',
        'steps_en': ['Face a wall.'],
        'steps_hi': <String>[],
        'body_region': 'ankle',
        'equipment': ['wall'],
      },
    },
    {
      'id': 'item-1',
      'position': 1,
      'sets': 2,
      'reps': 10,
      'duration_seconds': null,
      'hold_seconds': 5,
      'rest_seconds': 30,
      'per_side': false,
      'move_seconds': 2,
      'release_seconds': 3,
      'days_of_week': [1, 2, 3, 4, 5, 6, 7],
      'notes': 'Only to 45 degrees',
      'exercises': {
        'id': 'ex-wall',
        'slug': 'wall_squat',
        'title_en': 'Wall squat',
        'steps_en': ['Stand with your back to a wall.'],
        'body_region': 'knee',
        'equipment': ['wall'],
        'move_label_en': 'Slide down',
        'release_label_en': 'Slide up',
      },
    },
  ],
};

class _FakeBackend implements ProgramBackend {
  Map<String, dynamic>? program;
  final pushed = <String>[];
  bool offline = false;

  @override
  Future<CareLink> link(String code) async {
    if (code != 'ABCD2345') throw Exception('bad code');
    return const CareLink(patientId: 'pat-1', displayName: 'Ravi', clinicName: 'Clinic A', clinicianPhone: '+91 90000 00001');
  }

  @override
  Future<Map<String, dynamic>?> latestProgram() async {
    if (offline) throw const SocketException('offline');
    return program;
  }

  @override
  Future<void> push(String patientId, List<SessionRecord> sessions, List<FlagRecord> flags) async {
    if (offline) throw const SocketException('offline');
    pushed.addAll([for (final s in sessions) 'session:${s.id}', for (final f in flags) 'flag:${f.id}']);
  }
}

void main() {
  final library = ExerciseLibrary.fromJson(File('assets/exercises/starter_exercises.json').readAsStringSync());

  test('a server program becomes ordered entries with their own doses and days', () {
    final program = Program.fromServer(_serverProgram(version: 3));
    expect(program.version, 3);
    expect(program.notes, 'Go gently this week');
    expect([for (final e in program.entries) e.exercise.id], ['wall_squat', 'calf_stretch']);

    final wall = program.entries.first;
    expect(wall.itemId, 'item-1');
    expect(wall.note, 'Only to 45 degrees');
    expect(wall.exercise.moveLabel, 'Slide down');
    expect(wall.exercise.prescription.releaseSeconds, 3);

    final calf = program.entries.last;
    expect(calf.exercise.prescription.isTimed, isTrue);
    expect(calf.exercise.prescription.perSide, isTrue);
    expect(program.on(DateTime(2026, 10, 26)).length, 2, reason: 'a Monday');
    expect(program.on(DateTime(2026, 10, 27)).length, 1, reason: 'a Tuesday');
  });

  test('Hindi patients get Hindi text where the library has it', () {
    final program = Program.fromServer(_serverProgram(version: 1)).inLanguage('hi');
    expect(program.entries.last.exercise.title, 'पिंडली स्ट्रेच');
    expect(program.entries.last.exercise.steps, ['Face a wall.'], reason: 'no Hindi steps yet, so English');
    expect(program.inLanguage('en').entries.last.exercise.title, 'Calf stretch', reason: 'switches back offline');
    final cached = Program.fromJson(program.toJson()).inLanguage('hi');
    expect(cached.entries.last.exercise.title, 'पिंडली स्ट्रेच', reason: 'Hindi survives the phone cache');
  });

  test('a cached program survives a save and reload unchanged', () {
    final program = Program.fromServer(_serverProgram(version: 2));
    final again = Program.fromJson(program.toJson());
    expect(again.version, 2);
    expect(again.entries.last.days, {1, 3, 5});
    expect(again.entries.first.exercise.prescription.summary, program.entries.first.exercise.prescription.summary);
  });

  test('linking downloads the program; a newer version raises the update note', () async {
    final backend = _FakeBackend()..program = _serverProgram(version: 1);
    final store = MemoryStore();
    final c = await ProgramController.load(library: library, store: store, backend: backend);
    expect(c.isLinked, isFalse);
    expect(c.program.fromClinic, isFalse);

    await c.linkWithCode('ABCD2345');
    expect(c.isLinked, isTrue);
    expect(c.program.version, 1);
    expect(c.programUpdated, isFalse, reason: 'the first download is not an update');

    backend.program = _serverProgram(version: 2);
    expect(await c.sync(), isTrue);
    expect(c.programUpdated, isTrue);

    // A fresh start reads the link and program back from the phone.
    final reopened = await ProgramController.load(library: library, store: store, backend: backend);
    expect(reopened.program.version, 2);
    expect(reopened.link!.phone, '+91 90000 00001');
  });

  test('only ended clinic sessions are sent, and offline keeps them queued', () async {
    final backend = _FakeBackend()..program = _serverProgram(version: 1);
    final store = MemoryStore();
    final c = await ProgramController.load(library: library, store: store, backend: backend);
    await c.linkWithCode('ABCD2345');

    final now = DateTime.now();
    await store.startSession(SessionRecord(id: 'clinic-ended', programId: 'prog-1', performedOn: now, startedAt: now));
    await store.endSession('clinic-ended', feedback: 'ok');
    await store.startSession(SessionRecord(id: 'clinic-open', programId: 'prog-1', performedOn: now, startedAt: now));
    await store.startSession(SessionRecord(id: 'starter', performedOn: now, startedAt: now));
    await store.endSession('starter');
    await store.addFlag(FlagRecord(id: 'f1', reason: 'high_pain', details: const {'pain': 8}, createdAt: now));

    backend.offline = true;
    await c.sync();
    expect(c.state, SyncState.offline);
    expect(backend.pushed, isEmpty);

    backend.offline = false;
    await c.sync();
    expect(backend.pushed, unorderedEquals(['session:clinic-ended', 'flag:f1']));

    backend.pushed.clear();
    await c.sync();
    expect(backend.pushed, isEmpty, reason: 'nothing is sent twice');
  });
}
