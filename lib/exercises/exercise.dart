import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// How an exercise is dosed. Rep-based exercises use [reps] with a tempo
/// (move, hold, release); timed exercises such as stretches use
/// [durationSeconds] instead.
class Prescription {
  const Prescription({
    required this.sets,
    this.reps,
    this.durationSeconds,
    this.holdSeconds = 0,
    this.moveSeconds = 2,
    this.releaseSeconds = 2,
    this.restSeconds = 30,
    this.perSide = false,
  }) : assert(sets > 0),
       assert((reps == null) != (durationSeconds == null), 'Use either reps or durationSeconds');

  factory Prescription.fromJson(Map<String, dynamic> json) => Prescription(
    sets: json['sets'] as int,
    reps: json['reps'] as int?,
    durationSeconds: json['durationSeconds'] as int?,
    holdSeconds: json['holdSeconds'] as int? ?? 0,
    moveSeconds: json['moveSeconds'] as int? ?? 2,
    releaseSeconds: json['releaseSeconds'] as int? ?? 2,
    restSeconds: json['restSeconds'] as int? ?? 30,
    perSide: json['perSide'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'sets': sets,
    'reps': ?reps,
    'durationSeconds': ?durationSeconds,
    'holdSeconds': holdSeconds,
    'moveSeconds': moveSeconds,
    'releaseSeconds': releaseSeconds,
    'restSeconds': restSeconds,
    'perSide': perSide,
  };

  final int sets;
  final int? reps;
  final int? durationSeconds;
  final int holdSeconds;
  final int moveSeconds;
  final int releaseSeconds;
  final int restSeconds;
  final bool perSide;

  bool get isTimed => durationSeconds != null;

  /// Short human summary, e.g. "2 sets × 10 reps · hold 5 s · each side".
  String get summary {
    final parts = <String>[
      isTimed ? '$sets × ${durationSeconds}s' : '$sets sets × $reps reps',
      if (!isTimed && holdSeconds > 0) 'hold $holdSeconds s',
      if (perSide) 'each side',
      'rest $restSeconds s',
    ];
    return parts.join(' · ');
  }
}

class Exercise {
  const Exercise({
    required this.id,
    required this.title,
    required this.bodyRegion,
    required this.steps,
    required this.prescription,
    this.equipment = const [],
    this.moveLabel = 'Move',
    this.releaseLabel = 'Return',
  });

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'] as String,
    title: json['title'] as String,
    bodyRegion: json['bodyRegion'] as String,
    equipment: (json['equipment'] as List? ?? const []).cast<String>(),
    steps: (json['steps'] as List).cast<String>(),
    moveLabel: json['moveLabel'] as String? ?? 'Move',
    releaseLabel: json['releaseLabel'] as String? ?? 'Return',
    prescription: Prescription.fromJson(json['prescription'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'bodyRegion': bodyRegion,
    'equipment': equipment,
    'steps': steps,
    'moveLabel': moveLabel,
    'releaseLabel': releaseLabel,
    'prescription': prescription.toJson(),
  };

  final String id;
  final String title;
  final String bodyRegion;
  final List<String> equipment;
  final List<String> steps;
  final String moveLabel;
  final String releaseLabel;

  /// Starter dose. From M2 on, the clinician's program overrides it.
  final Prescription prescription;
}

/// The bundled starter library. It ships inside the app so it works offline.
class ExerciseLibrary {
  ExerciseLibrary({
    required this.exercises,
    required this.reviewedByPhysio,
    required this.demoProgramTitle,
    required this.demoProgram,
  });

  factory ExerciseLibrary.fromJson(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final exercises = [
      for (final e in json['exercises'] as List) Exercise.fromJson(e as Map<String, dynamic>),
    ];
    final byId = {for (final e in exercises) e.id: e};
    final demo = json['demoProgram'] as Map<String, dynamic>;
    return ExerciseLibrary(
      exercises: exercises,
      reviewedByPhysio: json['reviewedByPhysio'] as bool? ?? false,
      demoProgramTitle: demo['title'] as String,
      demoProgram: [
        for (final id in (demo['exerciseIds'] as List).cast<String>())
          byId[id] ?? (throw FormatException('Demo program lists unknown exercise "$id"')),
      ],
    );
  }

  static const assetPath = 'assets/exercises/starter_exercises.json';

  static Future<ExerciseLibrary> load() async =>
      ExerciseLibrary.fromJson(await rootBundle.loadString(assetPath));

  final List<Exercise> exercises;
  final bool reviewedByPhysio;
  final String demoProgramTitle;
  final List<Exercise> demoProgram;
}
