# All-in-One Calculator

A privacy-first Flutter utility app for Android and iOS. It is intentionally built without login, cloud storage, location, contacts, camera, microphone, or other unnecessary permissions.

## Included in v1.0
- Modern Material 3 UI with light/dark/system themes
- Basic calculator: +, −, ×, ÷, %, sign, decimal, backspace, history
- Finance: Percentage, GST, EMI, SIP, FD
- Converter: Length, Weight, Temperature, Area, Data
- Tools: Age, BMI, Date Difference, Word/Character Counter, Fuel Cost
- Haptic feedback toggle
- Local preferences only
- No account required

## Development baseline
- Flutter 3.47 stable / Dart 3.9+ target
- Android target API 36 for Google Play submissions from Aug 31, 2026
- iOS deployment target should be set to the current Xcode-supported minimum at release time

## Run on Windows PC
1. Install the current stable Flutter SDK and Android Studio.
2. Run `flutter doctor` and resolve Android toolchain issues.
3. From this folder run `flutter pub get`.
4. Run `flutter analyze`.
5. Run `flutter test`.
6. Connect an Android phone/emulator and run `flutter run`.
7. For release: configure the final application ID, app icon, signing key, privacy-policy URL, store metadata, then run the release build.

## Store-readiness notes
- Do not add ad/analytics SDKs until their privacy disclosures and consent requirements are reviewed.
- Do not add permissions that are not necessary for a feature.
- Keep the privacy policy accessible inside the app and in store metadata.
- Before submission, verify current Google Play target API and Apple App Review requirements.

## Next production tasks before publishing
- Replace placeholder package/application IDs with the final brand identity.
- Add final launcher icon and adaptive icon.
- Add localized app name/metadata.
- Add privacy policy URL.
- Add optional AdMob/IAP only after monetization configuration is finalized.
- Perform Android physical-device, tablet and large-screen testing.
- Perform iPhone/iPad testing and App Store Connect metadata validation.
- Generate signed AAB and iOS archive on the developer machine.

## Monetization
v1.5.1 includes a centralized AdMob/UMP integration. Google test ads are used by default. Production AdMob App IDs and ad unit IDs must be supplied from your own account before release. See `docs/ADMOB_SETUP.md`.
