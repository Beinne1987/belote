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
