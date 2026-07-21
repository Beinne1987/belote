import 'package:app/game/view_model.dart';
import 'package:app/net/api_client.dart';
import 'package:app/platform/app_platform.dart';
import 'package:app/ui/auth/auth_landing_screen.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/app_frame.dart';
import 'package:app/ui/player_hand_fan.dart';
import 'package:app/ui/player_seat_round.dart';
import 'package:app/ui/table_metrics.dart';
import 'package:app/ui/table_screen.dart';
import 'package:app/ui/turn_clock.dart';
import 'package:belote_engine/belote_engine.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';

/// **نسخةُ سطح المكتب (ويندوز وماك) على قاعدة الكود نفسِها.**
///
/// لا مشروعَ ثانٍ ولا شاشةَ ثانية: الفرقُ كلُّه أنّ النافذةَ قد تبلغ 3840 بكسلًا
/// عرضًا، فيُقتطع **مسرحٌ متمركز** ([AppStage]) تُرسَم فيه الشاشاتُ كما هي.
///
/// الشرطُ الحاكمُ في كلّ ما دون: **الهاتفُ لا يتغيّر بكسلًا واحدًا**.
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

/// أحجامُ نوافذَ حقيقيّة: هاتفان · لابتوب · مكتبيّ · 4K · ونافذةٌ عريضةٌ قصيرة.
const _phones = [Size(320, 568), Size(393, 852)];
const _desktops = [
  Size(1000, 820), // نافذةُ البدء
  Size(1280, 800), // لابتوب
  Size(1920, 1080), // مكتبيّ
  Size(2560, 1440),
  Size(3840, 2160), // 4K
  Size(1600, 600), // عريضةٌ قصيرة — أقسى حالة
];

Widget _wrap(Widget child) => ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(
        scrollBehavior: const AppScrollBehavior(),
        builder: (context, c) => Directionality(
          textDirection: TextDirection.rtl,
          child: AppFrame(child: c!),
        ),
        home: child,
      ),
    );

Future<void> _pump(WidgetTester t, Size size) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  await t.pumpWidget(_wrap(const TableScreen(view: _view)));
  await t.pumpAndSettle();
}

