import '../logic/adherence.dart';
import '../logic/dose.dart';
import '../logic/text.dart';

DateTime? _time(Object? v) => v == null ? null : DateTime.parse(v as String).toLocal();

/// A `date` column ("2026-10-20") as a local calendar day.
DateTime _date(Object? v) {
  final d = DateTime.parse(v as String);
  return DateTime(d.year, d.month, d.day);
}

/// The signed-in clinician and their clinic.
class Clinician {
  const Clinician({required this.id, required this.clinicId, required this.fullName, required this.clinicName, this.role = 'physio'});

  factory Clinician.fromRow(Map<String, dynamic> r) => Clinician(
    id: r['id'] as String,
    clinicId: r['clinic_id'] as String,
    fullName: r['full_name'] as String,
    role: r['role'] as String? ?? 'physio',
    clinicName: (r['clinics'] as Map<String, dynamic>?)?['name'] as String? ?? 'Your clinic',
  );

  final String id;
  final String clinicId;
  final String fullName;
  final String clinicName;
  final String role;
}

class PatientRow {
  const PatientRow({
    required this.id,
    required this.displayName,
    required this.language,
    required this.linked,
    required this.createdAt,
    this.linkedAt,
    this.codeExpiresAt,
  });

  static const columns = 'id, display_name, language, auth_user_id, consent_at, created_at, access_code_expires_at';

  factory PatientRow.fromRow(Map<String, dynamic> r) => PatientRow(
    id: r['id'] as String,
    displayName: r['display_name'] as String,
    language: r['language'] as String? ?? 'en',
    linked: r['auth_user_id'] != null,
    createdAt: _time(r['created_at'])!,
    linkedAt: _time(r['consent_at']),
    codeExpiresAt: _time(r['access_code_expires_at']),
  );

  final String id;
  final String displayName;
  final String language;

  /// A phone has redeemed this patient's code and not been reset since.
  final bool linked;
  final DateTime createdAt;

  /// When a phone first linked (consent was given).
  final DateTime? linkedAt;

  /// When the current, unused code stops working.
  final DateTime? codeExpiresAt;

  String get languageLabel => language == 'hi' ? 'Hindi' : 'English';
}

/// One row of the patients list.
class PatientSummary {
  const PatientSummary({required this.patient, required this.adherence, required this.openFlags, this.lastSession, this.hasProgram = false});

  final PatientRow patient;
  final DateTime? lastSession;
  final int openFlags;
  final Adherence adherence;
  final bool hasProgram;

  bool get needsAttention => openFlags > 0 || adherence.showMissedWarning;
}

/// An exercise from the shared library or the clinic's own.
class LibraryExercise {
  const LibraryExercise({
    required this.id,
    required this.title,
    required this.bodyRegion,
    this.slug,
    this.titleHi,
    this.equipment = const [],
    this.steps = const [],
    this.defaultDose,
    this.shared = true,
  });

  static const columns = 'id, slug, title_en, title_hi, body_region, equipment, steps_en, default_dose, clinic_id';

  factory LibraryExercise.fromRow(Map<String, dynamic> r) => LibraryExercise(
    id: r['id'] as String,
    slug: r['slug'] as String?,
    title: r['title_en'] as String,
    titleHi: r['title_hi'] as String?,
    bodyRegion: r['body_region'] as String? ?? 'other',
    equipment: (r['equipment'] as List? ?? const []).cast<String>(),
    steps: (r['steps_en'] as List? ?? const []).cast<String>(),
    defaultDose: r['default_dose'] as Map<String, dynamic>?,
    shared: r['clinic_id'] == null,
  );

  final String id;
  final String? slug;
  final String title;
  final String? titleHi;
  final String bodyRegion;
  final List<String> equipment;
  final List<String> steps;
  final Map<String, dynamic>? defaultDose;

  /// From the shared starter library rather than this clinic's own.
  final bool shared;

  ItemDraft toDraft() => ItemDraft.fromDefaultDose(exerciseId: id, title: title, bodyRegion: bodyRegion, dose: defaultDose);

