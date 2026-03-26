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

  // Inicializar SDK com UMP (GDPR)
  Future<void> initializeWithConsent() async {
    if (_isInitializing || _isSdkInitialized) return;
    _isInitializing = true;

    debugPrint('[AdMob] === INICIO INICIALIZACAO ===');

    final completer = Completer<void>();
    final params = ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        final status = ConsentInformation.instance.getConsentStatus();
        debugPrint('[AdMob] UMP status: $status');

        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          debugPrint('[AdMob] Formulario GDPR disponivel');
          _loadAndShowConsentForm(completer);
        } else {
          debugPrint('[AdMob] Formulario GDPR nao necessario');
          await _initializeSdk();
          if (!completer.isCompleted) completer.complete();
        }
      },
      (FormError error) {
        debugPrint('[AdMob] Erro UMP: ${error.message}');
        _initializeSdk().then((_) {
          if (!completer.isCompleted) completer.complete();
        });
      },
    );

    return completer.future;
  }

  void _loadAndShowConsentForm(Completer<void> completer) {
    ConsentForm.loadConsentForm(
      (ConsentForm consentForm) {
        final status = ConsentInformation.instance.getConsentStatus();
        debugPrint('[AdMob] Consent status apos load: $status');

        if (status == ConsentStatus.required) {
          consentForm.show((FormError? error) {
            if (error != null) {
              debugPrint('[AdMob] Erro formulario: ${error.message}');
            } else {
              debugPrint('[AdMob] Consentimento dado pelo utilizador');
            }
            _initializeSdk().then((_) {
              if (!completer.isCompleted) completer.complete();
            });
          });
        } else {
          debugPrint('[AdMob] Consentimento ja obtido ou nao necessario');
          _initializeSdk().then((_) {
            if (!completer.isCompleted) completer.complete();
          });
        }
      },
      (FormError error) {
        debugPrint('[AdMob] Erro ao carregar formulario: ${error.message}');
        _initializeSdk().then((_) {
          if (!completer.isCompleted) completer.complete();
        });
      },
    );
  }

  Future<void> _initializeSdk() async {
    if (_isSdkInitialized) return;

    debugPrint('[AdMob] A inicializar Mobile Ads SDK...');
    await MobileAds.instance.initialize();
    _isSdkInitialized = true;
    debugPrint('[AdMob] SDK inicializado!');

    // Pre-carregar intersticial
    loadInterstitialAd();
  }

  // Carregar Banner
  void loadBannerAd({Function()? onLoaded}) {
    if (!_isSdkInitialized) {
      debugPrint('[AdMob] SDK nao inicializado, a inicializar...');
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
          debugPrint('[AdMob] Banner CARREGADO!');
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdMob] ERRO Banner: code=${error.code}, msg=${error.message}');
          ad.dispose();
          bannerAd = null;
          // Retry em 30s
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
          debugPrint('[AdMob] Intersticial CARREGADO!');
          interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdMob] ERRO Intersticial: code=${error.code}, msg=${error.message}');
          interstitialAd = null;
          // Retry em 30s
          Future.delayed(const Duration(seconds: 30), () {
            loadInterstitialAd();
          });
        },
      ),
    );
  }

  // Mostrar Intersticial
  void showInterstitialAd({Function()? onDismissed}) {
    if (interstitialAd == null) {
      debugPrint('[AdMob] Intersticial nao disponivel, a tentar carregar e mostrar...');
      // Tentar carregar e mostrar imediatamente
      InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('[AdMob] Intersticial carregado de emergencia! A mostrar...');
            interstitialAd = ad;
            _showAd(onDismissed);
          },
          onAdFailedToLoad: (error) {
            debugPrint('[AdMob] ERRO carregar emergencia: code=${error.code}, msg=${error.message}');
            interstitialAd = null;
            onDismissed?.call();
          },
        ),
      );
      return;
    }

    _showAd(onDismissed);
  }

  void _showAd(Function()? onDismissed) {
    debugPrint('[AdMob] A MOSTRAR intersticial...');
    interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('[AdMob] Intersticial MOSTRADO');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdMob] Intersticial fechado');
        ad.dispose();
        interstitialAd = null;
        loadInterstitialAd();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdMob] ERRO mostrar: ${error.message}');
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
