# SyyncIn — Flutter (Onboarding → Profile Setup → Verified)

Pixel-matched to Figma page **"SyyncIn · V3 · MoM 17 Oct updates"** (iPhone 393 × 852).
Colours, type sizes, radii and spacing are copied from the Figma layers; Inter is bundled.

## Run

```bash
cd syyncin_app
flutter create . --org com.trustiqlabs --project-name syyncin --platforms=ios,android   # adds ios/ & android/ (won't overwrite lib/)
flutter pub get
flutter run
```

Then export the 4 images listed in `assets/images/README.md` (the app shows placeholders until you do).

**Demo OTP:** `123456` (any other code shows the "incorrect code" state).

## Flow

Splash (1.5 s) → Welcome → Onboarding ×3 (swipe / Next / Skip) → Log in → OTP →
Step 1 About you → Step 2 Your work → Step 3 Interests + "I'm here to…" → Step 4 Mindset →
Step 5 Community → Selfie → Verified → Home placeholder.

| Rule | Where |
|---|---|
| Continue needs phone/email + Terms ticked | Login |
| 6 digits to verify, 30 s resend timer | OTP |
| Full name required | Step 1 |
| Job title, industry, experience required | Step 2 |
| ≥ 3 interests and 1–3 reasons | Step 3 |
| All 5 questions answered | Step 4 |
| City required | Step 5 |

## Structure

```
lib/
  main.dart                    App + text-height behaviour (matches Figma leading)
  app/routes.dart              Named routes
  core/
    theme/app_colors.dart      All Figma colours + gradients (auth / setup / splash)
    theme/app_text_styles.dart Type scale (Inter 400/500/600/700)
    icons/app_icons.dart       SVG icons + Google/LinkedIn/Apple logos
    widgets/                   Reusable UI kit (import widgets.dart)
      buttons.dart             PrimaryButton (auth|setup, disabled 40 %), SocialButton, back buttons
      inputs.dart              AppTextField (text / picker), AuthTextField, OtpInput, FieldLabel
      selection.dart           SelectChip, ReasonCard, OptionCard/OptionGrid, SegmentedChoice,
                               AppRadio, AppCheckbox, AppToggle, NumberBadge
      layout.dart              StepHeader, SetupScaffold, SectionHeading, BrandLogo, Tagline,
                               AssetBox, FillScrollView, DividerLine
  features/
    onboarding/                Splash, Welcome (+ NearbyVisual), Onboarding pager
    auth/                      Login, OTP
    profile_setup/             Steps 1–5, Selfie, Verified, SetupDraft (in-memory state)
    home/                      Placeholder
```

## Next to wire

- `SetupDraft` → replace with Riverpod/Bloc + your Node API.
- Photo upload → `image_picker`; Selfie → `camera` + liveness/face-match SDK.
- OTP → your SMS/email OTP endpoint (`OtpScreen._verify`).

## Connecting to the API

The app talks to the SyyncIn API (`syyncin_api`). Start it first (`npm run dev`, optionally `npm run db:demo`).

```bash
flutter pub get
flutter run                                             # uses the server in lib/core/config/env.dart (https://api.syyncin.trustiqlabs.com)
flutter build apk                                       # same — no flag needed for builds

# Only when testing against the API running on your Mac:
flutter run -d chrome --dart-define=API_URL=http://localhost:4000
flutter run --dart-define=API_URL=http://10.0.2.2:4000       # Android emulator
flutter run --dart-define=API_URL=http://192.168.1.20:4000   # real phone → your Mac's Wi-Fi IP
```

Demo login (after `npm run db:demo`): **+919000000001** (Krupa Shah). In mock OTP mode the code is shown on the OTP screen ("Test mode · your code is …").

### Live notifications (while the app is open)
- After login the app keeps a Socket.IO connection (`lib/core/realtime/realtime_service.dart`).
- New connection request / request accepted → in-app banner (foreground, all platforms) or system notification (Android/iOS in background). Tap → Inbox.
- Inbox lists, the Inbox tab dot and the bell count update live — no refresh needed.
- Anything that arrived while the app was closed is in the bell → Notifications screen.
- Push notifications (app fully closed) come later via FCM; the API already routes every notification through `src/services/push.js`.

### When you add Android / iOS (`flutter create --platforms=android,ios .`)
- Android: `flutter_local_notifications` needs core library desugaring — in `android/app/build.gradle` add `coreLibraryDesugaringEnabled true` under `compileOptions` and `coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'` under `dependencies`. For a local `http://` API also set `android:usesCleartextTraffic="true"` on `<application>` in `AndroidManifest.xml`.
- iOS: nothing extra for foreground notifications; the permission prompt appears on first launch.

## Publish the web app (Hostinger domain)

```bash
bash tool/deploy_web.sh                      # domain root
BASE_HREF=/syyncin/ bash tool/deploy_web.sh  # or a sub-folder
```
Upload `build/syyncin_web.zip` in hPanel → File Manager → `public_html` → Extract.
`web/.htaccess` is included so a new upload shows up immediately.
