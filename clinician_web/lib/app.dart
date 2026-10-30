import 'package:flutter/material.dart';
import 'package:physio_app/branding/logo.dart';
import 'package:physio_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'ui/auth_gate.dart';

/// Light, dark or follow the computer, remembered in this browser.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController(this._prefs) : super(_read(_prefs));

  final SharedPreferences? _prefs;

  static const _key = 'theme_mode';

  static ThemeMode _read(SharedPreferences? prefs) =>
      ThemeMode.values.where((m) => m.name == prefs?.getString(_key)).firstOrNull ?? ThemeMode.system;

  set mode(ThemeMode mode) {
    value = mode;
    _prefs?.setString(_key, mode.name);
  }
}

/// The patient app's design system, tuned for a mouse and a wide screen.
ThemeData dashboardTheme(ThemeData base) {
  final c = base.colorScheme;
  final radius = BorderRadius.circular(Brand.calm.radius - 4);
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: color, width: width));
  return base.copyWith(
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {for (final p in TargetPlatform.values) p: const FadeForwardsPageTransitionsBuilder()},
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(c.outline),
      enabledBorder: border(c.outline),
      focusedBorder: border(c.primary, 2),
      errorBorder: border(c.error),
      focusedErrorBorder: border(c.error, 2),
      labelStyle: base.textTheme.bodyLarge?.copyWith(color: c.onSurfaceVariant),
      floatingLabelStyle: base.textTheme.bodyLarge?.copyWith(color: c.primary, fontWeight: FontWeight.w600),
    ),
    tooltipTheme: const TooltipThemeData(waitDuration: Duration(milliseconds: 400)),
  );
}

class ClinicianApp extends StatelessWidget {
  const ClinicianApp({super.key, required this.theme});

  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: theme,
      builder: (context, mode, _) => MaterialApp(
        title: 'PhysioSathi for clinics',
        debugShowCheckedModeBanner: false,
        theme: dashboardTheme(AppTheme.light()),
        darkTheme: dashboardTheme(AppTheme.dark()),
        themeMode: mode,
        home: Env.hasSupabase ? AuthGate(theme: theme) : const _NotConfigured(),
      ),
    );
  }
}

class _NotConfigured extends StatelessWidget {
  const _NotConfigured();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Wordmark(size: 40),
              const SizedBox(height: 24),
              Text(
                'This dashboard is not connected to a clinic server yet.\n'
                'Run it with --dart-define-from-file pointing at env/dev.json.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
