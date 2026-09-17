# v1.5.0 Release Status

This package is the final source handoff built from the current project baseline.

## Implemented in the supplied codebase
- Material 3 Android/iOS Flutter structure
- Basic calculator
- Finance calculators: Percentage, GST, EMI, SIP, FD, Simple Interest, Compound Interest, RD, Salary
- Everyday tools: Age, BMI, Date Difference, Word Counter, Fuel Cost
- Theme and haptic preferences
- Android target SDK 36
- iOS project scaffold
- Automated formula sanity tests

## Required on the release PC
Flutter SDK and Xcode/Android Studio are not available in this execution environment, so a real `flutter analyze`, `flutter test`, Android AAB build, and iOS archive could not be executed here. Run the commands in RELEASE_CHECKLIST.md before store submission.

## Store safety
Do not publish until the final privacy policy URL, app identity/signing, store disclosures, screenshots, icons, and current Play/App Store requirements have been completed.

## v1.5.1 — Monetization-ready
- Google Mobile Ads Flutter plugin integrated.
- AdMob test IDs enabled by default.
- UMP consent gate and privacy-options hook included.
- Banner UI mounted at the app shell.
- Interstitial/rewarded hooks centralized for future controlled placements.
- Production publisher IDs remain configuration values and must be supplied before release.
