import 'package:app/app_settings.dart';
import 'package:app/game/view_model.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/l10n/app_localizations_ar.dart';
import 'package:app/l10n/app_localizations_fr.dart';
import 'package:app/l10n/labels.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/bid_bar.dart';
import 'package:app/ui/result_panel.dart';
import 'package:app/ui/rules_screen.dart';
import 'package:app/ui/table_screen.dart';
import 'package:belote_engine/belote_engine.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';

/// **العربيّةُ افتراضًا والفرنسيّةُ اختيارًا** (طلب المالك 2026-07-23).
///
/// يحرس ثلاثةَ أشياء لا يراها المطوّرُ بعينه:
/// 1. **قاموسُ المالك حرفيًّا** — `صن=SA` و`تو=TA` و`الأكوينس=Coinche`… لا
///    اجتهادَ فيها؛ لاعبُ بيلوت الفرنسيُّ يعرف هذه الكلماتِ وحدَها.
/// 2. **الاتّجاه يتبع اللغة** — لا `Directionality` مثبَّتًا في الجذر.
/// 3. **الفرنسيّةُ أطول** — أزرارٌ تنكسر عليها على أضيق هاتف.
const _hand = [
  Card('pique', 'A'),
  Card('coeur', 'K'),
  Card('carreau', 'J'),
  Card('trefle', '8'),
];

const _view = TableView(
  myHand: _hand,
  handCounts: [4, 4, 4, 4],
  usScore: 12,
  themScore: 30,
  bid: Bid.ofSuit('coeur'),
  bidderSeat: 0,
  akwins: false,
  dealerSeat: 3,
  seatBids: [null, null, null, null],
  turn: 0,
  trick: [],
  legalCards: {},
  phase: GamePhase.playing,
);

Widget _app(Locale locale, Widget home) => ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppSettings.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: home,
      ),
    );

void main() {
  group('قاموسُ المالك — لا اجتهادَ في مصطلحات اللعبة', () {
    final fr = AppLocalizationsFr();
    final ar = AppLocalizationsAr();

    test('المصطلحاتُ الحاسمة كما أملاها المالك حرفًا بحرف', () {
      expect(fr.bidSans, 'SA'); // صن
      expect(fr.bidTout, 'TA'); // تو
      expect(fr.bidAkwins, 'Coinche'); // الأكوينس
      expect(fr.phaseBidding, 'Contrat'); // الضمانة
      expect(fr.bidYours, 'Votre contrat'); // ضمانتك
      expect(fr.bidPass, 'Passe'); // تمرير
      expect(fr.teamUs, 'Nous'); // نحن
      expect(fr.teamThem, 'Eux'); // هم
      // والعربيّةُ لم تتغيّر بحرف.
      expect(ar.bidSans, 'صن');
      expect(ar.bidAkwins, 'أكوينس');
      expect(ar.bidYours, 'ضمانتك');
    });

    test('«الحكم» أتوت و«الأبلي» بلي في نصوص القواعد', () {
      expect(fr.ruleBidBody, contains('atout'));
      expect(fr.ruleAkwinsTitle, contains('Coinche'));
      expect(fr.momentStrongestCardDetail(5), contains('pli'));
      expect(fr.tricksCount(3), contains('plis'));
    });

    test('تسمياتُ المحرّك تُترجَم من قيمته لا من نصّ', () {
      expect(Labels.bid(fr, const Bid.sans()), 'SA');
      expect(Labels.bid(fr, const Bid.tout()), 'TA');
      expect(Labels.bid(fr, const Bid.ofSuit('coeur')), 'Cœur');
      expect(Labels.bid(fr, const Bid.ofSuit('coeur'), akwins: true),
          contains('Coinche'));
      expect(Labels.bid(ar, const Bid.ofSuit('coeur')), 'كير');
      expect(Labels.reason(fr, 'chute'), 'Contrat chuté');
      expect(Labels.seat(fr, 2), 'Partenaire');
    });
  });

  group('الاتّجاه يتبع اللغة', () {
    testWidgets('العربيّةُ RTL والفرنسيّةُ LTR — بلا اتّجاهٍ مثبَّت',
        (tester) async {
      for (final (locale, expected) in [
        (const Locale('ar'), TextDirection.rtl),
        (const Locale('fr'), TextDirection.ltr),
      ]) {
        await tester.pumpWidget(_app(
          locale,
          Builder(
            builder: (context) => Text(
              AppLocalizations.of(context).bidYours,
              key: const Key('probe'),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        expect(Directionality.of(tester.element(find.byKey(const Key('probe')))),
            expected,
            reason: locale.languageCode);
      }
    });

    testWidgets('شريطُ الضمانة يُقرأ بالفرنسيّة', (tester) async {
      await tester.pumpWidget(_app(
        const Locale('fr'),
        Scaffold(
          body: Center(
            child: BidBar(
              view: const BidBarView(
                options: [
                  BidOption(
                      label: 'Passe',
                      action: BidAction.pass(),
                      enabled: true,
                      isPass: true),
                  BidOption(
                      label: 'SA',
                      action: BidAction.ofBid(Bid.sans()),
                      enabled: true),
                ],
                currentBid: null,
              ),
              onBid: _ignore,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Votre contrat'), findsOneWidget);
      expect(find.text('ضمانتك'), findsNothing);
    });
  });

  group('الفرنسيّةُ أطول — لا كسرَ على أضيق هاتف', () {
    /// أيُّ فيضٍ في التخطيط يرمي استثناءً في الاختبار ⇒ الشاشةُ التي تُبنى
    /// بلا استثناءٍ هي شاشةٌ لا يقطع فيها نصٌّ أو يخرج زرٌّ عن حدّه.
    Future<void> pumpAt(WidgetTester t, Widget home, Locale locale) async {
      t.view.physicalSize = const Size(320, 640);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.reset);
      await t.pumpWidget(_app(locale, home));
      await t.pumpAndSettle();
      // **الفيضُ وحدَه يُسقِط الاختبار**: غيابُ قناةٍ أصليّةٍ في بيئة الاختبار
      // (تفضيلات · معلوماتُ الحزمة) ليس عطبَ تخطيط.
      final e = t.takeException();
      expect(
        e == null || !'$e'.contains('overflowed'),
        isTrue,
        reason: 'فيضٌ في التخطيط (${locale.languageCode}): $e',
      );
    }

    for (final locale in [const Locale('ar'), const Locale('fr')]) {
      testWidgets('الطاولة على عرض 320 — ${locale.languageCode}', (t) async {
        await pumpAt(t, const TableScreen(view: _view), locale);
      });

      testWidgets('شاشةُ القواعد — ${locale.languageCode}', (t) async {
        await pumpAt(t, const RulesScreen(), locale);
      });

      testWidgets('لوحةُ النتيجة — ${locale.languageCode}', (t) async {
        await pumpAt(
          t,
          const Scaffold(
            body: ResultPanel(
              result: RoundResult(
                usPoints: 16,
                themPoints: 0,
                roundValue: 16,
                reason: 'chute',
                usTotal: 44,
                themTotal: 30,
                matchOutcome: null,
              ),
            ),
          ),
          locale,
        );
      });
    }
  });
}

void _ignore(BidAction _) {}
