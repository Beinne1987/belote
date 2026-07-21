import 'dart:async';
import 'dart:convert';

import 'package:app/game/online_game_controller.dart';
import 'package:app/net/table_client.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/gift_picker.dart';
import 'package:app/ui/quick_chat_picker.dart';
import 'package:app/game/seat_player.dart';
import 'package:belote_engine/belote_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// الدردشة السريعة والهدايا في العميل — نظيرُ `reactions_test.dart`. الثلاثة تتقاسم
/// آليّة الفقاعة، وما يخصّ هاتين: **العبارة تُرسَل بمعرّفها**، و**الهديّة تظهر فوق
/// المستقبِل لا المُرسِل**، و**مقعد الإهداء يُترجَم لإحداثيّات الخادم**.
Widget _wrap(Widget child) => ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(home: Scaffold(body: child)),
    );

/// لقطةٌ صغرى غرضُها تثبيت `mySeat` وحده (تدوير العرض يُقاس منه).
Map<String, dynamic> _snapshot({required int seat}) {
  final codes = [for (final c in buildDeck()) c.code];
  return {
    'phase': 'playing',
    'seat': seat,
    'myHand': [codes[0]],
    'handCounts': [8, 8, 8, 8],
    'usScore': 0,
    'themScore': 0,
    'dealerSeat': 0,
    'bid': 'T',
    'bidderSeat': 2,
    'akwins': false,
    'turn': 1,
    'trick': const [],
    'yourTurn': false,
    'legalCards': const [],
    'legalBids': const [],
    'roundResult': null,
    'matchOver': false,
  };
}

