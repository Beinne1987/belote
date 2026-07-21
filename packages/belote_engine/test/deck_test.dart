import 'package:test/test.dart';
import 'package:belote_engine/belote_engine.dart';

/// تسلسلات الخلط الذهبية — مولّدة من محرك JS المرجعي (نفس buildDeck/shuffle/lcg)
/// عبر سكربت مؤقت خارج الريبو. الترميز: حرف اللون + الرتبة (golden.json).
///
/// لا نقارن بـ hands5 في golden.json هنا: الضمانة تستهلك أرقاماً من rng قبل
/// الخلط، وهي لم تُكتب بعد. فالتحقق مباشر على shuffle(buildDeck(), Lcg(seed)).
const goldenShuffle = <int, List<String>>{
  12345: [
    'HK', 'S9', 'HJ', 'S7', 'HQ', 'C7', 'C9', 'T9', 'C8', 'TJ', 'SQ', 'C10',
    'H8', 'TQ', 'HA', 'TK', 'TA', 'S10', 'T8', 'H10', 'CA', 'SK', 'SJ', 'CK',
    'CQ', 'CJ', 'T10', 'S8', 'H9', 'H7', 'SA', 'T7',
  ],
  1: [
    'H9', 'HQ', 'S8', 'CJ', 'SA', 'T10', 'HK', 'C9', 'H10', 'HA', 'S10', 'T9',
    'TK', 'S9', 'H8', 'S7', 'H7', 'TJ', 'SQ', 'SK', 'C7', 'TQ', 'CK', 'T7',
    'CQ', 'SJ', 'C8', 'T8', 'HJ', 'CA', 'C10', 'TA',
  ],
  20260710: [
    'T7', 'TQ', 'SJ', 'C8', 'H9', 'S7', 'T10', 'T8', 'C7', 'SK', 'TJ', 'CK',
    'HJ', 'HA', 'TK', 'HQ', 'HK', 'C10', 'CQ', 'S8', 'SA', 'CJ', 'H10', 'TA',
    'T9', 'S10', 'H8', 'S9', 'CA', 'H7', 'SQ', 'C9',
  ],
};

void main() {
  group('Card', () {
    test('== و hashCode بالقيمة', () {
      expect(const Card('coeur', 'K'), const Card('coeur', 'K'));
      expect(const Card('coeur', 'K'), isNot(const Card('coeur', 'A')));
      expect(const Card('coeur', 'K'), isNot(const Card('pique', 'K')));
      expect(
        const Card('coeur', 'K').hashCode,
        const Card('coeur', 'K').hashCode,
      );
      // صالحة كمفتاح مجموعة
      final s = {const Card('coeur', 'K'), const Card('coeur', 'K')};
      expect(s.length, 1);
    });

    test('الترميز مطابق لـ golden.json', () {
      expect(const Card('pique', 'J').code, 'SJ');
      expect(const Card('coeur', '10').code, 'H10');
      expect(const Card('trefle', '7').code, 'T7');
    });
  });

  group('buildDeck', () {
    test('٣٢ ورقة فريدة، بالترتيب الملزِم', () {
      final deck = buildDeck();
      expect(deck.length, 32);
      expect(deck.map((c) => c.code).toSet().length, 32);
      expect(deck.first.code, 'T7'); // أتريف 7 أولاً
      expect(deck.last.code, 'SA'); // أبيك A أخيراً
    });
  });

  group('shuffle — تطابق بت-ببت مع JS', () {
    goldenShuffle.forEach((seed, expected) {
      test('Lcg($seed) → نفس الـ٣٢ ورقة', () {
        final got = shuffle(buildDeck(), Lcg(seed)).map((c) => c.code).toList();
        expect(got, expected);
      });
    });

    test('لا يغيّر الأصل', () {
      final deck = buildDeck();
      final before = deck.map((c) => c.code).toList();
      shuffle(deck, Lcg(999));
      expect(deck.map((c) => c.code).toList(), before);
    });
  });

  group('التوزيع', () {
    test('dealOpening: ٥ لكل لاعب، ١٢ مؤجّلة، بلا فقد', () {
      final deck = shuffle(buildDeck(), Lcg(12345));
      final d = dealOpening(deck);
      expect(d.hands.length, 4);
      expect(d.hands.every((h) => h.length == 5), isTrue);
      expect(d.rest.length, 12);
      final all = [...d.hands.expand((h) => h), ...d.rest];
      expect(all.map((c) => c.code).toSet().length, 32); // كل الأوراق حاضرة
    });

    test('dealRest: ٨ لكل لاعب، والخمس الأولى محفوظة', () {
      final deck = shuffle(buildDeck(), Lcg(12345));
      final d = dealOpening(deck);
      final first5 = [
        for (final h in d.hands) h.map((c) => c.code).toList(),
      ];
      final hands8 = dealRest(d.hands, d.rest);
      expect(hands8.every((h) => h.length == 8), isTrue);
      for (var s = 0; s < 4; s++) {
        expect(hands8[s].take(5).map((c) => c.code).toList(), first5[s]);
      }
      final all = hands8.expand((h) => h).map((c) => c.code).toSet();
      expect(all.length, 32);
    });
  });
}
