import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's language: 'en', 'hi', or null to follow the phone.
/// Remembered between launches.
class LanguageController extends ValueNotifier<String?> {
  LanguageController([super.value]);

  static const _key = 'language';
  static const supported = ['en', 'hi'];

  static Future<LanguageController> load() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(_key);
      return LanguageController(supported.contains(saved) ? saved : null);
    } catch (_) {
      return LanguageController();
    }
  }

  /// The locale to force, or null to let the phone decide.
  Locale? get locale => value == null ? null : Locale(value!);

  Future<void> set(String? language) async {
    value = language;
    try {
      final prefs = await SharedPreferences.getInstance();
      language == null ? await prefs.remove(_key) : await prefs.setString(_key, language);
    } catch (_) {
      // Not saved; the choice still applies until the app closes.
    }
  }
}
