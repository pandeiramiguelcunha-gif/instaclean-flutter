import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  BannerAd? bannerAd;
  InterstitialAd? interstitialAd;
  bool _isConsentObtained = false;

  // IDs reais do AdMob
  static const String bannerAdUnitId = 'ca-app-pub-2353019524746156/4464707500';
  static const String interstitialAdUnitId = 'ca-app-pub-2353019524746156/9525462496';

  // Inicializar UMP (consentimento GDPR) e AdMob
  Future<void> initialize() async {
    // Passo 1: Configurar UMP para GDPR
    final params = ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        // Verificar se o formulário de consentimento está disponível
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          _showConsentForm();
        } else {
          // Sem formulário necessário (ex: fora da EU)
          _isConsentObtained = true;
          _initializeAds();
        }
      },
      (FormError error) {
        debugPrint('[AdMob] Erro UMP: ${error.message}');
        // Mesmo com erro, tentar inicializar os anúncios
        _isConsentObtained = true;
        _initializeAds();
      },
    );
  }

  void _showConsentForm() {
    ConsentForm.loadConsentForm(
      (ConsentForm consentForm) {
        // Verificar se o consentimento já foi dado
        final status = ConsentInformation.instance.getConsentStatus();
        if (status == ConsentStatus.required) {
          consentForm.show(
            (FormError? formError) {
              if (formError != null) {
                debugPrint('[AdMob] Erro formulário: ${formError.message}');
              }
              _isConsentObtained = true;
              _initializeAds();
            },
          );
        } else {
          _isConsentObtained = true;
          _initializeAds();
        }
      },
      (FormError formError) {
        debugPrint('[AdMob] Erro ao carregar formulário: ${formError.message}');
        _isConsentObtained = true;
        _initializeAds();
      },
    );
  }

  void _initializeAds() {
    debugPrint('[AdMob] A inicializar anúncios...');
    MobileAds.instance.initialize().then((_) {
      debugPrint('[AdMob] SDK inicializado com sucesso');
      // Pré-carregar intersticial
      loadInterstitialAd();
    });
  }

  // Carregar Banner
  void loadBannerAd({Function()? onLoaded}) {
    debugPrint('[AdMob] A carregar banner...');
    bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('[AdMob] Banner carregado com sucesso');
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdMob] ERRO Banner: code=${error.code}, message=${error.message}, domain=${error.domain}');
          ad.dispose();
          bannerAd = null;
        },
      ),
    )..load();
  }

  // Carregar Intersticial
  void loadInterstitialAd() {
    debugPrint('[AdMob] A carregar intersticial...');
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdMob] Intersticial carregado com sucesso');
          interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdMob] ERRO Intersticial: code=${error.code}, message=${error.message}, domain=${error.domain}');
          interstitialAd = null;
        },
      ),
    );
  }

  // Mostrar Intersticial (chamado imediatamente após eliminar)
  void showInterstitialAd({Function()? onDismissed}) {
    if (interstitialAd == null) {
      debugPrint('[AdMob] Intersticial não disponível, a recarregar...');
      loadInterstitialAd();
      onDismissed?.call();
      return;
    }

    debugPrint('[AdMob] A mostrar intersticial...');
    interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('[AdMob] Intersticial mostrado');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdMob] Intersticial fechado pelo utilizador');
        ad.dispose();
        interstitialAd = null;
        loadInterstitialAd(); // Pré-carregar próximo
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdMob] ERRO ao mostrar intersticial: ${error.message}');
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
