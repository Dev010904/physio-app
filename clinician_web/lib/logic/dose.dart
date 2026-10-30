import 'package:physio_app/exercises/exercise.dart';
import 'package:physio_app/session/session_plan.dart';

/// Whether an exercise is counted in repetitions or held for a time.
enum DoseMode { reps, time }

/// One exercise in the program builder, as the clinician is editing it.
///
/// It mirrors one element of `publish_program`'s `p_items`, so what is on
/// screen is exactly what gets published.
class ItemDraft {
  ItemDraft({
    required this.exerciseId,
    required this.title,
    this.bodyRegion = 'other',
    this.mode = DoseMode.reps,
    this.sets = 2,
    this.reps = 10,
    this.durationSeconds = 30,
    this.holdSeconds = 0,
    this.restSeconds = 30,
    this.moveSeconds = 2,
    this.releaseSeconds = 2,
    this.perSide = false,
    Set<int>? days,
    this.notes = '',
  }) : days = days ?? {...allDays};

  /// ISO weekdays, Monday = 1 to Sunday = 7, as the patient app reads them.
  static const allDays = {1, 2, 3, 4, 5, 6, 7};

  /// Starts from the library's `default_dose`, which has the same keys as p_items.
  factory ItemDraft.fromDefaultDose({
    required String exerciseId,
    required String title,
    String? bodyRegion,
    Map<String, dynamic>? dose,
  }) {
    final d = dose ?? const {};
    final duration = _int(d['duration_seconds']);
    final reps = _int(d['reps']);
    final timed = duration != null && reps == null;
    return ItemDraft(
      exerciseId: exerciseId,
      title: title,
      bodyRegion: bodyRegion ?? 'other',
      mode: timed ? DoseMode.time : DoseMode.reps,
      sets: _int(d['sets']) ?? 2,
      reps: reps ?? 10,
      durationSeconds: duration ?? 30,
      holdSeconds: _int(d['hold_seconds']) ?? 0,
      restSeconds: _int(d['rest_seconds']) ?? 30,
      moveSeconds: _int(d['move_seconds']) ?? 2,
      releaseSeconds: _int(d['release_seconds']) ?? 2,
      perSide: d['per_side'] as bool? ?? false,
      days: _days(d['days_of_week']),
      notes: d['notes'] as String? ?? '',
    );
  }

  /// Starts from a published `program_items` row with its `exercises` embedded,
  /// so a new version begins where the last one ended.
  factory ItemDraft.fromProgramItem(Map<String, dynamic> item) {
    final ex = item['exercises'] as Map<String, dynamic>? ?? const {};
    return ItemDraft.fromDefaultDose(
      exerciseId: item['exercise_id'] as String? ?? ex['id'] as String,
      title: ex['title_en'] as String? ?? 'Exercise',
      bodyRegion: ex['body_region'] as String?,
      dose: item,
    );
  }

  /// An independent copy, so editing never changes a loaded version.
  ItemDraft copy() => ItemDraft(
    exerciseId: exerciseId,
    title: title,
    bodyRegion: bodyRegion,
    mode: mode,
    sets: sets,
    reps: reps,
    durationSeconds: durationSeconds,
    holdSeconds: holdSeconds,
    restSeconds: restSeconds,
    moveSeconds: moveSeconds,
    releaseSeconds: releaseSeconds,
    perSide: perSide,
    days: {...days},
    notes: notes,
  );

  final String exerciseId;
  final String title;
  final String bodyRegion;
  DoseMode mode;
  int sets;

  // Both are kept while editing, so switching mode back and forth loses
  // nothing; only the one for [mode] is published.
  int reps;
  int durationSeconds;
  int holdSeconds;
  int restSeconds;
  int moveSeconds;
  int releaseSeconds;
  bool perSide;
  Set<int> days;
  String notes;

  bool get isTimed => mode == DoseMode.time;

  /// Problems that stop this item from being published, in plain words.
  List<String> get problems => validateDose(
    sets: sets,
    reps: isTimed ? null : reps,
    durationSeconds: isTimed ? durationSeconds : null,
    holdSeconds: holdSeconds,
    restSeconds: restSeconds,
    moveSeconds: moveSeconds,
    releaseSeconds: releaseSeconds,
    days: days,
  );