void main() {
  group('مسرحُ اللعب (حسابٌ خالص)', () {
    test('على الهاتف: المسرحُ هو الشاشةُ نفسُها — بلا إطارٍ ولا اقتطاع', () {
      for (final p in _phones) {
        expect(AppStage.of(p), p, reason: '$p');
        expect(AppStage.framed(p), isFalse, reason: '$p');
      }
    });

    test('على الحاسوب: مسرحٌ متمركزٌ نسبتُه ≤ 0.80 ولا يفيض عن النافذة', () {
      for (final d in _desktops) {
        final s = AppStage.of(d);
        expect(s.width, lessThanOrEqualTo(d.width + 1e-9), reason: '$d');
        expect(s.height, lessThanOrEqualTo(d.height + 1e-9), reason: '$d');
        expect(s.width / s.height, lessThanOrEqualTo(AppStage.maxAspect + 1e-9),
            reason: '$d');
        expect(s.height, lessThanOrEqualTo(AppStage.maxHeight + 1e-9));
        expect(AppStage.framed(d), isTrue, reason: '$d');
      }
    });

    test('كلّما كبرت النافذةُ كبر المسرحُ — ولا ينكمش أبدًا', () {
      var prev = 0.0;
      for (var h = 560.0; h <= 2160; h += 40) {
        final area = AppStage.of(Size(h * 2, h));
        expect(area.height, greaterThanOrEqualTo(prev - 1e-9));
        prev = area.height;
      }
    });
  });

  group('مقاييسُ الطاولة تكبر بالمسرح', () {
    test('الهاتفُ كما كان بالضبط: العرضُ وحدَه يحكم', () {
      // 393×852: `w/4.9` و`w/11` و54 — نفسُ أرقام 4081 حرفيًّا.
      expect(TableMetrics.myCardWidth(393, 852), closeTo(393 / 4.9, 1e-9));
      expect(TableMetrics.backCardWidth(393, 852), closeTo(393 / 11, 1e-9));
      expect(TableMetrics.seatSize(393, 852), 54.0);
    });

    test('مسرحُ الحاسوب: الأوراقُ والمقاعدُ أكبرُ لا أصغر', () {
      final stage = AppStage.of(const Size(1920, 1080));
      final w = stage.width, h = stage.height;
      expect(TableMetrics.myCardWidth(w, h),
          greaterThan(TableMetrics.myCardWidth(393, 852)));
      expect(TableMetrics.backCardWidth(w, h),
          greaterThan(TableMetrics.backCardWidth(393, 852)));
      expect(TableMetrics.seatSize(w, h), greaterThan(54.0));
      // وبسقفٍ: لا تصير الورقةُ لوحًا على شاشة 4K.
      final big = AppStage.of(const Size(3840, 2160));
      expect(TableMetrics.myCardWidth(big.width, big.height),
          lessThanOrEqualTo(150.0));
      expect(TableMetrics.seatSize(big.width, big.height),
          lessThanOrEqualTo(78.0));
    });
  });

  group('الطاولة داخل نافذة حاسوب', () {
    for (final size in _desktops) {
      testWidgets('$size: المسرحُ متمركزٌ وكلُّ ما فيه داخلَه', (t) async {
        await _pump(t, size);

        final stage = AppStage.of(size);
        final table = t.getRect(find.byType(TableScreen));
        expect(table.width, closeTo(stage.width, 0.5));
        expect(table.height, closeTo(stage.height, 0.5));
        // متمركزٌ أفقيًّا وعموديًّا (فرقُ الهامشين ≈ صفر).
        expect(table.left, closeTo(size.width - table.right, 0.5));
        expect(table.top, closeTo(size.height - table.bottom, 0.5));

        // اليدُ والمقاعدُ داخل المسرح — لا فيضَ ولا قصّ.
        final fan = t.getRect(find.byType(PlayerHandFan));
        expect(fan.left, greaterThanOrEqualTo(table.left - 1e-6));
        expect(fan.right, lessThanOrEqualTo(table.right + 1e-6));
        expect(fan.bottom, lessThanOrEqualTo(table.bottom + 1e-6));
        for (final seat
            in t.widgetList<PlayerSeatRound>(find.byType(PlayerSeatRound))) {
          final r = t.getRect(find.byWidget(seat));
          expect(table.contains(r.topLeft), isTrue,
              reason: 'مقعدٌ خارج المسرح');
          expect(table.contains(r.bottomRight - const Offset(1, 1)), isTrue);
        }
      });
    }

    testWidgets('**الفرجةُ بين بطاقتي ودائرة اللعب تصمد على الحاسوب أيضًا**',
        (t) async {
      for (final size in _desktops) {
        await _pump(t, size);
        final circle = t.getRect(find.byType(TurnClock));
        final me = t.getRect(
            find.byWidgetPredicate((w) => w is PlayerSeatRound && w.mine));
        expect(me.top, greaterThan(circle.bottom), reason: '$size');
      }
    });

    /// **تغييرُ حجم النافذة أثناء اللعب** — يجرّه اللاعبُ بالفأرة، ولا يجوز أن
    /// يترك الواجهةَ مشوّهةً أو أن يُسقط إطارًا بفيضٍ (`RenderFlex overflow`).
    testWidgets('سحبُ حافّة النافذة: من صغيرةٍ إلى 4K وبالعكس بلا تشوّه',
        (t) async {
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.reset);
      const path = [
        Size(640, 560), // أصغرُ نافذةٍ يسمح بها المشغّل الأصليّ
        Size(900, 700),
        Size(1920, 1080),
        Size(3840, 2160),
        Size(1280, 800),
        Size(640, 560),
      ];
      await t.pumpWidget(_wrap(const TableScreen(view: _view)));
      for (final s in path) {
        t.view.physicalSize = s;
        await t.pumpAndSettle();
        expect(tester_hasNoException(), isTrue, reason: 'عند $s');
        final stage = AppStage.of(s);
        final table = t.getRect(find.byType(TableScreen));
        expect(table.width, closeTo(stage.width, 0.5), reason: 'عند $s');
        final fan = t.getRect(find.byType(PlayerHandFan));
        expect(fan.width, lessThanOrEqualTo(stage.width + 1e-6),
            reason: 'عند $s');
      }
    });
  });

  group('الفأرة', () {
    test('السحبُ بالفأرة يمرّر القوائم (افتراضُ Flutter يمنعه)', () {
      const b = AppScrollBehavior();
      expect(b.dragDevices, contains(PointerDeviceKind.mouse));
      expect(b.dragDevices, contains(PointerDeviceKind.touch),
          reason: 'اللمسُ يبقى كما هو');
    });

    testWidgets('مؤشّرُ اليد على أوراق يدي', (t) async {
      await _pump(t, const Size(1280, 800));
      final cursors = t
          .widgetList<MouseRegion>(find.descendant(
            of: find.byType(PlayerHandFan),
            matching: find.byType(MouseRegion),
          ))
          .map((m) => m.cursor);
      expect(cursors, contains(SystemMouseCursors.click));
    });
  });

  group('شاشاتٌ غيرُ الطاولة داخل المسرح', () {
    testWidgets(
        'شاشةُ الدخول: تُرسَم داخل المسرح، وتقول حدَّ المنصّة قبل المحاولة',
        (t) async {
      t.view.physicalSize = const Size(1920, 1080);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.reset);
      await t.pumpWidget(_wrap(AuthLandingScreen(
        api: ApiClient(),
        onAuthenticated: (_) async {},
      )));
      await t.pumpAndSettle();

      final stage = AppStage.of(const Size(1920, 1080));
      final screen = t.getRect(find.byType(AuthLandingScreen));
      expect(screen.width, closeTo(stage.width, 0.5));
      // **الدخولُ يعمل على الحاسوب، وإنشاءُ الحساب لا** (رمزُ SMS من Firebase
      // لا تنفيذَ له هناك) ⇒ يُقال قبل أن يملأ اللاعبُ بياناتِه لا بعدها.
      expect(find.text('تسجيل الدخول'), findsWidgets);
      expect(find.textContaining('من تطبيق الهاتف'), findsOneWidget);
    });
  });

  group('قدراتُ المنصّة', () {
    test('لا دفعَ ولا مثبِّتَ APK ولا صوتَ على سطح المكتب', () {
      // على مضيف الاختبار (لينكس) ليست منصّةَ هاتفٍ ولا سطحَ مكتبٍ مدعومًا —
      // المهمُّ أنّ القدراتِ المشروطةَ بالهاتف **لا تُفتَح** خارجه.
      expect(AppPlatform.push, AppPlatform.isMobile);
      expect(AppPlatform.voice, AppPlatform.isMobile);
      expect(AppPlatform.isDesktop && AppPlatform.push, isFalse);
      expect(AppPlatform.isDesktop && AppPlatform.inAppUpdate, isFalse);
    });
  });
}

/// هل سُجّل استثناءُ إطارٍ (فيضُ تخطيطٍ مثلًا) منذ آخر فحص؟
bool tester_hasNoException() {
  final e = TestWidgetsFlutterBinding.instance.takeException();
  return e == null;
}
