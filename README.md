# Physio App (working name)

Offline-first physiotherapy home exercise app with on-device AI.
Spec and roadmap: <https://claude.ai/code/artifact/4a4808d3-cfb5-4e04-bd01-da28f109b313>

## Run it

1. Copy `env/example.json` to `env/dev.json` and fill in the values you have.
   Every value is optional; the app runs offline without them.
2. Plug in an Android phone with USB debugging on, then:

```bash
flutter run --dart-define-from-file=env/dev.json
```

Build an installable APK instead:

```bash
flutter build apk --debug --dart-define-from-file=env/dev.json
```

## Layout

| Path | What lives there |
| --- | --- |
| `lib/main.dart` | Start-up: optional Supabase and Sentry, then the app |
| `lib/app.dart` | App shell and the M0 status screen |
| `lib/config/env.dart` | Build-time settings read from `env/*.json` |
| `supabase/migrations/` | Database schema with row-level security |

## Services

- **Crash reporting:** Sentry project `dev-u15/physio-app`. No personal data or screenshots are sent.
- **Backend:** Supabase, India region (ap-south-1). Apply `supabase/migrations/` once the project exists.
