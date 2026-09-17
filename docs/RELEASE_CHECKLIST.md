# v1.5 Release Checklist

1. Install current Flutter stable.
2. `flutter pub get`
3. `flutter analyze`
4. `flutter test`
5. Test on a physical Android phone.
6. Test on a physical iPhone.
7. Configure final Android applicationId and iOS bundle identifier.
8. Configure release signing.
9. Add final app icon and launch assets.
10. Add public privacy policy and support URLs.
11. Complete Google Play Data Safety and Apple App Privacy declarations based on the actual release build.
12. `flutter build appbundle --release`
13. `flutter build ipa --release` after Apple signing is configured.
14. Recheck current store policies immediately before submission.
