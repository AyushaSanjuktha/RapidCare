# RapidCare — Flutter Frontend (real-scope version)

## What's actually here vs. what ChatGPT's prompt asked for

That prompt listed 9 backend endpoints. Your real, tested backend only has
**2**: `POST /sos` and `POST /dispatch/{case_id}`. Building full screens for
the other 7 (hospital hand-off, case-status timeline, analytics, offline
fallback, responder accept/en-route) would mean UI that either silently
fails or has to fake data live in front of your panel — far riskier than a
smaller app that's 100% real.

So this app has **3 real, fully-wired screens** (Home → Emergency Details →
Severity + Dispatch result) plus lightweight "Coming Soon" placeholders for
Emergency Contacts, Profile, Medical Info, and History — so navigation
doesn't dead-end, but nothing claims to work that doesn't.

## Setup

1. Make sure you have Flutter installed: `flutter --version` (install from
   flutter.dev if not)
2. Copy this whole folder structure into a Flutter project:
   ```
   flutter create rapidcare_app
   ```
   then replace the generated `lib/` folder and `pubspec.yaml` with these files.
3. Install dependencies:
   ```
   flutter pub get
   ```
4. **Set your backend URL** in `lib/utils/constants.dart`:
   - Android emulator → `http://10.0.2.2:8000` (already set, default)
   - Physical phone on same WiFi → `http://<your-laptop-LAN-IP>:8000`
   - iOS simulator → `http://127.0.0.1:8000`
5. **Set a real user ID** in `lib/screens/emergency_details_screen.dart` —
   find `_demoUserId` and replace with a real UUID from your Supabase
   `users` table (copy one from Table Editor, same as we did for Swagger
   testing).
6. Make sure your FastAPI backend is running (`uvicorn main:app --reload`)
   before launching the app.
7. Run:
   ```
   flutter run
   ```

## Android location permission

`geolocator` needs a permission entry. Open
`android/app/src/main/AndroidManifest.xml` and add, just inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```
If you skip this, the app still works — `LocationService` catches the
permission failure and falls back to a fixed demo coordinate, so a live
demo never hard-crashes over a missing permission.

## What's a real placeholder vs. what's fully wired

**Fully wired, tested logic path:**
Home → press SOS → fill emergency details → confirm → `POST /sos` (gets
real severity from Harsha's model) → automatically calls
`POST /dispatch/{case_id}` → shows real assigned responder or a clear
"no responder available" state.

**Deliberately NOT wired (marked clearly in the UI, not faked):**
- Injury photo — captured in the UI, not sent anywhere yet (CV endpoint
  doesn't exist). See the `TODO` comment in `emergency_details_screen.dart`.
- Call Responder button — shows a placeholder snackbar instead of placing
  a real call.
- Emergency Contacts / Profile / Medical Info / History — "Coming Soon"
  screens via `ComingSoonPlaceholder` widget.
- Map — intentionally not included. Nothing in the brief's map section maps
  to a real backend endpoint yet; adding a visual-only map would be
  decoration, not function. Add it once live location tracking has a real
  data source.

## If you want to add a feature from the original ChatGPT prompt

Only do this once the matching FastAPI endpoint exists AND has been tested
via Swagger — the same discipline used for `/sos` and `/dispatch`. Then:
1. Add the method to `lib/services/api_service.dart` (there's a commented
   section at the bottom showing where the stubs go)
2. Add/extend a model in `lib/models/` if the response has new fields
3. Build the screen, wire it to the real method — never fabricate response
   data in the UI layer

## For your R2 deck

This app structure (models/services/screens/widgets separation, one
centralized API service, honest placeholders instead of fake data) is
itself a legitimate thing to show on your "Module Implementation" slide —
it demonstrates deliberate scope discipline, which the framework's
"Performance Metrics & Known Issues" slide explicitly rewards.
