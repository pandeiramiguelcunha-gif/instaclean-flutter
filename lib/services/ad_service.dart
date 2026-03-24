import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  BannerAd? bannerAd;
  InterstitialAd? interstitialAd;

  // IDs reais do AdMob
  static const String bannerAdUnitId = 'ca-app-pub-2353019524746156/4464707500';
  static const String interstitialAdUnitId = 'ca-app-pub-2353019524746156/9525462496';

  // Carregar Banner
  void loadBannerAd({Function()? onLoaded}) {
    bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onLoaded?.call(),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  // Carregar Intersticial
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => interstitialAd = ad,
        onAdFailedToLoad: (error) => interstitialAd = null,
      ),
    );
  }

  // Mostrar Intersticial
  void showInterstitialAd({Function()? onDismissed}) {
    if (interstitialAd == null) {
      onDismissed?.call();
      return;
    }

    interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        interstitialAd = null;
        loadInterstitialAd();
        onDismissed?.call();
      },
    );

    interstitialAd!.show();
  }

  void dispose() {
    bannerAd?.dispose();
    interstitialAd?.dispose();
  }
}
