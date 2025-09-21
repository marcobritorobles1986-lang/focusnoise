import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// IDs de prueba oficiales de Google.
/// Android banner: ca-app-pub-3940256099942544/6300978111
/// Android interstitial: ca-app-pub-3940256099942544/1033173712
class AdsHelper {
  static const _bannerIdAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _interstitialIdAndroid = 'ca-app-pub-3940256099942544/1033173712';

  // === Banner ===
  static BannerAd createBanner() {
    return BannerAd(
      size: AdSize.banner,
      adUnitId: _bannerIdAndroid,
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, err) { ad.dispose(); },
      ),
      request: const AdRequest(),
    )..load();
  }

  // === Interstitial con cooldown ===
  static InterstitialAd? _interstitial;
  static DateTime _lastShown = DateTime.fromMillisecondsSinceEpoch(0);
  static const _cooldown = Duration(minutes: 8);

  static Future<void> preloadInterstitial() async {
    await InterstitialAd.load(
      adUnitId: _interstitialIdAndroid,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Llamar solo en eventos (p.ej., fin de pomodoro / guardar mezcla)
  static void maybeShowInterstitial() {
    final now = DateTime.now();
    if (_interstitial != null && now.difference(_lastShown) > _cooldown) {
      _interstitial!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          preloadInterstitial(); // para la próxima
        },
        onAdFailedToShowFullScreenContent: (ad, _) {
          ad.dispose();
          _interstitial = null;
        },
      );
      _interstitial!.show();
      _lastShown = now;
    } else {
      // si no hay uno listo, intenta precargar
      if (_interstitial == null) preloadInterstitial();
    }
  }
}
