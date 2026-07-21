import 'package:belote_engine/belote_engine.dart';

/// ذكاء آلي مبدئي — نقلٌ حرفي لـ `reference/src/ai.js`.
///
/// **ليس قاعدة** (المرجع نفسه يقول ذلك): heuristics قابلة للاستبدال بالكامل.
/// يعيش في `game/` لا `ui/`، فاستدعاء دوال المحرك هنا مسموح.
const _aiBidThreshold = 48; // عتبة تقديرية، قابلة للضبط

/// يختار إجراء الضمانة لِمقعد بيده [hand] في الحالة [st].
BidAction aiBid(BiddingState st, List<Card> hand) {
  final acts = legalBidActions(st);
  final bidActs = acts.where((a) => a.kind == BidKind.bid).toList();
  int cnt(String s) => hand.where((c) => c.suit == s).length;
  bool has(String s, String r) => hand.any((c) => c.suit == s && c.rank == r);

  // أكوينس إذا أمسكنا أقوى ورقتَي حكم الخصم.
  if (acts.any((a) => a.kind == BidKind.akwins)) {
    final b = st.currentBid!;
    if (b.type == BidType.suit && has(b.suit!, 'J') && has(b.suit!, '9')) {
      return const BidAction.akwins();
    }
    if (b.type != BidType.suit &&
        hand.where((c) => c.rank == 'J').length >= 2) {
      return const BidAction.akwins();
    }
  }

  double scoreOf(Bid b) {
    if (b.type == BidType.suit) {
      final s = b.suit!;
      var v = hand
          .where((c) => c.suit == s)
          .fold<int>(0, (a, c) => a + unitsTout[c.rank]!)
          .toDouble();
      v += 6 * cnt(s);
      v += 11 * hand.where((c) => c.suit != s && c.rank == 'A').length;
      return v;
    }
    if (b.type == BidType.sans) {
      return (15 * hand.where((c) => c.rank == 'A').length +
              9 * hand.where((c) => c.rank == '10').length)
          .toDouble();
    }
    return (19 * hand.where((c) => c.rank == 'J').length +
            13 * hand.where((c) => c.rank == '9').length)
        .toDouble();
  }

  final scored = bidActs.map((a) => (a: a, v: scoreOf(a.bid!))).toList()
    ..sort((x, y) => y.v.compareTo(x.v));
  final best = scored.isEmpty ? null : scored.first;

  if (best != null && (st.turnsTaken == 0 || best.v >= _aiBidThreshold)) {
    return best.a;
  }
  final pass = acts.where((a) => a.kind == BidKind.pass);
  return pass.isNotEmpty ? pass.first : best!.a;
}

/// يختار الورقة التي يلعبها [seat] بيده [hand] في الأبلي [trick] تحت الضمانة [bid].
///
/// [foujaChance] (مع [rng]): احتمال ارتكاب فوجة — يترك اتباع لون الافتتاح رغم امتلاكه —
/// محاكاةً لخطأ بشري كي يجد اللاعب ما يكتشفه ويعترض عليه. صفر ⇒ لا فوجة (حتمية).
Card aiPlay(int seat, List<Card> hand, List<Play> trick, Bid bid,
    {Lcg? rng, double foujaChance = 0}) {
  final legal = legalPlays(hand, trick);

  // الأقل: أقل الوحدات، وعند التساوي الأضعف قوةً (strength الأعلى = الأضعف).
  Card low(List<Card> cs) {
    final sorted = cs.toList()
      ..sort((a, b) {
        final d = cardUnits(bid, a) - cardUnits(bid, b);
        return d != 0 ? d : strength(bid, b) - strength(bid, a);
      });
    return sorted.first;
  }

  // الأقوى: أدنى فهرس قوة (strength الأصغر = الأقوى).
  Card high(List<Card> cs) {
    final sorted = cs.toList()
      ..sort((a, b) => strength(bid, a) - strength(bid, b));
    return sorted.first;
  }

  // الأكثر وحداتٍ (لتحميل نقاط أبلي الشريك)؛ وعند التساوي الأضعف قوةً (نُبقي القويّ).
  Card topUnits(List<Card> cs) {
    final sorted = cs.toList()
      ..sort((a, b) {
        final d = cardUnits(bid, b) - cardUnits(bid, a);
        return d != 0 ? d : strength(bid, b) - strength(bid, a);
      });
    return sorted.first;
  }

  if (trick.isEmpty) return high(legal);

  // فوجة نادرة: يملك لون الافتتاح لكنه يرمي لونًا آخر (خارج القانوني عمدًا).
  final led = trick[0].card.suit;
  if (rng != null && foujaChance > 0 && hand.any((c) => c.suit == led)) {
    final offSuit = hand.where((c) => c.suit != led).toList();
    if (offSuit.isNotEmpty && rng.next() < foujaChance) return low(offSuit);
  }

  final winner = trickWinner(trick, bid);
  if (teamOf(winner) == teamOf(seat)) {
    // الشريك يقود الأبلي: إن كنتَ آخر لاعب (لا خطر بعدك) فحمّله أعلى الوحدات (بنك النقاط)؛
    // وإلا فارمِ الأقلّ لأن خصمًا قد يتجاوز الشريك.
    return trick.length == 3 ? topUnits(legal) : low(legal);
  }

  final wins = legal
      .where((c) =>
          trickWinner([...trick, (seat: seat, card: c)], bid) == seat)
      .toList();
  if (wins.isNotEmpty) {
    wins.sort((a, b) => cardUnits(bid, a) - cardUnits(bid, b));
    return wins.first;
  }
  return low(legal);
}