  /// The default dose in the patient app's words, e.g. "2 sets × 10 reps · hold 5 s".
  String get doseSummary {
    final d = toDraft();
    return d.isValid ? d.prescription.summary : 'No default dose';
  }
}

/// One published version of a patient's program.
class ProgramVersion {
  const ProgramVersion({
    required this.id,
    required this.version,
    required this.createdAt,
    required this.items,
    this.notes,
    this.authorName,
    this.slugTitles = const {},
  });

  static const columns =
      'id, version, created_at, clinician_notes, clinicians(full_name), '
      'program_items(id, position, exercise_id, sets, reps, duration_seconds, hold_seconds, rest_seconds, '
      'per_side, move_seconds, release_seconds, days_of_week, notes, exercises(id, slug, title_en, body_region))';

  factory ProgramVersion.fromRow(Map<String, dynamic> r) {
    final items = [...(r['program_items'] as List? ?? const []).cast<Map<String, dynamic>>()]
      ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));
    return ProgramVersion(
      id: r['id'] as String,
      version: r['version'] as int,
      createdAt: _time(r['created_at'])!,
      notes: r['clinician_notes'] as String?,
      authorName: (r['clinicians'] as Map<String, dynamic>?)?['full_name'] as String?,
      items: [for (final i in items) ItemDraft.fromProgramItem(i)],
      slugTitles: {
        for (final i in items)
          if ((i['exercises'] as Map<String, dynamic>?)?['slug'] case final String slug)
            slug: (i['exercises'] as Map<String, dynamic>)['title_en'] as String,
      },
    );
  }

  final String id;
  final int version;
  final DateTime createdAt;
  final String? notes;
  final String? authorName;

  /// The version's exercises, in order, as editable drafts.
  final List<ItemDraft> items;

  /// Exercise titles by slug, the id the phone uses in flag details.
  final Map<String, String> slugTitles;

  ScheduleVersion get schedule => ScheduleVersion(
    startsOn: Adherence.dateOnly(createdAt),
    weekdays: {for (final i in items) ...i.days},
  );
}

/// One exercise as the patient logged it.
class ExerciseLog {
  const ExerciseLog({
    required this.id,
    required this.exerciseId,
    required this.title,
    required this.setsDone,
    this.repsDone,
    this.plannedSets,
    this.plannedReps,
    this.plannedSeconds,
    this.pain,
    this.sharedNote,
    this.repSource = 'manual',
    this.peakAngle,
  });

  factory ExerciseLog.fromRow(Map<String, dynamic> r) {
    final item = r['program_items'] as Map<String, dynamic>? ?? const {};
    final ex = item['exercises'] as Map<String, dynamic>? ?? const {};
    return ExerciseLog(
      id: r['id'] as String,
      exerciseId: item['exercise_id'] as String? ?? ex['id'] as String? ?? 'unknown',
      title: ex['title_en'] as String? ?? 'Exercise',
      setsDone: r['sets_done'] as int? ?? 0,
      repsDone: r['reps_done'] as int?,
      plannedSets: item['sets'] as int?,
      plannedReps: item['reps'] as int?,
      plannedSeconds: item['duration_seconds'] as int?,
      pain: r['pain_0_10'] as int?,
      sharedNote: r['shared_note'] as String?,
      repSource: r['rep_source'] as String? ?? 'manual',
      peakAngle: (r['peak_angle_deg'] as num?)?.toDouble(),
    );
  }

  final String id;
  final String exerciseId;
  final String title;
  final int setsDone;
  final int? repsDone;
  final int? plannedSets;
  final int? plannedReps;
  final int? plannedSeconds;
  final int? pain;
  final String? sharedNote;
  final String repSource;
  final double? peakAngle;

  /// "2 of 2 sets · 20 reps", "1 of 1 set · 1 rep".
  String get doneLabel {
    final sets = plannedSets == null ? plural(setsDone, 'set') : '$setsDone of ${plural(plannedSets!, 'set')}';
    final reps = repsDone == null ? '' : ' · ${plural(repsDone!, 'rep')}${repSource == 'camera' ? ' (camera)' : ''}';
    return '$sets$reps';
  }
}

