import 'package:clinician_web/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

ExerciseLog log({int setsDone = 1, int? plannedSets = 1, int? repsDone, String repSource = 'manual'}) => ExerciseLog(
  id: 'l',
  exerciseId: 'e',
  title: 'Wall squat',
  setsDone: setsDone,
  plannedSets: plannedSets,
  repsDone: repsDone,
  repSource: repSource,
);

FlagEntry flag(String id, String reason, Map<String, dynamic> details, {DateTime? at}) => FlagEntry(
  id: id,
  reason: reason,
  details: details,
  status: 'open',
  createdAt: at ?? DateTime(2026, 10, 30, 10),
);

PatientDetail detail(List<FlagEntry> flags) => PatientDetail(
  patient: PatientRow(id: 'p', displayName: 'Test Patient', language: 'en', linked: true, createdAt: DateTime(2026, 10, 30)),
  programs: const [],
  sessions: [SessionEntry(id: 's1', performedOn: DateTime(2026, 10, 30), exercises: const [])],
  flags: flags,
  today: DateTime(2026, 10, 30),
);

void main() {
  group('what the patient did, in words', () {
    test('one set and one rep are singular', () => expect(log(repsDone: 1).doneLabel, '1 of 1 set · 1 rep'));
    test('more are plural', () => expect(log(setsDone: 2, plannedSets: 3, repsDone: 20).doneLabel, '2 of 3 sets · 20 reps'));
    test('no plan and a timed exercise', () => expect(log(setsDone: 1, plannedSets: null).doneLabel, '1 set'));
    test('camera counts are marked', () => expect(log(repsDone: 8, repSource: 'camera').doneLabel, '1 of 1 set · 8 reps (camera)'));
  });

  group('sessions stopped for safety', () {
    test('high pain and warning-sign flags mark their session', () {
      final pain = flag('f1', 'high_pain', {'pain': 8, 'exercise': 'heel_raise', 'session_id': 's1'});
      expect(detail([pain]).safetyStops, {'s1': pain});
      final red = flag('f2', 'red_flag', {'symptom': 'fall', 'session_id': 's2'});
      expect(detail([red]).safetyStops, {'s2': red});
    });

    test('other flags and flags without a session do not', () {
      expect(detail([flag('f1', 'missed_days', {'days': 3, 'session_id': 's1'})]).safetyStops, isEmpty);
      expect(detail([flag('f2', 'high_pain', {'pain': 9})]).safetyStops, isEmpty);
    });

    test('with two flags on one session the first one stays', () {
      // Flags arrive newest first, as the patient page loads them.
      final first = flag('f1', 'high_pain', {'pain': 8, 'session_id': 's1'}, at: DateTime(2026, 10, 30, 10));
      final second = flag('f2', 'red_flag', {'symptom': 'fall', 'session_id': 's1'}, at: DateTime(2026, 10, 30, 11));
      expect(detail([second, first]).safetyStops['s1'], same(first));
    });
  });
}
