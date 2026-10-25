import '../exercises/exercise.dart';

/// One exercise in a program, with the days it is scheduled.
class ProgramEntry {
  const ProgramEntry({required this.exercise, this.itemId, this.days = allDays, this.note});

  /// ISO weekdays, Monday = 1 to Sunday = 7.
  static const allDays = {1, 2, 3, 4, 5, 6, 7};

  factory ProgramEntry.fromJson(Map<String, dynamic> json) => ProgramEntry(
    exercise: Exercise.fromJson(json['exercise'] as Map<String, dynamic>),
    itemId: json['itemId'] as String?,
    days: {...(json['days'] as List).cast<int>()},
    note: json['note'] as String?,
  );

  /// The server's program item id; null in the bundled starter program, whose
  /// logs stay on the phone.
  final String? itemId;
  final Exercise exercise;
  final Set<int> days;

  /// The physio's note for this exercise.
  final String? note;

  Map<String, dynamic> toJson() => {
    'exercise': exercise.toJson(),
    'itemId': ?itemId,
    'days': days.toList()..sort(),
    'note': ?note,
  };
}

/// What the patient follows: their physio's program once the app is linked
/// with an access code, otherwise the bundled starter program.
class Program {
  const Program({required this.title, required this.entries, this.id, this.version, this.notes});

  /// The starter program from the bundled library, scheduled every day.
  factory Program.starter(ExerciseLibrary library) => Program(
    title: library.demoProgramTitle,
    entries: [for (final e in library.demoProgram) ProgramEntry(exercise: e)],
  );

  factory Program.fromJson(Map<String, dynamic> json) => Program(
    id: json['id'] as String?,
    version: json['version'] as int?,
    title: json['title'] as String,
    notes: json['notes'] as String?,
    entries: [
      for (final e in json['entries'] as List) ProgramEntry.fromJson(e as Map<String, dynamic>),
    ],
  );

  /// Builds a program from the server's latest `programs` row with its
  /// `program_items` and their `exercises` embedded.
  factory Program.fromServer(Map<String, dynamic> row, {String language = 'en'}) {
    final items = [...(row['program_items'] as List).cast<Map<String, dynamic>>()]
      ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));
    return Program(
      id: row['id'] as String,
      version: row['version'] as int,
      title: 'Your program',
      notes: row['clinician_notes'] as String?,
      entries: [for (final item in items) _entryFromServer(item, language)],
    );
  }

  /// Server program id; null for the starter program.
  final String? id;
  final int? version;
  final String title;

  /// The physio's notes for the whole program.
  final String? notes;
  final List<ProgramEntry> entries;

  bool get fromClinic => id != null;

  List<Exercise> get exercises => [for (final e in entries) e.exercise];

  /// Entries scheduled on [day]'s weekday.
  List<ProgramEntry> on(DateTime day) => [for (final e in entries) if (e.days.contains(day.weekday)) e];

  /// The next day after [day] with something scheduled, within a week.
  DateTime? nextSessionAfter(DateTime day) {
    for (var i = 1; i <= 7; i++) {
      final d = DateTime(day.year, day.month, day.day + i);
      if (on(d).isNotEmpty) return d;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': ?id,
    'version': ?version,
    'title': title,
    'notes': ?notes,
    'entries': [for (final e in entries) e.toJson()],
  };
}

ProgramEntry _entryFromServer(Map<String, dynamic> item, String language) {
  final ex = item['exercises'] as Map<String, dynamic>;
  final hindi = language == 'hi';
  String text(String key) => (hindi ? ex['${key}_hi'] as String? : null) ?? ex['${key}_en'] as String;
  String? label(String key) => (hindi ? ex['${key}_hi'] as String? : null) ?? ex['${key}_en'] as String?;
  List<String> list(String key) {
    final hi = (ex['${key}_hi'] as List?)?.cast<String>() ?? const [];
    return hindi && hi.isNotEmpty ? hi : (ex['${key}_en'] as List).cast<String>();
  }

  final reps = item['reps'] as int?;
  return ProgramEntry(
    itemId: item['id'] as String,
    days: {...((item['days_of_week'] as List?) ?? ProgramEntry.allDays.toList()).cast<int>()},
    note: item['notes'] as String?,
    exercise: Exercise(
      // The slug is the bundled exercise id, so tutorials still match.
      id: ex['slug'] as String? ?? ex['id'] as String,
      title: text('title'),
      bodyRegion: ex['body_region'] as String? ?? 'other',
      equipment: (ex['equipment'] as List? ?? const []).cast<String>(),
      steps: list('steps'),
      moveLabel: label('move_label') ?? 'Move',
      releaseLabel: label('release_label') ?? 'Return',
      prescription: Prescription(
        sets: item['sets'] as int,
        reps: reps,
        durationSeconds: reps == null ? item['duration_seconds'] as int? : null,
        holdSeconds: item['hold_seconds'] as int? ?? 0,
        moveSeconds: item['move_seconds'] as int? ?? 2,
        releaseSeconds: item['release_seconds'] as int? ?? 2,
        restSeconds: item['rest_seconds'] as int? ?? 30,
        perSide: item['per_side'] as bool? ?? false,
      ),
    ),
  );
}
