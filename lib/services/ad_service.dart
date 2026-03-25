import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  BannerAd? bannerAd;
  InterstitialAd? interstitialAd;
  bool _isSdkInitialized = false;
  bool _isInitializing = false;

  // IDs reais do AdMob
  static const String bannerAdUnitId = 'ca-app-pub-2353019524746156/4464707500';
  static const String interstitialAdUnitId = 'ca-app-pub-2353019524746156/9525462496';

  // Inicializar SDK com UMP (GDPR) - chamar no primeiro ecrã
  Future<void> initializeWithConsent() async {
    if (_isInitializing || _isSdkInitialized) return;
    _isInitializing = true;

    debugPrint('[AdMob] === INICIO INICIALIZACAO ===');
    debugPrint('[AdMob] App ID: ca-app-pub-2353019524746156~7848109235');
    debugPrint('[AdMob] Banner ID: $bannerAdUnitId');
    debugPrint('[AdMob] Interstitial ID: $interstitialAdUnitId');

    final completer = Completer<void>();

    // Passo 1: Pedir info de consentimento (GDPR)
    final params = ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        debugPrint('[AdMob] UMP info atualizada. Status: ${ConsentInformation.instance.getConsentStatus()}');

        // Passo 2: Mostrar formulário se necessário (EU/UK)
        ConsentForm.loadAndShowConsentFormIfRequired(
          (FormError? formError) {
            if (formError != null) {
              debugPrint('[AdMob] Erro formulário UMP: code=${formError.errorCode}, msg=${formError.message}');
            } else {
              debugPrint('[AdMob] Consentimento tratado com sucesso');
            }

            // Passo 3: Verificar se pode pedir anúncios
            _checkAndInitializeAds(completer);
          },
        );
      },
      (FormError error) {
        debugPrint('[AdMob] Erro UMP update: code=${error.errorCode}, msg=${error.message}');
        // Mesmo com erro UMP, tentar inicializar
        _checkAndInitializeAds(completer);
      },
    );

    return completer.future;
  }

  Future<void> _checkAndInitializeAds(Completer<void> completer) async {
    final canRequest = await ConsentInformation.instance.canRequestAds();
    debugPrint('[AdMob] canRequestAds: $canRequest');

    if (canRequest) {
      await _initializeSdk();
    } else {
      debugPrint('[AdMob] AVISO: Sem permissão para pedir anúncios (consentimento negado)');
      // Tentar inicializar mesmo assim para anúncios não-personalizados
      await _initializeSdk();
    }

    if (!completer.isCompleted) completer.complete();
  }

  Future<void> _initializeSdk() async {
    if (_isSdkInitialized) return;

    debugPrint('[AdMob] A inicializar Mobile Ads SDK...');
    await MobileAds.instance.initialize();
    _isSdkInitialized = true;
    debugPrint('[AdMob] SDK inicializado com sucesso!');

    // Pré-carregar intersticial
    loadInterstitialAd();
  }

  // Carregar Banner
  void loadBannerAd({Function()? onLoaded}) {
    if (!_isSdkInitialized) {
      debugPrint('[AdMob] SDK não inicializado, a inicializar primeiro...');
      MobileAds.instance.initialize().then((_) {
        _isSdkInitialized = true;
        _loadBanner(onLoaded: onLoaded);
      });
      return;
    }
    _loadBanner(onLoaded: onLoaded);
  }

  void _loadBanner({Function()? onLoaded}) {
    debugPrint('[AdMob] A carregar banner...');
    bannerAd?.dispose();
    bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('[AdMob] Banner CARREGADO com sucesso!');
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdMob] ERRO Banner: code=${error.code}, msg=${error.message}, domain=${error.domain}');
          ad.dispose();
          bannerAd = null;

          // Retry após 30 segundos
          debugPrint('[AdMob] Retry banner em 30s...');
          Future.delayed(const Duration(seconds: 30), () {
            _loadBanner(onLoaded: onLoaded);
          });
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
          debugPrint('[AdMob] Intersticial CARREGADO com sucesso!');
          interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdMob] ERRO Intersticial: code=${error.code}, msg=${error.message}, domain=${error.domain}');
          interstitialAd = null;

          // Retry após 30 segundos
          debugPrint('[AdMob] Retry intersticial em 30s...');
          Future.delayed(const Duration(seconds: 30), () {
            loadInterstitialAd();
          });
        },
      ),
    );
  }

  // Mostrar Intersticial (chamado imediatamente após eliminar)
  void showInterstitialAd({Function()? onDismissed}) {
    if (interstitialAd == null) {
      debugPrint('[AdMob] Intersticial não disponível');
      loadInterstitialAd();
      onDismissed?.call();
      return;
    }

    debugPrint('[AdMob] A MOSTRAR intersticial...');
    interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('[AdMob] Intersticial MOSTRADO ao utilizador');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdMob] Intersticial fechado');
        ad.dispose();
        interstitialAd = null;
        loadInterstitialAd();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdMob] ERRO ao mostrar: ${error.message}');
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