  bool get isValid => problems.isEmpty;

  /// The patient app's prescription for this item; only call when [isValid].
  Prescription get prescription => Prescription(
    sets: sets,
    reps: isTimed ? null : reps,
    durationSeconds: isTimed ? durationSeconds : null,
    holdSeconds: isTimed ? 0 : holdSeconds,
    moveSeconds: moveSeconds,
    releaseSeconds: releaseSeconds,
    restSeconds: restSeconds,
    perSide: perSide,
  );

  /// Length of this exercise in the patient's session, worked out the same
  /// way the phone's session player does. Null while the dose is invalid.
  Duration? get duration => isValid ? SessionPlan.exerciseDuration(prescription) : null;

  /// One element of `publish_program`'s p_items. Exactly one of reps and
  /// duration_seconds is present.
  Map<String, dynamic> toItemJson() {
    final note = notes.trim();
    return {
      'exercise_id': exerciseId,
      'sets': sets,
      if (isTimed) 'duration_seconds': durationSeconds else 'reps': reps,
      'hold_seconds': isTimed ? 0 : holdSeconds,
      'rest_seconds': restSeconds,
      'per_side': perSide,
      'move_seconds': moveSeconds,
      'release_seconds': releaseSeconds,
      'days_of_week': days.toList()..sort(),
      'notes': note.isEmpty ? null : note,
    };
  }

  static int? _int(Object? v) => switch (v) {
    int i => i,
    num n => n.toInt(),
    String s => int.tryParse(s),
    _ => null,
  };

  static Set<int> _days(Object? v) {
    final list = v is List ? [for (final d in v) ?_int(d)] : const <int>[];
    final days = {for (final d in list) if (d >= 1 && d <= 7) d};
    return days.isEmpty ? {...allDays} : days;
  }
}

/// Checks a dose the way the server does (sets > 0, reps XOR duration, and
/// non-negative timings), plus the rules the builder adds: at least one
/// weekday, and sizes that stay sensible for a home exercise.
List<String> validateDose({
  required int sets,
  int? reps,
  int? durationSeconds,
  int holdSeconds = 0,
  int restSeconds = 30,
  int moveSeconds = 2,
  int releaseSeconds = 2,
  Set<int> days = ItemDraft.allDays,
}) {
  final out = <String>[];
  if ((reps == null) == (durationSeconds == null)) {
    out.add('Choose either repetitions or a time, not both.');
  }
  if (sets < 1) out.add('Use at least 1 set.');
  if (sets > 10) out.add('Use 10 sets or fewer.');
  if (reps != null && reps < 1) out.add('Use at least 1 repetition.');
  if (reps != null && reps > 100) out.add('Use 100 repetitions or fewer.');
  if (durationSeconds != null && durationSeconds < 1) out.add('The time must be at least 1 second.');
  if (durationSeconds != null && durationSeconds > 600) out.add('Keep the time to 10 minutes or less.');
  if (holdSeconds < 0 || restSeconds < 0 || moveSeconds < 0 || releaseSeconds < 0) {
    out.add('Times cannot be negative.');
  }
  if (reps != null && moveSeconds + holdSeconds + releaseSeconds == 0) {
    out.add('Give each repetition some time to move, hold or release.');
  }
  if (days.isEmpty) out.add('Pick at least one day of the week.');
  if (days.any((d) => d < 1 || d > 7)) out.add('Days must be Monday to Sunday.');
  return out;
}

/// Seconds the patient spends on [items] on one weekday, with the pauses
/// between exercises the session player adds. Zero for a rest day.
Duration sessionDurationOn(int weekday, List<ItemDraft> items) {
  final today = [for (final i in items) if (i.isValid && i.days.contains(weekday)) i];
  if (today.isEmpty) return Duration.zero;
  final work = today.fold(Duration.zero, (sum, i) => sum + i.duration!);
  return work + Duration(seconds: SessionPlan.transitionSeconds * (today.length - 1));
}

/// The whole of `publish_program`'s p_items, in the order shown.
List<Map<String, dynamic>> programItemsJson(List<ItemDraft> items) => [for (final i in items) i.toItemJson()];
