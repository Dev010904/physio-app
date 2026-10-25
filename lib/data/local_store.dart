import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// One exercise as it was done in a session.
class ExerciseRecord {
  const ExerciseRecord({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.setsDone,
    required this.setsPlanned,
    required this.createdAt,
    this.itemId,
    this.repsDone,
    this.repSource = 'manual',
    this.peakAngle,
    this.pain,
    this.note,
    this.shareNote = false,
    this.synced = false,
  });

  final String id;
  final String sessionId;

  /// The bundled exercise id (slug), for history and tutorials.
  final String exerciseId;

  /// The server's program item id; null in the starter program.
  final String? itemId;
  final int setsDone;
  final int setsPlanned;
  final int? repsDone;
  final String repSource;
  final double? peakAngle;

  /// 0 to 10, or null when the patient skipped the question.
  final int? pain;

  /// Private unless [shareNote] is true.
  final String? note;
  final bool shareNote;
  final DateTime createdAt;
  final bool synced;
}

/// A session: one run of the player, whole or stopped early.
class SessionRecord {
  const SessionRecord({
    required this.id,
    required this.performedOn,
    required this.startedAt,
    this.programId,
    this.feedback,
    this.ended = false,
    this.stoppedForSafety = false,
    this.exercises = const [],
    this.synced = false,
  });

  final String id;

  /// The server program; null for the starter program, whose logs stay here.
  final String? programId;
  final DateTime performedOn;
  final DateTime startedAt;

  /// "easy", "ok" or "hard", optionally followed by the patient's words.
  final String? feedback;
  final bool ended;
  final bool stoppedForSafety;
  final List<ExerciseRecord> exercises;
  final bool synced;
}

/// A safety flag raised on the phone for the physio.
class FlagRecord {
  const FlagRecord({required this.id, required this.reason, required this.details, required this.createdAt, this.synced = false});

  final String id;

  /// 'high_pain' or 'red_flag', as the server's flags table allows.
  final String reason;
  final Map<String, dynamic> details;
  final DateTime createdAt;
  final bool synced;
}

/// Everything kept on the phone: the clinic link, the cached program, and the
/// logs, which stay here and are sent to the physio when online.
abstract interface class LocalStore {
  Future<String?> read(String key);
  Future<void> write(String key, String? value);

  Future<void> startSession(SessionRecord session);
  Future<void> addExercise(ExerciseRecord record);
  Future<void> endSession(String sessionId, {String? feedback, bool stoppedForSafety = false});
  Future<void> addFlag(FlagRecord flag);

  /// Every session with its exercises, newest first.
  Future<List<SessionRecord>> sessions();
  Future<List<SessionRecord>> unsyncedSessions();
  Future<List<FlagRecord>> unsyncedFlags();
  Future<void> markSynced({Iterable<String> sessions = const [], Iterable<String> exercises = const [], Iterable<String> flags = const []});

  /// Forgets everything, as after "Delete my data".
  Future<void> clear();
}

