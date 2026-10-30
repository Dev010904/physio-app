import 'package:clinician_web/logic/adherence.dart';
import 'package:flutter_test/flutter_test.dart';

// Sunday 25 October 2026; so 19 Oct is a Monday.
final today = DateTime(2026, 10, 25, 15, 30);
DateTime oct(int day) => DateTime(2026, 10, day);
DateTime sep(int day) => DateTime(2026, 9, day);

const everyDay = {1, 2, 3, 4, 5, 6, 7};
const weekdays = {1, 2, 3, 4, 5};

Adherence make({
  List<ScheduleVersion>? versions,
  List<DateTime> sessions = const [],
  DateTime? linkedOn,
}) => Adherence(
  versions: versions ?? [ScheduleVersion(startsOn: sep(1), weekdays: everyDay)],
  sessionDays: sessions,
  linkedOn: linkedOn ?? sep(1),
  today: today,
);

void main() {
  group('start', () {
    test('nothing is counted without a program', () {
      final a = make(versions: []);
      expect(a.start, isNull);
      expect(a.rate(7), isNull);
      expect(a.missedInARow, 0);
    });

    test('nothing is counted before the phone is linked', () {
      final a = Adherence(versions: [ScheduleVersion(startsOn: oct(1), weekdays: everyDay)], sessionDays: const [], today: today);
      expect(a.start, isNull);
      expect(a.statusOn(oct(20)), DayStatus.outside);
    });

    test('counting starts at the later of the program and the link', () {
      expect(make(versions: [ScheduleVersion(startsOn: oct(10), weekdays: everyDay)], linkedOn: oct(3)).start, oct(10));
      expect(make(versions: [ScheduleVersion(startsOn: oct(3), weekdays: everyDay)], linkedOn: oct(10)).start, oct(10));
    });

    test('without a link date the first session starts it', () {
      final a = Adherence(versions: [ScheduleVersion(startsOn: oct(1), weekdays: everyDay)], sessionDays: [oct(12)], today: today);
      expect(a.start, oct(12));
    });
  });

  group('day status', () {
    test('done, missed, rest and due', () {
      final a = make(versions: [ScheduleVersion(startsOn: sep(1), weekdays: weekdays)], sessions: [oct(19)]);
      expect(a.statusOn(oct(19)), DayStatus.done); // Monday
      expect(a.statusOn(oct(20)), DayStatus.missed); // Tuesday
      expect(a.statusOn(oct(24)), DayStatus.rest); // Saturday
      expect(a.statusOn(oct(26)), DayStatus.outside); // tomorrow
    });

    test('today is due until it is done', () {
      expect(make().statusOn(today), DayStatus.due);
      expect(make(sessions: [oct(25)]).statusOn(today), DayStatus.done);
    });

    test('a session on a rest day is not counted', () {
      final a = make(versions: [ScheduleVersion(startsOn: sep(1), weekdays: weekdays)], sessions: [oct(24)]);
      expect(a.statusOn(oct(24)), DayStatus.rest);
    });

    test('the version in force on each day decides the schedule', () {
      final a = make(
        versions: [
          ScheduleVersion(startsOn: oct(22), weekdays: {1}), // only Mondays from Thursday on
          ScheduleVersion(startsOn: sep(1), weekdays: everyDay),
        ],
      );
      expect(a.statusOn(oct(21)), DayStatus.missed); // still the first version
      expect(a.statusOn(oct(22)), DayStatus.rest);
      expect(a.statusOn(oct(23)), DayStatus.rest);
      expect(a.versionOn(oct(21))!.weekdays, everyDay);
    });
  });

  group('adherence rate', () {
    test('7 days: today is left out until done', () {
      // 19 to 25 Oct: done Mon, Tue, Thu, Fri; missed Wed, Sat; Sun is today.
      final a = make(sessions: [oct(19), oct(20), oct(22), oct(23)]);
      expect(a.countsFor(7), (done: 4, scheduled: 6));
      expect(a.rate(7), closeTo(4 / 6, 1e-9));
    });

    test('7 days on a weekday schedule ignores weekends', () {
      final a = make(versions: [ScheduleVersion(startsOn: sep(1), weekdays: weekdays)], sessions: [oct(19), oct(20), oct(21), oct(22), oct(23), oct(24)]);
      expect(a.countsFor(7), (done: 5, scheduled: 5));
      expect(a.rate(7), 1.0);
    });

    test('28 days counts only from the start', () {
      final a = make(linkedOn: oct(18), sessions: [oct(18), oct(21), oct(25)]);
      // 18 to 25 Oct is 8 days, all scheduled; today is done, so it counts.
      expect(a.countsFor(28), (done: 3, scheduled: 8));
    });

    test('null when nothing was scheduled', () {
      final a = make(versions: [ScheduleVersion(startsOn: sep(1), weekdays: {1})], linkedOn: oct(20));
      // 20 to 25 Oct has no Monday.
      expect(a.rate(7), isNull);
    });
  });

  group('missed days in a row', () {
    test('counts back from yesterday while today is due', () {
      final a = make(sessions: [oct(20)]);
      expect(a.currentMissedRun, [oct(24), oct(23), oct(22), oct(21)]);
      expect(a.missedInARow, 4);
      expect(a.showMissedWarning, isTrue);
    });

    test('two missed days is not a warning', () {
      final a = make(sessions: [oct(22)]);
      expect(a.missedInARow, 2);
      expect(a.showMissedWarning, isFalse);
    });

    test('rest days neither break nor add to the run', () {
      // Weekdays only: missed Wed 21, Thu 22, Fri 23; Sat 24 and Sun 25 are rest.
      final a = make(versions: [ScheduleVersion(startsOn: sep(1), weekdays: weekdays)], sessions: [oct(20)]);
      expect(a.currentMissedRun, [oct(23), oct(22), oct(21)]);
      expect(a.showMissedWarning, isTrue);
    });

    test('a session today ends the run', () {
      expect(make(sessions: [oct(20), oct(25)]).missedInARow, 0);
    });

    test('the run stops where counting started', () {
      final a = make(linkedOn: oct(23));
      expect(a.currentMissedRun, [oct(24), oct(23)]);
    });

    test('exactly three in a row shows the warning', () {
      final a = make(sessions: [oct(21)]);
      expect(a.missedInARow, 3);
      expect(a.showMissedWarning, isTrue);
    });
  });

  test('recent days run oldest first and end today', () {
    final days = make(sessions: [oct(24)]).recentDays(3);
    expect(days.map((d) => d.$1), [oct(23), oct(24), oct(25)]);
    expect(days.map((d) => d.$2), [DayStatus.missed, DayStatus.done, DayStatus.due]);
  });
}