void main() {
  group('تحليل الأحداث', () {
    test('phase=chat ⇒ ChatEvent بمعرّفٍ لا نصّ', () {
      final e = TableEvent.parse({'phase': 'chat', 'seat': 2, 'phrase': 'salam'});
      expect(e, isA<ChatEvent>());
      expect((e as ChatEvent).seat, 2);
      expect(e.phrase, 'salam');
    });

    test('phase=gift ⇒ GiftEvent بطرفيه', () {
      final e = TableEvent.parse({'phase': 'gift', 'from': 0, 'to': 3, 'gift': 'rose'});
      expect(e, isA<GiftEvent>());
      expect((e as GiftEvent).from, 0);
      expect(e.to, 3);
      expect(e.gift, 'rose');
    });
  });

  group('الكنترولر', () {
    late StreamController<String> incoming;
    late List<String> sent;
    late OnlineGameController c;

    void feed(Map<String, dynamic> m) => incoming.add(jsonEncode(m));

    setUp(() {
      incoming = StreamController<String>.broadcast();
      sent = [];
      c = OnlineGameController(
        LiveTableClient(incoming: incoming.stream, send: sent.add),
      );
    });

    test('إرسال عبارةٍ ينقل معرّفها ولا يعرض شيئًا محليًّا', () {
      c.chat('salam');
      expect(jsonDecode(sent.single), {'type': 'chat', 'phrase': 'salam'});
      // لا عرضَ متفائل: ننتظر بثّ الخادم (قد يُسقطها حدُّ الإغراق).
      expect(c.chats, [null, null, null, null]);
    });

    test('العبارة الواردة تظهر فوق مقعد قائلها — **نصًّا مُترجَمًا لا معرّفًا**',
        () async {
      feed({'phase': 'chat', 'seat': 1, 'phrase': 'bravo'});
      await Future<void>.delayed(Duration.zero);
      expect(c.chats, [null, 'أحسنت', null, null]);
    });

    test('الهديّة تظهر فوق **المستقبِل** لا المُرسِل', () async {
      feed({'phase': 'gift', 'from': 1, 'to': 3, 'gift': 'rose'});
      await Future<void>.delayed(Duration.zero);
      expect(c.gifts, [null, null, null, 'rose'], reason: 'الهديّة خبرٌ عن المستقبِل');
    });

    test('العبارة والهديّة والتفاعل معًا على مقعدٍ واحد ⇒ ثلاثتها مستقلّة', () async {
      feed({'phase': 'chat', 'seat': 1, 'phrase': 'nice'});
      feed({'phase': 'gift', 'from': 0, 'to': 1, 'gift': 'crown'});
      feed({'phase': 'reaction', 'seat': 1, 'emoji': '🔥'});
      await Future<void>.delayed(Duration.zero);

      expect(c.chats[1], 'لعبةٌ جميلة');
      expect(c.gifts[1], 'crown');
      expect(c.reactionAt(1), '🔥', reason: 'لا يطرد بعضها بعضًا');
    });

    test('عبارةٌ جديدةٌ من نفس المقعد تستبدل السابقة (لا تكديس)', () async {
      feed({'phase': 'chat', 'seat': 2, 'phrase': 'salam'});
      await Future<void>.delayed(Duration.zero);
      feed({'phase': 'chat', 'seat': 2, 'phrase': 'bye'});
      await Future<void>.delayed(Duration.zero);

      expect(c.chats[2], 'إلى اللقاء');
      expect(c.chats.where((e) => e != null), hasLength(1));
    });

    test('فقاعتا العبارة والهديّة تختفيان بعد reactionHold', () async {
      final c = OnlineGameController(
        LiveTableClient(incoming: incoming.stream, send: sent.add),
        reactionHold: const Duration(milliseconds: 40),
      );
      feed({'phase': 'chat', 'seat': 1, 'phrase': 'luck'});
      feed({'phase': 'gift', 'from': 1, 'to': 2, 'gift': 'tea'});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(c.chats[1], 'بالتوفيق');

      // **الهديّةُ تطير أوّلًا**: فقاعتُها تهبط فوق المستقبِل عند **الوصول** لا عند
      // الإرسال — وإلّا ظهرت الهديّةُ في وجهه والحركةُ لم تصله بعد.
      expect(c.gifts[2], isNull, reason: 'ما زالت في الجوّ');
      expect(c.giftFlight, isNotNull);
      expect(c.giftFlight!.fromSeat, 1);
      expect(c.giftFlight!.toSeat, 2);

      // **مهلةُ الفقاعة تبدأ من الهبوط لا من الإرسال** — تُلتقَط المدّةُ الآن لأنّ
      // الرحلةَ تُمحى بعد وصولها.
      final travel = c.giftFlight!.travel;
      await Future<void>.delayed(travel + const Duration(milliseconds: 20));
      expect(c.chats[1], isNull, reason: 'انقضت مهلةُ العبارة أثناء الطيران');
      expect(c.gifts[2], 'tea', reason: 'هبطت فوق المستقبِل');

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(c.gifts[2], isNull, reason: 'انقضت مهلةُ الفقاعة');
      c.dispose();
    });

    test('الإتلاف أثناء فقاعتين حيّتين لا يُوقظ كنترولرًا متلَفًا', () async {
      final c = OnlineGameController(
        LiveTableClient(incoming: incoming.stream, send: sent.add),
        reactionHold: const Duration(milliseconds: 30),
      );
      feed({'phase': 'chat', 'seat': 1, 'phrase': 'sorry'});
      feed({'phase': 'gift', 'from': 0, 'to': 2, 'gift': 'rose'});
      await Future<void>.delayed(const Duration(milliseconds: 5));
      c.dispose();

      // لو بقي مؤقّتٌ لأشعر بعد الإتلاف ⇒ استثناء. الانتظار يتجاوز المهلة.
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    test('الإهداء يترجم مقعد العرض لإحداثيّات الخادم (عكس التدوير)', () async {
      feed(_snapshot(seat: 1)); // مقعدي 1 ⇒ العرض يدور بمقداره
      await Future<void>.delayed(Duration.zero);

      c.sendGift(1, 'rose'); // يميني بالعرض ⇒ الخادم (1+1)%4 = 2
      expect(jsonDecode(sent.last), {'type': 'gift', 'seat': 2, 'gift': 'rose'});

      c.sendGift(3, 'tea'); // (3+1)%4 = 0
      expect(jsonDecode(sent.last), {'type': 'gift', 'seat': 0, 'gift': 'tea'});
    });

    test('الهديّة الواردة تدور للعرض هي الأخرى', () async {
      feed(_snapshot(seat: 1));
      await Future<void>.delayed(Duration.zero);
      feed({'phase': 'gift', 'from': 2, 'to': 1, 'gift': 'rose'}); // إليّ أنا
      await Future<void>.delayed(Duration.zero);

      expect(c.gifts, ['rose', null, null, null], reason: 'مقعدي = 0 بالعرض');
    });
  });

  group('الواجهة', () {
    testWidgets('منتقي العبارات يعرضها كلَّها ويُبلّغ المختارة بمعرّفها', (t) async {
      final picked = <String>[];
      await t.pumpWidget(_wrap(QuickChatPicker(onPick: picked.add)));

      for (final text in quickChatPhrases.values) {
        expect(find.text(text), findsOneWidget, reason: '«$text» مفقودةٌ من المنتقي');
      }
      await t.tap(find.text('أحسنت'));
      expect(picked, ['bravo'], reason: 'يُرسَل المعرّف لا النصّ');
    });

    testWidgets('فقاعة العبارة تعرض نصّها', (t) async {
      await t.pumpWidget(_wrap(const ChatBubble(text: 'شكرًا')));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('شكرًا'), findsOneWidget);
    });

    testWidgets('لوحة الهدايا: تختار مَن ثمّ ماذا، فتُبلّغ الاثنين', (t) async {
      final sent = <(int, String)>[];
      await t.pumpWidget(_wrap(Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showGiftSheet(
            context,
            targets: [
              (viewSeat: 1, player: const SeatPlayer(name: 'بلال')),
              (viewSeat: 2, player: const SeatPlayer(name: 'سالم')),
            ],
            onSend: (seat, gift) => sent.add((seat, gift)),
          ),
          child: const Text('افتح'),
        ),
      )));
      await t.tap(find.text('افتح'));
      await t.pumpAndSettle();

      for (final g in giftCatalogUi) {
        expect(find.text(g.name), findsOneWidget, reason: '${g.name} مفقودةٌ من الكتالوج');
      }
      await t.tap(find.text('سالم')); // المستقبِل الثاني
      await t.pump();
      await t.tap(find.text('تاج'));
      await t.pumpAndSettle();

      expect(sent, [(2, 'crown')]);
    });

    test('معرّفٌ لا نعرفه ⇒ لا فقاعة بدل معرّفٍ خام', () {
      expect(quickChatText('nope'), isNull);
      expect(giftEmoji('nope'), isNull);
      expect(quickChatText('salam'), isNotNull);
      expect(giftEmoji('rose'), '🌹');
    });
  });
}
