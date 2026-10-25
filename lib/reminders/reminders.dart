import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Schedules the reminder on the phone. Split out so tests need no plugin.
abstract interface class ReminderScheduler {
  /// Asks for permission to show notifications; true when allowed.
  Future<bool> requestPermission();
  Future<void> scheduleDaily(TimeOfDay time);
  Future<void> cancel();
}

/// Android notifications through flutter_local_notifications. They are
/// scheduled inexactly, so no exact-alarm permission is needed; a few
/// minutes' drift is fine for a daily nudge.
class LocalNotificationScheduler implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  static const _id = 1;

  Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    }
    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('ic_launcher_monochrome')),
    );
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<bool> requestPermission() async => await _android?.requestNotificationsPermission() ?? true;

  @override
  Future<void> scheduleDaily(TimeOfDay time) async {
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: _id,
      title: 'Time for your exercises',
      body: 'A few minutes now keeps your recovery on track.',
      scheduledDate: at,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily reminder',
          channelDescription: 'A daily nudge to do your exercises',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancel() => _plugin.cancel(id: _id);
}

/// Does nothing; for tests and platforms without notifications.
class NoReminderScheduler implements ReminderScheduler {
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> scheduleDaily(TimeOfDay time) async {}
  @override
  Future<void> cancel() async {}
}

/// Whether the daily reminder is on, and when. Remembered between launches.
class ReminderSettings {
  const ReminderSettings({this.enabled = false, this.time = const TimeOfDay(hour: 9, minute: 0)});

  final bool enabled;
  final TimeOfDay time;
}

class ReminderController extends ValueNotifier<ReminderSettings> {
  ReminderController(this._scheduler, [super.value = const ReminderSettings()]);

  static const _enabledKey = 'reminder_enabled';
  static const _minutesKey = 'reminder_minutes';

  final ReminderScheduler _scheduler;

  static Future<ReminderController> load(ReminderScheduler scheduler) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final minutes = prefs.getInt(_minutesKey) ?? 9 * 60;
      return ReminderController(
        scheduler,
        ReminderSettings(
          enabled: prefs.getBool(_enabledKey) ?? false,
          time: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
        ),
      );
    } catch (_) {
      return ReminderController(scheduler);
    }
  }

  /// Turns the reminder on at [time]. Returns false when the phone does not
  /// allow notifications, leaving it off.
  Future<bool> enable(TimeOfDay time) async {
    if (!await _scheduler.requestPermission()) return false;
    await _scheduler.scheduleDaily(time);
    value = ReminderSettings(enabled: true, time: time);
    await _save();
    return true;
  }

  Future<void> disable() async {
    await _scheduler.cancel();
    value = ReminderSettings(time: value.time);
    await _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, value.enabled);
      await prefs.setInt(_minutesKey, value.time.hour * 60 + value.time.minute);
    } catch (_) {
      // Not saved; the reminder itself is still scheduled.
    }
  }
}
