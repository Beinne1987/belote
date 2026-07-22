import 'package:app/game/view_model.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/bid_bar.dart';
import 'package:app/ui/suit_pip.dart';
import 'package:app/ui/table/table_geometry.dart';
import 'package:app/ui/table/table_surface.dart';
import 'package:belote_engine/belote_engine.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';

/// طلبان من المالك (2026-07-22):
/// 1. **شريطُ الضمانة برموز الألوان** لا بأسمائها — وصنٌّ وتوٌّ وأكوينسُ نصًّا.
/// 2. **خطُّ العدّاد ينزل** إلى حدّ الشريط الأحمر السفليّ في علم اللبّاد.
void main() {
  /// الشريطُ يقرأ الثيمَ من الشجرة ⇒ لا بدّ من `ThemeScope` كما في التطبيق.
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        ThemeScope(
          manager: ThemeManager(),
          child: MaterialApp(home: Scaffold(body: Center(child: child))),
        ),
      );

  group('رموزُ الألوان في شريط الضمانة', () {
    const suits = ['trefle', 'carreau', 'coeur', 'pique'];

    test('لكلّ لونٍ مسارٌ داخل مربّع 100×100', () {
      for (final s in suits) {
        final b = SuitPip.pathOf(s).getBounds();
        expect(b.left, greaterThanOrEqualTo(0), reason: s);
        expect(b.top, greaterThanOrEqualTo(0), reason: s);
        expect(b.right, lessThanOrEqualTo(100), reason: s);
        expect(b.bottom, lessThanOrEqualTo(100), reason: s);
        // يملأ المربّعَ فعلًا: رمزٌ ضامرٌ في زاويةٍ عطبٌ صامت.
        expect(b.width, greaterThan(60), reason: s);
        expect(b.height, greaterThan(60), reason: s);
      }
    });

    test('الأحمرُ للكير والكارو وحدَهما', () {
      const ink = Color(0xFFEEEEEE);
      expect(SuitPip.inkOnDark('coeur', ink), isNot(ink));
      expect(SuitPip.inkOnDark('carreau', ink), isNot(ink));
      expect(SuitPip.inkOnDark('pique', ink), ink);
      expect(SuitPip.inkOnDark('trefle', ink), ink);
    });

    testWidgets('الشريطُ يرسم أربعةَ رموزٍ ولا يكتب اسمَ لون', (tester) async {
      const names = ['أتريف', 'كارو', 'كير', 'أبيك'];
      final options = <BidOption>[
        const BidOption(
            label: 'تمرير', action: BidAction.pass(), enabled: true,
            isPass: true),
        for (final s in ['trefle', 'carreau', 'coeur', 'pique'])
          BidOption(
            label: 'ضمانة $s',
            suit: s,
            action: BidAction.ofBid(Bid.ofSuit(s)),
            enabled: true,
          ),
        const BidOption(
            label: 'صن', action: BidAction.ofBid(Bid.sans()), enabled: true),
        const BidOption(
            label: 'تو', action: BidAction.ofBid(Bid.tout()), enabled: true),
        const BidOption(
            label: 'أكوينس', action: BidAction.akwins(), enabled: true,
            isAkwins: true),
      ];

      await pump(
        tester,
        BidBar(
          view: BidBarView(options: options, currentBid: null),
          onBid: (_) {},
        ),
      );

      expect(find.byType(SuitPip), findsNWidgets(4));
      for (final n in names) {
        expect(find.text(n), findsNothing, reason: n);
      }
      // ما لا رمزَ له يبقى نصًّا.
      expect(find.text('صن'), findsOneWidget);
      expect(find.text('تو'), findsOneWidget);
      expect(find.text('أكوينس'), findsOneWidget);
      expect(find.text('تمرير'), findsOneWidget);
    });

    testWidgets('لمسُ رمزٍ يُطلق ضمانةَ لونِه', (tester) async {
      BidAction? fired;
      await pump(
        tester,
        BidBar(
          view: BidBarView(
            options: [
              BidOption(
                label: 'كير',
                suit: 'coeur',
                action: BidAction.ofBid(Bid.ofSuit('coeur')),
                enabled: true,
              ),
            ],
            currentBid: null,
          ),
          onBid: (a) => fired = a,
        ),
      );
      await tester.tap(find.byType(SuitPip));
      expect(fired?.bid?.suit, 'coeur');
    });
  });

  group('خطُّ العدّاد على حدّ العلم', () {
    test('حدُّ الشريط الأحمر السفليّ يُشتقّ من نسبةٍ واحدة', () {
      final g = TableGeometry.of(const Size(400, 800), TableSurface.hall);
      expect(
        g.flagBottomBandTop,
        closeTo(g.felt.bottom - g.felt.height * TableGeometry.flagBandRatio,
            0.0001),
      );
      // ينزل عن موضعه القديم (فوق صندوق المروحة) ويبقى فوق قاع الطاولة.
      expect(g.flagBottomBandTop, lessThan(g.felt.bottom));
      expect(g.flagBottomBandTop, greaterThan(g.felt.center.dy));
    });
  });
}
