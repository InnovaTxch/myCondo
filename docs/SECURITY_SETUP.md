# Public Repo Security Setup

This repository is public. Keep credentials and machine-specific config out of git.

## Never Commit These Files

- `.env`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- Any Firebase service-account key JSON (example: `firebase-adminsdk-*.json`, `serviceAccountKey.json`)
- Any Apple key/certificate files (`*.p8`, `*.p12`, `*.mobileprovision`)

These are already ignored in `.gitignore`. If you created them locally, that is expected.

## Safe Setup For New Developers

1. Clone the repo.
2. Create local env file:
   - Copy `.env.example` to `.env`
   - Fill your own Supabase and Firebase Web values
3. Add Firebase mobile config files locally:
   - Android: place `google-services.json` in `android/app/`
   - iOS: place `GoogleService-Info.plist` in `ios/Runner/`
4. For web push, update `web/firebase-messaging-sw.js` with your Firebase Web app values.
5. Run:
   - `flutter pub get`
   - `flutter run`

## If Sensitive Files Were Already Tracked

Stop tracking them without deleting local copies:

```bash
git rm --cached .env
git rm --cached android/app/google-services.json
git rm --cached ios/Runner/GoogleService-Info.plist
```

Verify they are no longer tracked:

```bash
git ls-files .env android/app/google-services.json ios/Runner/GoogleService-Info.plist
```

Then commit the cleanup:

```bash
git add .gitignore docs/SECURITY_SETUP.md README.md
git commit -m "docs: add public-repo security setup and ignore guidance"
```

## Rotate Credentials If Exposed

If a key was ever pushed to a public remote, rotate it immediately:

1. Firebase service-account key: revoke old key, create a new one
2. Supabase secrets: replace affected secrets in dashboard/CLI
3. Re-deploy `send-push-event` function after updating secrets

## Note On Firebase Web Config

Firebase Web config values (`apiKey`, `projectId`, etc.) are client identifiers and are typically exposed in web apps.  
They are not a substitute for server secrets. Keep privileged keys (service-account JSON, Supabase service role key) private.
