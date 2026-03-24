import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isInitialized = false;

  // ========================================
  // SUBSTITUA ESTES IDs PELOS SEUS IDs REAIS
  // ========================================
  
  // IDs de TESTE (usar durante desenvolvimento)
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  
  // IDs de PRODUÇÃO (substituir pelos seus IDs reais)
  static const String _prodBannerAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _prodInterstitialAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  
  // Mudar para false quando publicar na Play Store
  static const bool _useTestAds = true;
  
  String get bannerAdUnitId => _useTestAds ? _testBannerAdUnitId : _prodBannerAdUnitId;
  String get interstitialAdUnitId => _useTestAds ? _testInterstitialAdUnitId : _prodInterstitialAdUnitId;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await MobileAds.instance.initialize();
    _isInitialized = true;
    
    // Pré-carregar anúncio intersticial
    await _loadInterstitialAd();
  }

  // ========================================
  // BANNER AD
  // ========================================
  
  BannerAd? get bannerAd => _bannerAd;

  Future<void> loadBannerAd({
    required Function() onAdLoaded,
    required Function(String error) onAdFailedToLoad,
  }) async {
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          onAdLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
          onAdFailedToLoad(error.message);
        },
      ),
    );
    
    await _bannerAd?.load();
  }

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  // ========================================
  // INTERSTITIAL AD
  // ========================================
  
  Future<void> _loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd?.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  Future<void> showInterstitialAd({
    Function()? onAdDismissed,
  }) async {
    if (_interstitialAd == null) {
      // Se não houver anúncio carregado, tentar carregar e continuar
      await _loadInterstitialAd();
      onAdDismissed?.call();
      return;
    }

    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd(); // Carregar próximo anúncio
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        onAdDismissed?.call();
      },
    );

    await _interstitialAd?.show();
  }

  // Mostrar anúncio intersticial após limpeza
  Future<void> showAdAfterClean({Function()? onComplete}) async {
    await showInterstitialAd(onAdDismissed: onComplete);
  }

  void dispose() {
    disposeBannerAd();
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
