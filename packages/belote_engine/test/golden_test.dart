import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:belote_engine/belote_engine.dart';

/// الاختبار التفاضلي الكامل: محرك Dart يعيد إنتاج كل جولة من الـ300 في
/// fixtures/golden.json حرفياً — الموزّع، الضمانة، التوزيع، **كل أبلي**،
/// ثم الوحدات والدير و`scoreRound` (بما فيها OPEN_RULE_AKWINS_TIE).
///
/// المسار نسبيّ لجذر الحزمة، حيث يُشغَّل `dart test`.
List<String> encodeHand(List<Card> h) => h.map((c) => c.code).toList();
List<List<String>> encodeHands(List<List<Card>> hs) => hs.map(encodeHand).toList();

void main() {
  final file = File('../../fixtures/golden.json');
  if (!file.existsSync()) {
    fail('لم يُعثر على المتجهات الذهبية: ${file.absolute.path}\n'
        'شغّل الاختبار من جذر الحزمة: cd packages/belote_engine && dart test');
  }
  final g = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final rounds = (g['rounds'] as List).cast<Map<String, dynamic>>();

  test('Dart يطابق JS: الجولة كاملةً في ${rounds.length} جولة', () {
    for (final r in rounds) {
      final seed = r['seed'] as int;
      final rng = Lcg(seed);

      // 1. الموزّع
      expect((rng.next() * 4).floor(), r['dealer'],
          reason: 'seed $seed: الموزّع');

      // 2. الضمانة — خطوة بخطوة
      final bidding = r['bidding'] as Map<String, dynamic>;
      final st = createBidding(r['dealer'] as int);
      final log = (bidding['log'] as List).cast<Map<String, dynamic>>();
      for (final step in log) {
        final acts = legalBidActions(st);
        expect(st.turn, step['seat'], reason: 'seed $seed: المقعد صاحب الدور');
        expect(acts.length, step['n'],
            reason: 'seed $seed مقعد ${step['seat']}: طول القائمة (اختلاف ترتيب؟)');
        final i = (rng.next() * acts.length).floor();
        expect(i, step['i'], reason: 'seed $seed: الفهرس المختار');
        expect(acts[i].code, step['a'], reason: 'seed $seed: الإجراء المختار');
        applyBidAction(st, acts[i]);
      }
      final bid = st.currentBid!;
      expect(bid.code, bidding['bid'], reason: 'seed $seed: الضمانة النهائية');
      expect(st.bidderSeat, bidding['bidderSeat'],
          reason: 'seed $seed: مقعد الضامن');
      expect(st.akwins, bidding['akwins'], reason: 'seed $seed: أكوينس');

      // 3. التوزيع
      final deal = r['deal'] as Map<String, dynamic>;
      final deck = shuffle(buildDeck(), rng);
      final d = dealOpening(deck);
      expect(encodeHands(d.hands), deal['hands5'], reason: 'seed $seed: hands5');
      dealRest(d.hands, d.rest);
      expect(encodeHands(d.hands), deal['hands8'], reason: 'seed $seed: hands8');

      // 4. الأبالي — 8 دورات، خطوة بخطوة
      final hands = d.hands;
      final units = [0, 0];
      var leader = firstBidder(r['dealer'] as int);
      var last = leader;
      final tricks = (r['tricks'] as List).cast<Map<String, dynamic>>();
      for (final t in tricks) {
        expect(leader, t['leader'], reason: 'seed $seed: قائد الأبلي');
        final trick = <Play>[];
        var seat = leader;
        final plays = (t['plays'] as List).cast<Map<String, dynamic>>();
        for (final p in plays) {
          expect(seat, p['seat'], reason: 'seed $seed: المقعد صاحب الدور في اللعب');
          final legal = legalPlays(hands[seat], trick);
          expect(encodeHand(legal), p['legal'],
              reason: 'seed $seed: قائمة القانوني (ترتيب؟)');
          final idx = (rng.next() * legal.length).floor();
          expect(idx, p['i'], reason: 'seed $seed: فهرس الورقة المختارة');
          final card = legal[idx];
          expect(card.code, p['c'], reason: 'seed $seed: الورقة المختارة');
          hands[seat].remove(card);
          trick.add((seat: seat, card: card));
          seat = nextSeat(seat);
        }
        final w = trickWinner(trick, bid);
        final u = trickUnits(trick, bid);
        expect(w, t['winner'], reason: 'seed $seed: الفائز بالأبلي');
        expect(u, t['units'], reason: 'seed $seed: وحدات الأبلي');
        units[teamOf(w)] += u;
        last = w;
        leader = w;
      }
      units[teamOf(last)] += derUnits;
      expect(last, r['der'], reason: 'seed $seed: الدير');

      // 5. الوحدات
      final bt = teamOf(st.bidderSeat!);
      final unitsBidder = units[bt];
      final unitsOpp = units[1 - bt];
      final totals = r['totals'] as Map<String, dynamic>;
      expect(unitsBidder, totals['unitsBidder'], reason: 'seed $seed: وحدات الضامن');
      expect(unitsOpp, totals['unitsOpp'], reason: 'seed $seed: وحدات الخصم');
      expect(unitsBidder + unitsOpp, totals['expected'],
          reason: 'seed $seed: لا تسريب وحدات');

      // 6. النقاط — بما فيها OPEN_RULE_AKWINS_TIE
      if (r['error'] != null) {
        expect(r['error'], openRuleAkwinsTie,
            reason: 'seed $seed: الخطأ المتوقّع هو الثغرة #1 فقط');
        expect(
          () => scoreRound(
              bid: bid,
              akwins: st.akwins,
              unitsBidder: unitsBidder,
              unitsOpp: unitsOpp),
          throwsA(isA<AkwinsTieException>()),
          reason: 'seed $seed: يجب رمي OPEN_RULE_AKWINS_TIE',
        );
      } else {
        final s = scoreRound(
            bid: bid,
            akwins: st.akwins,
            unitsBidder: unitsBidder,
            unitsOpp: unitsOpp);
        final score = r['score'] as Map<String, dynamic>;
        expect(s.bidder, score['bidder'], reason: 'seed $seed: نقاط الضامن');
        expect(s.opponent, score['opponent'], reason: 'seed $seed: نقاط الخصم');
        expect(s.reason, score['reason'], reason: 'seed $seed: سبب الحسم');
      }
    }
  });

  // جدول القيم الحرجة لقاعدة النقطة العالقة — مولَّد من JS في golden.json.
  // كل صف يحمل الآن نتيجته الكاملة: distributePoints(u, uOpp, pts) == (bidder, opponent).
  final scoring = (g['scoring'] as List).cast<Map<String, dynamic>>();
  test('Dart يطابق JS: ${scoring.length} حالة حرجة في قاعدة النقطة العالقة', () {
    for (final row in scoring) {
      final total = row['total'] as int;
      final pts = row['pts'] as int;
      final u = row['u'] as int;
      final uOpp = row['uOpp'] as int;
      final res = distributePoints(u, uOpp, pts);
      expect(res.bidder, row['bidder'],
          reason: 'total $total, u $u: نقاط الضامن');
      expect(res.opponent, row['opponent'],
          reason: 'total $total, u $u: نقاط الخصم');
    }
  });

  // تغطية 100٪ لقاعدة النقطة العالقة: كل قيمة وحدات ممكنة (163 + 259 = 422 حالة).
  // scoringFull[total][u] == [u, bidderPoints, opponentPoints] — مولَّد من JS.
  // pts (قيمة الجولة) = 16 للون (162) · 26 لصن-تو (258).
  final scoringFull = g['scoringFull'] as Map<String, dynamic>;
  const ptsForTotal = {162: 16, 258: 26};
  var fullCount = 0;
  for (final e in scoringFull.entries) {
    if (int.tryParse(e.key) == null) continue; // تخطّي مفتاح 'note'
    fullCount += (e.value as List).length;
  }
  test('Dart يطابق JS: $fullCount حالة (تغطية كاملة لقاعدة النقطة العالقة)', () {
    for (final e in scoringFull.entries) {
      final total = int.tryParse(e.key);
      if (total == null) continue; // تخطّي مفتاح 'note'
      final pts = ptsForTotal[total]!;
      final rows = (e.value as List).cast<List<dynamic>>();
      for (var u = 0; u <= total; u++) {
        final row = rows[u];
        expect(row[0], u, reason: 'total $total: الفهرس = الوحدات');
        final res = distributePoints(u, total - u, pts);
        expect(res.bidder, row[1],
            reason: 'total $total, u $u: نقاط الضامن');
        expect(res.opponent, row[2],
            reason: 'total $total, u $u: نقاط الخصم');
      }
    }
  });
}
