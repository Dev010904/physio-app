# PhysioSathi clinician dashboard

Flutter web app for physiotherapists: sign in, create the clinic, add patients
(one-time access codes), build and publish programs, and follow adherence,
pain and flags. It talks to the same Supabase project as the patient app
(`../supabase/migrations`); row-level security keeps every query inside the
clinician's clinic.

It reuses the patient app by path for the theme, logo, `Prescription` and
`SessionPlan`, so session lengths match the phone's player exactly. It never
imports the patient app's `dart:io` or sqflite files.

## Run locally

```bash
flutter run -d chrome --dart-define-from-file=../env/dev.json
```

Or build and serve the `web` folder:

```bash
flutter build web --release --dart-define-from-file=../env/dev.json
```

`env/dev.json` is git-ignored; never commit it. The build output in `build/`
contains the publishable key, so it is ignored too.

## Test

```bash
flutter analyze
flutter test
```

`flutter test tool/render_web_icons_test.dart` redraws the favicon and web
icons from the logo painter.
