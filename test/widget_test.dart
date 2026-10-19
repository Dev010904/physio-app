import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:physio_app/app.dart';
import 'package:physio_app/exercises/exercise.dart';
import 'package:physio_app/settings/appearance.dart';

void main() {
  final library = ExerciseLibrary.fromJson(
    File('assets/exercises/starter_exercises.json').readAsStringSync(),
  );

  testWidgets('Today shows the starter program and one start button', (tester) async {
    await tester.pumpWidget(PhysioApp(library: library));

    expect(find.text(library.demoProgramTitle), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Start session'), findsOneWidget);
    expect(find.text(library.demoProgram.first.title), findsOneWidget);
  });

  testWidgets('an exercise page shows steps, dose and the draft notice', (tester) async {
    await tester.pumpWidget(PhysioApp(library: library));
    await tester.tap(find.text(library.demoProgram.first.title));
    await tester.pumpAndSettle();

    final exercise = library.demoProgram.first;
    expect(find.text(exercise.prescription.summary), findsOneWidget);
    expect(find.textContaining('Draft instructions'), findsOneWidget);
    await tester.scrollUntilVisible(find.text(exercise.steps.first), 200);
    expect(find.text(exercise.steps.first), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Start exercise'), findsOneWidget);
  });

  testWidgets('the Library tab lists all 10 exercises', (tester) async {
    await tester.pumpWidget(PhysioApp(library: library));
    await tester.tap(find.widgetWithText(NavigationDestination, 'Library'));
    await tester.pumpAndSettle();

    expect(find.text('10 exercises'), findsOneWidget);
  });

  testWidgets('appearance setting switches between light and dark', (tester) async {
    final appearance = AppearanceController(ThemeMode.light);
    await tester.pumpWidget(PhysioApp(library: library, appearance: appearance));
    expect(Theme.of(tester.element(find.text(library.demoProgramTitle))).brightness, Brightness.light);

    appearance.value = ThemeMode.dark;
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text(library.demoProgramTitle))).brightness, Brightness.dark);
  });
}
