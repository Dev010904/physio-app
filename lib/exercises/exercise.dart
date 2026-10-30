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
      isTimed ? '$sets × ${durationSeconds}s' : '$sets ${sets == 1 ? 'set' : 'sets'} × $reps ${reps == 1 ? 'rep' : 'reps'}',
      if (!isTimed && holdSeconds > 0) 'hold $holdSeconds s',
      if (perSide) 'each side',
      'rest $restSeconds s',
    ];
    return parts.join(' · ');
  }
}

/// An exercise's text in a second language. Anything left out falls back
/// to English.
class ExerciseText {
  const ExerciseText({this.title, this.steps = const [], this.moveLabel, this.releaseLabel});

  factory ExerciseText.fromJson(Map<String, dynamic> json) => ExerciseText(
    title: json['title'] as String?,
    steps: (json['steps'] as List? ?? const []).cast<String>(),
    moveLabel: json['moveLabel'] as String?,
    releaseLabel: json['releaseLabel'] as String?,
  );

  final String? title;
  final List<String> steps;
  final String? moveLabel;
  final String? releaseLabel;

  Map<String, dynamic> toJson() => {
    'title': ?title,
    'steps': steps,
    'moveLabel': ?moveLabel,
    'releaseLabel': ?releaseLabel,
  };
}

/// An exercise with its text in English and, where written, Hindi. The text
/// getters answer in [language]; [inLanguage] switches without a download.
class Exercise {
  const Exercise({
    required this.id,
    required String title,
    required this.bodyRegion,
    required List<String> steps,
    required this.prescription,
    this.equipment = const [],
    String moveLabel = 'Move',
    String releaseLabel = 'Return',
    this.hindi,
    this.language = 'en',
  }) : titleEn = title,
       stepsEn = steps,
       moveLabelEn = moveLabel,
       releaseLabelEn = releaseLabel;

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'] as String,
    title: json['title'] as String,
    bodyRegion: json['bodyRegion'] as String,
    equipment: (json['equipment'] as List? ?? const []).cast<String>(),
    steps: (json['steps'] as List).cast<String>(),
    moveLabel: json['moveLabel'] as String? ?? 'Move',
    releaseLabel: json['releaseLabel'] as String? ?? 'Return',
    prescription: Prescription.fromJson(json['prescription'] as Map<String, dynamic>),
    hindi: json['hi'] == null ? null : ExerciseText.fromJson(json['hi'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': titleEn,
    'bodyRegion': bodyRegion,
    'equipment': equipment,
    'steps': stepsEn,
    'moveLabel': moveLabelEn,
    'releaseLabel': releaseLabelEn,
    'prescription': prescription.toJson(),
    'hi': ?hindi?.toJson(),
  };

  final String id;
  final String bodyRegion;
  final List<String> equipment;

  /// Starter dose. From M2 on, the clinician's program overrides it.
  final Prescription prescription;

  /// Hindi text, when it has been written.
  final ExerciseText? hindi;

  /// 'en' or 'hi': the language the text getters answer in.
  final String language;

  /// The English text, always present.
  final String titleEn;
  final List<String> stepsEn;
  final String moveLabelEn;
  final String releaseLabelEn;

  ExerciseText? get _text => language == 'hi' ? hindi : null;

  String get title => _text?.title ?? titleEn;
  List<String> get steps => (_text?.steps.isNotEmpty ?? false) ? _text!.steps : stepsEn;
  String get moveLabel => _text?.moveLabel ?? moveLabelEn;
  String get releaseLabel => _text?.releaseLabel ?? releaseLabelEn;

  /// The same exercise, answering in [lang].
  Exercise inLanguage(String lang) => lang == language
      ? this
      : Exercise(
          id: id,
          title: titleEn,
          bodyRegion: bodyRegion,
          steps: stepsEn,
          prescription: prescription,
          equipment: equipment,
          moveLabel: moveLabelEn,
          releaseLabel: releaseLabelEn,
          hindi: hindi,
          language: lang,
        );

  /// The same exercise with another dose.
  Exercise withPrescription(Prescription rx) => Exercise(
    id: id,
    title: titleEn,
    bodyRegion: bodyRegion,
    steps: stepsEn,
    prescription: rx,
    equipment: equipment,
    moveLabel: moveLabelEn,
    releaseLabel: releaseLabelEn,
    hindi: hindi,
    language: language,
  );
}

/// The bundled starter library. It ships inside the app so it works offline.
class ExerciseLibrary {
  ExerciseLibrary({
    required this.exercises,
    required this.reviewedByPhysio,
    required this.demoProgramTitle,
    required this.demoProgram,
    this.demoProgramTitleHi,
    this.language = 'en',
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
      demoProgramTitleHi: demo['titleHi'] as String?,
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
  final String? demoProgramTitleHi;
  final List<Exercise> demoProgram;
  final String language;

  /// The starter program's name in this library's language.
  String get starterTitle => language == 'hi' ? demoProgramTitleHi ?? demoProgramTitle : demoProgramTitle;

  /// The same library, answering in [lang].
  ExerciseLibrary inLanguage(String lang) => lang == language
      ? this
      : ExerciseLibrary(
          exercises: [for (final e in exercises) e.inLanguage(lang)],
          reviewedByPhysio: reviewedByPhysio,
          demoProgramTitle: demoProgramTitle,
          demoProgramTitleHi: demoProgramTitleHi,
          demoProgram: [for (final e in demoProgram) e.inLanguage(lang)],
          language: lang,
        );
}
