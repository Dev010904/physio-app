# Getting PhysioSathi onto Google Play (pilot)

What is ready, what you still need to do, and the answers for Play's forms.
Checked against the Play Console Help pages on 2026-10-30:
- [Data safety section](https://support.google.com/googleplay/android-developer/answer/10787469)
- [Health app categories](https://support.google.com/googleplay/android-developer/answer/13996367)

## 1. Make the upload key (you do this once)

The upload key's password is yours to choose and keep, so this step is yours.

1. Run this command and answer its questions. Choose a strong password.

   ```
   mkdir C:\Users\hp602\keys
   "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore C:\Users\hp602\keys\physiosathi-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Copy `android/key.properties.example` to `android/key.properties` and fill in both passwords. Git ignores this file.
3. Back up the `.jks` file and the password, for example in your password manager. With Play App Signing, Google keeps the real app-signing key. If the upload key is ever lost, you can ask Play for a new one, but that takes time.

After that, `flutter build appbundle --release --dart-define-from-file=env/dev.json` signs with your upload key.
Without `key.properties`, the build still works but is signed with the debug key, which Play rejects.

## 2. Start with the internal testing track

According to the Data safety page, "Apps that are active on internal testing tracks are exempt" from the Data safety section.
An internal test for the pilot clinic and its patients can therefore start before that form is final.
You still need these:
- a privacy policy URL (draft: `docs/privacy-policy.md`, to host once you fill in the [brackets]);
- the **Health apps declaration**, which Play now requires for every app.

Current build: version 0.1.0 (code 1). The bundle is about 102 MB, but most of that is debug symbols that Play keeps and phones never download.
On an arm64 phone like the POCO, the app's own files come to about 27 MB compressed before Play's own compression.
The camera pose model accounts for about 12 MB of that. The "accurate" pose model (6.4 MB) is bundled but not used, so a later build can drop it.

## 3. Health apps declaration

Play's categories include **health and fitness apps**, which let users track progress towards fitness goals.
They also include **medical apps**, which cover "remote monitoring apps" and "disease management apps" used by patients for health management and care delivery.
PhysioSathi does both: a patient follows a physio-prescribed exercise program, and the clinic monitors adherence, pain and safety alerts.
Pick the options in the form that match those two descriptions.
PhysioSathi does not diagnose anything and is not a regulated medical device. Say so in the store listing.

## 4. Data safety answers (when moving past internal testing)

Definitions from Play's page:
- **Collect** means sending data off the phone.
- Processing that happens only on the phone is "not in scope".
- **Sharing** means a transfer to a third party. A transfer does not count as sharing if it goes to a service provider working for us (Supabase, Sentry) or follows "a specific user-initiated action, where the user reasonably expects the data to be shared". Entering the physio's code is that kind of action.

**Overview questions**
- Does the app collect or share any of the required data types? **Yes.**
- Is all collected data encrypted in transit? **Yes.** Both Supabase and Sentry are reached over HTTPS (checked in `env/dev.json`).
- Can users request that their data be deleted? **Yes.** The app has Settings → Your data → Delete my data, and you can add a contact email.

**Data types**

| Play data type | What PhysioSathi sends | Collected / shared | Required or optional | Purpose |
| --- | --- | --- | --- | --- |
| Health and fitness → Health info | Pain scores 0–10; safety alerts (high pain, chest pain, numbness, severe pain, fall) | Collected, not shared | Optional (only after linking with a code) | App functionality |
| Health and fitness → Fitness info | Session dates, sets and reps done, rep source, best movement angle, easy/OK/hard | Collected, not shared | Optional | App functionality |
| App activity → Other user-generated content | Notes the patient chooses to share with the physio | Collected, not shared | Optional | App functionality |
| Personal info → User IDs | Random anonymous account ID, tied to the patient record the clinic created | Collected, not shared | Optional | App functionality, Account management |
| App info and performance → Crash logs | Sentry error reports | Collected, not shared | Required (no opt-out yet) | Analytics |
| App info and performance → Diagnostics | Sentry performance samples (20% of sessions) | Collected, not shared | Required | Analytics |
| Device or other IDs | Random installation ID in Sentry reports | Collected, not shared | Required | Analytics |

**Not collected**
- **Photos and videos:** camera frames are processed on the phone only, which Play defines as not in scope.
- **Audio:** the app uses no microphone. The plugin's microphone permission is removed from the manifest.
- **Name, email, phone:** the app never sends these. The clinic types the patient's name into its own dashboard.
- **Location:** not used, and IP addresses are not used to infer location.

The device-ID row is a cautious choice. Sentry's Android SDK adds an installation ID to its reports.
Declaring more than you collect is allowed; declaring less is a policy violation.

**Optional improvement:** add a "Send crash reports" switch in Settings. Crash logs, diagnostics and the device ID could then be marked optional.

## 5. Still to do before a public release

- Do the camera accuracy check on a real person: count reps by hand and compare them with the camera, for each of the 5 countable exercises.
- Run the full end-to-end test: dashboard → code → session → sync → dashboard. This needs anonymous sign-in turned on in Supabase Auth.
- Have a physio review the draft exercise text, the Hindi text and the muscle labels.
- Write a Hindi version of the privacy policy.
