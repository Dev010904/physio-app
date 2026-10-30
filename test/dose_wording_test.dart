import 'package:flutter_test/flutter_test.dart';

import 'package:physio_app/exercises/exercise.dart';
import 'package:physio_app/l10n/app_localizations_en.dart';
import 'package:physio_app/l10n/l10n.dart';

void main() {
  const one = Prescription(sets: 1, reps: 1, holdSeconds: 2, restSeconds: 30);
  const many = Prescription(sets: 2, reps: 10, holdSeconds: 0, restSeconds: 30);

  test('one set or rep reads singular, in the app and the summary', () {
    final l = AppLocalizationsEn();
    expect(doseSummary(l, one), '1 set × 1 rep · hold 2 s · rest 30 s');
    expect(doseSummary(l, many), '2 sets × 10 reps · rest 30 s');
    expect(one.summary, '1 set × 1 rep · hold 2 s · rest 30 s');
    expect(many.summary, '2 sets × 10 reps · rest 30 s');
    expect(l.setsOfPlanned(1, 1), '1 of 1 set');
    expect(l.repsCount(1), '1 rep');
  });
}