class SessionEntry {
  const SessionEntry({required this.id, required this.performedOn, required this.exercises, this.startedAt, this.feedback});

  static const columns =
      'id, performed_on, started_at, feedback, '
      'exercise_logs(id, sets_done, reps_done, rep_source, peak_angle_deg, pain_0_10, shared_note, created_at, '
      'program_items(exercise_id, sets, reps, duration_seconds, exercises(id, title_en)))';

  factory SessionEntry.fromRow(Map<String, dynamic> r) => SessionEntry(
    id: r['id'] as String,
    performedOn: _date(r['performed_on']),
    startedAt: _time(r['started_at']),
    feedback: SessionFeedback.parse(r['feedback'] as String?),
    exercises: [for (final e in (r['exercise_logs'] as List? ?? const [])) ExerciseLog.fromRow(e as Map<String, dynamic>)],
  );

  final String id;
  final DateTime performedOn;
  final DateTime? startedAt;
  final SessionFeedback? feedback;
  final List<ExerciseLog> exercises;

  int? get maxPain {
    final scores = [for (final e in exercises) ?e.pain];
    return scores.isEmpty ? null : scores.reduce((a, b) => a > b ? a : b);
  }
}

class FlagEntry {
  const FlagEntry({required this.id, required this.reason, required this.details, required this.status, required this.createdAt, this.resolvedAt});

  static const columns = 'id, reason, details, status, created_at, resolved_at';

  factory FlagEntry.fromRow(Map<String, dynamic> r) => FlagEntry(
    id: r['id'] as String,
    reason: r['reason'] as String,
    details: r['details'] as Map<String, dynamic>? ?? const {},
    status: r['status'] as String,
    createdAt: _time(r['created_at'])!,
    resolvedAt: _time(r['resolved_at']),
  );

  final String id;
  final String reason;
  final Map<String, dynamic> details;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  bool get isOpen => status == 'open';
}

/// A pain score on a day, for the trend chart.
typedef PainPoint = ({DateTime day, int pain});

/// Everything the patient page shows.
class PatientDetail {
  PatientDetail({required this.patient, required this.programs, required this.sessions, required this.flags, required DateTime today})
    : adherence = Adherence(
        versions: [for (final p in programs) p.schedule],
        sessionDays: [for (final s in sessions) s.performedOn],
        linkedOn: patient.linkedAt,
        today: today,
      );

  final PatientRow patient;

  /// Newest version first.
  final List<ProgramVersion> programs;

  /// Newest first.
  final List<SessionEntry> sessions;
  final List<FlagEntry> flags;
  final Adherence adherence;

  ProgramVersion? get current => programs.isEmpty ? null : programs.first;

  List<FlagEntry> get openFlags => [for (final f in flags) if (f.isOpen) f];

  /// The flag that ended a session early, by session id. The phone stops the
  /// session on high pain or a warning sign and puts the session's id in the
  /// flag's details; session_logs has no column for it. [flags] is newest
  /// first, so a later (older) entry wins: the flag that stopped the session.
  late final Map<String, FlagEntry> safetyStops = {
    for (final f in flags)
      if ((f.reason == 'high_pain' || f.reason == 'red_flag') && f.details['session_id'] is String)
        f.details['session_id'] as String: f,
  };

  /// Pain scores per exercise, oldest first, with the exercise's title.
  List<({String title, List<PainPoint> points})> get painTrends {
    final byExercise = <String, ({String title, List<PainPoint> points})>{};
    for (final s in sessions.reversed) {
      for (final e in s.exercises) {
        if (e.pain == null) continue;
        byExercise.putIfAbsent(e.exerciseId, () => (title: e.title, points: <PainPoint>[])).points.add((day: s.performedOn, pain: e.pain!));
      }
    }
    return byExercise.values.toList();
  }

  /// Title of an exercise by the slug the phone puts in flag details.
  String? exerciseTitleForSlug(String slug) {
    for (final p in programs) {
      final title = p.slugTitles[slug];
      if (title != null) return title;
    }
    return null;
  }
}
