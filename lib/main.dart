import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/env.dart';
import 'exercises/exercise.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The backend is optional: the patient app must work fully offline.
  if (Env.hasSupabase) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
    );
  }

  // Bundled with the app, so it loads with no network.
  final library = await ExerciseLibrary.load();
  final app = PhysioApp(library: library);

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
