import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../net/api_client.dart';
import '../net/session_controller.dart';

/// معرّفُ منتج المتجر لباقة [packId] — **مطابقٌ لـ`storeProductId` في الخادم**
/// (`d500` ⇒ `com.hisabipro.belote.d500`). تُنشأ منتجاتٌ استهلاكيّةٌ بهذه
/// المعرّفات في App Store Connect وPlay Console.
String storeProductId(String packId) => 'com.hisabipro.belote.$packId';

/// نتيجةُ محاولة شراء.
enum StoreBuyResult {
  /// الماسُ وصل.
  done,

  /// ألغى اللاعبُ عند المتجر — ليس خطأ.
  cancelled,

  /// المتجرُ غيرُ متاحٍ هنا (حاسوب · محاكي · لا منتجَ بعدُ في المتجر).
  unavailable,

  /// فشل الدفعُ أو التحقّق.
  failed,
}

/// **شراءُ الماس من المتجر** — Apple على iOS/macOS وGoogle Play على أندرويد.
///
/// **طلب المالك (2026-09-29):** الكودُ جاهزٌ والتشغيلُ معطَّلٌ حتى يجهز الحسابُ
/// البنكيّ. الإطفاءُ **من الخادم**: `BankilyConfig.storeIos/storeAndroid` — حتى
/// يُوصَل مُحقّقُ الإيصالات هناك لا يُعرَض زرُّ المتجر أصلًا ([available]).
///
/// **القاعدةُ الذهبيّة للدفع:** لا تُنهى العمليّةُ عند المتجر
/// (`completePurchase`) إلّا بعد أن يمنح خادمُنا الماس. انقطع الاتّصالُ بين الدفع
/// والمنح؟ تبقى العمليّةُ معلّقةً عند المتجر فتُعاد إلينا عند الإقلاع القادم —
/// [listen] يعالجها، والخادمُ يمنع المنحَ المكرّر برقم العمليّة.
class StorePurchaseService {
  final SessionController session;
  final InAppPurchase _iap;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  final _pending = <String, Completer<StoreBuyResult>>{};

  StorePurchaseService(this.session, {InAppPurchase? iap})
      : _iap = iap ?? InAppPurchase.instance;

  /// منصّةُ الخادم لهذا الجهاز، أو null ⇒ لا متجرَ (حاسوب).
  static String? get platformName {
    if (kIsWeb) return null;
    if (Platform.isIOS || Platform.isMacOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return null;
  }

  /// أيُعرَض زرُّ المتجر؟ — الخادمُ يقول متى، وللمنصّة متجرٌ.
  static bool available(BankilyConfig c) {
    switch (platformName) {
      case 'ios':
        return c.storeIos;
      case 'android':
        return c.storeAndroid;
      default:
        return false;
    }
  }

  /// يبدأ الإنصاتَ لتحديثات المشتريات (يعالج المعلَّقَ أيضًا). آمنٌ للتكرار.
  void listen() {
    if (_sub != null || platformName == null) return;
    try {
      _sub = _iap.purchaseStream.listen(_onUpdates, onError: (Object error) {
        debugPrint('Store purchase stream failed: $error');
        for (final entry in _pending.entries.toList()) {
          _pending.remove(entry.key);
          if (!entry.value.isCompleted) {
            entry.value.complete(StoreBuyResult.failed);
          }
        }
      });
    } catch (error) {
      debugPrint('Could not listen to store purchases: $error');
    }
  }

  void dispose() => _sub?.cancel();

  /// أسعارُ الباقات **كما يعرضها المتجر** (عملةُ حساب المشتري) — `packId ⇒ "2,99 €"`.
  /// على متاجر Apple يجب أن يرى المشتري سعرَ App Store لا الأوقية؛ فارغةٌ إن لم يُجِب
  /// المتجر (المنتجاتُ غيرُ مفعّلةٍ بعد) فيبقى العرضُ بالأوقية.
  Future<Map<String, String>> storePrices(Iterable<String> packIds) async {
    if (platformName == null) return const {};
    try {
      if (!await _iap.isAvailable()) return const {};
      final r =
          await _iap.queryProductDetails(packIds.map(storeProductId).toSet());
      return {
        for (final d in r.productDetails)
          if (d.id.startsWith('com.hisabipro.belote.'))
            d.id.substring('com.hisabipro.belote.'.length): d.price,
      };
    } catch (_) {
      return const {};
    }
  }

  /// يشتري باقةَ [packId]. يعود حين تُحسَم العمليّة.
  Future<StoreBuyResult> buy(String packId) async {
    if (platformName == null) return StoreBuyResult.unavailable;
    try {
      if (!await _iap.isAvailable()) return StoreBuyResult.unavailable;
      final id = storeProductId(packId);
      final r = await _iap.queryProductDetails({id});
      if (r.productDetails.isEmpty) {
        debugPrint(
            'Store product unavailable: $id; not found: ${r.notFoundIDs}');
        return StoreBuyResult.unavailable;
      }
      listen();
      final c = Completer<StoreBuyResult>();
      _pending[id] = c;
      final started = await _iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: r.productDetails.first),
      );
      if (!started) {
        _pending.remove(id);
        return StoreBuyResult.failed;
      }
      return c.future;
    } catch (error) {
      _pending.remove(storeProductId(packId));
      debugPrint('Could not start store purchase for $packId: $error');
      return StoreBuyResult.failed;
    }
  }

  Future<void> _onUpdates(List<PurchaseDetails> updates) async {
    for (final p in updates) {
      final waiter = _pending[p.productID];
      switch (p.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.canceled:
          _pending.remove(p.productID);
          waiter?.complete(StoreBuyResult.cancelled);
          if (p.pendingCompletePurchase) await _iap.completePurchase(p);
        case PurchaseStatus.error:
          debugPrint('StoreKit purchase failed for ${p.productID}: ${p.error}');
          _pending.remove(p.productID);
          waiter?.complete(StoreBuyResult.failed);
          if (p.pendingCompletePurchase) await _iap.completePurchase(p);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final ok = await _deliver(p);
          _pending.remove(p.productID);
          waiter?.complete(ok ? StoreBuyResult.done : StoreBuyResult.failed);
      }
    }
  }

  /// يسلّم الإيصالَ للخادم؛ **ينجح ⇒ يُنهي العمليّةَ عند المتجر**، يفشل ⇒ تبقى
  /// معلّقةً فتُعاد لاحقًا (لا يضيع دفعُ اللاعب).
  Future<bool> _deliver(PurchaseDetails p) async {
    final platform = platformName;
    if (platform == null) return false;
    try {
      await session.verifyStorePurchase(
          platform, p.productID, p.verificationData.serverVerificationData);
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
      return true;
    } on ApiException catch (e) {
      debugPrint(
          'Store verification API failed for ${p.productID}: ${e.status} ${e.message}');
      // رفضٌ قاطعٌ من الخادم (إيصالٌ مزوَّر/منتجٌ غريب) لا يُعاد فيه المحاولة.
      if (e.status == 400 || e.status == 402) {
        if (p.pendingCompletePurchase) await _iap.completePurchase(p);
      }
      return false;
    } catch (error) {
      debugPrint(
          'Store receipt verification failed for ${p.productID}: $error');
      return false;
    }
  }
}
