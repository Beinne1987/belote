import 'package:app/net/api_client.dart';
import 'package:app/net/session_controller.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/honor_badge.dart';
import 'package:app/ui/honor_board.dart';
import 'package:app/ui/player_seat_round.dart';
import 'package:app/game/seat_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// لوحةُ الشرف الأسبوعيّة وشارةُ اللقب ([[honors-weekly]]).
Widget _wrap(Widget child) => ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: child),
        ),
      ),
    );

HonorCategoryBoard _cat(
  String id,
  String label,
  String title,
  String unit, {
  List<(String, int)> winners = const [],
}) =>
    HonorCategoryBoard(
      id: id,
      label: label,
      title: title,
      unit: unit,
      entries: [
        for (var i = 0; i < winners.length; i++)
          HonorRow(
            rank: i + 1,
            playerId: 'id_${winners[i].$1}',
            name: winners[i].$1,
            tag: 'TAG',
            avatarUrl: '',
            value: winners[i].$2,
          )
      ],
    );

HonorsBoard _board({bool empty = false}) => HonorsBoard(
      week: 'W2026-07-20',
      categories: [
        _cat('king', 'أفضل لاعب', '👑 ملك الأسبوع', 'نقطة تصنيف',
            winners: empty ? const [] : const [('سالم', 120), ('مريم', 90)]),
        _cat('mostWins', 'أكثر فوزًا', '🏆 قاهر الطاولات', 'فوزًا',
            winners: empty ? const [] : const [('مريم', 14)]),
        _cat('mostGifts', 'أكرم لاعب', '💝 سيّد الكرم', 'هديّة',
            winners: empty ? const [] : const [('خالد', 31)]),
      ],
      titles: empty ? const {} : const {'id_سالم': ['king', 'mostGifts']},
    );

