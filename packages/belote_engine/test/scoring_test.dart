import 'package:test/test.dart';
import 'package:belote_engine/belote_engine.dart';

void main() {
  group('distributePoints — الأمثلة الأربعة من docs/PORT-TO-DART.md', () {
    test('لون 95/67 → الضامن 9 · الخصم 7 (الأعلى في البقية)', () {
      expect(distributePoints(95, 67, 16), (bidder: 9, opponent: 7));
    });

    test('لون 86/76 → الضامن 9 · الخصم 7 (تساوي البقية ← الأعلى وحدات)', () {
      expect(distributePoints(86, 76, 16), (bidder: 9, opponent: 7));
    });

    test('صن/تو 139/119 → الضامن 15 · الخصم 11 (نقطتان عالقتان)', () {
      expect(distributePoints(139, 119, 26), (bidder: 15, opponent: 11));
    });

    test('صن/تو 129/129 → الضامن 14 · الخصم 12 (تعادل تام → الضامن)', () {
      expect(distributePoints(129, 129, 26), (bidder: 14, opponent: 12));
    });
  });

  group('distributePoints — لا نقطة تضيع ولا تُخترع', () {
    test('لون: كل الحالات 0..162 مجموعها 16 بالضبط', () {
      for (var uB = 0; uB <= 162; uB++) {
        final uO = 162 - uB;
        final r = distributePoints(uB, uO, 16);
        expect(r.bidder + r.opponent, 16, reason: 'الوحدات $uB/$uO');
        expect(r.bidder, greaterThanOrEqualTo(0));
        expect(r.opponent, greaterThanOrEqualTo(0));
      }
    });

    test('صن/تو: كل الحالات 0..258 مجموعها 26 بالضبط', () {
      for (var uB = 0; uB <= 258; uB++) {
        final uO = 258 - uB;
        final r = distributePoints(uB, uO, 26);
        expect(r.bidder + r.opponent, 26, reason: 'الوحدات $uB/$uO');
        expect(r.bidder, greaterThanOrEqualTo(0));
        expect(r.opponent, greaterThanOrEqualTo(0));
      }
    });
  });

  group('scoreWhiteRound — الجولة البيضاء (الكابوت)', () {
    test('لا كابوت إن أخذ الفريقان أبليًا ⇒ null', () {
      expect(
          scoreWhiteRound(
              bid: const Bid.sans(), akwins: false, tricksWon: [3, 5]),
          isNull);
      expect(
          scoreWhiteRound(bid: Bid.ofSuit('pique'), akwins: false, tricksWon: [1, 7]),
          isNull);
    });

    test('كابوت لون ⇒ 26 للفريق الكاسح', () {
      expect(scoreWhiteRound(bid: Bid.ofSuit('coeur'), akwins: false, tricksWon: [8, 0]),
          (team: 0, value: 26));
      expect(scoreWhiteRound(bid: Bid.ofSuit('coeur'), akwins: false, tricksWon: [0, 8]),
          (team: 1, value: 26));
    });

    test('كابوت صن/تو ⇒ 35', () {
      expect(scoreWhiteRound(bid: const Bid.sans(), akwins: false, tricksWon: [0, 8]),
          (team: 1, value: 35));
      expect(scoreWhiteRound(bid: const Bid.tout(), akwins: false, tricksWon: [8, 0]),
          (team: 0, value: 35));
    });

    test('كابوت أكوينس ⇒ القيمة تبقى 32/52 (الحسم فوق الجولة)', () {
      expect(scoreWhiteRound(bid: Bid.ofSuit('trefle'), akwins: true, tricksWon: [8, 0]),
          (team: 0, value: 32));
      expect(scoreWhiteRound(bid: const Bid.sans(), akwins: true, tricksWon: [0, 8]),
          (team: 1, value: 52));
    });
  });
}
