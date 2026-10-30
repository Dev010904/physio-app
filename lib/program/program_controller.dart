import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/local_store.dart';
import '../exercises/exercise.dart';
import 'program.dart';

/// The patient's link to a clinic, kept on the phone so it works offline.
class CareLink {
  const CareLink({
    required this.patientId,
    required this.displayName,
    this.language = 'en',
    this.clinicName,
    this.clinicPhone,
    this.clinicianName,
    this.clinicianPhone,
  });

  factory CareLink.fromJson(Map<String, dynamic> j) => CareLink(
    patientId: j['patientId'] as String,
    displayName: j['displayName'] as String,
    language: j['language'] as String? ?? 'en',
    clinicName: j['clinicName'] as String?,
    clinicPhone: j['clinicPhone'] as String?,
    clinicianName: j['clinicianName'] as String?,
    clinicianPhone: j['clinicianPhone'] as String?,
  );

  final String patientId;
  final String displayName;
  final String language;
  final String? clinicName;
  final String? clinicPhone;
  final String? clinicianName;
  final String? clinicianPhone;

  /// The number to call about a problem: the physio's own, else the clinic's.
  String? get phone => clinicianPhone ?? clinicPhone;

  Map<String, dynamic> toJson() => {
    'patientId': patientId,
    'displayName': displayName,
    'language': language,
    'clinicName': ?clinicName,
    'clinicPhone': ?clinicPhone,
    'clinicianName': ?clinicianName,
    'clinicianPhone': ?clinicianPhone,
  };
}

/// What the server can do for the patient app. The Supabase version lives in
/// lib/sync/supabase_backend.dart; tests use a fake.
abstract interface class ProgramBackend {
  /// Signs this phone in and links it to the patient behind [code].
  Future<CareLink> link(String code);

  /// The newest version of the patient's program, as a `programs` row with
  /// `program_items` and their `exercises` embedded; null when there is none.
  Future<Map<String, dynamic>?> latestProgram();

  /// Sends sessions (with their exercises) and flags. Each id is made on the
  /// phone, so sending the same record twice changes nothing.
  Future<void> push(String patientId, List<SessionRecord> sessions, List<FlagRecord> flags);

  /// Deletes the patient's record at the clinic and signs this phone out.
  Future<void> deleteMyData();
}

enum SyncState { idle, syncing, offline }

/// The program the patient follows, where it came from, and its sync state.
class ProgramController extends ChangeNotifier {
  ProgramController._(this.library, this.store, this.backend, this._program, this._link, this._updated);

  static const _linkKey = 'care_link';
  static const _programKey = 'program';
  static const _updatedKey = 'program_updated';

  /// A session left open longer than this (the app was closed mid-way) is
  /// sent as it is.
  static const _staleSession = Duration(hours: 6);

  /// The starter program with nothing stored yet; for tests and builds
  /// without a clinic server.
  factory ProgramController.starter(ExerciseLibrary library, {LocalStore? store, ProgramBackend? backend}) =>
      ProgramController._(library, store ?? MemoryStore(), backend, Program.starter(library), null, false);

  static Future<ProgramController> load({
    required ExerciseLibrary library,
    required LocalStore store,
    ProgramBackend? backend,
  }) async {
    final linkJson = await store.read(_linkKey);
    final programJson = await store.read(_programKey);
    final link = linkJson == null ? null : CareLink.fromJson(jsonDecode(linkJson) as Map<String, dynamic>);
    final program = link != null && programJson != null
        ? Program.fromJson(jsonDecode(programJson) as Map<String, dynamic>)
        : Program.starter(library);
    return ProgramController._(library, store, backend, program, link, await store.read(_updatedKey) == 'true');
  }

  final ExerciseLibrary library;
  final LocalStore store;
  final ProgramBackend? backend;

  Program _program;
  CareLink? _link;
  bool _updated;
  SyncState _state = SyncState.idle;

  /// Bumped whenever a session is logged, so progress views reload.
  final ValueNotifier<int> logRevision = ValueNotifier(0);

