import 'dart:math' as math;

import 'package:app/ui/card_face.dart';
import 'package:app/ui/player_hand_fan.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/l10n/app_localizations_ar.dart';
import 'package:app/l10n/labels.dart';
import 'package:belote_engine/belote_engine.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

/// يدٌ من ثمانِ أوراقٍ كاليد الحقيقيّة أوّلَ الجولة.
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

Widget _wrap(Widget child) => ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(home: Scaffold(body: Center(child: child))),
    );

Finder _card(Card c) =>
    find.byWidgetPredicate((w) => w is CardFace && w.card == c);

void main() {
  // ── الهندسة: حسابٌ خالصٌ يُفحَص بلا رسم ──

  group('هندسةُ المروحة', () {
    test('**قوسٌ منخفض**: الوسطى أعلى الكلّ، والأطرافُ أخفضُها، والنزولُ متدرّج', () {
      final m = HandFanMetrics.fit(
          count: 8, maxWidth: 400, preferredCardWidth: 70);
      final bottoms = [for (var i = 0; i < 8; i++) m.bottom(i)];

      // الوسطان (3 و4) أعلى من الطرفين.
      expect(bottoms[3], greaterThan(bottoms[0]));
      expect(bottoms[4], greaterThan(bottoms[7]));
      // تدرّجٌ رتيبٌ صعودًا حتى المنتصف ثمّ هبوطًا — لا سنَّ منشارٍ ولا قفزة.
      for (var i = 1; i <= 3; i++) {
        expect(bottoms[i], greaterThan(bottoms[i - 1]), reason: 'صعودٌ حتى المنتصف');
      }
      for (var i = 5; i < 8; i++) {
        expect(bottoms[i], lessThan(bottoms[i - 1]), reason: 'هبوطٌ بعد المنتصف');
      }
      // **منخفض** لا نصفَ دائرة: فرقُ الطرف عن الوسط دون ثُلث ارتفاع الورقة.
      expect(bottoms[3] - bottoms[0], lessThan(m.cardHeight / 3));
    });

    test('التداخلُ داخل مدى المالك 35–60% مهما ضاقت الشاشة', () {
      for (final w in [320.0, 360.0, 400.0, 430.0, 900.0]) {
        final m =
            HandFanMetrics.fit(count: 8, maxWidth: w, preferredCardWidth: 94);
        expect(m.overlap, greaterThanOrEqualTo(HandFanMetrics.minOverlap - 1e-9),
            reason: 'شاشة $w');
        expect(m.overlap, lessThanOrEqualTo(HandFanMetrics.maxOverlap + 1e-9),
            reason: 'شاشة $w');
      }
    });

    /// **العطبُ الذي رفع التداخلَ إلى 54% سابقًا** (شكوى المالك: «طرفُ يدي
    /// يختفي»): مروحةٌ أعرضُ من الشاشة تُقصّ، وما خرج عن الصندوق يُرسَم ولا
    /// يُلمَس. الحلُّ هنا تصغيرُ الورقة عند الضيق — لا قصُّ الطرف.
    test('**لا تُقصّ أبدًا**: العرضُ ≤ المتاح، وتُصغَّر الورقةُ عند الضيق وحدَه', () {
      for (final w in [300.0, 320.0, 360.0, 400.0, 430.0]) {
        final m =
            HandFanMetrics.fit(count: 8, maxWidth: w, preferredCardWidth: 94);
        expect(m.width, lessThanOrEqualTo(w + 1e-9), reason: 'شاشة $w');
        expect(m.cardWidth, lessThanOrEqualTo(94));
      }
      // شاشةٌ واسعة ⇒ الورقةُ بحجمها المفضَّل كاملًا، بلا تصغيرٍ بلا سبب.
      final wide =
          HandFanMetrics.fit(count: 8, maxWidth: 900, preferredCardWidth: 94);
      expect(wide.cardWidth, 94);
    });

    /// **الورقةُ الطرفيّةُ كانت لا تُلمَس على الجهاز** (شكوى المالك 2026-07-21):
    /// المروحةُ تصل حافّةَ الشاشة، وهناك يبتلع شريطُ إيماءات النظام اللمسة.
    /// الحمى يُقاس هنا كما تحسبه الشاشة: عرضُ الشاشة ناقصَ الحمى جانبَين.
    test('**حِمى الحافّة**: اليدُ تُبقي ≥26 بكسلًا من كلّ جانبٍ من الشاشة', () {
      for (final screen in [320.0, 360.0, 392.0, 430.0, 900.0]) {
        final m = HandFanMetrics.fit(
          count: 8,
          maxWidth: screen - 2 * HandFanMetrics.edgeGuard,
          preferredCardWidth: 94,
        );
        final margin = (screen - m.width) / 2;
        expect(margin, greaterThanOrEqualTo(HandFanMetrics.edgeGuard - 1e-9),
            reason: 'شاشة $screen');
      }
    });

    test('ميلٌ متدرّجٌ متناظر: الوسطُ قائمٌ والأطرافُ تميل بعكس بعضها', () {
      final m = HandFanMetrics.fit(
          count: 8, maxWidth: 400, preferredCardWidth: 70);
      final angles = [for (var i = 0; i < 8; i++) m.angle(i)];

      expect(angles.first, lessThan(0));
      expect(angles.last, greaterThan(0));
      expect(angles.first, closeTo(-angles.last, 1e-9), reason: 'تناظرٌ حول الوسط');
      for (var i = 1; i < 8; i++) {
        expect(angles[i], greaterThan(angles[i - 1]), reason: 'تدرّجٌ لا قفز');
      }
      // فتحةُ اليد كلِّها ≈ 40°: مروحةُ يدٍ ممسوكة لا قطاعُ دائرة.
      final spread = (angles.last - angles.first) * 180 / math.pi;
      expect(spread, greaterThan(25));
      expect(spread, lessThan(55));
    });

    test('الصندوقُ يسع الرفعَ والتكبير (ما فاض لا يُلمَس)', () {
      final m = HandFanMetrics.fit(
          count: 8, maxWidth: 400, preferredCardWidth: 70);
      expect(
        m.height,
        greaterThanOrEqualTo(m.cardHeight * HandFanMetrics.selectedScale +
            m.arcRise +
            HandFanMetrics.selectedLift),
      );
    });

    test('ورقةٌ واحدة: لا قوسَ ولا ميل — ولا قسمةَ على صفر', () {
      final m = HandFanMetrics.fit(
          count: 1, maxWidth: 400, preferredCardWidth: 70);
      expect(m.angle(0), 0);
      expect(m.bottom(0), 0);
      expect(m.width, greaterThan(0));
    });
  });

  // ── السلوك: ما أقرّه المالك سابقًا لا يسقط بإعادة التصميم ──

  group('سلوكُ اليد', () {
    testWidgets('في دوري: لمسُ ورقةٍ يلعبها فورًا', (t) async {
      final played = <Card>[];
      await t.pumpWidget(_wrap(PlayerHandFan(
        cards: _hand,
        cardWidth: 70,
        maxWidth: 400,
        interactive: true,
        onPlay: played.add,
      )));
      await t.pumpAndSettle(); // تنفتح المروحة

      await t.tap(find.byType(CardFace).last, warnIfMissed: false);
      await t.pump();
      expect(played, hasLength(1));
    });

    testWidgets('في غير دوري: اللمسُ يُجهّز ولا يلعب، ولمسةٌ ثانيةٌ تُلغي',
        (t) async {
      final played = <Card>[];
      await t.pumpWidget(_wrap(PlayerHandFan(
        cards: _hand,
        cardWidth: 70,
        maxWidth: 400,
        interactive: false,
        onPlay: played.add,
      )));
      await t.pumpAndSettle();

      // **مثبِّتُها الورقةُ لا الترتيب**: المرفوعةُ تُنقَل آخرَ المكدّس، فـ`last`
      // بعد الرفع قد تكون ورقةً أخرى — وكان الاختبارُ يقيس غيرَ ما يظنّ.
      final card = _card(_hand[5]);
      final resting = t.getCenter(card);
      await t.tap(card, warnIfMissed: false);
      await t.pumpAndSettle();

      expect(played, isEmpty, reason: 'لا تُلعَب ورقةٌ في غير دوري');
      expect(t.getCenter(card).dy, lessThan(resting.dy - 20), reason: 'ارتفعت ≈30');

      await t.tap(card, warnIfMissed: false);
      await t.pumpAndSettle();
      expect(t.getCenter(card).dy, closeTo(resting.dy, 1),
          reason: 'اللمسةُ الثانية تُعيدها');
    });

    testWidgets('سحبٌ للأعلى في دوري ⇒ لعب، وسحبٌ قصيرٌ ⇒ عودة', (t) async {
      final played = <Card>[];
      Widget fan(bool interactive) => _wrap(PlayerHandFan(
            cards: _hand,
            cardWidth: 70,
            maxWidth: 400,
            interactive: interactive,
            onPlay: played.add,
          ));

      await t.pumpWidget(fan(true));
      await t.pumpAndSettle();
      await t.drag(_card(_hand[5]), const Offset(0, -90), warnIfMissed: false);
      await t.pumpAndSettle();
      expect(played, hasLength(1), reason: 'سحبٌ فوق العتبة يلعب');

      // **فوق عتبة الانزلاق (18) ودون عتبة اللعب**: أقلُّ من ذلك تُقرأ *نقرةً*
      // فتلعب — وهو الصواب في دورك، لكنّه لا يفحص عودةَ الورقة.
      played.clear();
      await t.drag(_card(_hand[2]), const Offset(0, -30), warnIfMissed: false);
      await t.pumpAndSettle();
      expect(played, isEmpty, reason: 'سحبٌ قصيرٌ لا يلعب');
    });

    testWidgets('يدٌ فارغة ⇒ لا شيء (بلا عطب)', (t) async {
      await t.pumpWidget(_wrap(PlayerHandFan(
        cards: const [],
        cardWidth: 70,
        maxWidth: 400,
        interactive: true,
        onPlay: (_) {},
      )));
      expect(find.byType(CardFace), findsNothing);
    });

    /// المروحةُ تنفتح من كومةٍ ⇒ في أوّل إطارٍ الأوراقُ متراكبةٌ ثمّ تفترق.
    testWidgets('الدخول: كومةٌ تنفتح يدًا (لا ظهورَ دفعةً واحدة)', (t) async {
      await t.pumpWidget(_wrap(PlayerHandFan(
        cards: _hand,
        cardWidth: 70,
        maxWidth: 400,
        interactive: false,
        onPlay: (_) {},
      )));
      await t.pump(const Duration(milliseconds: 16));
      final startSpread =
          (t.getCenter(_card(_hand.last)).dx - t.getCenter(_card(_hand.first)).dx)
              .abs();

      await t.pumpAndSettle();
      final endSpread =
          (t.getCenter(_card(_hand.last)).dx - t.getCenter(_card(_hand.first)).dx)
              .abs();

      expect(startSpread, lessThan(endSpread / 3), reason: 'تبدأ مكوّمةً وتنفرج');
      expect(endSpread, greaterThan(0), reason: 'وتنتهي مروحةً لا كومة');
    });

    /// **الاختبارُ الذي كشف عطبَين في هذه الجلسة** (وكلاهما يُرى في الاختبار قبل
    /// الجهاز): شجرةٌ بُنيت خارج الـ`AnimatedBuilder` فبقيت اليدُ كومةً، وصيغةُ
    /// عرضٍ أسقطت عرضَ الورقة فخرجت الطرفيّةُ عن الصندوق. **الخارجُ يُرسَم ولا
    /// يُلمَس** — فالاحتواءُ شرطٌ لا زينة.
    testWidgets('**كلُّ ورقةٍ داخل صندوق المروحة** — وإلّا سقطت لمستُها', (t) async {
      await t.pumpWidget(_wrap(PlayerHandFan(
        cards: _hand,
        cardWidth: 94,
        maxWidth: 400,
        interactive: false,
        onPlay: (_) {},
      )));
      await t.pumpAndSettle();

      final box = t.getRect(find.byType(PlayerHandFan));
      expect(box.width, lessThanOrEqualTo(400 + 1e-6));
      for (final c in _hand) {
        final r = t.getRect(_card(c));
        expect(r.left, greaterThanOrEqualTo(box.left - 0.5), reason: '${c.code}');
        expect(r.right, lessThanOrEqualTo(box.right + 0.5), reason: '${c.code}');
      }
    });

    /// **خريطةُ لمسٍ لا نقرةٌ في المنتصف.**
    ///
    /// كان الاختبارُ ينقر **مركزَ الصندوق المحيط** بكلّ ورقة — وهو مركزٌ لا يراه
    /// اللاعبُ أصلًا في ورقةٍ مبنيّة: جارتُها تغطّيه. فكان يقيس صدفةً لا سلوكًا،
    /// ولم يكشف شكوى المالك «الورقتان اليسريان لا تستجيبان».
    ///
    /// البديلُ: امسح صندوقَ المروحة نقطةً نقطةً وسجّل **أيُّ ورقةٍ تربح كلَّ
    /// نقطة**. منه يُقاس ما يهمّ: ألّا تموت ورقةٌ، وأن يبقى لكلٍّ ما يسع إصبعًا.
    testWidgets('**خريطةُ اللمس**: لا ورقةَ ميّتة', (t) async {
      final played = <Card>[];
      await t.pumpWidget(_wrap(PlayerHandFan(
        cards: _hand,
        cardWidth: 94,
        maxWidth: 400,
        interactive: true,
        onPlay: played.add,
      )));
      await t.pumpAndSettle();

      final fan = t.getRect(find.byType(PlayerHandFan));
      final area = <String, int>{};
      const step = 6.0;
      for (var y = fan.top; y < fan.bottom; y += step) {
        for (var x = fan.left; x < fan.right; x += step) {
          played.clear();
          await t.tapAt(Offset(x, y));
          await t.pump();
          if (played.isNotEmpty) {
            area[played.first.code] = (area[played.first.code] ?? 0) + 1;
          }
        }
      }

      for (final c in _hand) {
        expect(area[c.code] ?? 0, greaterThan(20),
            reason: 'الورقة ${c.code} مساحةُ لمسها أضيقُ من إصبع');
      }
    });

    /// **الرمزُ يُقرأ معتدلًا — وهو ما يحكم ترتيبَ التراكب.**
    ///
    /// وجهُ الورقة يحمل رمزَها في **الزاوية العليا اليسرى**، ونظيرَه **مقلوبًا
    /// 180°** في السفلى اليمنى. فإن عَلَت اليسرى جارتَها لم يبقَ ظاهرًا من
    /// المبنيّة إلّا يمينُها — أي الرمزَ المقلوب. جُرّب ذلك (2026-07-21) لكسب
    /// مساحة لمسٍ للطرف الأيسر، فجاء ردُّ المالك فورًا: «تُجبرنا على قراءتها من
    /// تحت». **اليدُ تُقرأ قبل أن تُلمَس** — فاليمنى فوق اليسرى، دائمًا.
    ///
    /// يُقاس بالنتيجة لا بترتيب الأبناء: نقطةٌ يشترك فيها جاران **تربحها
    /// اليمنى** ⇔ اليمنى هي العليا ⇔ زاويةُ الرمز في اليسرى مكشوفة.
    testWidgets('**اليمنى فوق اليسرى**: زاويةُ الرمز تبقى مكشوفةً في كلّ ورقة',
        (t) async {
      final played = <Card>[];
      await t.pumpWidget(_wrap(PlayerHandFan(
        cards: _hand,
        cardWidth: 94,
        maxWidth: 400,
        interactive: true,
        onPlay: played.add,
      )));
      await t.pumpAndSettle();

      for (var i = 0; i < _hand.length - 1; i++) {
        // نقطةٌ في الثلث الأيمن من الورقة i — تغطّيها الورقة i+1.
        final r = t.getRect(_card(_hand[i]));
        played.clear();
        await t.tapAt(Offset(r.right - 6, r.center.dy));
        await t.pump();
        // **مَن يربح؟ ورقةٌ عن يمينها** — لا i+1 بالضرورة: عند تداخل 60% تصل
        // الورقةُ i+2 إلى ذلك الطرف أيضًا. المهمُّ الاتّجاه: اليمينُ يعلو.
        expect(played, hasLength(1), reason: 'نقطةٌ ميّتة عند طرف ${_hand[i].code}');
        expect(_hand.indexOf(played.first), greaterThan(i),
            reason: 'الورقة ${_hand[i].code} تعلو ما عن يمينها ⇒ رمزُ جارتها مغطّى');
      }
    });
  });

  // ── تمييزُ القانونيّة: يُرى ولا يمنع ──

  group('تمييزُ الورقة القانونيّة', () {
    /// شفافيّةُ ورقةٍ بعينها: أقربُ `Opacity` فوقها في الشجرة.
    double opacityOf(WidgetTester t, Card c) => t
        .widget<Opacity>(
            find.ancestor(of: _card(c), matching: find.byType(Opacity)).first)
        .opacity;

    Widget fan(Set<Card> legal, {bool interactive = true}) => _wrap(
          PlayerHandFan(
            cards: _hand,
            cardWidth: 70,
            maxWidth: 400,
            interactive: interactive,
            legalCards: legal,
            onPlay: (_) {},
          ),
        );

    testWidgets('في دورك: المخالفةُ تخفت والقانونيّةُ تامّةُ الوضوح', (t) async {
      final legal = {_hand[2], _hand[3]}; // القلب وحدَه
      await t.pumpWidget(fan(legal));
      await t.pumpAndSettle();

      for (final c in _hand) {
        expect(opacityOf(t, c), closeTo(legal.contains(c) ? 1.0 : HandFanMetrics.illegalOpacity, 1e-6),
            reason: c.code);
      }
    });

    /// **الفوجةُ قاعدةٌ لا خطأ** ([`docs/RULES.md`]): الواجهةُ تُمَيّز ولا تمنع.
    /// لو منعت لَحذفت من اللعبة اعتراضًا كاملًا بُني له خادمٌ وعميلٌ وصوت.
    testWidgets('**والمخالفةُ تُلعَب**: الخفوتُ خبرٌ لا قفل', (t) async {
      final played = <Card>[];
      await t.pumpWidget(_wrap(PlayerHandFan(
        cards: _hand,
        cardWidth: 70,
        maxWidth: 400,
        interactive: true,
        legalCards: {_hand[2]},
        onPlay: played.add,
      )));
      await t.pumpAndSettle();

      await t.tap(_card(_hand[7]), warnIfMissed: false); // مخالفةٌ صريحة
      await t.pump();
      expect(played, [_hand[7]]);
    });

    testWidgets('في غير دورك: لا خفوت — لا قرارَ يُعان عليه', (t) async {
      await t.pumpWidget(fan({_hand[0]}, interactive: false));
      await t.pumpAndSettle();
      for (final c in _hand) {
        expect(opacityOf(t, c), closeTo(1.0, 1e-6), reason: c.code);
      }
    });

    testWidgets('أوّلُ ورقةٍ في الأبلي (الكلُّ قانونيّ) ⇒ بلا أثر', (t) async {
      await t.pumpWidget(fan(_hand.toSet()));
      await t.pumpAndSettle();
      for (final c in _hand) {
        expect(opacityOf(t, c), closeTo(1.0, 1e-6), reason: c.code);
      }
    });

    /// **الخفوتُ لونٌ لا يُسمَع**: من يقرأ بالقارئ الصوتيّ لا يرى الفرق، فيُقال
    /// له قولًا. والأسماءُ من `docs/RULES.md` (الفالة · الديس · أرواه · الضم)
    /// لا ترجمةً مخترَعة.
    testWidgets('القارئُ الصوتيّ يسمع اسمَ الورقة، والمخالفةَ يسمعها مخالفة',
        (t) async {
      final handle = t.ensureSemantics();
      await t.pumpWidget(fan({_hand[4]})); // الفالة كارو وحدَها قانونيّة
      await t.pumpAndSettle();

      final l = AppLocalizationsAr();
      expect(find.bySemanticsLabel(Labels.card(l, _hand[4])), findsOneWidget);
      expect(
          find.bySemanticsLabel(l.foujaCardHint(Labels.card(l, _hand[0]))),
          findsOneWidget,
          reason: 'المخالفةُ تُقرأ ورقةً عاديّة');
      handle.dispose();
    });

    testWidgets('بلا قائمةٍ أصلًا (الافتراضيّ) ⇒ بلا أثر', (t) async {
      await t.pumpWidget(fan(const {}));
      await t.pumpAndSettle();
      for (final c in _hand) {
        expect(opacityOf(t, c), closeTo(1.0, 1e-6), reason: c.code);
      }
    });
  });

  // ── الحاسوب: فأرةٌ ولوحةُ مفاتيح ──

  group('اليدُ على الحاسوب', () {
    /// ارتفاعُ ورقةٍ عن قاع الصندوق — به يُقاس الرفعُ بلا نظرٍ إلى لقطة.
    double liftOf(WidgetTester t, Card c) =>
        t.getRect(find.byType(PlayerHandFan)).bottom - t.getRect(_card(c)).bottom;

    testWidgets('**التحويم يرفع** الورقةَ التي تحت الفأرة ويعيدها بمغادرتها',
        (t) async {
      await t.pumpWidget(_wrap(PlayerHandFan(
        cards: _hand,
        cardWidth: 70,
        maxWidth: 400,
        interactive: true,
        onPlay: (_) {},
      )));
      await t.pumpAndSettle();

      final rest = liftOf(t, _hand[3]);
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);

      await mouse.moveTo(t.getCenter(_card(_hand[3])));
      await t.pumpAndSettle();
      expect(liftOf(t, _hand[3]), greaterThan(rest + 20),
          reason: 'المحوَّم عليها لم ترتفع ⇒ لا يُعرَف ما تحت المؤشّر');

      // **ولا تبقى مجهَّزةً بعد المغادرة**: وإلّا لعبها `Enter` بلا قصد.
      await mouse.moveTo(Offset.zero);
      await t.pumpAndSettle();
      expect(liftOf(t, _hand[3]), closeTo(rest, 0.5));
    });

    testWidgets('التحويم **لا يلعب** — النقرُ وحدَه يلعب', (t) async {
      final played = <Card>[];
      await t.pumpWidget(_wrap(PlayerHandFan(
        cards: _hand,
        cardWidth: 70,
        maxWidth: 400,
        interactive: true,
        onPlay: played.add,
      )));
      await t.pumpAndSettle();

      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      for (final c in _hand) {
        await mouse.moveTo(t.getCenter(_card(c)));
        await t.pump();
      }
      expect(played, isEmpty);
    });

    Future<List<Card>> keyboardFan(WidgetTester t,
        {bool interactive = true}) async {
      final played = <Card>[];
      await t.pumpWidget(_wrap(PlayerHandFan(
        cards: _hand,
        cardWidth: 70,
        maxWidth: 400,
        interactive: interactive,
        onPlay: played.add,
      )));
      await t.pumpAndSettle();
      return played;
    }

    testWidgets('`1`..`8` تلعب ورقةً بموضعها المرئيّ (يسارًا فيمينًا)', (t) async {
      for (var i = 0; i < _hand.length; i++) {
        final played = await keyboardFan(t);
        await t.sendKeyEvent(_digitKeys[i]);
        await t.pump();
        expect(played, [_hand[i]], reason: 'المفتاح ${i + 1}');
      }
    });

    testWidgets('لوحةُ الأرقام كصفّها العلويّ', (t) async {
      final played = await keyboardFan(t);
      await t.sendKeyEvent(LogicalKeyboardKey.numpad3);
      await t.pump();
      expect(played, [_hand[2]]);
    });

    testWidgets('`←` `→` تُجهّز و`Enter` يلعب المجهَّزة', (t) async {
      final played = await keyboardFan(t);
      // بلا تجهيزٍ سابق: `→` يبدأ من أقصى اليسار.
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pump();
      expect(played, [_hand[1]]);
    });

    testWidgets('`Space` كـ`Enter`، و`Esc` يُلغي التجهيز فلا يلعب شيئًا',
        (t) async {
      final played = await keyboardFan(t);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.space);
      await t.pump();
      expect(played, isEmpty, reason: 'لُغِي التجهيزُ ثمّ لُعِب!');

      await t.sendKeyEvent(LogicalKeyboardKey.arrowLeft); // يبدأ من أقصى اليمين
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.space);
      await t.pump();
      expect(played, [_hand.last]);
    });

    /// **في غير دورك لا يلعب مفتاحٌ شيئًا** — ولوحةُ النتيجة فوق الطاولة لا
    /// تُلعَب من تحتها ورقة.
    testWidgets('غيرُ دورك: المفاتيحُ تُجهّز ولا تلعب', (t) async {
      final played = await keyboardFan(t, interactive: false);
      await t.sendKeyEvent(_digitKeys.first);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pump();
      expect(played, isEmpty);
    });

    testWidgets('مفتاحٌ لا موضعَ له (`9` بيدٍ من ثمانٍ) ⇒ لا شيء، بلا عطب',
        (t) async {
      final played = await keyboardFan(t);
      await t.sendKeyEvent(LogicalKeyboardKey.digit9);
      await t.pump();
      expect(played, isEmpty);
    });
  });
}

/// مفاتيحُ الصفّ العلويّ `1`..`8` — مرتّبةٌ كترتيب الأوراق المرئيّ.
const _digitKeys = [
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
  LogicalKeyboardKey.digit5,
  LogicalKeyboardKey.digit6,
  LogicalKeyboardKey.digit7,
  LogicalKeyboardKey.digit8,
];
