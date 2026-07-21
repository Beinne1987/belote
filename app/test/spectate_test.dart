import 'dart:async';
import 'dart:convert';

import 'package:app/game/online_game_controller.dart';
import 'package:app/net/table_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// كنترولر **مشاهدة** فوق عميلٍ وهميّ ([[spectator-system]]).
(OnlineGameController, void Function(Map<String, dynamic>), List<Map<String, dynamic>>)
    _harness({String? watch}) {
  final incoming = StreamController<String>.broadcast();
  final sent = <Map<String, dynamic>>[];
  final client = LiveTableClient(
    incoming: incoming.stream,
    send: (s) => sent.add(jsonDecode(s) as Map<String, dynamic>),
  );
  final c = OnlineGameController(client, spectateTableId: watch);
  void feed(Map<String, dynamic> m) => incoming.add(jsonEncode(m));
  return (c, feed, sent);
}

/// لقطةُ مشاهدٍ كما يبثّها الخادم: `seat: -1` وبلا يدٍ ولا نيّات.
Map<String, dynamic> _spectatorSnapshot({bool over = false, int watchers = 1}) => {
      'phase': over ? 'done' : 'playing',
      'seat': -1,
      'spectator': true,
      'watchers': watchers,
      'myHand': const [],
      'handCounts': [8, 8, 8, 8],
      'usScore': 40,
      'themScore': 25,
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
      'matchOver': over,
      if (over) 'matchWinner': 0,
    };

Map<String, dynamic> _lobbyFor() => {
      'phase': 'lobby',
      'tableId': 't7',
      'seats': [
        {'seat': 0, 'ai': false, 'playerId': 'p0', 'name': 'سالم', 'connected': true},
        {'seat': 1, 'ai': false, 'playerId': 'p1', 'name': 'زيد', 'connected': true},
        {'seat': 2, 'ai': true},
        {'seat': 3, 'ai': false, 'playerId': 'p3', 'name': 'عمر', 'connected': true},
      ],
    };

