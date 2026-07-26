import 'package:app/game/view_model.dart';
import 'package:app/l10n/app_localizations_ar.dart';
import 'package:app/l10n/labels.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/bid_bar.dart';
import 'package:app/ui/bid_visuals.dart';
import 'package:app/ui/gifts/gift_flight.dart';
import 'package:app/ui/player_hand_fan.dart';
import 'package:app/ui/player_seat_round.dart';
import 'package:app/ui/table/table_geometry.dart';
import 'package:app/ui/table/table_surface.dart';
import 'package:app/ui/table_screen.dart';
import 'package:app/ui/turn_clock.dart';
import 'package:belote_engine/belote_engine.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';

/// يدٌ كاملةٌ وضمانةٌ مستقرّة — أكثرُ لحظةٍ ازدحامًا على الطاولة.
const _hand = [
  Card('pique', 'A'),
  Card('pique', '10'),
  Card('coeur', 'K'),
  Card('coeur', 'Q'),
  Card('carreau', 'J'),
  Card('carreau', '9'),
  Card('trefle', 'A'),
  Card('trefle', '8'),
];

const _view = TableView(
  myHand: _hand,
  handCounts: [8, 8, 8, 8],
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

/// نفسُها ولي حقُّ الاعتراض بفوجة — لحظةُ ظهورِ الزرَّين معًا.
const _foujaView = TableView(
  myHand: _hand,
  handCounts: [8, 8, 8, 8],
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
  canAccuseFouja: true,
);

Widget _wrap(Widget child) =>
    ThemeScope(manager: ThemeManager(), child: MaterialApp(home: child));

/// مقعدي أنا: الوحيدُ بـ`mine` — لا يُميَّز بترتيبٍ في الشجرة قد يتبدّل.
Finder get _mySeat =>
    find.byWidgetPredicate((w) => w is PlayerSeatRound && w.mine);

/// **شاشةُ هاتفٍ حقيقيّة** لا نافذةَ الاختبار الافتراضيّة (800×600 **عرضيّة**):
/// اللعبةُ تُلعَب طوليًّا، وقياسُ تخطيطها على نافذةٍ عرضيّة يقيس شاشةً لا وجودَ لها.
Future<void> _pumpPhone(WidgetTester t, {Size size = const Size(393, 852)}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  await t.pumpWidget(_wrap(const TableScreen(view: _view)));
  await t.pumpAndSettle();
}

/// حراسُ التخطيط بعد دخول الطاولة المرسومة.
void main() {
  group('مراسي المقاعد', () {
    test('الخصمان أنزلُ من الشريك وأعلى منّي — ولا يلتصقان بحافّة الشاشة', () {
      final me = kSeatAnchors[0].y;
      final right = kSeatAnchors[1].y;
      final partner = kSeatAnchors[2].y;
      final left = kSeatAnchors[3].y;

      // الخصمان متساويان تمامًا (لو انحرف أحدهما بدت الطاولةُ مائلة).
      expect(right, left);
      // بينهما وبين الشريك فرجةٌ، وبينهما وبيني فرجةٌ أوسع (يدي تحتاج المكان).
      expect(right, greaterThan(partner));
      expect(right, lessThan(me));
      // **أنزلُ ممّا كانا** (-0.4): كانا مرفوعَين بسبب كِبَر بطاقتي ومروحتي.
      expect(right, greaterThan(-0.4));
    });

    test('كلُّ المراسي داخل الشاشة', () {
      for (final a in kSeatAnchors) {
        expect(a.x.abs(), lessThanOrEqualTo(1.0));
        expect(a.y.abs(), lessThanOrEqualTo(1.0));
      }
    });
  });

  /// **ملاحظاتُ المالك 2026-07-21 — تُقاس بالأرقام لا بالنظر إلى لقطة:**
  /// بطاقتي تلامس دائرةَ اللعب · لوحُ النتيجة شريطٌ فوق الطاولة · الضمانةُ مكرّرةٌ
  /// في وسط الدائرة · الورقةُ الطرفيّةُ لا تستجيب للضغط.
  group('الطاولة كما تُرى', () {
    // من أضيق هاتفٍ يُباع إلى أعرضِه: التخطيطُ نِسَبٌ، والنِّسَبُ تُختبَر بالأطراف.
    for (final size in const [
      Size(320, 568),
      Size(393, 852),
      Size(430, 932),
    ]) {
      testWidgets(
          '**فرجةٌ بين بطاقتي ودائرة اللعب** — لا تلامسَ ولا تراكب ($size)',
          (t) async {
        await _pumpPhone(t, size: size);

        final circle = t.getRect(find.byType(TurnClock));
        final me = t.getRect(_mySeat);
        expect(me.top, greaterThan(circle.bottom),
            reason: 'بطاقتي تعلو قاعَ دائرة اللعب');
        expect(me.top - circle.bottom, greaterThan(8),
            reason: 'الفرجةُ أضيقُ من أن تُرى');
      });
    }

    testWidgets('بطاقتي لا تركب أوراقَ يدي المستقرّة', (t) async {
      await _pumpPhone(t);

      final me = t.getRect(_mySeat);
      final fan = t.getRect(find.byType(PlayerHandFan));
      // أعلى صندوقِ المروحة مساحةُ **رفعِ** الورقة المحدَّدة وتكبيرِها وقوسِها،
      // لا أوراقًا مستقرّة ⇒ الحدُّ قاعُ تلك المساحة لا قمّةُ الصندوق.
      expect(me.bottom,
          lessThanOrEqualTo(fan.top + HandFanMetrics.selectedLift + 1e-6));
    });

    testWidgets('لوحُ المباراة **داخل الطاولة فوق الشريك** لا شريطًا يعمّ العرض',
        (t) async {
      await _pumpPhone(t);

      final screen = t.getSize(find.byType(TableScreen));
      final us = t.getRect(find.text(AppLocalizationsAr().teamUs));
      final them = t.getRect(find.text(AppLocalizationsAr().teamThem));
      final partner = t.getRect(find.byWidgetPredicate(
          (w) => w is PlayerSeatRound && w.name == Labels.seat(AppLocalizationsAr(), 2)));

      expect(them.bottom, lessThanOrEqualTo(partner.top),
          reason: 'اللوحُ يزاحم بطاقةَ الشريك');
      // ضيّقٌ لا يمتدّ: ما بين طرفَي النتيجتين دون ثلثَي عرض الشاشة.
      expect(them.right - us.left, lessThan(screen.width * 0.66));
    });

    testWidgets('**الضمانةُ مرّةً واحدة**: على اللوح لا في دائرة اللعب',
        (t) async {
      await _pumpPhone(t);

      expect(find.text(Labels.bid(AppLocalizationsAr(), _view.bid)), findsOneWidget);
    });

    testWidgets('اليدُ تُبقي حِمى الحافّة (وإلّا ابتلع النظامُ لمسةَ الطرفيّة)',
        (t) async {
      await _pumpPhone(t);

      final screen = t.getSize(find.byType(TableScreen));
      final fan = t.getRect(find.byType(PlayerHandFan));
      expect(fan.left, greaterThanOrEqualTo(HandFanMetrics.edgeGuard - 1e-6));
      expect(fan.right,
          lessThanOrEqualTo(screen.width - HandFanMetrics.edgeGuard + 1e-6));
    });
  });

  /// طلبُ المالك 2026-07-23: زرُّ الإيموجي كان ملقًى على حافّة الطاولة.
  group('زرُّ التفاعلات داخل الطاولة', () {
    /// حافّةُ اللبّاد على الشاشة — نفسُ الحساب الذي يرسم به السطحُ نفسُه.
    double feltLeft(Size screen) =>
        TableGeometry.of(screen, TableSurface.hall).felt.left;

    for (final size in const [
      Size(320, 568),
      Size(393, 852),
      Size(430, 932),
    ]) {
      testWidgets('يجلس على اللبّاد لا على الإطار الخشبيّ ($size)', (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1.0;
        addTearDown(t.view.reset);
        await t.pumpWidget(_wrap(TableScreen(view: _view, onReact: (_) {})));
        await t.pumpAndSettle();

        final btn = t.getRect(find.byIcon(Icons.add_reaction_outlined));
        final screen = t.getSize(find.byType(TableScreen));
        // **داخلَ اللبّاد**: لو ركب الخشبَ لكان يساره دون هذا الحدّ.
        expect(btn.left, greaterThanOrEqualTo(feltLeft(screen)),
            reason: 'الزرُّ على الإطار الخشبيّ لا على الطاولة');
        // ولا يهرب إلى الوسط: يبقى في ثلث الشاشة الأيسر.
        expect(btn.right, lessThan(screen.width / 3));
        // وفوق المروحة بفرجةٍ تُرى.
        expect(btn.bottom,
            lessThan(t.getRect(find.byType(PlayerHandFan)).top + 1e-6));
      });
    }

    testWidgets('زرُّ الفوجة يقابله على اللبّاد بلا انحراف', (t) async {
      t.view.physicalSize = const Size(393, 852);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.reset);
      await t.pumpWidget(_wrap(TableScreen(
        view: _foujaView,
        onReact: (_) {},
        onStartFoujaClaim: () {},
      )));
      await t.pumpAndSettle();

      // **حدودُ الزرّ لا حدودُ محتواه**: حشوةُ الأيقونة (9) غيرُ حشوةِ النصّ (16)،
      // فمقارنةُ الرمزِ بالكلمة تقيس الحشوتين لا الموضعَين.
      Rect box(Finder inner) => t.getRect(
          find.ancestor(of: inner, matching: find.byType(InkWell)).first);
      final react = box(find.byIcon(Icons.add_reaction_outlined));
      final fouja = box(find.text(AppLocalizationsAr().fouja));
      final screen = t.getSize(find.byType(TableScreen));
      // مرآةٌ حقيقيّة: بُعدُ ذاك عن اليمين = بُعدُ هذا عن اليسار، وقاعاهما واحد.
      expect(screen.width - fouja.right, closeTo(react.left, 1e-6));
      expect(fouja.bottom, closeTo(react.bottom, 12),
          reason: 'أحدُهما أعلى من الآخر');
    });

    testWidgets('يغيب حين يعلو شريطُ الضمانة مكانَه', (t) async {
      t.view.physicalSize = const Size(393, 852);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.reset);
      await t.pumpWidget(_wrap(TableScreen(
        view: _view,
        onReact: (_) {},
        bidBar: const BidBarView(
          options: [
            BidOption(
                label: 'تمرير',
                action: BidAction.pass(),
                enabled: true,
                isPass: true),
            BidOption(
                label: 'صن', action: BidAction.ofBid(Bid.sans()), enabled: true),
          ],
          currentBid: null,
        ),
        onBid: (_) {},
      )));
      await t.pumpAndSettle();

      // **لمسةُ الضمانة لا تُشترى بإيموجي**: الشريطُ يملأ ما فوق المروحة،
      // فلا موضعَ للزرّ هناك — يغيب لحظةَ ضمانتي كما يغيب لحظةَ الفوجة.
      expect(find.byType(BidBar), findsOneWidget);
      expect(find.byIcon(Icons.add_reaction_outlined), findsNothing,
          reason: 'الزرُّ يركب شريطَ الضمانة');
    });
  });

  group('ذهبُ اللوحات من الطاولة نفسِها', () {
    test('لكلّ طاولةٍ ذهبُها', () {
      expect(TableSurface.inlayFor(vip: false), TableSurface.hall.inlayColor);
      expect(TableSurface.inlayFor(vip: true), TableSurface.vip.inlayColor);
      // ذهبُ VIP أفتحُ — وإلّا لَما تميّزت الطاولةُ المدفوعة.
      expect(
        HSLColor.fromColor(TableSurface.vip.inlayColor).lightness,
        greaterThan(HSLColor.fromColor(TableSurface.hall.inlayColor).lightness),
      );
    });
  });

  group('فقاعةُ الضمانة أمام صاحبها', () {
    /// طلبُ المالك 2026-07-23: **بشكل الشريط نفسِه** — ضمانةُ اللون رمزٌ على
    /// قرصٍ فاتح لا كلمة «كير»، وما لا لونَ له يبقى نصًّا.
    testWidgets('ضمانةُ اللون رمزٌ لا كلمة، وغيرُها نصّ', (t) async {
      t.view.physicalSize = const Size(393, 852);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.reset);
      await t.pumpWidget(_wrap(const TableScreen(
        view: TableView(
          myHand: _hand,
          handCounts: [8, 8, 8, 8],
          usScore: 0,
          themScore: 0,
          bid: null,
          bidderSeat: null,
          akwins: false,
          dealerSeat: 3,
          seatBids: [
            SeatBid('كير', suit: 'coeur'),
            SeatBid('تمرير', isPass: true),
            SeatBid('صن'),
            SeatBid('أكوينس 32', isAkwins: true),
          ],
          turn: 0,
          trick: [],
          legalCards: {},
          phase: GamePhase.bidding,
        ),
      )));
      await t.pumpAndSettle();

      // الكيرُ رمزٌ بحبره الحقيقيّ على قرصٍ فاتح — ولا أثرَ لاسم اللون.
      final chip = t.widget<SuitBidChip>(find.byType(SuitBidChip));
      expect(chip.suit, 'coeur');
      expect(find.text('كير'), findsNothing);
      // وما لا رمزَ له يبقى نصًّا في قرصه.
      for (final l in ['تمرير', 'صن', 'أكوينس 32']) {
        expect(find.text(l), findsOneWidget, reason: l);
      }
    });
  });
}
