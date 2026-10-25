import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/env.dart';
import 'debug/frame_stats.dart';
import 'exercises/exercise.dart';
import 'data/local_store.dart';
import 'onboarding/welcome.dart';
import 'program/program_controller.dart';
import 'reminders/reminders.dart';
import 'settings/appearance.dart';
import 'settings/language.dart';
import 'sync/supabase_backend.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Env.environment == 'dev') FrameStats.start();

  // The backend is optional: the patient app must work fully offline.
  if (Env.hasSupabase) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
    );
  }

  // Bundled with the app, so it loads with no network.
  final library = await ExerciseLibrary.load();
  final appearance = await AppearanceController.load();
  final language = await LanguageController.load();
  final welcome = await WelcomeController.load();
  final programs = await ProgramController.load(
    library: library,
    store: await SqliteStore.open(),
    backend: Env.hasSupabase ? SupabaseBackend(Supabase.instance.client) : null,
  );
  // Sends anything logged offline and picks up program changes, in the background.
  programs.sync();
  final scheduler = LocalNotificationScheduler();
  final reminders = await ReminderController.load(scheduler);
  // Time zones and the notification plugin load in the background.
  scheduler.init();
  final app = PhysioApp(
    library: library,
    appearance: appearance,
    welcome: welcome,
    programs: programs,
    reminders: reminders,
    language: language,
  );

  if (!Env.hasSentry) {
    runApp(app);
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = Env.sentryDsn;
      options.environment = Env.environment;
      options.tracesSampleRate = 0.2;
      // Health app: never attach IP addresses, user details or screenshots.
      options.sendDefaultPii = false;
      options.attachScreenshot = false;
    },
    appRunner: () => runApp(SentryWidget(child: app)),
  );
}
