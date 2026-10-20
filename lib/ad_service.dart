// lib/ad_service.dart
//
// Google AdMob banner reklamı + kullanıcı onayı (Google UMP / GDPR / KVKK uyumu).
// Premium kullanıcılara reklam gösterilmez.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'premium_service.dart';

class AdService {
  AdService._();
  static final instance = AdService._();

  // !!! YAYINLAMADAN ÖNCE DEĞİŞTİR !!!
  // Aşağıdaki kimlikler Google'ın TEST kimlikleridir (gelir getirmez, ama güvenle denenir).
  // AdMob'da uygulamanızı ve bir "Banner" reklam birimi oluşturup kendi kimliğinizi yazın.
  // Uygulama kimliğini ayrıca AndroidManifest.xml içindeki APPLICATION_ID alanına da yazın.
  // Geliştirme sırasında KENDİ GERÇEK reklamlarınıza asla tıklamayın (hesap kapatılabilir).
  static const bannerUnitId = 'ca-app-pub-3940256099942544/6300978111';

  /// Onay alındıktan ve SDK hazır olduktan sonra true olur.
  final ValueNotifier<bool> canShowAds = ValueNotifier<bool>(false);

  /// Kullanıcının reklam gizlilik ayarlarını tekrar açabilmesi gerekiyorsa true (AB/UK).
  final ValueNotifier<bool> privacyOptionsRequired = ValueNotifier<bool>(false);

  bool _started = false;

  Future<void> init() async {
    if (_started) return;
    _started = true;

    try {
      final done = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          try {
            await ConsentForm.loadAndShowConsentFormIfRequired((FormError? e) {});
          } catch (_) {}
          if (!done.isCompleted) done.complete();
        },
        (FormError e) {
          if (!done.isCompleted) done.complete();
        },
      );
      await done.future;

      try {
        privacyOptionsRequired.value = await ConsentInformation.instance
                .getPrivacyOptionsRequirementStatus() ==
            PrivacyOptionsRequirementStatus.required;
      } catch (_) {}

      if (await ConsentInformation.instance.canRequestAds()) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(
            tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
            tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
            maxAdContentRating: MaxAdContentRating.pg,
          ),
        );
        await MobileAds.instance.initialize();
        canShowAds.value = true;
      }
    } catch (_) {
      // Reklam başlatılamazsa uygulama reklamsız çalışmaya devam eder.
    }
  }

  Future<void> showPrivacyOptions() async {
    try {
      await ConsentForm.showPrivacyOptionsForm((FormError? e) {});
    } catch (_) {}
  }
}

/// Ekranın altında duran küçük banner. Premium'da ya da reklam yoksa görünmez.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    AdService.instance.canShowAds.addListener(_maybeLoad);
    PremiumService.instance.isPremium.addListener(_onPremiumChanged);
    _maybeLoad();
  }

  void _onPremiumChanged() {
    if (PremiumService.instance.isPremium.value) {
      _ad?.dispose();
      _ad = null;
      _loaded = false;
    }
    if (mounted) setState(() {});
  }

  void _maybeLoad() {
    if (_ad != null) return;
    if (!AdService.instance.canShowAds.value) return;
    if (PremiumService.instance.isPremium.value) return;

    final ad = BannerAd(
      adUnitId: AdService.bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (failed, _) {
          failed.dispose();
          if (mounted) setState(() {
            _ad = null;
            _loaded = false;
          });
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    AdService.instance.canShowAds.removeListener(_maybeLoad);
    PremiumService.instance.isPremium.removeListener(_onPremiumChanged);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null || !_loaded || PremiumService.instance.isPremium.value) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}