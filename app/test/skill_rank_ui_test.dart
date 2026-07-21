import 'package:app/game/game_controller.dart';
import 'package:app/game/view_model.dart';
import 'package:app/net/player_rank.dart';
import 'package:app/net/table_client.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/match_summary.dart';
import 'package:app/ui/rank_badge.dart';
import 'package:belote_engine/belote_engine.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';

/// **رتبةُ المهارة ولحظاتُ المباراة في الواجهة.**
///
/// الجوهر: الواجهةُ **تعرض ما يبثّه الخادم ولا تخترع** — لا رتبةَ محسوبةً هنا،
/// ولا لقطةً بلا حدث.
Widget _wrap(Widget child) => ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: child),
        ),
      ),
    );

PlayerRankView _rank({
  String tier = 'pro',
  String title = 'محترف',
  String emoji = '🏅',
  bool placed = true,
  int remaining = 0,
}) =>
    PlayerRankView(
      tier: tier,
      title: title,
      emoji: emoji,
      placed: placed,
      remaining: remaining,
      progress: 0.5,
      nextAt: 1450,
      nextTitle: 'نخبة',
    );

void main() {
  group('شارةُ الرتبة', () {
    testWidgets('تعرض اسمَ الرتبة ورمزَها', (t) async {
      await t.pumpWidget(_wrap(RankBadge(rank: _rank())));
      expect(find.text('محترف'), findsOneWidget);
      expect(find.text('🏅'), findsOneWidget);
    });

    testWidgets('خادمٌ أقدمُ من الميزة (null) ⇒ لا شيءَ يُرسَم', (t) async {
      await t.pumpWidget(_wrap(const RankBadge(rank: null)));
      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets('غيرُ المرشَّح يختفي على الطاولة ويظهر في الملفّ', (t) async {
      final unplaced =
          _rank(title: 'غير مصنَّف', emoji: '', placed: false, remaining: 3);
      await t.pumpWidget(_wrap(RankBadge(rank: unplaced)));
      expect(find.text('غير مصنَّف'), findsNothing);

      await t.pumpWidget(_wrap(RankBadge(rank: unplaced, showUnplaced: true)));
      expect(find.text('غير مصنَّف'), findsOneWidget);
    });

    testWidgets('شريطُ التقدّم يقول كم بقي — لا معادلةَ تُشرَح', (t) async {
      await t.pumpWidget(_wrap(RankProgress(rank: _rank(), rating: 1375)));
      // «إلى نخبة: 75 نقطة تصنيف» — الفارقُ محسوبٌ لا معادلةٌ معروضة.
      expect(find.text('إلى نخبة: 75 نقطة تصنيف'), findsOneWidget);
      expect(find.text('1375'), findsOneWidget); // الأرقامُ لاتينيّة
    });
  });

  group('لوحةُ اللحظات', () {
    MatchSummaryView build(MatchInsights i) => MatchSummaryView(
          insights: i,
          names: const ['أنت', 'خصم', 'شريكي', 'خصم آخر'],
          mySeat: 0,
        );

    testWidgets('تروي اللحظاتِ الأربعَ بأسماء أصحابها', (t) async {
      const spades = Bid.ofSuit('pique');
      final tr = MatchTracker()
        ..roundStarted(bid: spades, bidderSeat: 2, akwins: false);
      for (var k = 0; k < 3; k++) {
        final trick = <Play>[
          (seat: 0, card: const Card('trefle', '7')),
          (seat: 1, card: const Card('trefle', '8')),
          (seat: 2, card: const Card('trefle', 'A')),
          (seat: 3, card: const Card('trefle', 'Q')),
        ];
        tr.trickWon(
            trick: trick,
            bid: spades,
            winnerSeat: trickWinner(trick, spades),
            units: trickUnits(trick, spades));
      }
      tr.roundEnded(team0Points: 16, team1Points: 0, reason: 'ok');

      await t.pumpWidget(_wrap(
          SingleChildScrollView(child: MatchSummary(summary: build(tr.build(winnerTeam: 0))))));

      expect(find.text('رجل المباراة'), findsOneWidget);
      expect(find.text('أفضل إعلان'), findsOneWidget);
      expect(find.text('أقوى ورقة'), findsOneWidget);
      expect(find.text('أطول سلسلة'), findsOneWidget);
      // المقعد 2 حمل كلَّ شيء ⇒ اسمُه في اللقطات.
      expect(find.textContaining('شريكي'), findsWidgets);
    });

    testWidgets('ما لم يقع لا يُعرَض له صندوقٌ فارغ', (t) async {
      // مباراةٌ بلا أبليٍّ ولا ضمانةٍ موفَّى بها ⇒ رجلُ المباراة وحدَه.
      await t.pumpWidget(_wrap(
          MatchSummary(summary: build(MatchTracker().build(winnerTeam: 0)))));
      expect(find.text('رجل المباراة'), findsOneWidget);
      expect(find.text('أفضل إعلان'), findsNothing);
      expect(find.text('أقوى ورقة'), findsNothing);
      expect(find.text('أطول سلسلة'), findsNothing);
    });

    testWidgets('لقطتي أنا تُميَّز بـ«(أنت)»', (t) async {
      const spades = Bid.ofSuit('pique');
      final tr = MatchTracker()
        ..roundStarted(bid: spades, bidderSeat: 0, akwins: false)
        ..roundEnded(team0Points: 16, team1Points: 0, reason: 'ok');
      await t.pumpWidget(
          _wrap(MatchSummary(summary: build(tr.build(winnerTeam: 0)))));
      expect(find.textContaining('(أنت)'), findsWidgets);
    });
  });

  group('حمولةُ الشبكة', () {
    test('اللقطةُ تحمل الملخّصَ، ورسالةُ التصنيف تحمل الرتبة', () {
      final snap = TableEvent.parse({
        'phase': 'done',
        'seat': 0,
        'matchOver': true,
        'insights': {
          'winnerTeam': 1,
          'mvpSeat': 3,
          'rounds': 4,
          'seats': [
            for (var s = 0; s < 4; s++) {'seat': s, 'tricks': s, 'units': s * 10}
          ],
        },
      });
      expect(snap, isA<GameEvent>());
      final g = snap as GameEvent;
      expect(g.insights!.mvpSeat, 3);
      expect(g.insights!.seatPerf(2).units, 20);

      final rating = TableEvent.parse({
        'phase': 'rating',
        'rating': 1310,
        'delta': 14,
        'rank': {'tier': 'pro', 'title': 'محترف', 'emoji': '🏅', 'placed': true},
      });
      expect((rating as RatingEvent).skill!.title, 'محترف');
    });

    test('خادمٌ أقدم: لا ملخّصَ ولا رتبة — بلا انهيار', () {
      final g = TableEvent.parse(
              {'phase': 'done', 'seat': 0, 'matchOver': true}) as GameEvent;
      expect(g.insights, isNull);
      final r = TableEvent.parse({'phase': 'rating', 'rating': 1000, 'delta': 0})
          as RatingEvent;
      expect(r.skill, isNull);
    });
  });

  group('الأوفلاين يروي لحظاتِه', () {
    testWidgets('مباراةٌ كاملةٌ تُنتج ملخّصًا بأسماء الجالسين', (tester) async {
      await tester.runAsync(() async {
        final c = GameController(
          seed: 20260720,
          aiThink: Duration.zero,
          pliPause: Duration.zero,
          pliCollect: Duration.zero,
          pliSettle: Duration.zero,
          bidHold: Duration.zero,
          dealPause: Duration.zero,
          resultHold: Duration.zero,
        );
        // لا ملخّصَ قبل نهاية المباراة.
        expect(c.matchSummary, isNull);

        var guard = 0;
        while (c.roundResult?.matchOutcome != 0 &&
            c.roundResult?.matchOutcome != 1) {
          if (++guard > 40000) fail('المباراة لم تكتمل (حلقة عالقة؟)');
          final bar = c.bidBar;
          if (bar != null) {
            final bid = bar.options.firstWhere(
              (o) => o.enabled && !o.isPass && !o.isAkwins,
              orElse: () => bar.options.firstWhere((o) => o.enabled),
            );
            c.placeBid(bid.action);
          } else if (c.tableView.humanCanPlay) {
            c.playCard(c.tableView.legalCards.first);
          } else if (c.tableView.phase == GamePhase.done) {
            c.newRound(); // النتيجةُ معروضةٌ بلا مهلة ⇒ تقدّم يدويًّا
          } else {
            await Future<void>.delayed(Duration.zero);
          }
        }

        final s = c.matchSummary;
        expect(s, isNotNull, reason: 'انتهت المباراةُ ⇒ لها ملخّص');
        expect(s!.names.first, 'أنت');
        expect(s.mySeat, 0);
        expect(s.insights.rounds, greaterThan(0));
        // كلُّ أبليٍّ لُعب نُسب إلى مقعد — لا تسريبَ ولا اختراع.
        expect(s.insights.seats.fold(0, (a, p) => a + p.tricks),
            s.insights.rounds * 8);
        c.dispose();
      });
    });
  });
}
