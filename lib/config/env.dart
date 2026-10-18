/// Build-time configuration, passed with `--dart-define-from-file=env/dev.json`.
///
/// Every value is optional so the app still builds and runs offline when a
/// service is not configured yet.
abstract final class Env {
  static const environment = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get hasSentry => sentryDsn.isNotEmpty;
  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