  void logsChanged() => logRevision.value++;

  Program get program => _program;
  CareLink? get link => _link;
  bool get isLinked => _link != null;
  bool get canLink => backend != null;

  /// True after a newer version arrived, until the patient dismisses the note.
  bool get programUpdated => _updated;
  SyncState get state => _state;

  /// Links this phone with the physio's code, then downloads the program.
  /// Throws with a message for the patient when the code is not accepted.
  Future<void> linkWithCode(String code) async {
    final backend = this.backend;
    if (backend == null) throw StateError('This build cannot reach the clinic server.');
    final link = await backend.link(code);
    _link = link;
    await store.write(_linkKey, jsonEncode(link.toJson()));
    // A new link starts from the physio's program, not the starter one.
    _program = Program(title: 'Your program', entries: const []);
    await refresh(markUpdate: false);
    notifyListeners();
  }

  /// Downloads the newest program. Returns true when a newer version arrived.
  Future<bool> refresh({bool markUpdate = true}) async {
    final backend = this.backend;
    final link = _link;
    if (backend == null || link == null) return false;
    final row = await backend.latestProgram();
    if (row == null) return false;
    final next = Program.fromServer(row);
    if (next.version == _program.version && next.id == _program.id) return false;
    final wasLinkedProgram = _program.fromClinic;
    _program = next;
    await store.write(_programKey, jsonEncode(next.toJson()));
    if (markUpdate && wasLinkedProgram) {
      _updated = true;
      await store.write(_updatedKey, 'true');
    }
    notifyListeners();
    return true;
  }

  /// Sends waiting logs and fetches program changes. Safe to call any time:
  /// with no connection it leaves everything queued for next time.
  Future<bool> sync() async {
    final backend = this.backend;
    final link = _link;
    if (backend == null || link == null || _state == SyncState.syncing) return false;
    _setState(SyncState.syncing);
    try {
      await pushPending(backend, link.patientId);
      final changed = await refresh();
      _setState(SyncState.idle);
      return changed;
    } catch (e) {
      debugPrint('sync failed: $e');
      _setState(SyncState.offline);
      return false;
    }
  }

  /// Sends ended clinic sessions, their exercises, and flags.
  @visibleForTesting
  Future<void> pushPending(ProgramBackend backend, String patientId) async {
    final now = DateTime.now();
    final sessions = [
      for (final s in await store.unsyncedSessions())
        if (s.programId != null && (s.ended || now.difference(s.startedAt) > _staleSession)) s,
    ];
    final flags = await store.unsyncedFlags();
    if (sessions.isEmpty && flags.isEmpty) return;
    await backend.push(patientId, sessions, flags);
    await store.markSynced(
      sessions: [for (final s in sessions) s.id],
      exercises: [
        for (final s in sessions)
          for (final e in s.exercises)
            if (e.itemId != null) e.id,
      ],
      flags: [for (final f in flags) f.id],
    );
  }

  Future<void> dismissUpdate() async {
    _updated = false;
    await store.write(_updatedKey, null);
    notifyListeners();
  }

  /// Deletes everything about the patient: first their record at the clinic
  /// when linked, which needs the internet (if that fails, it throws and
  /// nothing is deleted), then every log, note and link on this phone.
  Future<void> deleteAllData() async {
    final backend = this.backend;
    if (_link != null && backend != null) await backend.deleteMyData();
    await store.clear();
    _link = null;
    _updated = false;
    _program = Program.starter(library);
    logsChanged();
    notifyListeners();
  }

  /// Forgets the clinic link on this phone and returns to the starter program.
  /// Logs already on the phone stay for the patient's own history.
  Future<void> unlink() async {
    _link = null;
    _updated = false;
    _program = Program.starter(library);
    await store.write(_linkKey, null);
    await store.write(_programKey, null);
    await store.write(_updatedKey, null);
    notifyListeners();
  }

  void _setState(SyncState s) {
    if (_state == s) return;
    _state = s;
    notifyListeners();
  }
}
