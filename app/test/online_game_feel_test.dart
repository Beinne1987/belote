import 'dart:async';
import 'dart:convert';

import 'package:app/game/online_game_controller.dart';
import 'package:app/game/view_model.dart';
import 'package:app/net/table_client.dart';
import 'package:belote_engine/belote_engine.dart';
import 'package:flutter_test/flutter_test.dart';

final _codes = [for (final c in buildDeck()) c.code];

(OnlineGameController, void Function(Map<String, dynamic>), List<GameSound>) _harness({
  Duration dealAnim = Duration.zero,
  Duration collectAnim = Duration.zero,
}) {
  final incoming = StreamController<String>.broadcast();
  final sounds = <GameSound>[];
  final client = LiveTableClient(incoming: incoming.stream, send: (_) {});
  final c = OnlineGameController(client,
      onSound: sounds.add, dealAnim: dealAnim, collectAnim: collectAnim);
  void feed(Map<String, dynamic> m) => incoming.add(jsonEncode(m));
  return (c, feed, sounds);
}

Map<String, dynamic> _snap({
  required String phase,
  required int handLen,
  List<Map<String, dynamic>> trick = const [],
  Map<String, dynamic>? roundResult,
}) =>
    {
      'phase': phase,
      'seat': 0,
      'myHand': _codes.sublist(0, handLen),
      'handCounts': [handLen, handLen, handLen, handLen],
      'usScore': 0,
      'themScore': 0,
      'dealerSeat': 0,
      'bid': 'T',
      'bidderSeat': 0,
      'akwins': false,
      'turn': 0,
      'trick': trick,
      'yourTurn': false,
      'legalCards': const [],
      'legalBids': const [],
      'roundResult': roundResult,
      'matchOver': false,
    };

void main() {
  test('صوت التوزيع عند بداية الجولة، وصوت اللعب حين تكبر الأخذة', () async {
    final (c, feed, sounds) = _harness();
    feed(_snap(phase: 'bidding', handLen: 5)); // بداية ⇒ توزيع
    await Future<void>.delayed(Duration.zero);
    expect(sounds, contains(GameSound.deal));

    sounds.clear();
    // أول ورقةٍ في الأخذة ⇒ صوت لعب.
    feed(_snap(phase: 'playing', handLen: 5, trick: [
      {'seat': 1, 'card': _codes[10]},
    ]));
    await Future<void>.delayed(Duration.zero);
    expect(sounds, contains(GameSound.cardPlay));
  });

  test('اكتمال الأخذة ⇒ حركة جمعٍ نحو الفائز ثم إفراغ', () async {
    final (c, feed, _) = _harness(collectAnim: const Duration(milliseconds: 60));
    // أخذةٌ مكتملة (4 أوراق).
    feed(_snap(phase: 'playing', handLen: 4, trick: [
      {'seat': 0, 'card': _codes[0]},
      {'seat': 1, 'card': _codes[8]},
      {'seat': 2, 'card': _codes[16]},
      {'seat': 3, 'card': _codes[24]},
    ]));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    // لقطةٌ تُفرغ الأخذة ⇒ يبدأ الجمع.
    feed(_snap(phase: 'playing', handLen: 3, trick: const []));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(c.tableView!.collectingTo, isNotNull); // تنجمع نحو الفائز الآن
    expect(c.tableView!.trick.length, 4); // ما زالت الأربع ظاهرة أثناء الجمع

    await Future<void>.delayed(const Duration(milliseconds: 70));
    expect(c.tableView!.collectingTo, isNull); // انتهى الجمع
    expect(c.tableView!.trick, isEmpty); // وأُفرغت
  });

  test('صوت جمع الأبلي يُطلَق مع بداية حركة الجمع', () async {
    final (c, feed, sounds) = _harness(collectAnim: const Duration(milliseconds: 60));
    feed(_snap(phase: 'playing', handLen: 4, trick: [
      {'seat': 0, 'card': _codes[0]},
      {'seat': 1, 'card': _codes[8]},
      {'seat': 2, 'card': _codes[16]},
      {'seat': 3, 'card': _codes[24]},
    ]));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    sounds.clear(); // تجاهل صوت لعب الورقة
    feed(_snap(phase: 'playing', handLen: 3, trick: const []));

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(c.tableView!.collectingTo, isNotNull); // الحركة بدأت…
    expect(sounds, contains(GameSound.cardCollect)); // …ومعها صوتها
  });

  test('فقاعات الضمانة تُشتقّ من تيّار لقطات الخادم (كالأوفلاين)', () async {
    final (c, feed, _) = _harness();
    Map<String, dynamic> bidSnap({
      required int turn,
      String? bid,
      int? bidderSeat,
      bool akwins = false,
      String phase = 'bidding',
    }) =>
        {
          'phase': phase,
          'seat': 0, // مقعدي = 0 ⇒ العرض = هويّة
          'myHand': _codes.sublist(0, 5),
          'handCounts': const [5, 5, 5, 5],
          'usScore': 0,
          'themScore': 0,
          'dealerSeat': 3,
          'bid': bid,
          'bidderSeat': bidderSeat,
          'akwins': akwins,
          'turn': turn,
          'trick': const [],
          'yourTurn': false,
          'legalCards': const [],
          'legalBids': const [],
          'roundResult': null,
          'matchOver': false,
        };

    feed(bidSnap(turn: 0)); // بداية الضمانة — لا فقاعة بعد
    feed(bidSnap(turn: 1, bid: 'N', bidderSeat: 0)); // مقعد 0 ضمن صن
    feed(bidSnap(turn: 2, bid: 'N', bidderSeat: 0)); // مقعد 1 مرّر
    feed(bidSnap(turn: 3, bid: 'N', bidderSeat: 0)); // مقعد 2 مرّر
    feed(bidSnap(turn: 0, bid: 'N', bidderSeat: 0)); // مقعد 3 مرّر (انتهت الضمانة)
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final bids = c.tableView!.seatBids;
    expect(bids[0], isNotNull); // صاحب الضمانة له فقاعة (نصّ صن)
    expect(bids[1], 'تمرير');
    expect(bids[2], 'تمرير');
    expect(bids[3], 'تمرير');
  });
}
