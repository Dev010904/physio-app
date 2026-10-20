import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:physio_app/app.dart';
import 'package:physio_app/exercises/exercise.dart';
import 'package:physio_app/onboarding/welcome.dart';
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
    // The tutorial loops forever, so wait out the page transition instead of settling.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final exercise = library.demoProgram.first;
    // The square tutorial fills the top, so the rest is further down.
    await tester.scrollUntilVisible(find.text(exercise.prescription.summary), 200);
    expect(find.text(exercise.prescription.summary), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('Draft instructions'), 200);
    expect(find.textContaining('Works: Quadriceps'), findsOneWidget);
    await tester.scrollUntilVisible(find.text(exercise.steps.first), 200);
    expect(find.text(exercise.steps.first), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Start exercise'), findsOneWidget);
  });

  testWidgets('first launch walks through the welcome, then shows Today', (tester) async {
    final welcome = WelcomeController();
    await tester.pumpWidget(PhysioApp(library: library, welcome: welcome));
    expect(find.text('Welcome to PhysioSathi'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Watch, then move along'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Exercise safely'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Get started'));
    await tester.pumpAndSettle();
    expect(welcome.value, isTrue);
    expect(find.widgetWithText(FilledButton, 'Start session'), findsOneWidget);
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
