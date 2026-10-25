import '../data/local_store.dart';
import '../program/program.dart';

/// How one calendar day went.
enum DayStatus {
  /// At least one session was finished or stopped that day.
  done,

  /// Exercises were scheduled and nothing was done.
  missed,

  /// Nothing was scheduled.
  rest,

  /// Today, with exercises scheduled and not done yet.
  due,

  /// Before the patient started using the app.
  before,
}

/// One row of an exercise's history.
class ExerciseHistoryEntry {
  const ExerciseHistoryEntry({required this.day, required this.record});

  final DateTime day;
  final ExerciseRecord record;
}

/// Progress worked out on the phone from the program's schedule and the
/// logged sessions. It needs no internet, so streaks survive offline days.
class Progress {
  Progress(this.program, List<SessionRecord> sessions, {DateTime? today})
    : today = _date(today ?? DateTime.now()),
      _doneDays = {for (final s in sessions) _date(s.performedOn)},
      _sessions = sessions,
      _start = sessions.isEmpty
          ? null
          : sessions.map((s) => _date(s.performedOn)).reduce((a, b) => a.isBefore(b) ? a : b);

  final Program program;
  final DateTime today;
  final Set<DateTime> _doneDays;
  final List<SessionRecord> _sessions;
  final DateTime? _start;

  static DateTime _date(DateTime d) => DateTime(d.year, d.month, d.day);

  bool get hasHistory => _sessions.isNotEmpty;
  int get sessionCount => _sessions.length;

  DayStatus statusOn(DateTime day) {
    final d = _date(day);
    if (_doneDays.contains(d)) return DayStatus.done;
    final start = _start;
    if (start == null || d.isBefore(start) || d.isAfter(today)) {
      return d.isAfter(today) || program.on(d).isEmpty ? DayStatus.rest : DayStatus.before;
    }
    if (program.on(d).isEmpty) return DayStatus.rest;
    return d == today ? DayStatus.due : DayStatus.missed;
  }

  /// Scheduled days done over the last [days] days (today included only once
  /// it is done), as 0 to 1. Null when nothing was scheduled in that time.
  double? adherence({int days = 7}) {
    var scheduled = 0;
    var done = 0;
    for (var i = 0; i < days; i++) {
      final status = statusOn(today.subtract(Duration(days: i)));
      if (status == DayStatus.done) {
        scheduled++;
        done++;
      } else if (status == DayStatus.missed) {
        scheduled++;
      }
    }
    return scheduled == 0 ? null : done / scheduled;
  }

  /// Scheduled days done in a row, counting back from today (or yesterday
  /// while today is still due). Rest days do not break a streak.
  int get streak {
    var count = 0;
    for (var i = 0; i < 366; i++) {
      final status = statusOn(today.subtract(Duration(days: i)));
      switch (status) {
        case DayStatus.done:
          count++;
        case DayStatus.rest || DayStatus.due:
          continue;
        case DayStatus.missed || DayStatus.before:
          return count;
      }
    }
    return count;
  }

  /// The last [days] days, oldest first.
  List<(DateTime, DayStatus)> recentDays({int days = 14}) => [
    for (var i = days - 1; i >= 0; i--) (today.subtract(Duration(days: i)), statusOn(today.subtract(Duration(days: i)))),
  ];

  /// Every logged run of each exercise, newest first, keyed by exercise id.
  Map<String, List<ExerciseHistoryEntry>> get historyByExercise {
    final out = <String, List<ExerciseHistoryEntry>>{};
    for (final s in _sessions) {
      for (final e in s.exercises) {
        out.putIfAbsent(e.exerciseId, () => []).add(ExerciseHistoryEntry(day: _date(s.performedOn), record: e));
      }
    }
    for (final list in out.values) {
      list.sort((a, b) => b.record.createdAt.compareTo(a.record.createdAt));
    }
    return out;
  }
}
