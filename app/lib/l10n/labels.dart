import 'package:belote_engine/belote_engine.dart';

import '../game/seat_player.dart';
import 'app_localizations.dart';

/// **تسمياتٌ مشتقّةٌ من قيم المحرّك** — ضمانةٌ، سببُ حسمٍ، رتبةٌ، مقعد.
///
/// دوالُّ حرّةٌ تأخذ [AppLocalizations] بدل نصوصٍ ثابتة: القيمةُ تأتي من المحرّك
/// (`Bid` · `reason` · `PlayerRank`) والنصُّ من اللغة النشطة. **لا قاعدةَ هنا**
/// — عرضٌ محض؛ المحرّكُ لا يعرف لغةً.
class Labels {
  const Labels._();

  /// اسمُ اللون كما يُنطق على الطاولة.
  static String suit(AppLocalizations l, String suit) => switch (suit) {
        'trefle' => l.suitTrefle,
        'carreau' => l.suitCarreau,
        'coeur' => l.suitCoeur,
        'pique' => l.suitPique,
        _ => suit,
      };

  /// اسمُ الرتبة **كما تُنطق على الطاولة** — لا ترجمةً حرفيّةً من الإنجليزيّة.
  ///
  /// الأسماءُ منقولةٌ من `docs/RULES.md` حرفيًّا (الآس · الديس · أرواه · الضم ·
  /// الفالة · النيف · الويت · الست) وأصلُها فرنسيٌّ مُموريتَن. **لا تُخترَع هنا
  /// تسمية**: من كتب «ملك» و«بنت» ترجم لعبةً أخرى.
  /// (والاسمُ `cardRank` لا `rank`: [rank] رتبةُ **اللاعب** في التصنيف.)
  static String cardRank(AppLocalizations l, String rank) => switch (rank) {
        'A' => l.rankNameA,
        '10' => l.rankName10,
        'K' => l.rankNameK,
        'Q' => l.rankNameQ,
        'J' => l.rankNameJ,
        '9' => l.rankName9,
        '8' => l.rankName8,
        '7' => l.rankName7,
        _ => rank,
      };

  /// ورقةٌ كاملةٌ منطوقةً — للقارئ الصوتيّ حيث لا يُغني الرسم.
  static String card(AppLocalizations l, Card card) =>
      l.cardName(cardRank(l, card.rank), suit(l, card.suit));

  /// الضمانةُ الجارية. [akwins] يلحق بها الأكوينس.
  static String bid(AppLocalizations l, Bid? bid, {bool akwins = false}) {
    if (bid == null) return l.bidNone;
    final base = switch (bid.type) {
      BidType.sans => l.bidSans,
      BidType.tout => l.bidTout,
      BidType.suit => suit(l, bid.suit!),
    };
    return akwins ? l.bidWithAkwins(base) : base;
  }

  /// سببُ حسم الجولة (من `scoreRound().reason`).
  static String reason(AppLocalizations l, String reason) => switch (reason) {
        'chute' => l.reasonChute,
        'akwins' => l.reasonAkwins,
        'fouja' => l.fouja,
        'white' => l.reasonWhite,
        _ => l.reasonMade,
      };

  /// رتبةُ اللاعب على بطاقته.
  static String rank(AppLocalizations l, PlayerRank r) => switch (r) {
        PlayerRank.beginner => l.rankBeginner,
        PlayerRank.pro => l.rankPro,
        PlayerRank.expert => l.rankExpert,
        PlayerRank.legend => l.rankLegend,
      };

  /// تسميةُ المقعد بفهرس العرض 0..3 (0 أنت · 2 شريكك · 1 و3 الخصمان).
  static String seat(AppLocalizations l, int seat) => switch (seat) {
        0 => l.seatYou,
        2 => l.seatPartner,
        _ => l.seatOpponent,
      };
}
