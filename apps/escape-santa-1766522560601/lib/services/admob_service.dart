import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app_config.dart';
import 'iap_service.dart';

class AdMobService {
  static AdMobService? _instance;
  late AppConfig _config;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  AdMobService._();

  static Future<AdMobService> getInstance() async {
    if (_instance == null) {
      _instance = AdMobService._();
      _instance!._config = await AppConfig.getInstance();
    }
    return _instance!;
  }

  static Future<void> initialize() async {
    final config = await AppConfig.getInstance();
    if (config.admobEnabled && isSupported) {
      await MobileAds.instance.initialize();
    }
  }

  static bool get isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Check if ads should be shown (disabled if user has active subscription)
  Future<bool> shouldShowAds() async {
    try {
      final iapService = await IAPService.getInstance();
      return !iapService.hasActiveSubscription;
    } catch (e) {
      print('Error checking subscription status: $e');
      return true; // Show ads if error checking subscription
    }
  }

  String getBannerAdUnitId() {
    if (!isSupported) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _config.androidBannerAdUnitId;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _config.iosBannerAdUnitId;
    }
    return '';
  }

  String getInterstitialAdUnitId() {
    if (!isSupported) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _config.androidInterstitialAdUnitId;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _config.iosInterstitialAdUnitId;
    }
    return '';
  }

  BannerAd createBannerAd() {
    if (!isSupported) {
      throw UnsupportedError('AdMob is not supported on this platform');
    }
    return BannerAd(
      adUnitId: getBannerAdUnitId(),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner ad failed to load: $error');
          ad.dispose();
        },
      ),
    );
  }

  void loadInterstitialAd({VoidCallback? onAdLoaded}) {
    if (!_config.admobEnabled || !isSupported) return;

    InterstitialAd.load(
      adUnitId: getInterstitialAdUnitId(),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialAdReady = false;
              loadInterstitialAd(); // Preload next ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('Interstitial ad failed to show: $error');
              ad.dispose();
              _isInterstitialAdReady = false;
              loadInterstitialAd(); // Preload next ad
            },
          );
          
          if (onAdLoaded != null) {
            onAdLoaded();
          }
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  Future<void> showInterstitialAd({
    VoidCallback? onAdDismissed,
    VoidCallback? onAdFailedToShow,
  }) async {
    if (!_config.admobEnabled || !isSupported) {
      if (onAdFailedToShow != null) {
        onAdFailedToShow();
      }
      return;
    }

    // Load ad if not ready
    if (!_isInterstitialAdReady || _interstitialAd == null) {
      await _loadInterstitialAdAsync(
        onAdDismissed: onAdDismissed,
        onAdFailedToShow: onAdFailedToShow,
      );
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isInterstitialAdReady = false;
        _interstitialAd = null;
        if (onAdDismissed != null) {
          onAdDismissed();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('Interstitial ad failed to show: $error');
        ad.dispose();
        _isInterstitialAdReady = false;
        _interstitialAd = null;
        if (onAdFailedToShow != null) {
          onAdFailedToShow();
        }
      },
    );

    _interstitialAd!.show();
  }

  Future<void> _loadInterstitialAdAsync({
    VoidCallback? onAdDismissed,
    VoidCallback? onAdFailedToShow,
  }) async {
    if (!_config.admobEnabled) {
      if (onAdFailedToShow != null) {
        onAdFailedToShow();
      }
      return;
    }

    final completer = Completer<void>();

    InterstitialAd.load(
      adUnitId: getInterstitialAdUnitId(),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialAdReady = false;
              _interstitialAd = null;
              if (onAdDismissed != null) {
                onAdDismissed();
              }
              completer.complete();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('Interstitial ad failed to show: $error');
              ad.dispose();
              _isInterstitialAdReady = false;
              _interstitialAd = null;
              if (onAdFailedToShow != null) {
                onAdFailedToShow();
              }
              completer.complete();
            },
          );

          ad.show();
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
          _isInterstitialAdReady = false;
          if (onAdFailedToShow != null) {
            onAdFailedToShow();
          }
          completer.complete();
        },
      ),
    );

    return completer.future;
  }

  bool get isInterstitialAdReady => _isInterstitialAdReady;

  void dispose() {
    _interstitialAd?.dispose();
  }
}