String _day(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// The app's store, in SQLite.
class SqliteStore implements LocalStore {
  SqliteStore._(this._db);

  static Future<SqliteStore> open() async {
    final path = p.join(await getDatabasesPath(), 'physiosathi.db');
    final db = await openDatabase(path, version: 1, onCreate: (db, _) async {
      await db.execute('create table kv (key text primary key, value text)');
      await db.execute('''create table sessions (
        id text primary key, program_id text, performed_on text not null, started_at text not null,
        feedback text, ended integer not null default 0, stopped_for_safety integer not null default 0,
        synced integer not null default 0)''');
      await db.execute('''create table exercise_logs (
        id text primary key, session_id text not null, exercise_id text not null, item_id text,
        sets_done integer not null, sets_planned integer not null, reps_done integer,
        rep_source text not null default 'manual', peak_angle real, pain integer, note text,
        share_note integer not null default 0, created_at text not null, synced integer not null default 0)''');
      await db.execute('create index exercise_logs_session on exercise_logs (session_id)');
      await db.execute('''create table flags (
        id text primary key, reason text not null, details text not null, created_at text not null,
        synced integer not null default 0)''');
    });
    return SqliteStore._(db);
  }

  final Database _db;

  @override
  Future<String?> read(String key) async {
    final rows = await _db.query('kv', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      await _db.delete('kv', where: 'key = ?', whereArgs: [key]);
    } else {
      await _db.insert('kv', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  @override
  Future<void> startSession(SessionRecord s) => _db.insert('sessions', {
    'id': s.id,
    'program_id': s.programId,
    'performed_on': _day(s.performedOn),
    'started_at': s.startedAt.toUtc().toIso8601String(),
  });

  @override
  Future<void> addExercise(ExerciseRecord r) => _db.insert('exercise_logs', {
    'id': r.id,
    'session_id': r.sessionId,
    'exercise_id': r.exerciseId,
    'item_id': r.itemId,
    'sets_done': r.setsDone,
    'sets_planned': r.setsPlanned,
    'reps_done': r.repsDone,
    'rep_source': r.repSource,
    'peak_angle': r.peakAngle,
    'pain': r.pain,
    'note': r.note,
    'share_note': r.shareNote ? 1 : 0,
    'created_at': r.createdAt.toUtc().toIso8601String(),
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  @override
  Future<void> endSession(String sessionId, {String? feedback, bool stoppedForSafety = false}) => _db.update(
    'sessions',
    {'ended': 1, 'feedback': feedback, 'stopped_for_safety': stoppedForSafety ? 1 : 0},
    where: 'id = ?',
    whereArgs: [sessionId],
  );

  @override
  Future<void> addFlag(FlagRecord f) => _db.insert('flags', {
    'id': f.id,
    'reason': f.reason,
    'details': jsonEncode(f.details),
    'created_at': f.createdAt.toUtc().toIso8601String(),
  });

  @override
  Future<List<SessionRecord>> sessions() => _sessions();

  @override
  Future<List<SessionRecord>> unsyncedSessions() => _sessions(unsyncedOnly: true);

  Future<List<SessionRecord>> _sessions({bool unsyncedOnly = false}) async {
    final rows = await _db.query('sessions', orderBy: 'started_at desc');
    final logs = await _db.query('exercise_logs', orderBy: 'created_at');
    final bySession = <String, List<ExerciseRecord>>{};
    for (final l in logs) {
      bySession.putIfAbsent(l['session_id'] as String, () => []).add(ExerciseRecord(
        id: l['id'] as String,
        sessionId: l['session_id'] as String,
        exerciseId: l['exercise_id'] as String,
        itemId: l['item_id'] as String?,
        setsDone: l['sets_done'] as int,
        setsPlanned: l['sets_planned'] as int,
        repsDone: l['reps_done'] as int?,
        repSource: l['rep_source'] as String,
        peakAngle: (l['peak_angle'] as num?)?.toDouble(),
        pain: l['pain'] as int?,
        note: l['note'] as String?,
        shareNote: l['share_note'] == 1,
        createdAt: DateTime.parse(l['created_at'] as String).toLocal(),
        synced: l['synced'] == 1,
      ));
    }
    final out = <SessionRecord>[];
    for (final s in rows) {
      final exercises = bySession[s['id']] ?? const <ExerciseRecord>[];
      final synced = s['synced'] == 1;
      if (unsyncedOnly && synced && exercises.every((e) => e.synced)) continue;
      out.add(SessionRecord(
        id: s['id'] as String,
        programId: s['program_id'] as String?,
        performedOn: DateTime.parse(s['performed_on'] as String),
        startedAt: DateTime.parse(s['started_at'] as String).toLocal(),
        feedback: s['feedback'] as String?,
        ended: s['ended'] == 1,
        stoppedForSafety: s['stopped_for_safety'] == 1,
        exercises: exercises,
        synced: synced,
      ));
    }
    return out;
  }

  @override
  Future<List<FlagRecord>> unsyncedFlags() async => [
    for (final f in await _db.query('flags', where: 'synced = 0', orderBy: 'created_at'))
      FlagRecord(
        id: f['id'] as String,
        reason: f['reason'] as String,
        details: jsonDecode(f['details'] as String) as Map<String, dynamic>,
        createdAt: DateTime.parse(f['created_at'] as String).toLocal(),
      ),
  ];

  @override
  Future<void> markSynced({Iterable<String> sessions = const [], Iterable<String> exercises = const [], Iterable<String> flags = const []}) async {
    final batch = _db.batch();
    for (final id in sessions) {
      batch.update('sessions', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
    }
    for (final id in exercises) {
      batch.update('exercise_logs', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
    }
    for (final id in flags) {
      batch.update('flags', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> clear() async {
    for (final table in ['kv', 'sessions', 'exercise_logs', 'flags']) {
      await _db.delete(table);
    }
  }
}

/// An in-memory store for tests and for running without a database.
class MemoryStore implements LocalStore {
  final _kv = <String, String>{};
  final _sessions = <String, SessionRecord>{};
  final _exercises = <String, ExerciseRecord>{};
  final _flags = <String, FlagRecord>{};

  @override
  Future<String?> read(String key) async => _kv[key];

  @override
  Future<void> write(String key, String? value) async => value == null ? _kv.remove(key) : _kv[key] = value;

  @override
  Future<void> startSession(SessionRecord session) async => _sessions[session.id] = session;

  @override
  Future<void> addExercise(ExerciseRecord record) async => _exercises[record.id] = record;

  @override
  Future<void> endSession(String sessionId, {String? feedback, bool stoppedForSafety = false}) async {
    final s = _sessions[sessionId];
    if (s == null) return;
    _sessions[sessionId] = SessionRecord(
      id: s.id,
      programId: s.programId,
      performedOn: s.performedOn,
      startedAt: s.startedAt,
      feedback: feedback,
      ended: true,
      stoppedForSafety: stoppedForSafety,
      synced: s.synced,
    );
  }

  @override
  Future<void> addFlag(FlagRecord flag) async => _flags[flag.id] = flag;

  SessionRecord _withExercises(SessionRecord s) => SessionRecord(
    id: s.id,
    programId: s.programId,
    performedOn: s.performedOn,
    startedAt: s.startedAt,
    feedback: s.feedback,
    ended: s.ended,
    stoppedForSafety: s.stoppedForSafety,
    synced: s.synced,
    exercises: [for (final e in _exercises.values) if (e.sessionId == s.id) e],
  );

  @override
  Future<List<SessionRecord>> sessions() async =>
      [for (final s in _sessions.values) _withExercises(s)]..sort((a, b) => b.startedAt.compareTo(a.startedAt));

  @override
  Future<List<SessionRecord>> unsyncedSessions() async => [
    for (final s in await sessions())
      if (!s.synced || s.exercises.any((e) => !e.synced)) s,
  ];

  @override
  Future<List<FlagRecord>> unsyncedFlags() async => [for (final f in _flags.values) if (!f.synced) f];

  @override
  Future<void> markSynced({Iterable<String> sessions = const [], Iterable<String> exercises = const [], Iterable<String> flags = const []}) async {
    for (final id in sessions) {
      final s = _sessions[id]!;
      _sessions[id] = SessionRecord(
        id: s.id,
        programId: s.programId,
        performedOn: s.performedOn,
        startedAt: s.startedAt,
        feedback: s.feedback,
        ended: s.ended,
        stoppedForSafety: s.stoppedForSafety,
        synced: true,
      );
    }
    for (final id in exercises) {
      final e = _exercises[id]!;
      _exercises[id] = ExerciseRecord(
        id: e.id,
        sessionId: e.sessionId,
        exerciseId: e.exerciseId,
        itemId: e.itemId,
        setsDone: e.setsDone,
        setsPlanned: e.setsPlanned,
        repsDone: e.repsDone,
        repSource: e.repSource,
        peakAngle: e.peakAngle,
        pain: e.pain,
        note: e.note,
        shareNote: e.shareNote,
        createdAt: e.createdAt,
        synced: true,
      );
    }
    for (final id in flags) {
      final f = _flags[id]!;
      _flags[id] = FlagRecord(id: f.id, reason: f.reason, details: f.details, createdAt: f.createdAt, synced: true);
    }
  }

  @override
  Future<void> clear() async {
    _kv.clear();
    _sessions.clear();
    _exercises.clear();
    _flags.clear();
  }
}
