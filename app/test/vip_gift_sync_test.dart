import 'package:app/ui/gift_picker.dart';
import 'package:flutter_test/flutter_test.dart';

/// **حارسُ الانجراف بين كتالوجَي هدايا VIP.**
///
/// القائمتان مكرّرتان عمدًا (لا حزمةَ مشتركة): الخادمُ يحمل المعرّفَ والرصيد،
/// والعميلُ يحمل الاسمَ العربيَّ **والأصلَ الفنّيّ**. وتكرارٌ بلا حارسٍ يتباعد
/// صامتًا: هديّةٌ تُرسَل ولا يراها أحدٌ لأنّ العميلَ لا يعرف أصلَها.
///
/// **المصدر** — `server/lib/vip/vip_gifts.dart` (`vipGiftCatalog` بترتيبه).
const _serverVipGiftIds = ['vip_flower', 'vip_box', 'vip_pitcher'];

void main() {
  test('كتالوجُ الواجهة يطابق كتالوجَ الخادم — معرّفًا وترتيبًا', () {
    expect([for (final g in vipGiftCatalogUi) g.id], _serverVipGiftIds);
  });

  test('لكلّ هديّةٍ اسمٌ عربيٌّ وأصلٌ من مجلّد VIP', () {
    for (final g in vipGiftCatalogUi) {
      expect(g.name.trim(), isNotEmpty, reason: g.id);
      expect(g.asset, startsWith('assets/VIP/'), reason: g.id);
      expect(g.asset, endsWith('.png'), reason: 'الشفافيّةُ تلزم على الطاولة');
    }
  });

  // **الفقاعةُ تعرف أصلَها**: بلا هذا تُرسَل الهديّةُ ولا يراها أحدٌ على الطاولة.
  test('vipGiftAsset يجد كلَّ معرّفٍ ويردّ null لِما ليس منها', () {
    for (final id in _serverVipGiftIds) {
      expect(vipGiftAsset(id), isNotNull, reason: id);
    }
    expect(vipGiftAsset('rose'), isNull, reason: 'هديّةٌ عاديّةٌ ليست حصريّة');
    expect(vipGiftAsset(''), isNull);
  });

  // **لا تختلط بالعاديّة**: `giftEmoji` لا تعرفها، و`vipGiftAsset` لا تعرف تلك.
  test('لا تداخلَ بين الكتالوجين', () {
    for (final id in _serverVipGiftIds) {
      expect(giftEmoji(id), isNull, reason: '$id ليست في الكتالوج العاديّ');
    }
    for (final g in giftCatalogUi) {
      expect(vipGiftAsset(g.id), isNull, reason: '${g.id} ليست حصريّة');
    }
  });
}
