import 'package:belote_engine/belote_engine.dart';

import 'game/seat_player.dart';

/// كل النصوص العربية في مكان واحد — تسهيلًا للترجمة لاحقًا (فرنسي).
/// عرضٌ محض؛ لا قاعدة هنا. الأرقام تبقى لاتينية داخل الأوراق (انظر card_face).
class S {
  const S._();

  static const us = 'نحن';
  static const them = 'هم';
  static const noBid = 'لا ضمانة';

  /// تسمية رتبة اللاعب على بطاقته (عرضٌ محض).
  static String rankLabel(PlayerRank r) => switch (r) {
        PlayerRank.beginner => 'مبتدئ',
        PlayerRank.pro => 'محترف',
        PlayerRank.expert => 'خبير',
        PlayerRank.legend => 'أسطوريّ',
      };
  static const akwins = 'أكوينس';
  static const pass = 'تمرير';
  static const followSuit = 'يجب اتباع اللون';
  static const yourBid = 'ضمانتك';
  static const dealing = 'التوزيع';
  static const bidding = 'الضمانة';

  static const roundOver = 'انتهت الجولة';
  static const newRound = 'جولة جديدة';
  static const newMatch = 'مباراة جديدة';
  static const backToMenu = 'القائمة';
  static const rating = 'التصنيف'; // لوحة النتيجة: تقييم ELO بعد مباراةٍ مصنّفة

  // ── الفوجة ──
  static const fouja = 'فوجة';
  static const whoFouja = 'من عمل الفوجة؟';
  static const opponentRight = 'الخصم يمينك';
  static const opponentLeft = 'الخصم يسارك';
  static const cancel = 'إلغاء';
  static const cancelFouja = 'إلغاء الفوجة';
  static String foujaClaimedBy(String name) => '$name يعترض بالفوجة…';
  static const foujaWonUs = 'فوجة — لكم نقاط الضمانة';
  static const foujaWonThem = 'فوجة — للخصم نقاط الضمانة';
  static const roundValue = 'قيمة الجولة';
  static const matchWonUs = 'فزتم بالمباراة!';
  static const matchWonThem = 'فاز الخصم بالمباراة';
  static const matchTiebreak = 'تعادل — جولة فاصلة';
  static const openRuleTie = 'قاعدة مفتوحة: تعادل الأكوينس (نادر — لا حسم)';

  /// سبب حسم الجولة (من `scoreRound().reason`).
  static String reasonLabel(String reason) => switch (reason) {
        'chute' => 'سقطت الضمانة',
        'akwins' => 'أكوينس',
        'fouja' => fouja,
        'white' => 'جولة بيضاء!',
        _ => 'نجحت الضمانة',
      };

  /// تسمية كل مقعد بفهرسه 0..3 (0 أنت، 2 شريكك، 1 و3 الخصمان).
  static const seatNames = ['أنت', 'الخصم', 'الشريك', 'الخصم'];

  static const _suitBid = {
    'trefle': 'أتريف',
    'carreau': 'كارو',
    'coeur': 'كير',
    'pique': 'أبيك',
  };

  /// عرض الضمانة الجارية بالعربية (قيمة محرك → نص).
  static String bidLabel(Bid? bid, {bool akwins = false}) {
    if (bid == null) return noBid;
    final base = switch (bid.type) {
      BidType.sans => 'صن',
      BidType.tout => 'تو',
      BidType.suit => _suitBid[bid.suit] ?? bid.suit!,
    };
    return akwins ? '$base · ${S.akwins}' : base;
  }
}
