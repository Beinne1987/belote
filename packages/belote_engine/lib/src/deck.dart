/// بناء الشدّة وخلطها وتوزيعها — نقل حرفي من `reference/src/engine.js`.
library;

import 'card.dart';
import 'lcg.dart';

/// يبني الشدّة الـ32. **الترتيب مُلزِم:** الخارجية ألوان، الداخلية رتب.
/// أي تبديل يغيّر تسلسل الخلط بالكامل.
List<Card> buildDeck() {
  final d = <Card>[];
  for (final suit in suits) {
    for (final rank in ranks) {
      d.add(Card(suit, rank));
    }
  }
  return d;
}

/// خلط Fisher–Yates. **مُلزِم:** الحلقة تنازلية، واستدعاء واحد لـ `rng` كل دورة.
/// لا يغيّر الأصل — يعيد نسخة مخلوطة.
List<Card> shuffle(List<Card> deck, Lcg rng) {
  final d = List<Card>.of(deck);
  for (var i = d.length - 1; i > 0; i--) {
    final j = (rng.next() * (i + 1)).floor();
    final t = d[i];
    d[i] = d[j];
    d[j] = t;
  }
  return d;
}

/// التوزيع الأول: 3 ثم 2 لكل لاعب → 5 أوراق، والباقي (12) مؤجّل للضمانة.
/// **ترتيب التوزيع مُلزِم:** `[3,2]` ← مقاعد 0..3 ← أوراق الدفعة.
({List<List<Card>> hands, List<Card> rest}) dealOpening(List<Card> deck) {
  final hands = <List<Card>>[[], [], [], []];
  var i = 0;
  for (final n in [3, 2]) {
    for (var seat = 0; seat < 4; seat++) {
      for (var k = 0; k < n; k++) {
        hands[seat].add(deck[i++]);
      }
    }
  }
  return (hands: hands, rest: deck.sublist(i));
}

/// التوزيع الثاني بعد الضمانة: 3 أوراق لكل لاعب → 8. يعدّل `hands` في مكانها.
List<List<Card>> dealRest(List<List<Card>> hands, List<Card> rest) {
  var i = 0;
  for (var seat = 0; seat < 4; seat++) {
    for (var k = 0; k < 3; k++) {
      hands[seat].add(rest[i++]);
    }
  }
  return hands;
}
