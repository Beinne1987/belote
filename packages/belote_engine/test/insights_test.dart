import 'package:belote_engine/belote_engine.dart';
import 'package:test/test.dart';

/// أبليٌ مفتعَل: أربعُ أوراقٍ بالمقاعد 0..3 — يُحسَب فائزُه ووحداتُه بالمحرّك نفسِه
/// كي لا يختبرَ الاختبارُ أرقامًا كتبتُها بيدي.
({List<Play> trick, int winner, int units}) trickOf(Bid bid, List<Card> cards) {
  final trick = <Play>[
    for (var i = 0; i < cards.length; i++) (seat: i, card: cards[i])
  ];
  return (
    trick: trick,
    winner: trickWinner(trick, bid),
    units: trickUnits(trick, bid)
  );
}

void feedTrick(MatchTracker t, Bid bid, List<Card> cards) {
  final r = trickOf(bid, cards);
  t.trickWon(trick: r.trick, bid: bid, winnerSeat: r.winner, units: r.units);
}

void main() {
  const spades = Bid.ofSuit('pique');
  const hearts = 'coeur';

  group('الأبالي والوحدات', () {
    test('تُنسَب لآخذها، والدير يزيد وحداته بلا أبلي', () {
      final t = MatchTracker()
        ..roundStarted(bid: spades, bidderSeat: 0, akwins: false);
      // فالةُ الحكم (20) تأخذ آسًا (11) وورقتين فارغتين.
      feedTrick(t, spades, [
        const Card(hearts, 'A'),
        const Card('pique', 'J'),
        const Card(hearts, '7'),
        const Card(hearts, '8'),
      ]);
      t.derAwarded(seat: 1, units: 10);
      final i = t.build(winnerTeam: 0);

      expect(i.seatPerf(1).tricks, 1);
      expect(i.seatPerf(1).units, 31 + 10);
      expect(i.seatPerf(0).tricks, 0);
      expect(i.seatPerf(0).units, 0);
    });
  });

  group('أقوى ورقة', () {
    test('أثقلُ أبليٍّ لا أعلى رتبة', () {
      final t = MatchTracker()
        ..roundStarted(bid: spades, bidderSeat: 0, akwins: false);
      // أبليٌ ثقيل يأخذه المقعد 1 بفالة الحكم.
      feedTrick(t, spades, [
        const Card(hearts, 'A'),
        const Card('pique', 'J'),
        const Card(hearts, '10'),
        const Card(hearts, 'K'),
      ]);
      // أبليٌ خفيفٌ يأخذه المقعد 0 بآسٍ — رتبةٌ أعلى، وحداتٌ أقلّ.
      feedTrick(t, spades, [
        const Card('trefle', 'A'),
        const Card('trefle', '7'),
        const Card('trefle', '8'),
        const Card('trefle', 'Q'),
      ]);
      final i = t.build(winnerTeam: 0);

      expect(i.strongestCard!.seat, 1);
      expect(i.strongestCard!.card, 'SJ');
      expect(i.strongestCard!.units, greaterThan(30));
    });
  });

  group('أطول سلسلة', () {
    test('لا تُروى سلسلةٌ من أبليٍّ واحد', () {
      final t = MatchTracker()
        ..roundStarted(bid: spades, bidderSeat: 0, akwins: false);
      feedTrick(t, spades, [
        const Card('trefle', 'A'),
        const Card('trefle', '7'),
        const Card('trefle', '8'),
        const Card('trefle', 'Q'),
      ]);
      expect(t.build(winnerTeam: 0).longestStreak, isNull);
    });

    test('ثلاثةٌ متتاليةٌ لمقعدٍ واحد تُروى', () {
      final t = MatchTracker()
        ..roundStarted(bid: spades, bidderSeat: 0, akwins: false);
      for (final r in ['A', 'K', 'Q']) {
        feedTrick(t, spades, [
          Card('trefle', r),
          const Card('trefle', '7'),
          const Card('trefle', '8'),
          const Card('carreau', '9'),
        ]);
      }
      final s = t.build(winnerTeam: 0).longestStreak!;
      expect(s.seat, 0);
      expect(s.length, 3);
    });

    test('الجولةُ الجديدة تقطع السلسلة — توزيعٌ جديدٌ لا وصل', () {
      final t = MatchTracker()
        ..roundStarted(bid: spades, bidderSeat: 0, akwins: false);
      feedTrick(t, spades, [
        const Card('trefle', 'A'),
        const Card('trefle', '7'),
        const Card('trefle', '8'),
        const Card('carreau', '9'),
      ]);
      t.roundEnded(team0Points: 16, team1Points: 0, reason: 'ok');
      t.roundStarted(bid: spades, bidderSeat: 0, akwins: false);
      feedTrick(t, spades, [
        const Card('trefle', 'A'),
        const Card('trefle', '7'),
        const Card('trefle', '8'),
        const Card('carreau', '9'),
      ]);
      expect(t.build(winnerTeam: 0).longestStreak, isNull);
    });
  });

  group('أفضل إعلان', () {
    test('الضمانةُ الموفَّى بها وحدَها، والأثمنُ يتقدّم', () {
      final t = MatchTracker()
        ..roundStarted(bid: spades, bidderSeat: 0, akwins: false)
        ..roundEnded(team0Points: 16, team1Points: 0, reason: 'ok')
        // ضامنٌ سقط ⇒ لا يُروى إعلانُه.
        ..roundStarted(bid: const Bid.tout(), bidderSeat: 1, akwins: false)
        ..roundEnded(team0Points: 26, team1Points: 0, reason: 'chute')
        ..roundStarted(bid: const Bid.sans(), bidderSeat: 3, akwins: true)
        ..roundEnded(team0Points: 0, team1Points: 52, reason: 'akwins');
      final i = t.build(winnerTeam: 1);

      expect(i.bestBid!.seat, 3);
      expect(i.bestBid!.akwins, isTrue);
      expect(i.bestBid!.points, 52);
      expect(i.seatPerf(0).bidsWon, 1);
      expect(i.seatPerf(1).bids, 1);
      expect(i.seatPerf(1).bidsWon, 0); // سقط
      expect(i.seatPerf(3).akwinsWon, 1);
    });

    test('جولةُ الفوجة لا تُحسَب على الضمانة نجاحًا ولا سقوطًا', () {
      final t = MatchTracker()
        ..roundStarted(bid: spades, bidderSeat: 0, akwins: false)
        ..foujaResolved(accuserSeat: 1, accusedSeat: 0, proven: true)
        ..roundEnded(team0Points: 0, team1Points: 16, reason: 'fouja');
      final i = t.build(winnerTeam: 1);

      expect(i.seatPerf(0).bids, 1);
      expect(i.seatPerf(0).bidsWon, 0);
      expect(i.bestBid, isNull);
      expect(i.seatPerf(0).foujasCaught, 1);
      expect(i.seatPerf(1).rightAccusations, 1);
    });

    test('الاتّهامُ الخاطئ يُسجَّل على المتّهِم وحدَه', () {
      final t = MatchTracker()
        ..roundStarted(bid: spades, bidderSeat: 0, akwins: false)
        ..foujaResolved(accuserSeat: 1, accusedSeat: 0, proven: false);
      final i = t.build(winnerTeam: 0);

      expect(i.seatPerf(1).wrongAccusations, 1);
      expect(i.seatPerf(0).foujasCaught, 0);
      expect(i.seatPerf(1).score, lessThan(i.seatPerf(3).score));
    });
  });

  group('رجل المباراة', () {
    test('من جرّ الوحداتِ ووفّى بضمانته', () {
      final t = MatchTracker()
        ..roundStarted(bid: spades, bidderSeat: 2, akwins: false);
      for (var i = 0; i < 4; i++) {
        feedTrick(t, spades, [
          const Card('trefle', '7'),
          const Card('trefle', '8'),
          const Card('trefle', 'A'),
          const Card('trefle', 'Q'),
        ]);
      }
      t.roundEnded(team0Points: 16, team1Points: 0, reason: 'ok');
      expect(t.build(winnerTeam: 0).mvpSeat, 2);
    });

    test('قد يكون من الفريق الخاسر — من حمل الطاولة يُذكَر', () {
      final t = MatchTracker()
        ..roundStarted(bid: spades, bidderSeat: 1, akwins: false);
      for (var i = 0; i < 5; i++) {
        feedTrick(t, spades, [
          const Card('trefle', '7'),
          const Card('trefle', 'A'),
          const Card('trefle', '8'),
          const Card('trefle', 'Q'),
        ]);
      }
      t.roundEnded(team0Points: 0, team1Points: 16, reason: 'ok');
      // فاز الفريقُ 0 بالمباراة، والمقعد 1 هو من جرّ كلَّ شيء.
      final i = t.build(winnerTeam: 0);
      expect(i.mvpSeat, 1);
      expect(i.winnerTeam, 0);
    });

    test('حتميٌّ عند التعادل التامّ — أصغرُ مقعد', () {
      final i = MatchTracker().build(winnerTeam: 0);
      expect(i.mvpSeat, 0);
      for (var s = 0; s < 4; s++) {
        expect(i.seatPerf(s).score, i.seatPerf(0).score);
      }
    });
  });

  group('التسلسل عبر الشبكة', () {
    test('ما يخرج من الخادم يعود كما كان', () {
      final t = MatchTracker()
        ..roundStarted(bid: spades, bidderSeat: 0, akwins: false);
      feedTrick(t, spades, [
        const Card(hearts, 'A'),
        const Card('pique', 'J'),
        const Card(hearts, '10'),
        const Card(hearts, 'K'),
      ]);
      feedTrick(t, spades, [
        const Card('pique', '9'),
        const Card('pique', '7'),
        const Card('pique', '8'),
        const Card('pique', 'Q'),
      ]);
      t.derAwarded(seat: 0, units: 10);
      t.roundEnded(team0Points: 16, team1Points: 0, reason: 'ok');
      final a = t.build(winnerTeam: 0);
      final b = MatchInsights.fromJson(a.toJson());

      expect(b.mvpSeat, a.mvpSeat);
      expect(b.winnerTeam, a.winnerTeam);
      expect(b.rounds, a.rounds);
      expect(b.bestBid!.seat, a.bestBid!.seat);
      expect(b.strongestCard!.card, a.strongestCard!.card);
      expect(b.longestStreak?.length, a.longestStreak?.length);
      for (var s = 0; s < 4; s++) {
        expect(b.seatPerf(s).units, a.seatPerf(s).units);
        expect(b.seatPerf(s).tricks, a.seatPerf(s).tricks);
        expect(b.seatPerf(s).score, closeTo(a.seatPerf(s).score, 0.05));
      }
    });

    test('حمولةٌ ناقصةٌ لا تُسقط الشاشة', () {
      final i = MatchInsights.fromJson({'winnerTeam': 1});
      expect(i.seats.length, 4);
      expect(i.bestBid, isNull);
      expect(i.mvpSeat, 0);
    });
  });
}
