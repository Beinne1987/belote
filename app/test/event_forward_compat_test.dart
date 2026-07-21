import 'dart:async';
import 'dart:convert';

import 'package:app/game/online_game_controller.dart';
import 'package:app/game/view_model.dart';
import 'package:app/net/table_client.dart';
import 'package:belote_engine/belote_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// **التوافق للأمام**: خادمٌ أحدث يبثّ طورًا لا يعرفه هذا التطبيق.
///
/// كانت `parse` تنتهي بـ`return GameEvent.fromJson(m)`، فالطورُ المجهول **يُفسَّر لقطةَ
/// مباراة** لا يُتجاهَل ⇒ رسالةٌ فيها `seat` تمسح الطاولة، وأخرى بلا `seat` ترمي
/// TypeError. ولذلك كان كلّ بناءٍ يضيف طورًا **إلزاميًّا** بالضرورة (4041 آخرها).
///
/// هذه الاختبارات تحرس القائمة البيضاء: **لقطةُ المباراة أطوارٌ معدودة، وما سواها
/// يُتجاهَل بأمان**. كسرُها يعيد الإلزام على كل ميزةٍ خادميّة.
Map<String, dynamic> _snapshot({String phase = 'playing', int seat = 0}) {
  final codes = [for (final c in buildDeck()) c.code];
  return {
    'phase': phase,
    'seat': seat,
    'myHand': [codes[0], codes[1]],
    'handCounts': [8, 8, 8, 8],
    'usScore': 42,
    'themScore': 17,
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
  group('القائمة البيضاء لأطوار اللقطة', () {
    // تطابق `LivePhase` في الخادم (`live_session.dart`) — إن أضيف طورٌ هناك فهنا.
    for (final phase in ['bidding', 'playing', 'done']) {
      test('«$phase» لقطةُ مباراة', () {
        final e = TableEvent.parse(_snapshot(phase: phase));
        expect(e, isA<GameEvent>());
        expect((e as GameEvent).phase, phase);
      });
    }

    test('طورٌ من خادمٍ أحدث ⇒ UnknownEvent لا لقطةَ مباراة', () {
      // الفخّ: فيها `seat` ⇒ كانت تُبنى لقطةً «صالحة» بيدٍ فارغةٍ ونقاطٍ أصفار.
      final e = TableEvent.parse({'phase': 'poll', 'seat': 1, 'question': 'x'});
      expect(e, isA<UnknownEvent>());
      expect((e as UnknownEvent).phase, 'poll', reason: 'يُحفَظ للتشخيص');
    });

    test('طورٌ مجهولٌ بلا seat ⇒ UnknownEvent لا استثناء', () {
      // الفخّ الثاني: `j['seat'] as int` على null كان يرمي TypeError.
      expect(TableEvent.parse({'phase': 'trophy', 'to': 2}), isA<UnknownEvent>());
    });

    test('رسالةٌ بلا طورٍ نصّيّ أصلًا ⇒ UnknownEvent(null)', () {
      expect((TableEvent.parse({}) as UnknownEvent).phase, isNull);
      expect((TableEvent.parse({'phase': 7}) as UnknownEvent).phase, isNull);
    });

    test('الأطوار المعروفة ما تزال على حالها (لا انحدار)', () {
      expect(TableEvent.parse({'phase': 'lobby', 'tableId': 't', 'seats': []}),
          isA<LobbyEvent>());
      expect(TableEvent.parse({'phase': 'rating', 'rating': 1200, 'delta': 8}),
          isA<RatingEvent>());
      expect(TableEvent.parse({'phase': 'reaction', 'seat': 1, 'emoji': '👍'}),
          isA<ReactionEvent>());
      expect(TableEvent.parse({'phase': 'chat', 'seat': 1, 'phrase': 'salam'}),
          isA<ChatEvent>());
      expect(TableEvent.parse({'phase': 'gift', 'from': 0, 'to': 1, 'gift': 'rose'}),
          isA<GiftEvent>());
      // الخطأ يسبق الطور: رسالةُ خطأٍ تُعرَف بحقلها لا بطورها.
      expect(TableEvent.parse({'error': 'gift_insufficient'}), isA<ServerError>());
    });
  });

  group('الكنترولر يتجاهل المجهول بأمان', () {
    late StreamController<String> incoming;
    late OnlineGameController c;

    setUp(() {
      incoming = StreamController<String>.broadcast();
      c = OnlineGameController(LiveTableClient(incoming: incoming.stream, send: (_) {}));
    });

    test('طورٌ مجهولٌ لا يمسح الطاولة (الانحدار الذي أوجب الإلزام)', () async {
      incoming.add(jsonEncode(_snapshot()));
      await Future<void>.delayed(Duration.zero);
      expect(c.tableView, isNotNull);
      expect(c.tableView!.myHand, hasLength(2));
      expect(c.tableView!.usScore, 42);

      // ما كان يقع: تُطبَّق «لقطةً» فتصير اليد فارغةً والنقاط أصفارًا.
      incoming.add(jsonEncode({'phase': 'poll', 'seat': 1, 'question': 'x'}));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(c.tableView!.myHand, hasLength(2), reason: 'الطاولة كما هي');
      expect(c.tableView!.usScore, 42);
      expect(c.tableView!.phase, GamePhase.playing);
      expect(c.errorCode, isNull, reason: 'تجاهلٌ صامت — لا يُفزِع اللاعب بخطأ');
    });

    test('طورٌ مجهولٌ بلا seat لا يُسقط الاتصال (كان TypeError)', () async {
      incoming.add(jsonEncode(_snapshot()));
      await Future<void>.delayed(Duration.zero);
      incoming.add(jsonEncode({'phase': 'trophy', 'to': 2}));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // البثّ التالي ما زال يصل ⇒ الاشتراك حيّ.
      incoming.add(jsonEncode({'phase': 'reaction', 'seat': 1, 'emoji': '🔥'}));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(c.reactionAt(1), '🔥');
    });
  });
}
