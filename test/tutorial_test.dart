import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:physio_app/exercises/exercise.dart';
import 'package:physio_app/tutorials/tutorial.dart';

/// Width and height of a WebP file, read from its header.
(int, int) webpSize(Uint8List b) {
  final data = ByteData.sublistView(b);
  final chunk = String.fromCharCodes(b.sublist(12, 16));
  return switch (chunk) {
    'VP8 ' => (data.getUint16(26, Endian.little) & 0x3fff, data.getUint16(28, Endian.little) & 0x3fff),
    'VP8L' => (
      1 + (data.getUint32(21, Endian.little) & 0x3fff),
      1 + ((data.getUint32(21, Endian.little) >> 14) & 0x3fff),
    ),
    'VP8X' => (1 + (b[24] | b[25] << 8 | b[26] << 16), 1 + (b[27] | b[28] << 8 | b[29] << 16)),
    _ => throw FormatException('not a WebP image: $chunk'),
  };
}

void main() {
  final library = ExerciseLibrary.fromJson(File('assets/exercises/starter_exercises.json').readAsStringSync());

  test('every exercise has a tutorial with muscles listed', () {
    for (final e in library.exercises) {
      final tutorial = tutorials[e.id];
      expect(tutorial, isNotNull, reason: e.id);
      expect(tutorial!.muscles.values.expand((m) => m), isNotEmpty, reason: e.id);
    }
  });

  test('each sheet holds exactly its frames, 480 px square, in rows of 5', () {
    for (final t in tutorials.values) {
      final (w, h) = webpSize(File(t.sheet).readAsBytesSync());
      final columns = t.frames < Tutorial.columns ? t.frames : Tutorial.columns;
      final rows = (t.frames + Tutorial.columns - 1) ~/ Tutorial.columns;
      expect((w, h), (columns * 480, rows * 480), reason: t.id);
      expect(File(t.poster).existsSync(), isTrue, reason: t.poster);
    }
  });

  test('the demo loop rests at the start and holds at the end pose', () {
    final rep = tutorials['wall_squat']!;
    expect(demoProgress(0, rep), 0);
    expect(demoProgress(0.45, rep), 1);
    expect(demoProgress(0.97, rep), 0);
    final sway = tutorials['pendulum']!;
    expect(demoProgress(0, sway), closeTo(0, 1e-9));
    expect(demoProgress(0.5, sway), closeTo(1, 1e-9));
  });
}
