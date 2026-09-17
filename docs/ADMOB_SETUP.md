# AdMob & Advertising Setup

## Included in v1.5.1
- `google_mobile_ads` 9.1.0.
- Central `AdsService` abstraction.
- Banner, interstitial and rewarded ad APIs.
- Google UMP consent refresh on every launch.
- Privacy-options entry point.
- Google test ad unit IDs by default.
- Production IDs supplied through `--dart-define`, so no publisher IDs are hard-coded in Dart.

Google's current Flutter plugin supports banner, interstitial, rewarded and native ads. The app currently uses banner + optional interstitial/rewarded service hooks. Native ads can be added later without changing calculator code.

## Development
The app defaults to Google's test IDs. Do not click live ads during development. Google explicitly recommends test ads to avoid invalid activity.

## Production IDs
Create the Android/iOS AdMob app and ad units, then build with:

```text
flutter build appbundle --release \
  --dart-define=ADMOB_PRODUCTION=true \
  --dart-define=ADMOB_ANDROID_BANNER_ID=ca-app-pub-XXXX/YYYY \
  --dart-define=ADMOB_ANDROID_INTERSTITIAL_ID=ca-app-pub-XXXX/YYYY \
  --dart-define=ADMOB_ANDROID_REWARDED_ID=ca-app-pub-XXXX/YYYY
```

For iOS, also supply the three `ADMOB_IOS_*_ID` defines when building the IPA.

Replace the native App IDs in AndroidManifest.xml and iOS Runner/Info.plist with your own AdMob App IDs before store submission. The repository's current values are Google's sample/test App IDs.

## Privacy / consent
Ad requests are gated on UMP's `canRequestAds()`. The UMP SDK is refreshed at every launch and can display required consent forms. The settings screen exposes a privacy-options action; configure the corresponding privacy messages in the AdMob account.

If you enable mediation, add every mediation partner to the relevant consent/ad-partner configuration and enable test mode for each network while testing.

## Placement policy
- Banner: home shell only, below main content/navigation area.
- Interstitial/rewarded: service-level hooks only; do not call on every calculation or between input steps.
- Premium/remove-ads can later set `AdsService.instance.enabled = false` after entitlement verification.

## Important
A publisher AdMob account, app IDs, ad units, privacy policy, consent messages, store declarations and final ad placement review are still required before production monetization.
