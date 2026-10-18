import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:physio_app/app.dart';
import 'package:physio_app/exercises/exercise.dart';

void main() {
  final library = ExerciseLibrary.fromJson(
    File('assets/exercises/starter_exercises.json').readAsStringSync(),
  );

  testWidgets('Today shows the starter program and a start button', (tester) async {
    await tester.pumpWidget(PhysioApp(library: library));

    expect(find.text('Today'), findsOneWidget);
    expect(find.text(library.demoProgramTitle), findsOneWidget);
    expect(find.text('Start session'), findsOneWidget);
    expect(find.text(library.demoProgram.first.title), findsOneWidget);
  });

  testWidgets('an exercise page shows steps, dose and the draft notice', (tester) async {
    await tester.pumpWidget(PhysioApp(library: library));
    await tester.tap(find.text(library.demoProgram.first.title));
    await tester.pumpAndSettle();

    final exercise = library.demoProgram.first;
    expect(find.text(exercise.steps.first), findsOneWidget);
    expect(find.text(exercise.prescription.summary), findsOneWidget);
    expect(find.textContaining('Draft instructions'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Start exercise'), findsOneWidget);
  });

  testWidgets('the library lists all 10 exercises', (tester) async {
    await tester.pumpWidget(PhysioApp(library: library));
    await tester.tap(find.byTooltip('Exercise library'));
    await tester.pumpAndSettle();

    expect(find.text('Exercise library (10)'), findsOneWidget);
  });
}
