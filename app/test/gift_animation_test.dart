/// **محرّكُ حركة الهدايا** — يحرس العقدَ الذي بُني عليه:
///   • الوصفةُ بيانٌ: هديّةٌ جديدةٌ تطير بلا لمس منطق الحركة (وهذا شرطُ المالك).
///   • الطابور: رحلةٌ واحدةٌ في الجوّ مهما تدفّقت الهدايا.
///   • **المُرسِلُ يُرى** — العطبُ الأصليّ الذي بُني له كلُّ هذا.
library;

import 'dart:async';
import 'dart:convert';

import 'package:app/game/online_game_controller.dart';
import 'package:app/game/view_model.dart';
import 'package:app/net/table_client.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/gifts/gift_flight.dart';
import 'package:app/ui/gifts/gift_flight_layer.dart';
import 'package:app/ui/gifts/gift_spec.dart';
import 'package:app/ui/table_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// مضيفٌ بمقاسٍ ثابت: الطبقةُ تملأ ما أُعطيت، والمسارُ يُحسَب من المقاس.
Widget _host(GiftFlight? f) => ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 480,
            child: Stack(children: [GiftFlightLayer(flight: f)]),
          ),
        ),
      ),
    );

void main() {
  group('السجلّ البصريّ', () {
    test('الندرةُ من الثمن — لا من جدولٍ يدويٍّ يتناقض مع الكتالوج', () {
      expect(giftVisualsFor('rose').rarity, GiftRarity.common); // 5
      expect(giftVisualsFor('sweet').rarity, GiftRarity.rare); // 20
      expect(giftVisualsFor('camel').rarity, GiftRarity.epic); // 100
      expect(giftVisualsFor('vip_flower').rarity, GiftRarity.legendary);
    });

    test('الأندرُ أبطأُ وأكبرُ وأغزرُ جُسيمات — الثمنُ يُرى في الحركة', () {
      final common = giftVisualsFor('rose');
      final epic = giftVisualsFor('camel');
      final legend = giftVisualsFor('vip_flower');

      expect(epic.fx.travel, greaterThan(common.fx.travel));
      expect(legend.fx.travel, greaterThan(epic.fx.travel));
      expect(legend.scale, greaterThan(epic.scale));
      expect(epic.scale, greaterThan(common.scale));
      expect(legend.fx.trail, greaterThan(common.fx.trail));
      expect(legend.fx.burst, greaterThan(common.fx.burst));
    });

    test('صوتُ الوصول يتدرّج بالندرة، والإطلاقُ واحدٌ للجميع', () {
      expect(giftVisualsFor('rose').arriveSound, GameSound.giftArrive);
      expect(giftVisualsFor('car').arriveSound, GameSound.giftArriveEpic);
      expect(
          giftVisualsFor('vip_box').arriveSound, GameSound.giftArriveLegendary);
      expect(giftVisualsFor('rose').launchSound, GameSound.giftLaunch);
      expect(giftVisualsFor('vip_box').launchSound, GameSound.giftLaunch);
    });

    test('الأصلُ: إيموجي للكتالوج وصورةٌ لحصريّات VIP', () {
      expect(giftVisualsFor('crown').art, isA<GiftEmoji>());
      final vip = giftVisualsFor('vip_pitcher').art;
      expect(vip, isA<GiftImage>());
      expect((vip as GiftImage).asset, contains('assets/VIP/'));
    });

    test('**هديّةٌ من خادمٍ أحدث** تطير بأثرٍ محترمٍ بدل أن تختفي', () {
      final v = giftVisualsFor('dragon_2027');
      expect(v.art, isA<GiftEmoji>());
      expect((v.art as GiftEmoji).emoji, '🎁');
      expect(v.fx.trail, greaterThan(0), reason: 'تُرى فعلًا');
      expect(v.arriveSound, isNotNull);
    });

    test('التفريدُ لا يُلغي وصفةَ الدرجة بل يعدّلها', () {
      // الوردةُ تتهادى: قوسُها أعلى من قوس درجتها، وزمنُها زمنُ الدرجة نفسُه.
      final rose = giftVisualsFor('rose');
      final tea = giftVisualsFor('tea');
      expect(rose.fx.arc, greaterThan(tea.fx.arc));
      expect(rose.fx.travel, tea.fx.travel, reason: 'كلتاهما عاديّة');
    });
  });

  group('هندسةُ الرحلة', () {
    GiftFlight flight({int? from = 1, int to = 3, String gift = 'rose'}) =>
        GiftFlight(
          id: 1,
          fromSeat: from,
          toSeat: to,
          senderName: 'سالم',
          receiverName: 'أحمد',
          giftId: gift,
        );

    test('المرسى مقعدُ اللاعب — والمشاهدُ من المدرّجات لا من مقعد', () {
      expect(flight(from: 1).origin, kSeatAnchors[1]);
      expect(flight(from: null).origin, kStandsAnchor);
      expect(flight(to: 2).target, kSeatAnchors[2]);
    });

    test('الزمنُ الكلّيُّ عبورٌ ثمّ أثرُ وصول، والكسرُ بينهما صحيح', () {
      final f = flight();
      expect(f.total, f.travel + kGiftBurst);
      expect(f.travelFraction, greaterThan(0));
      expect(f.travelFraction, lessThan(1));
    });
  });

  group('طابورُ الرحلات', () {
    late StreamController<String> incoming;
    late List<String> sent;

    setUp(() {
      incoming = StreamController<String>.broadcast();
      sent = [];
    });
    tearDown(() => incoming.close());

    OnlineGameController make({Duration hold = const Duration(seconds: 3)}) =>
        OnlineGameController(
          LiveTableClient(incoming: incoming.stream, send: sent.add),
          reactionHold: hold,
        );

    void feed(Map<String, dynamic> m) => incoming.add(jsonEncode(m));

    test('**اسمُ المُرسِل يسافر مع الهديّة** — العطبُ الأصليّ', () async {
      final c = make();
      feed({'phase': 'gift', 'from': 1, 'to': 2, 'gift': 'rose'});
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final f = c.giftFlight!;
      expect(f.senderName, isNotEmpty, reason: 'المستقبِلُ يعرف مَن أهداه');
      expect(f.receiverName, isNotEmpty);
      expect(f.fromSeat, isNot(f.toSeat));
      c.dispose();
    });

    test('هديّةُ المدرّجات تطير باسم راميها من خارج الطاولة', () async {
      final c = make();
      feed({
        'phase': 'spectatorGift',
        'name': 'متفرّجٌ كريم',
        'to': 1,
        'gift': 'crown',
      });
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final f = c.giftFlight!;
      expect(f.fromSeat, isNull, reason: 'لا مقعدَ للمشاهد');
      expect(f.origin, kStandsAnchor);
      expect(f.senderName, 'متفرّجٌ كريم');
      c.dispose();
    });

    test('مشاهدٌ بلا اسم ⇒ «مشاهد» لا فراغ', () async {
      final c = make();
      feed({'phase': 'spectatorGift', 'name': '', 'to': 1, 'gift': 'rose'});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(c.giftFlight!.senderName, 'مشاهد');
      c.dispose();
    });

    test('**رحلةٌ واحدةٌ في الجوّ**: «هديّةٌ للجميع» تصطفّ ولا تتراكب', () async {
      final c = make();
      // ثلاثةُ أحداثٍ في لحظةٍ واحدة — كما يبثّها الخادمُ لزرّ «للجميع».
      feed({'phase': 'gift', 'from': 0, 'to': 1, 'gift': 'rose'});
      feed({'phase': 'gift', 'from': 0, 'to': 2, 'gift': 'rose'});
      feed({'phase': 'gift', 'from': 0, 'to': 3, 'gift': 'rose'});
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final first = c.giftFlight!;
      expect(first.toSeat, 1, reason: 'الأولى بالترتيب');

      // الثانيةُ لا تبدأ قبل أن تهبط الأولى ويُكمل أثرُها.
      await Future<void>.delayed(first.travel ~/ 2);
      expect(c.giftFlight!.id, first.id, reason: 'ما زالت الأولى');

      await Future<void>.delayed(first.total + const Duration(milliseconds: 200));
      expect(c.giftFlight!.toSeat, 2);
      expect(c.giftFlight!.id, isNot(first.id));
      c.dispose();
    });

    test('رحلتان متطابقتان متتاليتان **رحلتان** لا واحدة (الرقمُ يميّز)', () async {
      final c = make();
      feed({'phase': 'gift', 'from': 1, 'to': 2, 'gift': 'rose'});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final a = c.giftFlight!.id;

      feed({'phase': 'gift', 'from': 1, 'to': 2, 'gift': 'rose'});
      await Future<void>.delayed(
          c.giftFlight!.total + const Duration(milliseconds: 250));
      expect(c.giftFlight!.id, isNot(a), reason: 'وإلّا لم تُعَد الحركة');
      c.dispose();
    });

    test('الفقاعةُ تهبط عند الوصول، وطرفا الرحلة يُعرَفان للتوهّج', () async {
      final c = make();
      feed({'phase': 'gift', 'from': 1, 'to': 3, 'gift': 'rose'});
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(c.giftGlowFrom, 1);
      expect(c.giftGlowTo, 3);
      expect(c.gifts[3], isNull, reason: 'ما زالت في الجوّ');

      await Future<void>.delayed(
          c.giftFlight!.travel + const Duration(milliseconds: 40));
      expect(c.gifts[3], 'rose');
      c.dispose();
    });

    test('رشُّ الهدايا لا يحتكر الشاشة: ما فاض عن الطابور يهبط فقاعةً', () async {
      final c = make();
      for (var i = 0; i < 40; i++) {
        feed({'phase': 'gift', 'from': 1, 'to': 2, 'gift': 'rose'});
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
      // الفائضُ وصل خبرًا فورًا بدل أن يقف في طابورٍ طولُه دقائق.
      expect(c.gifts[2], 'rose');
      c.dispose();
    });

    test('بلا مهلة (اختبارات) ⇒ فقاعةٌ فورًا وبلا حركةٍ ولا مؤقّت', () async {
      final c = make(hold: Duration.zero);
      feed({'phase': 'gift', 'from': 1, 'to': 2, 'gift': 'tea'});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(c.giftFlight, isNull);
      expect(c.gifts[2], 'tea');
      c.dispose();
    });

    test('الإتلافُ ورحلةٌ في الجوّ لا يوقظ كنترولرًا متلَفًا', () async {
      final c = make();
      feed({'phase': 'gift', 'from': 1, 'to': 2, 'gift': 'car'});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(c.giftFlight, isNotNull);
      c.dispose();
      // لو بقي مؤقّتُ الهبوط لأشعر بعد الإتلاف ⇒ استثناء.
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });

    test('«مباراةٌ جديدة» تُفرغ الجوَّ والطابور', () async {
      final c = make();
      feed({'phase': 'gift', 'from': 1, 'to': 2, 'gift': 'rose'});
      feed({'phase': 'gift', 'from': 1, 'to': 3, 'gift': 'rose'});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(c.giftFlight, isNotNull);

      c.newMatch();
      expect(c.giftFlight, isNull, reason: 'لا تطير هديّةٌ فوق مباراةٍ أخرى');
      c.dispose();
    });
  });

  group('الطبقةُ البصريّة', () {
    testWidgets('تُظهر اسمَ المُرسِل عند الانطلاق واسمَ المستقبِل عند الوصول',
        (tester) async {
      final f = GiftFlight(
        id: 1,
        fromSeat: 1,
        toSeat: 3,
        senderName: 'سالم',
        receiverName: 'أحمد',
        giftId: 'rose',
      );

      await tester.pumpWidget(_host(f));
      await tester.pump(const Duration(milliseconds: 60));

      // الانطلاق: المُرسِلُ معلومٌ — وهذا ما كان ناقصًا.
      expect(find.text('سالم'), findsOneWidget);

      // الوصول: المستقبِلُ يُعلَن بأثره.
      await tester.pump(f.travel + const Duration(milliseconds: 60));
      expect(find.text('أحمد'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('لا رحلةَ ⇒ لا طبقةَ ولا مؤقّتٌ يدور', (tester) async {
      await tester.pumpWidget(_host(null));
      // لا رسّامَ **داخل الطبقة** (السقالةُ نفسُها فيها رسّاموها).
      expect(
        find.descendant(
          of: find.byType(GiftFlightLayer),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    });

    testWidgets('حصريّةُ VIP تطير بصورتها لا بإيموجي', (tester) async {
      final f = GiftFlight(
        id: 7,
        fromSeat: 0,
        toSeat: 2,
        senderName: 'سالم',
        receiverName: 'أحمد',
        giftId: 'vip_flower',
      );
      await tester.pumpWidget(_host(f));
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.byType(Image), findsWidgets);
      await tester.pumpAndSettle();
    });
  });

  group('على الطاولة الحقيقيّة', () {
    const view = TableView(
      myHand: [],
      handCounts: [0, 0, 0, 0],
      usScore: 0,
      themScore: 0,
      bid: null,
      bidderSeat: null,
      akwins: false,
      dealerSeat: 0,
      seatBids: [null, null, null, null],
      turn: 0,
      trick: [],
      legalCards: {},
      phase: GamePhase.playing,
    );

    testWidgets('الرحلةُ تعبر الطاولةَ كاملةً بلا فيضٍ ولا استثناء', (t) async {
      final f = GiftFlight(
        id: 1,
        fromSeat: 3,
        toSeat: 1,
        senderName: 'سالم',
        receiverName: 'أحمد',
        giftId: 'camel', // ملحميّةٌ: أكبرُ حجمًا وأغزرُ أثرًا ⇒ أقسى اختبارٍ للتخطيط
      );
      await t.pumpWidget(ThemeScope(
        manager: ThemeManager(),
        child: MaterialApp(home: TableScreen(view: view, giftFlight: f)),
      ));

      // عبورٌ خطوةً خطوةً: أيُّ فيضٍ أو استثناءِ رسمٍ يسقط الاختبار هنا.
      for (var i = 0; i < 12; i++) {
        await t.pump(f.total ~/ 12);
      }
      expect(t.takeException(), isNull);
      await t.pumpAndSettle();
    });

    testWidgets('بلا رحلة ⇒ الطاولةُ كما كانت (الأوفلاين لا يعرف الطبقة)', (t) async {
      await t.pumpWidget(ThemeScope(
        manager: ThemeManager(),
        child: const MaterialApp(home: TableScreen(view: view)),
      ));
      expect(find.byType(GiftFlightLayer), findsNothing);
    });
  });
}