void main() {
  test('الإنشاء بوضع المشاهدة يُرسل نيّة spectate فورًا', () async {
    final (c, _, sent) = _harness(watch: 't7');
    expect(c.isSpectator, isTrue);
    expect(sent, [
      {'type': 'spectate', 'tableId': 't7'}
    ]);
    c.dispose();
  });

  test('لقطةُ المشاهد: طور اللعب بلا يدٍ وبلا تدوير (منظور المقعد 0)', () async {
    final (c, feed, _) = _harness(watch: 't7');
    feed(_lobbyFor());
    feed(_spectatorSnapshot(watchers: 3));
    await Future<void>.delayed(Duration.zero);

    expect(c.stage, OnlineStage.playing);
    expect(c.mySeat, 0, reason: 'المتفرّج يرى الطاولة من منظور مقعد الخادم 0');
    expect(c.watchers, 3);

    final v = c.tableView!;
    expect(v.myHand, isEmpty);
    expect(v.humanCanPlay, isFalse);
    expect(v.canAccuseFouja, isFalse);
    expect(c.bidBar, isNull);
    // بلا تدوير: مقعد الخادم 3 = مقعد العرض 3 ⇒ الأسماء في مواضعها.
    expect(c.seatPlayers[0].name, 'سالم');
    expect(c.seatPlayers[3].name, 'عمر');
    c.dispose();
  });

  test('طورُ watchers يحدّث العدّاد دون مساس الطاولة', () async {
    final (c, feed, _) = _harness(watch: 't7');
    feed(_lobbyFor());
    feed(_spectatorSnapshot());
    await Future<void>.delayed(Duration.zero);
    feed({'phase': 'watchers', 'count': 12});
    await Future<void>.delayed(Duration.zero);

    expect(c.watchers, 12);
    expect(c.stage, OnlineStage.playing, reason: 'اللقطة لم تُمَسّ');
    c.dispose();
  });

  test('هديّةُ المدرّجات: فقاعةٌ فوق المستقبِل ولافتةٌ باسم الرامي', () async {
    final (c, feed, _) = _harness(watch: 't7');
    feed(_lobbyFor());
    feed(_spectatorSnapshot());
    await Future<void>.delayed(Duration.zero);
    feed({'phase': 'spectatorGift', 'name': 'واثق', 'to': 3, 'gift': 'rose'});
    await Future<void>.delayed(Duration.zero);

    expect(c.gifts[3], 'rose', reason: 'الفقاعة فوق المستقبِل (عرض 3 = خادم 3)');
    expect(c.standsGiftLabel, 'واثق أهدى عمر');
    c.dispose();
  });

  test('spectateEnd بعد نهاية المباراة ⇒ تبقى اللوحة؛ وقبلها ⇒ شاشةُ انتهاء', () async {
    // اكتملت ثم أُزيلت الطاولة: لا خطأ — لوحةُ النتيجة تبقى.
    final (c1, feed1, _) = _harness(watch: 't7');
    feed1(_lobbyFor());
    feed1(_spectatorSnapshot(over: true));
    await Future<void>.delayed(Duration.zero);
    feed1({'phase': 'spectateEnd'});
    await Future<void>.delayed(Duration.zero);
    expect(c1.spectateEnded, isTrue);
    expect(c1.stage, OnlineStage.playing, reason: 'اللوحة الختاميّة معروضة');
    c1.dispose();

    // ماتت قبل النهاية ⇒ لا شيء يُعرَض بعدها.
    final (c2, feed2, _) = _harness(watch: 't7');
    feed2(_lobbyFor());
    feed2(_spectatorSnapshot());
    await Future<void>.delayed(Duration.zero);
    feed2({'phase': 'spectateEnd'});
    await Future<void>.delayed(Duration.zero);
    expect(c2.stage, OnlineStage.error);
    expect(c2.errorCode, 'spectate_unavailable');
    c2.dispose();
  });

  test('هديّةُ المتفرّج تُرسَل بمقعد الخادم مباشرةً (بلا تدوير)', () async {
    final (c, feed, sent) = _harness(watch: 't7');
    feed(_lobbyFor());
    feed(_spectatorSnapshot());
    await Future<void>.delayed(Duration.zero);
    sent.clear();

    c.sendGift(3, 'crown');
    expect(sent, [
      {'type': 'gift', 'seat': 3, 'gift': 'crown'}
    ]);

    c.stopSpectating();
    expect(sent.last, {'type': 'spectateStop'});
    c.dispose();
  });

  test('انقطاعٌ وإعادةُ اتصال ⇒ نيّةُ spectate تُعاد تلقائيًّا (onReopen)', () async {
    final opened = <StreamController<String>>[];
    final sent = <String>[];
    WsChannel factory(Uri _) {
      final ctl = StreamController<String>();
      opened.add(ctl);
      return (
        stream: ctl.stream,
        send: sent.add,
        close: () {
          if (!ctl.isClosed) ctl.close();
        },
      );
    }

    final client = LiveTableClient.connect(
      Uri.parse('ws://x/ws'),
      retry: const Duration(milliseconds: 5),
      channelFactory: factory,
    );
    bool spectateSent() => sent.any((s) {
          final m = jsonDecode(s) as Map<String, dynamic>;
          return m['type'] == 'spectate' && m['tableId'] == 't7';
        });

    final c = OnlineGameController(client, spectateTableId: 't7');
    expect(spectateSent(), isTrue);

    sent.clear();
    await opened.first.close(); // انقطاعٌ غير مقصود
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(opened.length, 2, reason: 'أُعيد فتح القناة');
    expect(spectateSent(), isTrue,
        reason: 'الخادم أسقط المشاهدَ المنقطع ⇒ يعود بنيّةٍ جديدة');
    c.dispose();
  });
}
