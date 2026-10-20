// lib/premium_service.dart
//
// Tek seferlik "Premium" satın alma (Google Play Billing, in_app_purchase paketi).
// Play Console'da şu kimlikle bir "Yönetilen ürün / One-time product" oluşturun:
//   premium_unlock
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  PremiumService._();
  static final instance = PremiumService._();

  /// Play Console'daki ürün kimliği ile birebir aynı olmalı.
  static const productId = 'premium_unlock';

  /// Ücretsiz sürümde eklenebilecek en fazla ilaç sayısı.
  static const freeMedicineLimit = 5;

  static const _prefKey = 'premium_v1';

  final ValueNotifier<bool> isPremium = ValueNotifier<bool>(false);

  /// Mağazadan gelen yerelleştirilmiş fiyat (örn. "₺89,99"). Null = henüz yok.
  final ValueNotifier<String?> priceText = ValueNotifier<String?>(null);

  ProductDetails? _product;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _started = false;

  Future<void> init() async {
    if (_started) return;
    _started = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      isPremium.value = prefs.getBool(_prefKey) ?? false;
    } catch (_) {}

    try {
      final iap = InAppPurchase.instance;
      _sub = iap.purchaseStream.listen(
        _onPurchases,
        onError: (_) {},
      );

      if (!await iap.isAvailable()) return;

      final response = await iap.queryProductDetails({productId});
      if (response.productDetails.isNotEmpty) {
        _product = response.productDetails.first;
        priceText.value = _product!.price;
      }

      // Daha önce satın alındıysa (yeniden yükleme / yeni telefon) sessizce geri yükle.
      await iap.restorePurchases();
    } catch (_) {
      // Mağaza yoksa uygulama ücretsiz modda çalışmaya devam eder.
    }
  }

  Future<bool> buy() async {
    final product = _product;
    if (product == null) return false;
    try {
      return await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> restore() async {
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (_) {}
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID == productId &&
          (p.status == PurchaseStatus.purchased ||
              p.status == PurchaseStatus.restored)) {
        await _setPremium(true);
      }
      // Google Play, onaylanmayan (acknowledge) alımları 3 gün sonra iade eder.
      if (p.pendingCompletePurchase) {
        try {
          await InAppPurchase.instance.completePurchase(p);
        } catch (_) {}
      }
    }
  }

  Future<void> _setPremium(bool value) async {
    isPremium.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);
    } catch (_) {}
  }

  void dispose() {
    _sub?.cancel();
  }
}