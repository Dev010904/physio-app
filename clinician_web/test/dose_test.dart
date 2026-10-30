import 'package:clinician_web/logic/dose.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/session/session_plan.dart';

// The library's default_dose values, copied from the clinic_link migration.
const wallSquat = {
  'sets': 2,
  'reps': 10,
  'hold_seconds': 5,
  'rest_seconds': 30,
  'duration_seconds': null,
  'per_side': false,
  'move_seconds': 2,
  'release_seconds': 2,
};
const calfStretch = {
  'sets': 3,
  'reps': null,
  'hold_seconds': 0,
  'rest_seconds': 15,
  'duration_seconds': 30,
  'per_side': true,
  'move_seconds': 2,
  'release_seconds': 2,
};

void main() {
  group('validateDose: reps XOR duration', () {
    test('reps alone is fine', () => expect(validateDose(sets: 2, reps: 10), isEmpty));
    test('duration alone is fine', () => expect(validateDose(sets: 3, durationSeconds: 30), isEmpty));
    test('both is rejected', () {
      expect(validateDose(sets: 2, reps: 10, durationSeconds: 30), contains('Choose either repetitions or a time, not both.'));
    });
    test('neither is rejected', () {
      expect(validateDose(sets: 2), contains('Choose either repetitions or a time, not both.'));
    });
  });

  group('validateDose: sizes and days', () {
    test('sets must be at least 1', () => expect(validateDose(sets: 0, reps: 10), contains('Use at least 1 set.')));
    test('reps must be at least 1', () => expect(validateDose(sets: 1, reps: 0), contains('Use at least 1 repetition.')));
    test('duration must be positive', () {
      expect(validateDose(sets: 1, durationSeconds: 0), contains('The time must be at least 1 second.'));
    });
    test('timings cannot be negative', () => expect(validateDose(sets: 1, reps: 5, restSeconds: -1), contains('Times cannot be negative.')));
    test('a rep needs some time', () {
      expect(
        validateDose(sets: 1, reps: 5, moveSeconds: 0, holdSeconds: 0, releaseSeconds: 0),
        contains('Give each repetition some time to move, hold or release.'),
      );
    });
    test('at least one weekday', () => expect(validateDose(sets: 1, reps: 5, days: {}), contains('Pick at least one day of the week.')));
    test('weekdays are 1 to 7', () => expect(validateDose(sets: 1, reps: 5, days: {0, 8}), contains('Days must be Monday to Sunday.')));
  });

  group('ItemDraft from the library', () {
    test('a rep exercise starts in reps mode with its default dose', () {
      final d = ItemDraft.fromDefaultDose(exerciseId: 'e1', title: 'Wall squat', dose: wallSquat);
      expect(d.mode, DoseMode.reps);
      expect((d.sets, d.reps, d.holdSeconds, d.restSeconds), (2, 10, 5, 30));
      expect(d.days, ItemDraft.allDays);
      expect(d.isValid, isTrue);
    });

    test('a stretch starts in time mode', () {
      final d = ItemDraft.fromDefaultDose(exerciseId: 'e2', title: 'Calf stretch', dose: calfStretch);
      expect(d.mode, DoseMode.time);
      expect((d.sets, d.durationSeconds, d.perSide), (3, 30, true));
    });

    test('a missing dose still gives a valid starting point', () {
      expect(ItemDraft.fromDefaultDose(exerciseId: 'e3', title: 'New', dose: null).isValid, isTrue);
    });
  });

  group('p_items JSON', () {
    test('a rep item has reps and no duration_seconds', () {
      final d = ItemDraft.fromDefaultDose(exerciseId: 'e1', title: 'Wall squat', dose: wallSquat)
        ..days = {5, 1, 3}
        ..notes = '  Go slowly  ';
      expect(d.toItemJson(), {
        'exercise_id': 'e1',
        'sets': 2,
        'reps': 10,
        'hold_seconds': 5,
        'rest_seconds': 30,
        'per_side': false,
        'move_seconds': 2,
        'release_seconds': 2,
        'days_of_week': [1, 3, 5],
        'notes': 'Go slowly',
      });
    });

    test('a timed item has duration_seconds, no reps, and no hold', () {
      final d = ItemDraft.fromDefaultDose(exerciseId: 'e2', title: 'Calf stretch', dose: calfStretch)..holdSeconds = 9;
      final json = d.toItemJson();
      expect(json.containsKey('reps'), isFalse);
      expect(json['duration_seconds'], 30);
      expect(json['hold_seconds'], 0);
      expect(json['per_side'], isTrue);
      expect(json['notes'], isNull);
    });

    test('switching mode publishes only the chosen one', () {
      final d = ItemDraft.fromDefaultDose(exerciseId: 'e1', title: 'Wall squat', dose: wallSquat)..mode = DoseMode.time;
      final json = d.toItemJson();
      expect(json.containsKey('reps'), isFalse);
      expect(json['duration_seconds'], 30);
      d.mode = DoseMode.reps;
      expect(d.toItemJson()['reps'], 10);
      expect(d.toItemJson().containsKey('duration_seconds'), isFalse);
    });

    test('the list keeps the on-screen order', () {
      final items = [
        ItemDraft.fromDefaultDose(exerciseId: 'b', title: 'B', dose: wallSquat),
        ItemDraft.fromDefaultDose(exerciseId: 'a', title: 'A', dose: calfStretch),
      ];
      expect(programItemsJson(items).map((i) => i['exercise_id']), ['b', 'a']);
    });

    test('a published item loads back the same', () {
      final d = ItemDraft.fromDefaultDose(exerciseId: 'e2', title: 'Calf stretch', dose: calfStretch)..days = {2, 4};
      final row = {
        ...d.toItemJson(),
        'id': 'item-1',
        'position': 1,
        'exercises': {'id': 'e2', 'title_en': 'Calf stretch', 'body_region': 'ankle'},
      };
      final back = ItemDraft.fromProgramItem(row);
      expect(back.toItemJson(), d.toItemJson());
      expect(back.title, 'Calf stretch');
      expect(back.bodyRegion, 'ankle');
    });

    test('copy is independent', () {
      final d = ItemDraft.fromDefaultDose(exerciseId: 'e1', title: 'Wall squat', dose: wallSquat);
      final c = d.copy()
        ..sets = 4
        ..days.remove(7);
      expect(d.sets, 2);
      expect(d.days, contains(7));
      expect(c.toItemJson()['sets'], 4);
    });
  });

  group('session length', () {
    test('matches the session player for one exercise', () {
      final d = ItemDraft.fromDefaultDose(exerciseId: 'e1', title: 'Wall squat', dose: wallSquat);
      // 2 sets × (3 s count-in + 10 × (2 + 5 + 2)) + 1 rest of 30 s.
      expect(d.duration, const Duration(seconds: 2 * (3 + 90) + 30));
      expect(d.duration, SessionPlan.exerciseDuration(d.prescription));
    });

    test('per side doubles the work, not the rests', () {
      final d = ItemDraft.fromDefaultDose(exerciseId: 'e2', title: 'Calf stretch', dose: calfStretch);
      // 3 sets × 2 sides × (3 + 30) + 2 rests of 15 s.
      expect(d.duration, const Duration(seconds: 3 * 2 * 33 + 2 * 15));
    });

    test('a day adds the pause between exercises and skips unscheduled ones', () {
      final a = ItemDraft.fromDefaultDose(exerciseId: 'a', title: 'A', dose: wallSquat);
      final b = ItemDraft.fromDefaultDose(exerciseId: 'b', title: 'B', dose: calfStretch)..days = {1};
      final both = a.duration! + b.duration! + const Duration(seconds: SessionPlan.transitionSeconds);
      expect(sessionDurationOn(1, [a, b]), both);
      expect(sessionDurationOn(2, [a, b]), a.duration);
      expect(sessionDurationOn(2, [b]), Duration.zero);
    });

    test('an invalid dose has no duration and is left out of the day', () {
      final a = ItemDraft.fromDefaultDose(exerciseId: 'a', title: 'A', dose: wallSquat)..sets = 0;
      expect(a.duration, isNull);
      expect(sessionDurationOn(1, [a]), Duration.zero);
    });
  });
}
