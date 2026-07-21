/// اللعب — الأبالي (le pli). نقل حرفي من `reference/src/engine.js`.
///
/// لا إجبار على القص ولا على تجاوز أعلى حكم: يجب فقط اتباع اللون إن وُجد.
library;

import 'bid.dart';
import 'card.dart';
import 'tables.dart';

/// ورقة ملعوبة داخل أبلي: من لعبها + الورقة، بترتيب اللعب.
typedef Play = ({int seat, Card card});

/// هل [suit] هو لون الحكم في هذه الضمانة؟ (لضمانة اللون فقط).
bool isTrumpSuit(Bid bid, String suit) =>
    bid.type == BidType.suit && bid.suit == suit;

/// ترتيب القوة المطبَّق على ورقة من [suit] في هذه الضمانة (الأقوى أولاً).
List<String> orderFor(Bid bid, String suit) => switch (bid.type) {
      BidType.tout => orderTout,
      BidType.sans => orderSans,
      BidType.suit => isTrumpSuit(bid, suit) ? orderTout : orderSans,
    };

/// «قوة» الورقة = فهرسها في ترتيب لونها. الأصغر = الأقوى.
int strength(Bid bid, Card card) => orderFor(bid, card.suit).indexOf(card.rank);

/// وحدات الورقة حسب الضمانة: سُلَّم تو للحكم/صن/تو، والعادي لغيره.
int cardUnits(Bid bid, Card card) {
  if (bid.type == BidType.sans || bid.type == BidType.tout) {
    return unitsTout[card.rank]!;
  }
  return isTrumpSuit(bid, card.suit)
      ? unitsTout[card.rank]!
      : unitsPlain[card.rank]!;
}

/// الأوراق القانونية: اتبع لون الافتتاح إن ملكته، وإلا فكل اليد.
/// **لا** إجبار على لعب الحكم ولا على تجاوز أعلى ورقة على الطاولة.
List<Card> legalPlays(List<Card> hand, List<Play> trick) {
  if (trick.isEmpty) return List<Card>.of(hand);
  final led = trick[0].card.suit;
  final follow = hand.where((c) => c.suit == led).toList();
  return follow.isNotEmpty ? follow : List<Card>.of(hand);
}

/// فوجة (la faute): لعب لونًا آخر رغم امتلاكه لون الافتتاح.
bool isFouja(List<Card> handBefore, List<Play> trick, Card played) {
  if (trick.isEmpty) return false;
  final led = trick[0].card.suit;
  if (played.suit == led) return false;
  return handBefore.any((c) => c.suit == led);
}

/// الفائز بالأبلي: أقوى حكم إن وُجد، وإلا أقوى ورقة من لون الافتتاح.
/// عند التعادل في القوة تبقى الأولى (مطابقة لـ `<` الصارمة في JS).
int trickWinner(List<Play> trick, Bid bid) {
  final led = trick[0].card.suit;
  final trumps = bid.type == BidType.suit
      ? trick.where((p) => p.card.suit == bid.suit).toList()
      : const <Play>[];
  final pool =
      trumps.isNotEmpty ? trumps : trick.where((p) => p.card.suit == led).toList();
  return pool
      .reduce((best, p) =>
          strength(bid, p.card) < strength(bid, best.card) ? p : best)
      .seat;
}

/// مجموع وحدات الأوراق الأربع في الأبلي.
int trickUnits(List<Play> trick, Bid bid) =>
    trick.fold(0, (sum, p) => sum + cardUnits(bid, p.card));

/// وحدات «الدير» (der) — الأبلي الأخير يمنح 10 وحدات إضافية.
const derUnits = 10;
