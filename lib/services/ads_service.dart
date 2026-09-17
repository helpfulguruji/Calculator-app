import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Centralized advertising layer. Keep all ad-provider calls here so the UI
/// never depends directly on a specific network implementation.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  bool enabled = true;
  bool initialized = false;
  bool _adsAllowed = false;

  static const _androidBannerTest = 'ca-app-pub-3940256099942544/9214589741';
  static const _iosBannerTest = 'ca-app-pub-3940256099942544/2435281174';
  static const _androidInterstitialTest = 'ca-app-pub-3940256099942544/1033173712';
  static const _iosInterstitialTest = 'ca-app-pub-3940256099942544/4411468910';
  static const _androidRewardedTest = 'ca-app-pub-3940256099942544/5224354917';
  static const _iosRewardedTest = 'ca-app-pub-3940256099942544/1712485313';

  // Supply production IDs with --dart-define when the AdMob account is ready.
  static const productionAndroidBanner = String.fromEnvironment('ADMOB_ANDROID_BANNER_ID');
  static const productionIosBanner = String.fromEnvironment('ADMOB_IOS_BANNER_ID');
  static const productionAndroidInterstitial = String.fromEnvironment('ADMOB_ANDROID_INTERSTITIAL_ID');
  static const productionIosInterstitial = String.fromEnvironment('ADMOB_IOS_INTERSTITIAL_ID');
  static const productionAndroidRewarded = String.fromEnvironment('ADMOB_ANDROID_REWARDED_ID');
  static const productionIosRewarded = String.fromEnvironment('ADMOB_IOS_REWARDED_ID');

  bool get _useProductionIds => const bool.fromEnvironment('ADMOB_PRODUCTION', defaultValue: false);

  String get bannerId => defaultTargetPlatform == TargetPlatform.iOS
      ? (_useProductionIds && productionIosBanner.isNotEmpty ? productionIosBanner : _iosBannerTest)
      : (_useProductionIds && productionAndroidBanner.isNotEmpty ? productionAndroidBanner : _androidBannerTest);

  String get interstitialId => defaultTargetPlatform == TargetPlatform.iOS
      ? (_useProductionIds && productionIosInterstitial.isNotEmpty ? productionIosInterstitial : _iosInterstitialTest)
      : (_useProductionIds && productionAndroidInterstitial.isNotEmpty ? productionAndroidInterstitial : _androidInterstitialTest);

  String get rewardedId => defaultTargetPlatform == TargetPlatform.iOS
      ? (_useProductionIds && productionIosRewarded.isNotEmpty ? productionIosRewarded : _iosRewardedTest)
      : (_useProductionIds && productionAndroidRewarded.isNotEmpty ? productionAndroidRewarded : _androidRewardedTest);

  Future<void> initialize() async {
    if (kIsWeb || initialized) return;
    initialized = true;
    // Consent is refreshed by the UMP SDK on each launch. Ads are requested
    // only after canRequestAds() reports that a request is permitted.
    final params = ConsentRequestParameters();
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
        _adsAllowed = await ConsentInformation.instance.canRequestAds();
        if (_adsAllowed) await MobileAds.instance.initialize();
        if (!completer.isCompleted) completer.complete();
      },
      (_) async {
        _adsAllowed = await ConsentInformation.instance.canRequestAds();
        if (_adsAllowed) await MobileAds.instance.initialize();
        if (!completer.isCompleted) completer.complete();
      },
    );
    await completer.future;
  }

  Future<bool> privacyOptionsRequired() async =>
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
      PrivacyOptionsRequirementStatus.required;

  void showPrivacyOptions() {
    ConsentForm.showPrivacyOptionsForm((error) {
      if (error != null) debugPrint('Privacy options error: ${error.message}');
    });
  }

  bool get canRequestAds => enabled && _adsAllowed;

  BannerAd createBanner({AdSize size = AdSize.banner}) {
    return BannerAd(
      adUnitId: bannerId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner failed: $error');
        },
      ),
    );
  }

  Future<bool> showInterstitial() async {
    if (!canRequestAds) return false;
    final completer = Completer<bool>();
    InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(true);
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (_) {
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );
    return completer.future;
  }

  Future<bool> showRewarded({required VoidCallback onReward}) async {
    if (!canRequestAds) return false;
    final completer = Completer<bool>();
    RewardedAd.load(
      adUnitId: rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          var earned = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(earned);
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
          );
          ad.show(onUserEarnedReward: (_, reward) {
            earned = true;
            onReward();
            debugPrint('Reward earned: ${reward.amount} ${reward.type}');
          });
        },
        onAdFailedToLoad: (_) {
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );
    return completer.future;
  }
}
