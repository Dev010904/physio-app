/// One published program version, as the schedule sees it: the day it took
/// over and the weekdays it has anything on.
class ScheduleVersion {
  const ScheduleVersion({required this.startsOn, required this.weekdays});

  /// Local calendar day the version was published.
  final DateTime startsOn;

  /// ISO weekdays (Monday = 1) with at least one exercise.
  final Set<int> weekdays;
}

/// How one calendar day went, from the clinic's point of view.
enum DayStatus {
  /// Scheduled, and a session was logged.
  done,

  /// Scheduled, and nothing was logged.
  missed,

  /// Today, scheduled and not done yet. Not counted until it is done.
  due,

  /// Nothing was scheduled (a session that day is a bonus, not counted).
  rest,

  /// Before the patient started, or in the future.
  outside,
}

/// Adherence and missed days, worked out on read from the program versions
/// and the session dates. Nothing here is stored.
class Adherence {
  Adherence({
    required List<ScheduleVersion> versions,
    required Iterable<DateTime> sessionDays,
    required DateTime today,
    DateTime? linkedOn,
  }) : today = dateOnly(today),
       _versions = [...versions]..sort((a, b) => a.startsOn.compareTo(b.startsOn)),
       _done = {for (final d in sessionDays) dateOnly(d)},
       _linkedOn = linkedOn == null ? null : dateOnly(linkedOn);

  /// A run of missed scheduled days this long shows a warning.
  static const missedWarningDays = 3;

  final DateTime today;
  final List<ScheduleVersion> _versions;
  final Set<DateTime> _done;
  final DateTime? _linkedOn;

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// First day that counts: the later of the first program and the day the
  /// phone was linked (or, failing that, the first logged session). Null
  /// while the patient has not started.
  DateTime? get start {
    if (_versions.isEmpty) return null;
    final first = dateOnly(_versions.first.startsOn);
    final began = _linkedOn ?? (_done.isEmpty ? null : _done.reduce((a, b) => a.isBefore(b) ? a : b));
    if (began == null) return null;
    return began.isAfter(first) ? began : first;
  }

  /// The version in force on [day]: the latest one published on or before it.
  ScheduleVersion? versionOn(DateTime day) {
    final d = dateOnly(day);
    ScheduleVersion? found;
    for (final v in _versions) {
      if (!dateOnly(v.startsOn).isAfter(d)) found = v;
    }
    return found;
  }

  DayStatus statusOn(DateTime day) {
    final d = dateOnly(day);
    final s = start;
    if (s == null || d.isBefore(s) || d.isAfter(today)) return DayStatus.outside;
    final scheduled = versionOn(d)?.weekdays.contains(d.weekday) ?? false;
    if (!scheduled) return DayStatus.rest;
    if (_done.contains(d)) return DayStatus.done;
    return d == today ? DayStatus.due : DayStatus.missed;
  }

  DateTime _daysAgo(int n) => DateTime(today.year, today.month, today.day - n);

  /// Scheduled days with a session, over the last [days] days including today.
  ({int done, int scheduled}) countsFor(int days) {
    var done = 0;
    var scheduled = 0;
    for (var i = 0; i < days; i++) {
      switch (statusOn(_daysAgo(i))) {
        case DayStatus.done:
          done++;
          scheduled++;
        case DayStatus.missed:
          scheduled++;
        case DayStatus.due || DayStatus.rest || DayStatus.outside:
          break;
      }
    }
    return (done: done, scheduled: scheduled);
  }

  /// Share of scheduled days done over the last [days] days, 0 to 1; null
  /// when nothing was scheduled in that time.
  double? rate(int days) {
    final c = countsFor(days);
    return c.scheduled == 0 ? null : c.done / c.scheduled;
  }

  /// The scheduled days missed in a row up to now, newest first. Rest days
  /// neither break nor add to the run; a done day ends it.
  List<DateTime> get currentMissedRun {
    final run = <DateTime>[];
    for (var i = 0; i < 400; i++) {
      final day = _daysAgo(i);
      switch (statusOn(day)) {
        case DayStatus.missed:
          run.add(day);
        case DayStatus.due || DayStatus.rest:
          continue;
        case DayStatus.done || DayStatus.outside:
          return run;
      }
    }
    return run;
  }

  int get missedInARow => currentMissedRun.length;

  bool get showMissedWarning => missedInARow >= missedWarningDays;

  /// The last [days] days, oldest first, for a strip of day dots.
  List<(DateTime, DayStatus)> recentDays(int days) => [
    for (var i = days - 1; i >= 0; i--) (_daysAgo(i), statusOn(_daysAgo(i))),
  ];
}
