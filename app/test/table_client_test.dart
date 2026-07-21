import 'dart:async';
import 'dart:convert';

import 'package:app/net/table_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// يبني عميلًا فوق قناةٍ وهميّة: [feed] يحقن رسائل الخادم، و[sent] يلتقط ما يُرسله العميل.
(LiveTableClient, void Function(Map<String, dynamic>), List<Map<String, dynamic>>) _fake() {
  final incoming = StreamController<String>();
  final sent = <Map<String, dynamic>>[];
  final client = LiveTableClient(
    incoming: incoming.stream,
    send: (s) => sent.add(jsonDecode(s) as Map<String, dynamic>),
  );
  void feed(Map<String, dynamic> m) => incoming.add(jsonEncode(m));
  return (client, feed, sent);
}

void main() {
  test('يحلّل لقطة اللوبي (مقاعد + رمز)', () async {
    final (client, feed, _) = _fake();
    final next = client.events.first;
    feed({
      'phase': 'lobby',
      'tableId': 't1',
      'code': 'ABCD',
      'seats': [
        {'seat': 0, 'ai': false, 'playerId': 'A', 'name': 'أحمد', 'connected': true},
        {'seat': 1, 'ai': true},
      ],
    });
    final e = await next;
    expect(e, isA<LobbyEvent>());
    final lobby = e as LobbyEvent;
    expect(lobby.code, 'ABCD');
    expect(lobby.seats[0].name, 'أحمد');
    expect(lobby.seats[1].ai, isTrue);
  });

  test('يحلّل لقطة المباراة (يدي + الأخذة + القانونيّ + الدور)', () async {
    final (client, feed, _) = _fake();
    final next = client.events.first;
    feed({
      'phase': 'playing',
      'seat': 0,
      'myHand': ['SA', 'H10'],
      'handCounts': [2, 3, 3, 3],
      'usScore': 16,
      'themScore': 0,
      'dealerSeat': 3,
      'turn': 0,
      'trick': [
        {'seat': 3, 'card': 'TK'}
      ],
      'yourTurn': true,
      'legalCards': ['SA'],
      'legalBids': [],
      'matchOver': false,
    });
    final e = await next as GameEvent;
    expect(e.myHand, ['SA', 'H10']);
    expect(e.yourTurn, isTrue);
    expect(e.legalCards, ['SA']);
    expect(e.trick.single.card, 'TK');
    expect(cardFromCode('SA'), isNotNull); // يتحوّل لورقة للعرض
  });

  test('يحلّل الخطأ (server_full)', () async {
    final (client, feed, _) = _fake();
    final next = client.events.first;
    feed({'error': 'server_full'});
    expect((await next as ServerError).code, 'server_full');
  });

  test('النيّات تُرسَل بصيغة البروتوكول الصحيحة', () {
    final (client, _, sent) = _fake();
    client.quickMatch();
    client.createPrivate();
    client.joinByCode('WXYZ');
    client.start();
    client.bid(2);
    client.play('SA');
    expect(sent, [
      {'type': 'quick'},
      {'type': 'create'},
      {'type': 'join', 'code': 'WXYZ'},
      {'type': 'start'},
      {'type': 'bid', 'index': 2},
      {'type': 'play', 'card': 'SA'},
    ]);
  });
}
