# Symposium Flutter — Auth, KYN Intro & Onboarding

## Included screens
1. Welcome
2. Login / sign up (email or mobile)
3. OTP UI
4–6. Three KYN introductory carousel pages (real people photo assets)
7. Basic profile
8. Professional profile — "What do you do?" (shared form style reference)
9. Interests
10. Connections & home location
11. Current-location permission, GPS lookup and manual-city fallback
12. Home navigation handoff placeholder

## Getting started
Requires Flutter SDK 3.24+ and Android/iOS SDKs.

```sh
flutter create --platforms=android,ios .
flutter pub get
flutter run
```

Run `flutter create` in this directory to generate the native `android/` and `ios/` runners, which are not included in this source bundle.

## Android permission
In `android/app/src/main/AndroidManifest.xml`, inside `<manifest>` add:

```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

## iOS permission
In `ios/Runner/Info.plist`, inside `<dict>` add:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Symposium uses your approximate location to discover nearby people. Your precise location is not shared with other users.</string>
```

## Global styling
- `lib/core/theme.dart` → `AppColors`, `AppSpace`, `buildAppTheme()`
- `lib/widgets/common.dart` → shared form inputs, primary button, chips, onboarding shell
- `lib/core/routes.dart` → named navigation
- `lib/core/onboarding_data.dart` → temporary local state (not persisted securely)

## Production integration needed
- OTP screen is UI/navigation only: it **does not** validate a real OTP. Connect to a secure auth provider and only navigate on server-confirmed verification.
- Photo picker in basic profile is a visual placeholder, not a functioning upload.
- Onboarding data is in-memory and must be sent to a backend after authentication; `shared_preferences` stores only a demo completion flag.
- Geolocator retrieves current coordinates only after permission. Never publish raw coordinates to other users; enforce locality-only visibility on the server.
- Home is a placeholder handoff, not the full home screen.
- Font uses the `Inter` family name, but licensed font files are not bundled. Provide Inter font assets and declare them in `pubspec.yaml` for exact typography. Without the font installed, Flutter uses platform fallback.
- Figma exact export/screenshots weren't available for verification; layouts use 393×852 reference, brand pink `#D91D52`, 28px page padding, 54px buttons, and matched text/copy where known. Pixel-perfect comparison and adjustments are still required.
- Add form validation, accessibility review, widget/golden tests, API error states, loading/resend cooldown, permission retry and production routing before shipping.
