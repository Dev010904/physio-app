import 'package:uuid/uuid.dart';

import '../data/local_store.dart';
import '../program/program.dart';
import 'session_plan.dart';

/// Fixed safety rules. These are plain code, never AI, so they behave the
/// same way every time.
abstract final class SafetyRules {
  /// Pain at or above this ends the session and tells the physio.
  static const stopPain = 8;

  static bool painNeedsStop(int pain) => pain >= stopPain;
}

/// Symptoms that end a session at once and flag the physio. Their wording
/// is in lib/l10n (redFlagLabel).
enum RedFlag { chestPain, numbness, severePain, fall }

/// The patient's answer after an exercise.
class PainAnswer {
  const PainAnswer({this.pain, this.note, this.shareNote = false});

  final int? pain;
  final String? note;
  final bool shareNote;
}

/// Records one run of the player on the phone: each exercise as it ends,
/// any safety flags, and the patient's feedback. Nothing here needs the
/// internet; the program controller sends it later.
class SessionLogger {
  SessionLogger({required this.store, required this.entries, this.programId, DateTime Function()? clock, String Function()? newId})
    : _clock = clock ?? DateTime.now,
      _newId = newId ?? const Uuid().v4;

  final LocalStore store;
  final List<ProgramEntry> entries;

  /// The server program; null for the starter program and the library.
  final String? programId;
  final DateTime Function() _clock;
  final String Function() _newId;

  late final String sessionId = _newId();
  final _sets = <int, Set<int>>{};
  final _reps = <int, Set<String>>{};
  final _recorded = <int>{};
  final _camera = <int, ({int reps, double? peak})>{};
  Future<void>? _started;
  bool _ended = false;

  Future<void> start() => _started ??= () {
    final now = _clock();
    return store.startSession(SessionRecord(id: sessionId, programId: programId, performedOn: now, startedAt: now));
  }();

  /// Notes the work the patient actually reached, so sets and reps done
  /// reflect skips and "Finish set".
  void phaseEntered(Phase phase) {
    switch (phase.kind) {
      case PhaseKind.move || PhaseKind.hold || PhaseKind.release || PhaseKind.timed:
        _sets.putIfAbsent(phase.exerciseIndex, () => {}).add(phase.set);
        if (phase.rep != null) {
          _reps.putIfAbsent(phase.exerciseIndex, () => {}).add('${phase.set}/${phase.side}/${phase.rep}');
        }
      default:
        break;
    }
  }

  /// Sets reached in exercise [index].
  int setsDone(int index) => _sets[index]?.length ?? 0;

  /// Reps reached in exercise [index], over all its sets and sides.
  int? repsDone(int index) => entries[index].exercise.prescription.isTimed ? null : _reps[index]?.length ?? 0;

  bool isRecorded(int index) => _recorded.contains(index);

  /// Reps the camera counted over the whole of exercise [index]; they
  /// replace the timer's count in the log.
  void cameraCounted(int index, {required int reps, double? peak}) => _camera[index] = (reps: reps, peak: peak);

  Future<void> exerciseDone(int index, PainAnswer answer) async {
    if (!_recorded.add(index)) return;
    await start();
    final entry = entries[index];
    final camera = _camera[index];
    await store.addExercise(ExerciseRecord(
      id: _newId(),
      sessionId: sessionId,
      exerciseId: entry.exercise.id,
      itemId: entry.itemId,
      setsDone: setsDone(index),
      setsPlanned: entry.exercise.prescription.sets,
      repsDone: camera?.reps ?? repsDone(index),
      repSource: camera == null ? 'manual' : 'camera',
      peakAngle: camera?.peak,
      pain: answer.pain,
      note: (answer.note?.trim().isEmpty ?? true) ? null : answer.note!.trim(),
      shareNote: answer.shareNote,
      createdAt: _clock(),
    ));
  }

  Future<void> raiseFlag(String reason, Map<String, dynamic> details) async {
    await start();
    await store.addFlag(FlagRecord(id: _newId(), reason: reason, details: {...details, 'session_id': sessionId}, createdAt: _clock()));
  }

  /// Closes the session. Safe to call more than once; the first call wins.
  Future<void> end({String? feedback, bool stoppedForSafety = false}) async {
    if (_ended) return;
    _ended = true;
    await start();
    await store.endSession(sessionId, feedback: feedback, stoppedForSafety: stoppedForSafety);
  }
}