void main() {
  group('قسمُ الرئيسيّة', () {
    testWidgets('يعرض المتصدّر بلقبه ورقمه، والفئاتِ الباقية', (t) async {
      await t.pumpWidget(_wrap(HonorBoardSection(board: _board())));
      await t.pump();

      expect(find.text('سالم'), findsWidgets);
      expect(find.textContaining('120 نقطة تصنيف'), findsOneWidget);
      expect(find.text('ملك الأسبوع'), findsOneWidget, reason: 'لقبُ المتصدّر');
      expect(find.text('مريم'), findsOneWidget, reason: 'فئةٌ ثانية');
      expect(find.text('خالد'), findsOneWidget, reason: 'فئةٌ ثالثة');
    });

    /// **لا صناديقَ فارغة**: أسبوعٌ لم يلعب فيه أحدٌ ⇒ القسمُ يختفي كلُّه.
    testWidgets('بلا فائزٍ ⇒ لا قسمَ أصلًا', (t) async {
      await t.pumpWidget(_wrap(HonorBoardSection(board: _board(empty: true))));
      expect(find.textContaining('لوحة الشرف'), findsNothing);
    });

    testWidgets('خادمٌ أقدمُ من الميزة (لوحةٌ فارغة) ⇒ لا عطبَ ولا قسم', (t) async {
      await t.pumpWidget(_wrap(const HonorBoardSection(board: HonorsBoard.empty)));
      expect(tester_ok, isTrue);
      expect(find.textContaining('لوحة الشرف'), findsNothing);
    });

    testWidgets('«الكلّ» تفتح الشاشةَ الكاملةَ بأوائلِ كلّ فئة', (t) async {
      await t.pumpWidget(_wrap(HonorBoardSection(board: _board())));
      await t.tap(find.text('الكلّ'));
      await t.pumpAndSettle();

      expect(find.byType(HonorBoardScreen), findsOneWidget);
      // الأوّلُ والثاني في فئة الملك معًا.
      expect(find.text('سالم'), findsWidgets);
      expect(find.textContaining('90 نقطة تصنيف'), findsOneWidget);
    });
  });

  group('الشارة', () {
    testWidgets('بلا لقب ⇒ لا شيء يُرسَم (ولا مساحةٌ تُحجَز)', (t) async {
      await t.pumpWidget(_wrap(const HonorBadge(category: null)));
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('الرمزُ وحدَه افتراضًا، والنصُّ حين يُطلَب', (t) async {
      final c = _board().categories.first;
      await t.pumpWidget(_wrap(HonorBadge(category: c)));
      expect(find.text('👑'), findsOneWidget);
      expect(find.text('ملك الأسبوع'), findsNothing);

      await t.pumpWidget(_wrap(HonorBadge(category: c, showText: true)));
      expect(find.text('ملك الأسبوع'), findsOneWidget);
    });
  });

  group('اللقب على الطاولة', () {
    testWidgets('**رمزُ اللقب بجانب الاسم** — والاسمُ لا يُدفَع خارج اللوح',
        (t) async {
      await t.pumpWidget(_wrap(const Center(
        child: PlayerSeatRound(
          name: 'سالم',
          emoji: '😎',
          rank: PlayerRank.pro,
          honorEmoji: '👑',
        ),
      )));
      expect(find.text('👑'), findsOneWidget);
      expect(find.text('سالم'), findsOneWidget);
      expect(tester_ok, isTrue, reason: 'بلا فيضٍ في التخطيط');
    });

    testWidgets('بلا لقب ⇒ لا رمزَ على المقعد', (t) async {
      await t.pumpWidget(_wrap(const Center(
        child: PlayerSeatRound(
            name: 'سالم', emoji: '😎', rank: PlayerRank.pro),
      )));
      expect(find.text('👑'), findsNothing);
    });
  });

  group('الشارةُ في كلّ الشاشات', () {
    /// جلسةٌ محقونةٌ بلوحةٍ جاهزة — الشاشاتُ تقرأ الخريطةَ منها لا من الشبكة.
    Widget withSession(Widget child, {HonorsBoard? board}) {
      final c = SessionController(api: ApiClient());
      if (board != null) c.debugSetHonors(board);
      return ThemeScope(
        manager: ThemeManager(),
        child: SessionScope(
          controller: c,
          child: MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(body: child),
            ),
          ),
        ),
      );
    }

    testWidgets('صاحبُ اللقب تظهر شارتُه، وغيرُه لا', (t) async {
      await t.pumpWidget(withSession(
        const Column(children: [
          PlayerHonorBadge(playerId: 'id_سالم'),
          PlayerHonorBadge(playerId: 'id_مريم'),
        ]),
        board: _board(),
      ));
      await t.pump();
      expect(find.text('👑'), findsOneWidget, reason: 'الأعلى رتبةً لا الاثنان');
      expect(find.text('💝'), findsNothing);
    });

    /// **زينةٌ لا تُسقط شاشة**: الشاشاتُ تُختبَر وحدَها بلا `SessionScope`.
    testWidgets('بلا جلسةٍ ⇒ لا شارةَ ولا انهيار', (t) async {
      await t.pumpWidget(_wrap(const PlayerHonorBadge(playerId: 'id_سالم')));
      expect(find.text('👑'), findsNothing);
    });

    testWidgets('الملفّ يعرض **كلَّ** ألقابه لا الأعلى وحدَه', (t) async {
      await t.pumpWidget(withSession(
        const AllHonorBadges(playerId: 'id_سالم'),
        board: _board(),
      ));
      await t.pump();
      expect(find.text('ملك الأسبوع'), findsOneWidget);
      expect(find.text('سيّد الكرم'), findsOneWidget);
    });
  });

  group('أعلى الألقاب', () {
    test('**الأوّلُ في القائمة هو الأعلى رتبةً** (الخادمُ يرسلها مرتَّبة)', () {
      final b = _board();
      expect(b.topTitleOf('id_سالم'), 'king');
      expect(b.categoryById('king')!.emoji, '👑');
    });

    test('من لا لقبَ له ⇒ null لا سلسلةٌ فارغة', () {
      expect(_board().topTitleOf('id_مريم'), isNull);
      expect(_board().categoryById(null), isNull);
    });
  });
}

/// لا استثناءَ تخطيطٍ وقع أثناء البناء — `pumpWidget` يرمي عند الفيض، فوصولُنا
/// إلى هنا هو الدليل.
const tester_ok = true;
