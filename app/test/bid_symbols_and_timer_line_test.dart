import 'package:app/game/view_model.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/bid_bar.dart';
import 'package:app/ui/bid_visuals.dart';
import 'package:app/ui/suit_pip.dart';
import 'package:app/ui/table/table_geometry.dart';
import 'package:app/ui/table/table_surface.dart';
import 'package:belote_engine/belote_engine.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';

/// طلبان من المالك (2026-07-22):
/// 1. **شريطُ الضمانة برموز الألوان** لا بأسمائها — وصنٌّ وتوٌّ وأكوينسُ نصًّا.
/// 2. **خطُّ العدّاد ينزل** إلى حدّ الشريط الأحمر السفليّ في علم اللبّاد.
void _ignore(BidAction _) {}

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

    // بعد 2026-07-23 تُرسَم ضماناتُ الألوان على **وجهٍ عاجيّ** ⇒ الأسودُ أسودُ
    // الورق حقًّا (كان يُفتَّح كي يُرى على اللبّاد الداكن).
    test('حبرُ البطاقة هو حبرُ الورق: أحمرُ الكير والكارو وأسودُ الباقي', () {
      expect(SuitPip.cardInk('coeur'), SuitPip.cardInkRed);
      expect(SuitPip.cardInk('carreau'), SuitPip.cardInkRed);
      expect(SuitPip.cardInk('pique'), SuitPip.cardInkBlack);
      expect(SuitPip.cardInk('trefle'), SuitPip.cardInkBlack);
      // أسودُ الورق أسودُ فعلًا لا رماديٌّ فاتح — لو فُتِّح لضاع الفرقُ عن الأحمر.
      expect(SuitPip.cardInkBlack.computeLuminance(), lessThan(0.05));
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

      // **قرصٌ فاتحٌ خلف الرمز وحدَه** (البديل «ب»): بقعةٌ دائريّةٌ تحت الحبر
      // تُبقي الأسودَ أسودَ ومقروءًا على اللبّاد، بلا وجهِ ورقةٍ كامل.
      final disc = tester.widget<Container>(
        find
            .ancestor(
              of: find.byType(SuitPip).first,
              matching: find.byType(Container),
            )
            .first,
      );
      final discBox = disc.decoration! as BoxDecoration;
      expect(discBox.shape, BoxShape.circle);
      expect(discBox.color!.computeLuminance(), greaterThan(0.8));

      // **لا لوحةَ تجمعهم** (طلبُ المالك 2026-07-23): كلُّ خيارٍ زرٌّ قائمٌ
      // بذاته ⇒ لا صندوقَ مزخرفٌ واحدٌ يضمّ رمزًا وزرًّا معًا.
      final pipRect = tester.getRect(find.byType(SuitPip).first);
      final passRect = tester.getRect(find.text('تمرير'));
      for (final e in find
          .descendant(of: find.byType(BidBar), matching: find.byType(Container))
          .evaluate()) {
        final box = (e.widget as Container).decoration;
        if (box == null) continue;
        final r = tester.getRect(find.byWidget(e.widget));
        expect(r.contains(pipRect.center) && r.contains(passRect.center),
            isFalse,
            reason: 'صندوقٌ واحدٌ يضمّ الرمزَ والزرّ');
      }

      // **صفّان** (طلبُ المالك 2026-07-23): كلُّ رمزِ لونٍ فوق كلِّ زرّ.
      final lowestPip = tester
          .widgetList<SuitPip>(find.byType(SuitPip))
          .toList()
          .asMap()
          .keys
          .map((i) => tester.getBottomLeft(find.byType(SuitPip).at(i)).dy)
          .reduce((a, b) => a > b ? a : b);
      for (final label in ['تمرير', 'صن', 'تو', 'أكوينس']) {
        expect(tester.getTopLeft(find.text(label)).dy,
            greaterThan(lowestPip), reason: label);
      }
    });

    // انكسر هذا مرّةً: `Container` بمحاذاةٍ داخل `Wrap` يملأ العرضَ كلَّه ⇒
    // أربعةُ أزرارٍ في أربعة أسطر. الحارسُ يقيس الصفَّ على أضيق هاتف.
    testWidgets('تمرير · صن · تو · أكوينس في سطرٍ واحدٍ على عرض 320',
        (tester) async {
      await pump(
        tester,
        const SizedBox(
          width: 320,
          child: BidBar(
            view: BidBarView(
              options: [
                BidOption(
                    label: 'تمرير',
                    action: BidAction.pass(),
                    enabled: true,
                    isPass: true),
                BidOption(
                    label: 'صن',
                    action: BidAction.ofBid(Bid.sans()),
                    enabled: true),
                BidOption(
                    label: 'تو',
                    action: BidAction.ofBid(Bid.tout()),
                    enabled: true),
                BidOption(
                    label: 'أكوينس',
                    action: BidAction.akwins(),
                    enabled: true,
                    isAkwins: true),
              ],
              currentBid: null,
            ),
            onBid: _ignore,
          ),
        ),
      );
      // نقيس **الأقراصَ** لا نصوصَها: النصُّ يضمر عند الضيق فيتزحزح رأسُه،
      // أمّا القرصُ فموضعُه هو الصفّ.
      final pills = find.byType(BidPill);
      expect(pills, findsNWidgets(4));
      final rects = [
        for (var i = 0; i < 4; i++) tester.getRect(pills.at(i)),
      ];
      for (final r in rects) {
        expect(r.top, closeTo(rects.first.top, 0.5), reason: 'سطرٌ واحدٌ لا أكثر');
      }
      // ولا يفيض الصفُّ عن الشاشة.
      expect(rects.last.right - rects.first.left, lessThanOrEqualTo(320));
    });

    testWidgets('لمسُ رمزٍ يُطلق ضمانةَ لونِه', (tester) async {
      BidAction? fired;
      await pump(
        tester,
        BidBar(
          view: const BidBarView(
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
