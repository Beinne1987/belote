import 'dart:async';
import 'dart:convert';

import 'package:app/game/online_game_controller.dart';
import 'package:app/net/table_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// **هويّةُ الجالسين أثناء اللعب** — أساسُ لوحة اللاعب (ملفّ · تصنيف · صداقة).
///
/// كانت الأسماءُ تُقرأ من لقطة اللوبي وحدها، ومَن جلس على مقعدٍ محجوز (بطولة) أو
/// أعاد الوصلَ في منتصف المباراة لا يمرّ بلوبيٍّ أصلًا ⇒ **طاولةٌ بلا هويّة**.
/// هذه الاختبارات تحرس أنّ اللقطة صارت مصدرًا كافيًا بذاتها، وأنّ اللوبي يبقى
/// احتياطيًّا لخادمٍ أقدمَ من الميزة.
(OnlineGameController, void Function(Map<String, dynamic>)) _harness() {
  final incoming = StreamController<String>.broadcast();
  final client = LiveTableClient(incoming: incoming.stream, send: (_) {});
  final c = OnlineGameController(client);
  return (c, (m) => incoming.add(jsonEncode(m)));
}

Map<String, dynamic> _snapshot({List<Map<String, dynamic>>? players}) => {
      'phase': 'playing',
      'seat': 0,
      'myHand': const ['AS'],
      'handCounts': [8, 8, 8, 8],
      'usScore': 0,
      'themScore': 0,
      'dealerSeat': 0,
      'bid': 'T',
      'bidderSeat': 0,
      'akwins': false,
      'turn': 0,
      'trick': const [],
      'yourTurn': true,
      'legalCards': const ['AS'],
      'legalBids': const [],
      'roundResult': null,
      'matchOver': false,
      if (players != null) 'players': players,
    };

void main() {
  test('لقطةٌ بهويّاتٍ ⇒ أسماءٌ ومعرّفاتٌ **بلا لوبيٍّ قطّ**', () async {
    final (c, feed) = _harness();
    feed(_snapshot(players: [
      {'seat': 0, 'playerId': 'me', 'name': 'أنا'},
      {'seat': 1, 'playerId': 'p1', 'name': 'محمد', 'vip': true},
      {'seat': 2, 'ai': true},
      {'seat': 3, 'playerId': 'p3', 'name': 'فاطمة', 'connected': false},
    ]));
    await Future<void>.delayed(Duration.zero);

    final seats = c.seatPlayers;
    expect(seats[1].name, 'محمد');
    expect(seats[1].playerId, 'p1');
    expect(seats[1].isVip, isTrue);
    expect(seats[3].connected, isFalse);
    expect(c.seatPlayerIds[1], 'p1');
  });

  test('**الذكاء بلا معرّف** ⇒ بطاقتُه لا تُفتَح (لا ملفَّ لروبوت)', () async {
    final (c, feed) = _harness();
    feed(_snapshot(players: [
      {'seat': 0, 'playerId': 'me', 'name': 'أنا'},
      {'seat': 1, 'ai': true},
      {'seat': 2, 'ai': true},
      {'seat': 3, 'ai': true},
    ]));
    await Future<void>.delayed(Duration.zero);

    expect(c.seatPlayers[1].playerId, isEmpty);
    expect(c.seatPlayers[1].isAI, isTrue);
    expect(c.seatPlayerIds[1], isNull);
  });

  test('لقطةٌ بلا هويّات (خادمٌ أقدم) ⇒ **يسقط إلى اللوبي** لا إلى الفراغ', () async {
    final (c, feed) = _harness();
    feed({
      'phase': 'lobby',
      'tableId': 't1',
      'you': 0,
      'searching': false,
      'seats': [
        {'seat': 0, 'ai': false, 'playerId': 'me', 'name': 'أنا', 'connected': true},
        {'seat': 1, 'ai': false, 'playerId': 'old', 'name': 'قديم', 'connected': true},
        {'seat': 2, 'ai': true},
        {'seat': 3, 'ai': true},
      ],
    });
    await Future<void>.delayed(Duration.zero);
    feed(_snapshot()); // بلا `players`
    await Future<void>.delayed(Duration.zero);

    expect(c.seatPlayers[1].name, 'قديم');
    expect(c.seatPlayerIds[1], 'old');
  });

  test('هويّاتُ اللقطة **تغلب** اللوبي حين يختلفان (إعادةُ جلوسٍ باسمٍ جديد)',
      () async {
    final (c, feed) = _harness();
    feed({
      'phase': 'lobby',
      'tableId': 't1',
      'you': 0,
      'searching': false,
      'seats': [
        {'seat': 0, 'ai': false, 'playerId': 'me', 'name': 'أنا', 'connected': true},
        {'seat': 1, 'ai': false, 'playerId': 'old', 'name': 'قديم', 'connected': true},
        {'seat': 2, 'ai': true},
        {'seat': 3, 'ai': true},
      ],
    });
    await Future<void>.delayed(Duration.zero);
    feed(_snapshot(players: [
      {'seat': 0, 'playerId': 'me', 'name': 'أنا'},
      {'seat': 1, 'playerId': 'new', 'name': 'جديد'},
      {'seat': 2, 'ai': true},
      {'seat': 3, 'ai': true},
    ]));
    await Future<void>.delayed(Duration.zero);

    expect(c.seatPlayers[1].name, 'جديد', reason: 'اللقطةُ أحدثُ من اللوبي');
    expect(c.seatPlayerIds[1], 'new');
  });

  test('SeatIdentity تقرأ الحقول الناقصة بأمانٍ (خادمٌ يبثّ الحدَّ الأدنى)', () {
    final s = SeatIdentity.fromJson({'seat': 2});
    expect(s.playerId, isEmpty);
    expect(s.name, isEmpty);
    expect(s.isAI, isFalse);
    expect(s.connected, isTrue);
  });
}
