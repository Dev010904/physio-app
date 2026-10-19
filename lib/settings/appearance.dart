import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Light, dark or follow the phone; remembered between launches.
class AppearanceController extends ValueNotifier<ThemeMode> {
  AppearanceController([super.value = ThemeMode.system]);

  static const _key = 'appearance';

  static Future<AppearanceController> load() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(_key);
      return AppearanceController(
        ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.system),
      );
    } catch (_) {
      return AppearanceController();
    }
  }

  Future<void> set(ThemeMode mode) async {
    value = mode;
    try {
      await (await SharedPreferences.getInstance()).setString(_key, mode.name);
    } catch (_) {
      // Not saved; the choice still applies until the app closes.
    }
  }
}
